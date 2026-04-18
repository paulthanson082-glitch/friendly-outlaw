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

/**
 * Helper: run the seed module in an isolated module registry so the auto-
 * executing `seed().catch(console.error)` at the bottom of lib/seed.ts fires
 * freshly for each test.  Returns once the module has settled (we await the
 * microtask queue plus one macro-task tick).
 */
async function runSeedModule(): Promise<void> {
  await new Promise<void>((resolve) => {
    jest.isolateModules(() => {
      require('../seed');
      resolve();
    });
  });
  // Allow the async seed() promise to settle
  await new Promise((r) => setTimeout(r, 50));
}

describe('seed module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSql.mockImplementation(async () => []);
    mockInitDb.mockImplementation(async () => {});
    jest.spyOn(console, 'log').mockImplementation();
    jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('seed function', () => {
    it('should call initDb to initialize database', async () => {
      await runSeedModule();
      expect(mockInitDb).toHaveBeenCalled();
    });

    it('should insert all characters into database', async () => {
      await runSeedModule();

      const sql = mockSql;
      const insertCalls = (sql as jest.Mock).mock.calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('INSERT INTO bots'))
      );

      expect(insertCalls.length).toBeGreaterThanOrEqual(characters.length);
    });

    it('should use ON CONFLICT clause for upsert behavior', async () => {
      await runSeedModule();

      const sql = mockSql;
      const insertCalls = (sql as jest.Mock).mock.calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('ON CONFLICT (handle) DO UPDATE'))
      );

      expect(insertCalls.length).toBeGreaterThan(0);
    });

    it('should log success message after seeding', async () => {
      await runSeedModule();

      // console.log is called with two args:
      //   "Seeded AI Town residents:" and "@pixel (Pixel), @sage (Sage)"
      expect(console.log).toHaveBeenCalledWith(
        expect.stringContaining('Seeded AI Town residents'),
        expect.any(String)
      );
    });

    it('should include character handles in success message', async () => {
      await runSeedModule();

      const logCalls = (console.log as jest.Mock).mock.calls;
      // console.log("Seeded AI Town residents:", "@pixel (Pixel), @sage (Sage)")
      const seedMessage = logCalls.find((call) =>
        typeof call[0] === 'string' && call[0].includes('Seeded AI Town residents')
      );

      expect(seedMessage).toBeDefined();
      // Second argument contains the comma-separated handle list
      expect(seedMessage[1]).toContain('@pixel');
      expect(seedMessage[1]).toContain('@sage');
    });

    it('should handle database errors by logging via catch(console.error)', async () => {
      mockInitDb.mockRejectedValueOnce(new Error('DB Connection Error'));

      await runSeedModule();

      expect(console.error).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'DB Connection Error' })
      );
    });

    it('should handle insert errors by logging via catch(console.error)', async () => {
      mockSql.mockRejectedValueOnce(new Error('Insert Error'));

      await runSeedModule();

      expect(console.error).toHaveBeenCalled();
    });

    it('should not export the seed function (seed is module-private)', () => {
      let seedModule: any;
      jest.isolateModules(() => {
        seedModule = require('../seed');
      });
      // The seed function is unexported; only module-level effects are observable
      expect(seedModule.seed).toBeUndefined();
    });
  });

  describe('data integrity', () => {
    it('should insert correct character data for pixel', async () => {
      await runSeedModule();

      const calls = (mockSql as jest.Mock).mock.calls;

      // Template-tag calls: first arg is TemplateStringsArray; values are
      // individual interpolated arguments.
      const pixelCall = calls.find(
        (call) => call.includes('pixel') && call.includes('Pixel')
      );
      expect(pixelCall).toBeDefined();
    });

    it('should insert correct character data for sage', async () => {
      await runSeedModule();

      const calls = (mockSql as jest.Mock).mock.calls;
      const sageCall = calls.find(
        (call) => call.includes('sage') && call.includes('Sage')
      );
      expect(sageCall).toBeDefined();
    });

    it('should update existing characters on conflict using DO UPDATE SET', async () => {
      await runSeedModule();

      const calls = (mockSql as jest.Mock).mock.calls;
      const updateCalls = calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('DO UPDATE SET'))
      );
      expect(updateCalls.length).toBeGreaterThan(0);
    });

    it('should include EXCLUDED.name in the upsert clause', async () => {
      await runSeedModule();

      const calls = (mockSql as jest.Mock).mock.calls;
      const upsertCalls = calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('EXCLUDED.name'))
      );
      expect(upsertCalls.length).toBeGreaterThan(0);
    });

    it('should include EXCLUDED.description in the upsert clause', async () => {
      await runSeedModule();

      const calls = (mockSql as jest.Mock).mock.calls;
      const upsertCalls = calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('EXCLUDED.description'))
      );
      expect(upsertCalls.length).toBeGreaterThan(0);
    });
  });

  describe('idempotency', () => {
    it('should be safe to run multiple times (initDb called each time)', async () => {
      await runSeedModule();
      const firstCount = mockInitDb.mock.calls.length;
      expect(firstCount).toBeGreaterThan(0);

      await runSeedModule();
      expect(mockInitDb.mock.calls.length).toBeGreaterThan(firstCount);
    });

    it('should use ON CONFLICT to handle duplicate handles gracefully', async () => {
      await runSeedModule();

      const sql = mockSql;
      const conflictCalls = (sql as jest.Mock).mock.calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('ON CONFLICT'))
      );

      expect(conflictCalls.length).toBeGreaterThan(0);
    });
  });

  describe('edge cases', () => {
    it('should still log success even when characters list has entries with description', async () => {
      await runSeedModule();

      // Both characters have descriptions; log message should include their handles
      const logCalls = (console.log as jest.Mock).mock.calls;
      // console.log("Seeded AI Town residents:", "@pixel (Pixel), @sage (Sage)")
      const seedMsg = logCalls.find((c) => typeof c[0] === 'string' && c[0].includes('Seeded'));
      expect(seedMsg).toBeDefined();
      // Character display names appear in the second argument
      expect(seedMsg[1]).toContain('(Pixel)');
      expect(seedMsg[1]).toContain('(Sage)');
    });

    it('should call getDb after initDb succeeds', async () => {
      const { getDb } = require('../db');
      await runSeedModule();
      expect(getDb).toHaveBeenCalled();
    });

    it('should not throw at module level (errors caught by .catch)', async () => {
      mockInitDb.mockRejectedValueOnce(new Error('Fatal DB Error'));

      // Should not throw – seed() result is consumed by .catch(console.error)
      await expect(runSeedModule()).resolves.toBeUndefined();
    });
  });

  describe('performance and reliability', () => {
    it('should use parameterized queries (template tag) to prevent SQL injection', async () => {
      await runSeedModule();

      const sql = mockSql;
      // Template-tag calls pass a TemplateStringsArray as first argument
      const calls = (sql as jest.Mock).mock.calls;
      const taggedCalls = calls.filter((call) => Array.isArray(call[0]));
      expect(taggedCalls.length).toBeGreaterThan(0);
    });

    it('should execute one INSERT per character in the characters list', async () => {
      await runSeedModule();

      const insertCalls = (mockSql as jest.Mock).mock.calls.filter((call) =>
        call[0]?.some?.((str: string) => str.includes('INSERT INTO bots'))
      );

      expect(insertCalls.length).toBe(characters.length);
    });
  });
});