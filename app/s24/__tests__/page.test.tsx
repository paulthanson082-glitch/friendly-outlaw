import React from "react";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import S24ToolsPage from "../page";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const getTabButton = (name: string | RegExp) =>
  screen
    .getAllByRole("button")
    .find((btn) => btn.textContent?.match(name) && btn.tagName !== "LI");

// ---------------------------------------------------------------------------
// localStorage setup
// ---------------------------------------------------------------------------

beforeEach(() => {
  localStorage.clear();
  jest.spyOn(Storage.prototype, "getItem");
  jest.spyOn(Storage.prototype, "setItem");
});

afterEach(() => {
  jest.restoreAllMocks();
  localStorage.clear();
});

// ---------------------------------------------------------------------------
// Initial render
// ---------------------------------------------------------------------------

describe("S24ToolsPage – initial render", () => {
  it("renders the page title", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText(/S24 Tools/i)).toBeInTheDocument();
  });

  it("renders the subtitle", () => {
    render(<S24ToolsPage />);
    expect(
      screen.getByText(/Speed · Productivity · Email · File Cleaning/i)
    ).toBeInTheDocument();
  });

  it("renders all four section tabs", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("Speed & Performance")).toBeInTheDocument();
    expect(screen.getByText("Productivity")).toBeInTheDocument();
    expect(screen.getByText("Email Management")).toBeInTheDocument();
    expect(screen.getByText("File Cleaning")).toBeInTheDocument();
  });

  it("shows the Speed & Performance section by default (first tab active)", () => {
    render(<S24ToolsPage />);
    // The section heading should be visible
    expect(
      screen.getByRole("heading", { name: /Speed & Performance/i })
    ).toBeInTheDocument();
  });

  it("renders overall progress badge showing 0 of 27 tasks done", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("0/27")).toBeInTheDocument();
    expect(screen.getByText("tasks done")).toBeInTheDocument();
  });

  it("renders the footer text", () => {
    render(<S24ToolsPage />);
    expect(
      screen.getByText(
        /Tap any task to mark it done\. Progress is saved automatically on your device\./i
      )
    ).toBeInTheDocument();
  });

  it("does NOT show the Reset button when no tasks are checked", () => {
    render(<S24ToolsPage />);
    expect(screen.queryByText("Reset")).not.toBeInTheDocument();
  });

  it("reads saved state from localStorage on mount", () => {
    render(<S24ToolsPage />);
    expect(localStorage.getItem).toHaveBeenCalledWith("s24-tools-checked");
  });
});

// ---------------------------------------------------------------------------
// Tab navigation
// ---------------------------------------------------------------------------

describe("S24ToolsPage – tab navigation", () => {
  it("switches to Productivity tab when clicked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    await user.click(screen.getByText("Productivity"));

    expect(
      screen.getByRole("heading", { name: /Productivity/i })
    ).toBeInTheDocument();
  });

  it("switches to Email Management tab when clicked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    await user.click(screen.getByText("Email Management"));

    expect(
      screen.getByRole("heading", { name: /Email Management/i })
    ).toBeInTheDocument();
  });

  it("switches to File Cleaning tab when clicked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    await user.click(screen.getByText("File Cleaning"));

    expect(
      screen.getByRole("heading", { name: /File Cleaning/i })
    ).toBeInTheDocument();
  });

  it("shows tasks belonging to the active tab only", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Speed tab is default – first task label should be visible
    expect(
      screen.getByText("Run Device Care optimizer")
    ).toBeInTheDocument();

    // Switch to Productivity
    await user.click(screen.getByText("Productivity"));
    expect(screen.getByText("Install Microsoft 365")).toBeInTheDocument();
    expect(
      screen.queryByText("Run Device Care optimizer")
    ).not.toBeInTheDocument();
  });

  it("shows per-section progress in the tab badge", () => {
    render(<S24ToolsPage />);
    // Speed has 7 tasks, badge should read "0/7".
    // Multiple sections share this count so use getAllByText.
    const nav = screen.getByRole("navigation");
    const badges = within(nav).getAllByText("0/7");
    expect(badges.length).toBeGreaterThan(0);
  });

  it("shows correct total task count per section in tab badges", () => {
    render(<S24ToolsPage />);
    const nav = screen.getByRole("navigation");
    // speed: 7, productivity: 7, email: 6, files: 7
    const badges = within(nav).getAllByText(/\d+\/\d+/);
    const texts = badges.map((b) => b.textContent);
    expect(texts).toContain("0/7"); // speed
    expect(texts).toContain("0/6"); // email (unique count)
  });
});

// ---------------------------------------------------------------------------
// Task rendering
// ---------------------------------------------------------------------------

