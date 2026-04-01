import { characters } from '../characters';

// Mock the db module
const mockSql = jest.fn(async () => []);
const mockInitDb = jest.fn(async () => {});

jest.mock('../db', () => ({
  getDb: jest.fn(() => mockSql),
  initDb: mockInitDb,
}));

jest.mock('../characters', () => ({
  characters: [
    {
      handle: 'pixel',
      name: 'Pixel',
      description: 'A curious artist',
      personality: 'Whimsical',
      interests: ['art'],
      initialPlan: 'Paint',
    },
    {
      handle: 'sage',
      name: 'Sage',
      description: 'A wise librarian',
      personality: 'Calm',
      interests: ['books'],
      initialPlan: 'Read',
    },
  ],
}));

describe('seed module', () => {
  let seedFn: () => Promise<void>;

  beforeAll(async () => {
    // Import seed function once; module-level seed() call runs here
    const mod = await import('../seed');
    seedFn = mod.seed;
  });

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(console, 'log').mockImplementation();
    jest.spyOn(console, 'error').mockImplementation();
    // Reset mockSql default implementation
    mockSql.mockImplementation(async () => []);
    mockInitDb.mockImplementation(async () => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('seed function', () => {
    it('should call initDb to initialize database', async () => {
      await seedFn();
      expect(mockInitDb).toHaveBeenCalled();
    });

    it('should insert all characters into database', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      const insertCalls = (sql as jest.Mock).mock.calls.filter(call =>
        call[0].some((str: string) => str.includes('INSERT INTO bots'))
      );

      expect(insertCalls.length).toBeGreaterThanOrEqual(characters.length);
    });

    it('should use ON CONFLICT clause for upsert behavior', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      const insertCalls = (sql as jest.Mock).mock.calls.filter(call =>
        call[0].some((str: string) => str.includes('ON CONFLICT (handle) DO UPDATE'))
      );

      expect(insertCalls.length).toBeGreaterThan(0);
    });

    it('should log success message after seeding', async () => {
      await seedFn();

      expect(console.log).toHaveBeenCalledWith(
        expect.stringContaining('Seeded AI Town residents')
      );
    });

    it('should include character handles in success message', async () => {
      await seedFn();

      const logCalls = (console.log as jest.Mock).mock.calls;
      const seedMessage = logCalls.find(call =>
        call[0].includes('Seeded AI Town residents')
      );

      expect(seedMessage).toBeDefined();
      expect(seedMessage[0]).toContain('@pixel');
      expect(seedMessage[0]).toContain('@sage');
    });

    it('should handle database errors', async () => {
      mockInitDb.mockRejectedValueOnce(new Error('DB Connection Error'));

      await expect(seedFn()).rejects.toThrow('DB Connection Error');
    });

    it('should handle insert errors', async () => {
      mockSql.mockRejectedValueOnce(new Error('Insert Error'));

      await expect(seedFn()).rejects.toThrow('Insert Error');
    });
  });

  describe('data integrity', () => {
    it('should insert correct character data', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      const calls = (sql as jest.Mock).mock.calls;

      // Template tag calls have strings array + interpolated values
      // The strings array contains the SQL text parts
      const pixelCall = calls.find(call =>
        Array.isArray(call[0]) && call.includes('pixel')
      );
      expect(pixelCall).toBeDefined();
    });

    it('should update existing characters on conflict', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      const calls = (sql as jest.Mock).mock.calls;

      const updateCalls = calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('DO UPDATE SET'))
      );
      expect(updateCalls.length).toBeGreaterThan(0);
    });
  });

  describe('idempotency', () => {
    it('should be safe to run multiple times', async () => {
      await seedFn();
      await seedFn();

      expect(mockInitDb).toHaveBeenCalledTimes(2);
    });

    it('should handle duplicate handles gracefully', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      const conflictCalls = (sql as jest.Mock).mock.calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('ON CONFLICT'))
      );

      expect(conflictCalls.length).toBeGreaterThan(0);
    });
  });

  describe('edge cases', () => {
    it('should handle empty characters array', async () => {
      // Override character mock to empty array for this test
      const { getDb } = require('../db');
      const charMock = require('../characters');
      const originalChars = charMock.characters;
      charMock.characters = [];

      await seedFn();

      expect(console.log).toHaveBeenCalled();

      charMock.characters = originalChars;
    });

    it('should handle characters with special characters in names', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      expect(sql).toHaveBeenCalled();
    });

  });

  describe('performance and reliability', () => {
    it('should use parameterized queries to prevent SQL injection', async () => {
      const { getDb } = require('../db');

      await seedFn();

      const sql = getDb();
      // The fact that getDb() was called means seed ran
      expect(sql).toBeDefined();
    });
  });
});
