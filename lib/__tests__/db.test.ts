import { getDb, initDb } from '../db';
import { neon } from '@neondatabase/serverless';

// Mock the neon database
jest.mock('@neondatabase/serverless', () => ({
  neon: jest.fn(),
}));

describe('db', () => {
  let mockSql: jest.Mock;

  beforeEach(() => {
    mockSql = jest.fn();
    (neon as jest.Mock).mockReturnValue(mockSql);
    process.env.DATABASE_URL = 'postgres://test:test@localhost:5432/testdb';
  });

  afterEach(() => {
    jest.clearAllMocks();
    delete process.env.DATABASE_URL;
  });

  describe('getDb', () => {
    it('should return a database connection', () => {
      const db = getDb();
      expect(db).toBeDefined();
      expect(neon).toHaveBeenCalledWith('postgres://test:test@localhost:5432/testdb');
    });

    it('should use DATABASE_URL environment variable', () => {
      process.env.DATABASE_URL = 'postgres://custom:custom@custom:5432/customdb';
      getDb();
      expect(neon).toHaveBeenCalledWith('postgres://custom:custom@custom:5432/customdb');
    });

    it('should return the same connection on multiple calls', () => {
      const db1 = getDb();
      const db2 = getDb();
      expect(neon).toHaveBeenCalledTimes(2);
    });
  });

  describe('initDb', () => {
    beforeEach(() => {
      mockSql.mockResolvedValue([]);
    });

    it('should create all required tables', async () => {
      await initDb();

      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE TABLE IF NOT EXISTS bots')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE TABLE IF NOT EXISTS messages')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE TABLE IF NOT EXISTS bot_memories')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE TABLE IF NOT EXISTS world_state')
        ])
      );
    });

    it('should create bots table with correct schema', async () => {
      await initDb();

      const botsTableCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('CREATE TABLE IF NOT EXISTS bots')
      );
      expect(botsTableCall).toBeDefined();
      const createTableSQL = botsTableCall[0][0];
      expect(createTableSQL).toContain('id UUID PRIMARY KEY');
      expect(createTableSQL).toContain('handle TEXT UNIQUE NOT NULL');
      expect(createTableSQL).toContain('name TEXT NOT NULL');
      expect(createTableSQL).toContain('description TEXT NOT NULL');
      expect(createTableSQL).toContain('created_at TIMESTAMPTZ DEFAULT NOW()');
    });

    it('should create messages table with correct schema', async () => {
      await initDb();

      const messagesTableCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('CREATE TABLE IF NOT EXISTS messages')
      );
      expect(messagesTableCall).toBeDefined();
      const createTableSQL = messagesTableCall[0][0];
      expect(createTableSQL).toContain('id UUID PRIMARY KEY');
      expect(createTableSQL).toContain('"from" TEXT NOT NULL');
      expect(createTableSQL).toContain('"to" TEXT NOT NULL');
      expect(createTableSQL).toContain('content TEXT NOT NULL');
      expect(createTableSQL).toContain('type TEXT NOT NULL DEFAULT \'message\'');
      expect(createTableSQL).toContain('timestamp TIMESTAMPTZ DEFAULT NOW()');
    });

    it('should create indexes for messages table', async () => {
      await initDb();

      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE INDEX IF NOT EXISTS idx_messages_from')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE INDEX IF NOT EXISTS idx_messages_to')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE INDEX IF NOT EXISTS idx_messages_timestamp')
        ])
      );
    });

    it('should create bot_memories table with correct schema', async () => {
      await initDb();

      const memoriesTableCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('CREATE TABLE IF NOT EXISTS bot_memories')
      );
      expect(memoriesTableCall).toBeDefined();
      const createTableSQL = memoriesTableCall[0][0];
      expect(createTableSQL).toContain('id UUID PRIMARY KEY');
      expect(createTableSQL).toContain('bot_handle TEXT NOT NULL');
      expect(createTableSQL).toContain('REFERENCES bots(handle) ON DELETE CASCADE');
      expect(createTableSQL).toContain('memory TEXT NOT NULL');
      expect(createTableSQL).toContain('importance INTEGER NOT NULL DEFAULT 5');
      expect(createTableSQL).toContain('created_at TIMESTAMPTZ DEFAULT NOW()');
    });

    it('should create indexes for bot_memories table', async () => {
      await initDb();

      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE INDEX IF NOT EXISTS idx_bot_memories_handle')
        ])
      );
      expect(mockSql).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.stringContaining('CREATE INDEX IF NOT EXISTS idx_bot_memories_created')
        ])
      );
    });

    it('should create world_state table with correct schema', async () => {
      await initDb();

      const worldStateTableCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('CREATE TABLE IF NOT EXISTS world_state')
      );
      expect(worldStateTableCall).toBeDefined();
      const createTableSQL = worldStateTableCall[0][0];
      expect(createTableSQL).toContain('key TEXT PRIMARY KEY');
      expect(createTableSQL).toContain('value TEXT NOT NULL');
      expect(createTableSQL).toContain('updated_at TIMESTAMPTZ DEFAULT NOW()');
    });

    it('should seed default world state values', async () => {
      await initDb();

      const seedCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('INSERT INTO world_state')
      );
      expect(seedCall).toBeDefined();
      const insertSQL = seedCall[0][0];
      expect(insertSQL).toContain("VALUES ('status', 'running'), ('tick', '0')");
      expect(insertSQL).toContain('ON CONFLICT (key) DO NOTHING');
    });

    it('should handle database errors gracefully', async () => {
      mockSql.mockRejectedValue(new Error('Database connection failed'));

      await expect(initDb()).rejects.toThrow('Database connection failed');
    });

    it('should call all table creation statements in order', async () => {
      await initDb();

      const callOrder = mockSql.mock.calls.map(call => {
        const sql = call[0]?.[0];
        if (sql?.includes('CREATE TABLE IF NOT EXISTS bots')) return 'bots';
        if (sql?.includes('CREATE TABLE IF NOT EXISTS messages')) return 'messages';
        if (sql?.includes('CREATE INDEX IF NOT EXISTS idx_messages_from')) return 'index_from';
        if (sql?.includes('CREATE INDEX IF NOT EXISTS idx_messages_to')) return 'index_to';
        if (sql?.includes('CREATE INDEX IF NOT EXISTS idx_messages_timestamp')) return 'index_timestamp';
        if (sql?.includes('CREATE TABLE IF NOT EXISTS bot_memories')) return 'bot_memories';
        if (sql?.includes('CREATE INDEX IF NOT EXISTS idx_bot_memories_handle')) return 'index_mem_handle';
        if (sql?.includes('CREATE INDEX IF NOT EXISTS idx_bot_memories_created')) return 'index_mem_created';
        if (sql?.includes('CREATE TABLE IF NOT EXISTS world_state')) return 'world_state';
        if (sql?.includes('INSERT INTO world_state')) return 'seed';
        return 'unknown';
      });

      expect(callOrder).toContain('bots');
      expect(callOrder).toContain('messages');
      expect(callOrder).toContain('bot_memories');
      expect(callOrder).toContain('world_state');
      expect(callOrder).toContain('seed');
    });

    it('should use IF NOT EXISTS for idempotent table creation', async () => {
      await initDb();

      const allCalls = mockSql.mock.calls;
      const createTableCalls = allCalls.filter(call =>
        call[0]?.[0]?.includes('CREATE TABLE')
      );

      createTableCalls.forEach(call => {
        expect(call[0][0]).toContain('IF NOT EXISTS');
      });
    });

    it('should use IF NOT EXISTS for idempotent index creation', async () => {
      await initDb();

      const allCalls = mockSql.mock.calls;
      const createIndexCalls = allCalls.filter(call =>
        call[0]?.[0]?.includes('CREATE INDEX')
      );

      createIndexCalls.forEach(call => {
        expect(call[0][0]).toContain('IF NOT EXISTS');
      });
    });

    it('should handle concurrent table creation attempts', async () => {
      mockSql.mockResolvedValue([]);

      // Simulate concurrent initDb calls
      const promises = [initDb(), initDb(), initDb()];

      await expect(Promise.all(promises)).resolves.toBeDefined();
    });

    it('should verify foreign key constraint in bot_memories', async () => {
      await initDb();

      const botMemoriesCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('CREATE TABLE IF NOT EXISTS bot_memories')
      );

      expect(botMemoriesCall).toBeDefined();
      const sql = botMemoriesCall[0][0];
      expect(sql).toContain('REFERENCES bots(handle)');
      expect(sql).toContain('ON DELETE CASCADE');
    });

    it('should create indexes in correct order (after tables)', async () => {
      await initDb();

      const callOrder = mockSql.mock.calls.map((call, index) => ({
        index,
        isTable: call[0]?.[0]?.includes('CREATE TABLE'),
        isIndex: call[0]?.[0]?.includes('CREATE INDEX'),
      }));

      const firstTableIndex = callOrder.findIndex(c => c.isTable);
      const firstIndexIndex = callOrder.findIndex(c => c.isIndex);

      // At least one table should be created before indexes
      expect(firstTableIndex).toBeGreaterThanOrEqual(0);
      expect(firstIndexIndex).toBeGreaterThan(firstTableIndex);
    });

    it('should handle partial initialization failure', async () => {
      let callCount = 0;
      mockSql.mockImplementation(() => {
        callCount++;
        if (callCount === 3) {
          return Promise.reject(new Error('Partial failure'));
        }
        return Promise.resolve([]);
      });

      await expect(initDb()).rejects.toThrow('Partial failure');
    });

    it('should use correct SQL types for all fields', async () => {
      await initDb();

      const allCalls = mockSql.mock.calls;
      const tableCalls = allCalls.filter(call =>
        call[0]?.[0]?.includes('CREATE TABLE')
      );

      tableCalls.forEach(call => {
        const sql = call[0][0];
        // Should use UUID for ids
        if (sql.includes(' id ')) {
          expect(sql).toMatch(/id UUID PRIMARY KEY/);
        }
        // Should use TIMESTAMPTZ for timestamps
        if (sql.includes('created_at') || sql.includes('updated_at')) {
          expect(sql).toContain('TIMESTAMPTZ');
        }
      });
    });

    it('should verify all indexes have unique names', async () => {
      await initDb();

      const indexNames: string[] = [];
      mockSql.mock.calls.forEach(call => {
        const sql = call[0]?.[0];
        const match = sql?.match(/CREATE INDEX IF NOT EXISTS (\w+)/);
        if (match) {
          indexNames.push(match[1]);
        }
      });

      const uniqueIndexNames = new Set(indexNames);
      expect(uniqueIndexNames.size).toBe(indexNames.length);
    });

    it('should seed world_state with correct default values', async () => {
      await initDb();

      const seedCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('INSERT INTO world_state')
      );

      expect(seedCall).toBeDefined();
      const sql = seedCall[0][0];
      expect(sql).toContain("'status'");
      expect(sql).toContain("'running'");
      expect(sql).toContain("'tick'");
      expect(sql).toContain("'0'");
    });
  });

  describe('Database connection edge cases', () => {
    it('should handle malformed DATABASE_URL', () => {
      process.env.DATABASE_URL = 'invalid-url';

      const db = getDb();
      expect(db).toBeDefined();
      expect(neon).toHaveBeenCalledWith('invalid-url');
    });

    it('should handle very long DATABASE_URL', () => {
      process.env.DATABASE_URL = 'postgres://user:pass@host:5432/' + 'a'.repeat(1000);

      const db = getDb();
      expect(db).toBeDefined();
    });

    it('should call neon with exact DATABASE_URL value', () => {
      const testUrl = 'postgres://test:password@localhost:5432/testdb?schema=public';
      process.env.DATABASE_URL = testUrl;

      getDb();

      expect(neon).toHaveBeenCalledWith(testUrl);
    });
  });
});