describe("S24ToolsPage – task rendering", () => {
  it("renders task labels in the active section", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("Run Device Care optimizer")).toBeInTheDocument();
    expect(screen.getByText("Enable RAM Plus (8 GB)")).toBeInTheDocument();
  });

  it("renders task detail text when present", () => {
    render(<S24ToolsPage />);
    expect(
      screen.getByText(
        /Settings → Device Care → Optimize Now — clears RAM and junk/i
      )
    ).toBeInTheDocument();
  });

  it("renders a link for tasks that have a link property", () => {
    render(<S24ToolsPage />);
    // speed-6: "Install Good Lock for deeper tuning" has a Play Store link
    const link = screen.getByRole("link", { name: /Play Store/i });
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute("target", "_blank");
    expect(link).toHaveAttribute("rel", "noopener noreferrer");
  });

  it("does not render a link for tasks without a link property", () => {
    render(<S24ToolsPage />);
    // "Run Device Care optimizer" has no link
    const allLinks = screen.queryAllByRole("link");
    // Only one link should be present in the Speed section (speed-6)
    expect(allLinks.length).toBe(1);
  });

  it("renders checkboxes with aria-label 'Mark complete' when unchecked", () => {
    render(<S24ToolsPage />);
    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    expect(checkboxes.length).toBeGreaterThan(0);
  });

  it("section progress text shows 0 of N tasks completed initially", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("0 of 7 tasks completed")).toBeInTheDocument();
  });
});

// ---------------------------------------------------------------------------
// Task toggle
// ---------------------------------------------------------------------------

describe("S24ToolsPage – task toggle", () => {
  it("marks a task as done when its checkbox is clicked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    // The checkbox aria-label should now say "Mark incomplete"
    expect(
      screen.getAllByRole("button", { name: "Mark incomplete" }).length
    ).toBe(1);
  });

  it("updates overall progress count when a task is checked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    expect(screen.getByText("1/27")).toBeInTheDocument();
  });

  it("updates section progress text when a task is checked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    expect(screen.getByText("1 of 7 tasks completed")).toBeInTheDocument();
  });

  it("unchecks a done task when clicked again (toggle off)", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);
    // Now it's done; click again
    const doneCheckbox = screen.getByRole("button", {
      name: "Mark incomplete",
    });
    await user.click(doneCheckbox);

    expect(
      screen.queryByRole("button", { name: "Mark incomplete" })
    ).not.toBeInTheDocument();
    expect(screen.getByText("0/27")).toBeInTheDocument();
  });

  it("shows a checkmark (✓) inside a checked checkbox", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    expect(screen.getByText("✓")).toBeInTheDocument();
  });

  it("persists checked state to localStorage when a task is toggled", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    expect(localStorage.setItem).toHaveBeenCalledWith(
      "s24-tools-checked",
      expect.any(String)
    );

    const stored = JSON.parse(
      localStorage.getItem("s24-tools-checked") as string
    );
    const checkedIds = Object.entries(stored)
      .filter(([, v]) => v === true)
      .map(([k]) => k);
    expect(checkedIds.length).toBe(1);
  });

  it("checked state persists across tabs", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check the first task in Speed
    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    // Navigate to Productivity and back
    await user.click(screen.getByText("Productivity"));
    await user.click(screen.getByText("Speed & Performance"));

    expect(
      screen.getAllByRole("button", { name: "Mark incomplete" }).length
    ).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// Reset button
// ---------------------------------------------------------------------------

describe("S24ToolsPage – reset button", () => {
  it("shows Reset button only after at least one task is checked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    expect(screen.queryByText("Reset")).not.toBeInTheDocument();

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    expect(screen.getByText("Reset")).toBeInTheDocument();
  });

  it("reset button clears all checked tasks in the active section", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check two tasks in the Speed section
    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);
    await user.click(checkboxes[1]);

    expect(screen.getByText("2/27")).toBeInTheDocument();

    await user.click(screen.getByText("Reset"));

    expect(screen.getByText("0/27")).toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: "Mark incomplete" })
    ).not.toBeInTheDocument();
  });

  it("reset button disappears after resetting section to zero", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);
    await user.click(screen.getByText("Reset"));

    expect(screen.queryByText("Reset")).not.toBeInTheDocument();
  });

  it("resetting one section does not affect checked tasks in other sections", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check a task in Speed
    const speedCheckboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(speedCheckboxes[0]);

    // Switch to Productivity, check a task there
    await user.click(screen.getByText("Productivity"));
    const prodCheckboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(prodCheckboxes[0]);

    // Overall should be 2/27
    expect(screen.getByText("2/27")).toBeInTheDocument();

    // Reset Productivity only
    await user.click(screen.getByText("Reset"));

    // Speed task should still be counted
    expect(screen.getByText("1/27")).toBeInTheDocument();
  });
});

// ---------------------------------------------------------------------------
// localStorage restore on mount
// ---------------------------------------------------------------------------

