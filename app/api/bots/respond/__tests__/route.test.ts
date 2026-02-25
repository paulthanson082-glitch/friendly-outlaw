import { POST } from "../route";
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
  generateBotResponse: jest.fn().mockResolvedValue("Hello there!"),
  generateMemory: jest.fn().mockResolvedValue("Had a nice chat."),
}));

function makeRequest(body: object): NextRequest {
  return new NextRequest("http://localhost/api/bots/respond", {
    method: "POST",
    body: JSON.stringify(body),
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("POST /api/bots/respond", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("returns 400 when speaker is missing", async () => {
    const res = await POST(makeRequest({ listener: "sage" }));
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/speaker/);
  });

  it("returns 400 when listener is missing", async () => {
    const res = await POST(makeRequest({ speaker: "pixel" }));
    expect(res.status).toBe(400);
  });

  it("returns 400 when speaker and listener are the same", async () => {
    const res = await POST(makeRequest({ speaker: "pixel", listener: "pixel" }));
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/different/);
  });

  it("returns 404 when speaker bot does not exist", async () => {
    mockSql
      .mockResolvedValueOnce([])   // speaker lookup → not found
    const res = await POST(makeRequest({ speaker: "ghost", listener: "sage" }));
    expect(res.status).toBe(404);
  });

  it("returns 404 when listener bot does not exist", async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: "pixel" }])  // speaker found
      .mockResolvedValueOnce([])                      // listener not found
    const res = await POST(makeRequest({ speaker: "pixel", listener: "ghost" }));
    expect(res.status).toBe(404);
  });

  it("returns 201 with the stored message on success", async () => {
    const storedMessage = {
      id: "uuid-1",
      from: "pixel",
      to: "sage",
      content: "Hello there!",
      type: "ai_response",
      timestamp: new Date().toISOString(),
    };
    mockSql
      .mockResolvedValueOnce([{ handle: "pixel" }])  // speaker found
      .mockResolvedValueOnce([{ handle: "sage" }])   // listener found
      .mockResolvedValueOnce([])                      // recent messages
      .mockResolvedValueOnce([])                      // memories
      .mockResolvedValueOnce([storedMessage]);         // INSERT returning

    const res = await POST(makeRequest({ speaker: "pixel", listener: "sage" }));
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.content).toBe("Hello there!");
    expect(body.from).toBe("pixel");
  });
});
