// Smoke-test the seed module: verify it inserts each character

const mockSql = jest.fn();

jest.mock("@neondatabase/serverless", () => ({
  neon: jest.fn(() => {
    const sql: any = (...args: any[]) => mockSql(...args);
    return sql;
  }),
}));

import { characters } from "../characters";

describe("seed", () => {
  beforeEach(() => {
    process.env.DATABASE_URL = "postgres://test:test@localhost/test";
    mockSql.mockResolvedValue([]);
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
  });

  it("attempts to upsert every character into bots", async () => {
    // Dynamically import so the module-level mock is in place
    await import("../seed");

    // Give async work a tick to settle
    await new Promise((r) => setTimeout(r, 0));

    const insertCalls = mockSql.mock.calls.filter((c: any[]) => {
      const q = (Array.isArray(c[0]) ? c[0].join("") : String(c[0]))
        .replace(/\s+/g, " ")
        .toLowerCase();
      return q.includes("insert into bots");
    });

    expect(insertCalls.length).toBe(characters.length);
  });
});
