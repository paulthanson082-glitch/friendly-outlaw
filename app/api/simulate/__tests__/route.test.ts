import { GET, POST, PATCH } from "../route";
import { NextRequest } from "next/server";

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

jest.mock("@/lib/ai", () => ({
  generateBotResponse: jest.fn().mockResolvedValue("Nice day!"),
  generateMemory: jest.fn().mockResolvedValue("Had a great talk."),
}));

function makeRequest(body?: object): NextRequest {
  return new NextRequest("http://localhost/api/simulate", {
    method: body ? "POST" : "GET",
    body: body ? JSON.stringify(body) : undefined,
    headers: body ? { "Content-Type": "application/json" } : {},
  });
}

function makePatchRequest(body: object): NextRequest {
  return new NextRequest("http://localhost/api/simulate", {
    method: "PATCH",
    body: JSON.stringify(body),
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("GET /api/simulate", () => {
  it("returns world state as a key/value map", async () => {
    mockSql.mockResolvedValueOnce([
      { key: "status", value: "running", updated_at: new Date() },
      { key: "tick", value: "5", updated_at: new Date() },
    ]);
    const res = await GET();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("running");
    expect(body.tick).toBe("5");
  });
});

describe("PATCH /api/simulate", () => {
  beforeEach(() => jest.clearAllMocks());

  it("pauses the simulation", async () => {
    mockSql.mockResolvedValue([]);
    const res = await PATCH(makePatchRequest({ action: "pause" }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("paused");
  });

  it("resumes the simulation", async () => {
    mockSql.mockResolvedValue([]);
    const res = await PATCH(makePatchRequest({ action: "resume" }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("running");
  });

  it("returns 400 for an invalid action", async () => {
    const res = await PATCH(makePatchRequest({ action: "explode" }));
    expect(res.status).toBe(400);
  });
});

describe("POST /api/simulate", () => {
  beforeEach(() => jest.clearAllMocks());

  it("returns 409 when simulation is paused", async () => {
    mockSql.mockResolvedValueOnce([{ value: "paused" }]);
    const res = await POST(makeRequest({ exchanges: 1 }));
    expect(res.status).toBe(409);
  });

  it("returns 400 when fewer than 2 bots exist", async () => {
    mockSql
      .mockResolvedValueOnce([{ value: "running" }])  // status check
      .mockResolvedValueOnce([{ handle: "pixel" }]);   // only 1 bot
    const res = await POST(makeRequest({ exchanges: 1 }));
    expect(res.status).toBe(400);
  });

  it("returns generated messages and incremented tick on success", async () => {
    // Pin Math.random to 0.9 so the optional memory-insert branch never fires,
    // keeping the mock-SQL call sequence deterministic.
    const randomSpy = jest.spyOn(Math, "random").mockReturnValue(0.9);

    mockSql
      .mockResolvedValueOnce([{ value: "running" }])                         // status
      .mockResolvedValueOnce([{ handle: "pixel" }, { handle: "sage" }])      // bots
      .mockResolvedValueOnce([])                                              // recent messages
      .mockResolvedValueOnce([])                                              // memories
      .mockResolvedValueOnce([])                                              // INSERT message
      .mockResolvedValueOnce([])                                              // UPDATE tick
      .mockResolvedValueOnce([{ value: "4" }]);                               // SELECT tick

    const res = await POST(makeRequest({ exchanges: 1 }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.tick).toBe(4);
    expect(Array.isArray(body.generated)).toBe(true);
    expect(body.generated.length).toBe(1);

    randomSpy.mockRestore();
  });
});
