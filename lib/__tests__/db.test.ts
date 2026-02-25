import { getDb, initDb } from "../db";

// Mock the Neon client so tests never need a real database
const mockSql = jest.fn();

jest.mock("@neondatabase/serverless", () => ({
  neon: jest.fn(() => {
    // Make the mock callable as a tagged-template and as a function
    const sql: any = (...args: any[]) => mockSql(...args);
    return sql;
  }),
}));

describe("getDb", () => {
  beforeEach(() => {
    process.env.DATABASE_URL = "postgres://test:test@localhost/test";
  });

  it("returns a sql function", () => {
    const sql = getDb();
    expect(typeof sql).toBe("function");
  });
});

describe("initDb", () => {
  beforeEach(() => {
    process.env.DATABASE_URL = "postgres://test:test@localhost/test";
    mockSql.mockResolvedValue([]);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it("creates the bots table", async () => {
    await initDb();
    const calls: string[] = mockSql.mock.calls.map((c: any[]) =>
      (Array.isArray(c[0]) ? c[0].join("") : String(c[0])).replace(/\s+/g, " ").trim()
    );
    const createdBots = calls.some((s) => s.includes("bots"));
    expect(createdBots).toBe(true);
  });

  it("creates the messages table", async () => {
    await initDb();
    const calls: string[] = mockSql.mock.calls.map((c: any[]) =>
      (Array.isArray(c[0]) ? c[0].join("") : String(c[0])).replace(/\s+/g, " ").trim()
    );
    const createdMessages = calls.some((s) => s.includes("messages"));
    expect(createdMessages).toBe(true);
  });

  it("creates the bot_memories table", async () => {
    await initDb();
    const calls: string[] = mockSql.mock.calls.map((c: any[]) =>
      (Array.isArray(c[0]) ? c[0].join("") : String(c[0])).replace(/\s+/g, " ").trim()
    );
    const createdMemories = calls.some((s) => s.includes("bot_memories"));
    expect(createdMemories).toBe(true);
  });

  it("creates the world_state table", async () => {
    await initDb();
    const calls: string[] = mockSql.mock.calls.map((c: any[]) =>
      (Array.isArray(c[0]) ? c[0].join("") : String(c[0])).replace(/\s+/g, " ").trim()
    );
    const createdWorld = calls.some((s) => s.includes("world_state"));
    expect(createdWorld).toBe(true);
  });
});