describe("S24ToolsPage – localStorage restore", () => {
  it("restores previously saved checked state from localStorage", () => {
    const saved = { "speed-1": true, "speed-2": true };
    localStorage.setItem("s24-tools-checked", JSON.stringify(saved));

    render(<S24ToolsPage />);

    // Two speed tasks checked → overall badge shows 2/27
    expect(screen.getByText("2/27")).toBeInTheDocument();
  });

  it("handles corrupt JSON in localStorage without crashing", () => {
    localStorage.setItem("s24-tools-checked", "not-valid-json{{");
    expect(() => render(<S24ToolsPage />)).not.toThrow();
    // Component should render normally with empty state
    expect(screen.getByText("0/27")).toBeInTheDocument();
  });

  it("handles missing localStorage key gracefully", () => {
    // localStorage is empty by default after beforeEach clear
    expect(() => render(<S24ToolsPage />)).not.toThrow();
    expect(screen.getByText("0/27")).toBeInTheDocument();
  });
});

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

describe("S24ToolsPage – progress display", () => {
  it("overall progress updates correctly when multiple tasks are checked", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);
    await user.click(checkboxes[1]);
    await user.click(checkboxes[2]);

    expect(screen.getByText("3/27")).toBeInTheDocument();
  });

  it("section progress text updates after each toggle", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);
    expect(screen.getByText("1 of 7 tasks completed")).toBeInTheDocument();

    await user.click(checkboxes[1]);
    expect(screen.getByText("2 of 7 tasks completed")).toBeInTheDocument();
  });

  it("tab badge for active section reflects checked tasks", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    const nav = screen.getByRole("navigation");
    expect(within(nav).getByText("1/7")).toBeInTheDocument();
  });
});

// ---------------------------------------------------------------------------
// Link rendering
// ---------------------------------------------------------------------------

describe("S24ToolsPage – link rendering", () => {
  it("renders Play Store link in Productivity tab for tasks with links", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    await user.click(screen.getByText("Productivity"));

    const links = screen.getAllByRole("link");
    expect(links.length).toBeGreaterThan(0);
    links.forEach((link) => {
      expect(link).toHaveAttribute("target", "_blank");
      expect(link).toHaveAttribute("rel", "noopener noreferrer");
    });
  });

  it("link label includes ' →' arrow suffix", async () => {
    render(<S24ToolsPage />);
    // Speed tab has one link (speed-6: Good Lock)
    const link = screen.getByRole("link");
    expect(link.textContent).toMatch(/Play Store →/);
  });

  it("tasks without links do not render an anchor element", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // File Cleaning tab – verify tasks without links don't produce anchors
    await user.click(screen.getByText("File Cleaning"));

    // files section has 4 tasks with links and 3 without; links should be present
    const links = screen.getAllByRole("link");
    // All should point to Play Store
    links.forEach((link) =>
      expect(link).toHaveAttribute("href", expect.stringContaining("play.google.com"))
    );
  });
});

// ---------------------------------------------------------------------------
// Boundary / regression cases
// ---------------------------------------------------------------------------

describe("S24ToolsPage – boundary and regression cases", () => {
  it("can check and uncheck all tasks in a section without errors", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check all 7 Speed tasks
    let checkboxes = screen.getAllByRole("button", { name: "Mark complete" });
    for (const cb of checkboxes) {
      await user.click(cb);
    }
    expect(screen.getByText("7/27")).toBeInTheDocument();

    // Uncheck all via Reset
    await user.click(screen.getByText("Reset"));
    expect(screen.getByText("0/27")).toBeInTheDocument();
  });

  it("switching tabs rapidly does not corrupt checked state", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check a speed task
    const speedCheckboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(speedCheckboxes[0]);

    // Rapid tab switching
    await user.click(screen.getByText("Productivity"));
    await user.click(screen.getByText("Email Management"));
    await user.click(screen.getByText("File Cleaning"));
    await user.click(screen.getByText("Speed & Performance"));

    // Checked state should still show 1 done
    expect(screen.getByText("1/27")).toBeInTheDocument();
    expect(
      screen.getAllByRole("button", { name: "Mark incomplete" }).length
    ).toBe(1);
  });

  it("does not show Reset in a section with zero checked tasks even if other sections have checked tasks", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    // Check a task in Speed
    const checkboxes = screen.getAllByRole("button", {
      name: "Mark complete",
    });
    await user.click(checkboxes[0]);

    // Switch to Productivity (no tasks checked here)
    await user.click(screen.getByText("Productivity"));

    expect(screen.queryByText("Reset")).not.toBeInTheDocument();
  });

  it("displays correct section-level total when Email Management (6 tasks) is active", async () => {
    const user = userEvent.setup();
    render(<S24ToolsPage />);

    await user.click(screen.getByText("Email Management"));

    expect(screen.getByText("0 of 6 tasks completed")).toBeInTheDocument();
  });

  it("overall task count is 27 across all sections", () => {
    render(<S24ToolsPage />);
    // Header badge shows x/27
    expect(screen.getByText("0/27")).toBeInTheDocument();
  });
});