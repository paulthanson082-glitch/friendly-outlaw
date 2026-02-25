import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import Home from "../page";

// ---------------------------------------------------------------------------
// Mock fetch globally
// ---------------------------------------------------------------------------

const townData = {
  world: { status: "running", tick: "3" },
  residents: [
    {
      id: "abc",
      handle: "pixel",
      name: "Pixel",
      description: "A curious artist.",
      latestMemory: "I love painting sunsets.",
      created_at: new Date().toISOString(),
    },
    {
      id: "def",
      handle: "sage",
      name: "Sage",
      description: "A wise librarian.",
      latestMemory: null,
      created_at: new Date().toISOString(),
    },
  ],
  feed: [
    {
      id: "msg1",
      from: "pixel",
      to: "sage",
      from_name: "Pixel",
      to_name: "Sage",
      content: "Good morning, Sage!",
      type: "simulation",
      timestamp: new Date().toISOString(),
    },
  ],
};

const mockFetch = jest.fn();

beforeAll(() => {
  global.fetch = mockFetch;
});

beforeEach(() => {
  mockFetch.mockResolvedValue({
    ok: true,
    json: async () => townData,
    text: async () => JSON.stringify(townData),
  });
});

afterEach(() => {
  jest.clearAllMocks();
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Home (AI Town page)", () => {
  it("shows the AI Town heading", async () => {
    render(<Home />);
    await waitFor(() => screen.getByText(/AI Town/i));
    expect(screen.getByText(/AI Town/i)).toBeInTheDocument();
  });

  it("displays resident names after loading", async () => {
    render(<Home />);
    // "Pixel" and "Sage" appear in both the resident card and the feed header;
    // getAllByText handles the duplicates.
    await waitFor(() => screen.getAllByText("Pixel"));
    expect(screen.getAllByText("Pixel").length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText("Sage").length).toBeGreaterThanOrEqual(1);
  });

  it("renders the conversation feed", async () => {
    render(<Home />);
    await waitFor(() => screen.getByText("Good morning, Sage!"));
    expect(screen.getByText("Good morning, Sage!")).toBeInTheDocument();
  });

  it("shows the tick counter", async () => {
    render(<Home />);
    await waitFor(() => screen.getByText(/Tick #3/));
    expect(screen.getByText(/Tick #3/)).toBeInTheDocument();
  });

  it("shows a resident's memory", async () => {
    render(<Home />);
    await waitFor(() => screen.getByText(/I love painting sunsets/));
    expect(screen.getByText(/I love painting sunsets/)).toBeInTheDocument();
  });

  it("clicking a resident filters the feed label", async () => {
    render(<Home />);
    await waitFor(() => screen.getAllByText("Pixel"));
    fireEvent.click(screen.getAllByText("Pixel")[0]);
    await waitFor(() => screen.getByText(/Conversations with @pixel/i));
    expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
  });

  it("shows an error banner when fetch fails", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      text: async () => "Internal Server Error",
    });
    render(<Home />);
    await waitFor(() => screen.getByText(/Internal Server Error/i));
    expect(screen.getByText(/Internal Server Error/i)).toBeInTheDocument();
  });

  it("shows the Tick button", async () => {
    render(<Home />);
    await waitFor(() => screen.getByText(/▶ Tick/));
    expect(screen.getByText(/▶ Tick/)).toBeInTheDocument();
  });

  it("calls /api/simulate when Tick is clicked", async () => {
    mockFetch
      .mockResolvedValueOnce({ ok: true, json: async () => townData })   // initial load
      .mockResolvedValueOnce({ ok: true, json: async () => ({ tick: 4, generated: [] }) }) // simulate
      .mockResolvedValueOnce({ ok: true, json: async () => ({ ...townData, world: { ...townData.world, tick: "4" } }) }); // refresh

    render(<Home />);
    await waitFor(() => screen.getByText(/▶ Tick/));
    fireEvent.click(screen.getByText(/▶ Tick/));

    await waitFor(() => {
      const calls = mockFetch.mock.calls.map((c) => c[0] as string);
      expect(calls).toContain("/api/simulate");
    });
  });
});
