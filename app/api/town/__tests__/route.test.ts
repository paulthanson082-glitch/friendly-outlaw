import { GET } from "../route";

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const mockSql = jest.fn();

jest.mock("@neondatabase/serverless", () => ({
  neon: jest.fn(() => {
    const sql: any = (...args: any[]) => mockSql(...args);
    return sql;
  }),
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const residents = [
  { id: "1", handle: "pixel", name: "Pixel", description: "Artist", created_at: new Date() },
  { id: "2", handle: "sage", name: "Sage", description: "Librarian", created_at: new Date() },
];

const messages = [
  {
    id: "m1",
    from: "pixel",
    to: "sage",
    content: "Hi!",
    type: "simulation",
    timestamp: new Date(),
    from_name: "Pixel",
    to_name: "Sage",
  },
];

const worldState = [
  { key: "status", value: "running", updated_at: new Date() },
  { key: "tick", value: "7", updated_at: new Date() },
];

const memories = [
  { bot_handle: "pixel", memory: "Met Sage today.", created_at: new Date() },
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("GET /api/town", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Promise.all fires 4 queries in parallel
    mockSql
      .mockResolvedValueOnce(residents)
      .mockResolvedValueOnce(messages)
      .mockResolvedValueOnce(worldState)
      .mockResolvedValueOnce(memories);
  });

  it("returns 200", async () => {
    const res = await GET();
    expect(res.status).toBe(200);
  });

  it("includes residents with latestMemory attached", async () => {
    const res = await GET();
    const body = await res.json();
    expect(Array.isArray(body.residents)).toBe(true);
    const pixel = body.residents.find((r: any) => r.handle === "pixel");
    expect(pixel).toBeDefined();
    expect(pixel.latestMemory).toBe("Met Sage today.");
  });

  it("residents without a memory have latestMemory: null", async () => {
    const res = await GET();
    const body = await res.json();
    const sage = body.residents.find((r: any) => r.handle === "sage");
    expect(sage.latestMemory).toBeNull();
  });

  it("includes the feed", async () => {
    const res = await GET();
    const body = await res.json();
    expect(Array.isArray(body.feed)).toBe(true);
    expect(body.feed[0].content).toBe("Hi!");
  });

  it("includes world state", async () => {
    const res = await GET();
    const body = await res.json();
    expect(body.world.status).toBe("running");
    expect(body.world.tick).toBe("7");
  });
});
