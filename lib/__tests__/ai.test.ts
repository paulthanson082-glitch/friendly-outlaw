import { generateBotResponse, generateMemory } from "../ai";

// Mock the Anthropic SDK so tests never make real API calls
jest.mock("@anthropic-ai/sdk", () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
      messages: {
        create: jest.fn().mockResolvedValue({
          content: [{ type: "text", text: "Hello from the mock!" }],
        }),
      },
    })),
  };
});

describe("generateBotResponse", () => {
  it("returns the text from the Claude response", async () => {
    const result = await generateBotResponse("pixel", "sage", [], []);
    expect(typeof result).toBe("string");
    expect(result.length).toBeGreaterThan(0);
  });

  it("works with known characters", async () => {
    const result = await generateBotResponse(
      "pixel",
      "sage",
      [
        {
          from: "sage",
          to: "pixel",
          content: "Good morning!",
          timestamp: new Date().toISOString(),
        },
      ],
      []
    );
    expect(result).toBe("Hello from the mock!");
  });

  it("works with unknown handles (fallback to handle as name)", async () => {
    const result = await generateBotResponse("unknown-bot", "other-bot", [], []);
    expect(typeof result).toBe("string");
  });

  it("includes memories in the system prompt (smoke test)", async () => {
    const Anthropic = require("@anthropic-ai/sdk").default;
    const mockCreate = Anthropic.mock.results[0].value.messages.create;
    mockCreate.mockClear();

    await generateBotResponse("pixel", "sage", [], [
      { memory: "I enjoyed chatting with Sage yesterday.", importance: 5, created_at: new Date().toISOString() },
    ]);

    expect(mockCreate).toHaveBeenCalledTimes(1);
    const callArgs = mockCreate.mock.calls[0][0];
    expect(callArgs.system).toContain("memories");
  });

  it("throws if the API returns a non-text content block", async () => {
    const Anthropic = require("@anthropic-ai/sdk").default;
    const mockCreate = Anthropic.mock.results[0].value.messages.create;
    mockCreate.mockResolvedValueOnce({
      content: [{ type: "tool_use", id: "x", name: "y", input: {} }],
    });

    await expect(generateBotResponse("pixel", "sage", [], [])).rejects.toThrow(
      "Unexpected response type"
    );
  });
});

describe("generateMemory", () => {
  it("returns a non-empty string on success", async () => {
    const result = await generateMemory("pixel", "sage", [
      { from: "pixel", to: "sage", content: "Nice to meet you!", timestamp: new Date().toISOString() },
    ]);
    expect(typeof result).toBe("string");
    expect(result.length).toBeGreaterThan(0);
  });

  it("returns empty string when API returns non-text", async () => {
    const Anthropic = require("@anthropic-ai/sdk").default;
    const mockCreate = Anthropic.mock.results[0].value.messages.create;
    mockCreate.mockResolvedValueOnce({
      content: [{ type: "tool_use", id: "x", name: "y", input: {} }],
    });

    const result = await generateMemory("pixel", "sage", []);
    expect(result).toBe("");
  });
});
