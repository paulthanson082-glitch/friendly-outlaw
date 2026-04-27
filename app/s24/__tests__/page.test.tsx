import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import S24ToolsPage from "../page";

const STORAGE_KEY = "s24-tools-checked";

beforeEach(() => {
  localStorage.clear();
});

describe("S24ToolsPage", () => {
  // ---------------------------------------------------------------------------
  // Initial render
  // ---------------------------------------------------------------------------

  it("renders the page title", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("📱 S24 Tools")).toBeInTheDocument();
  });

  it("renders all four section tabs", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText("Speed & Performance")).toBeInTheDocument();
    expect(screen.getByText("Productivity")).toBeInTheDocument();
    expect(screen.getByText("Email Management")).toBeInTheDocument();
    expect(screen.getByText("File Cleaning")).toBeInTheDocument();
  });

  it("shows the first section by default", () => {
    render(<S24ToolsPage />);
    expect(
      screen.getByText("⚡ Speed & Performance")
    ).toBeInTheDocument();
    expect(
      screen.getByText("Run Device Care optimizer")
    ).toBeInTheDocument();
  });

  it("displays overall progress as 0 initially", () => {
    render(<S24ToolsPage />);
    expect(screen.getByText(/0\/27/)).toBeInTheDocument();
  });

  // ---------------------------------------------------------------------------
  // Tab switching
  // ---------------------------------------------------------------------------

  it("switches to another section when a tab is clicked", () => {
    render(<S24ToolsPage />);
    fireEvent.click(screen.getByText("Productivity"));
    expect(screen.getByText("🚀 Productivity")).toBeInTheDocument();
    expect(screen.getByText("Install Microsoft 365")).toBeInTheDocument();
  });

  // ---------------------------------------------------------------------------
  // Task toggling
  // ---------------------------------------------------------------------------

  it("toggles a task when the checkbox is clicked", () => {
    render(<S24ToolsPage />);
    const btn = screen.getAllByLabelText('Mark complete')[0];
    fireEvent.click(btn);
    expect(
      screen.getByLabelText('Mark incomplete')
    ).toBeInTheDocument();
  });

  it("updates section progress when a task is toggled", () => {
    render(<S24ToolsPage />);
    fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
    expect(screen.getByText("1 of 7 tasks completed")).toBeInTheDocument();
  });

  it("updates overall progress when a task is toggled", () => {
    render(<S24ToolsPage />);
    fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
    expect(screen.getByText(/1\/27/)).toBeInTheDocument();
  });

  // ---------------------------------------------------------------------------
  // Accessibility
  // ---------------------------------------------------------------------------

  it("uses accessible aria-labels on checkbox buttons", () => {
    render(<S24ToolsPage />);
    const buttons = screen.getAllByLabelText('Mark complete');
    expect(buttons.length).toBeGreaterThan(0);
    buttons.forEach((btn) => expect(btn).toHaveAttribute('aria-pressed', 'false'));
  });

  it("sets aria-pressed on the checkbox button", () => {
    render(<S24ToolsPage />);
    const btn = screen.getAllByLabelText('Mark complete')[0];
    expect(btn).toHaveAttribute("aria-pressed", "false");
    fireEvent.click(btn);
    const toggled = screen.getByLabelText('Mark incomplete');
    expect(toggled).toHaveAttribute("aria-pressed", "true");
  });

  // ---------------------------------------------------------------------------
  // localStorage persistence
  // ---------------------------------------------------------------------------

  it("persists checked state to localStorage", () => {
    render(<S24ToolsPage />);
    fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY)!);
    expect(stored["speed-1"]).toBe(true);
  });

  it("restores checked state from localStorage on mount", () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ "speed-1": true, "speed-2": true })
    );
    render(<S24ToolsPage />);
    expect(
      screen.getAllByLabelText('Mark incomplete')
    ).toHaveLength(2);
    expect(screen.getByText("2 of 7 tasks completed")).toBeInTheDocument();
  });

  it("ignores invalid JSON in localStorage", () => {
    localStorage.setItem(STORAGE_KEY, "not-json");
    render(<S24ToolsPage />);
    // Should render without errors, with 0 tasks done
    expect(screen.getByText("0 of 7 tasks completed")).toBeInTheDocument();
  });

  it("ignores null stored in localStorage", () => {
    localStorage.setItem(STORAGE_KEY, "null");
    render(<S24ToolsPage />);
    expect(screen.getByText("0 of 7 tasks completed")).toBeInTheDocument();
  });

  it("ignores array stored in localStorage", () => {
    localStorage.setItem(STORAGE_KEY, "[1,2,3]");
    render(<S24ToolsPage />);
    expect(screen.getByText("0 of 7 tasks completed")).toBeInTheDocument();
  });

  it("does not overwrite saved progress on initial mount", () => {
    const saved = { "speed-1": true, "speed-3": true };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(saved));
    render(<S24ToolsPage />);
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY)!);
    expect(stored["speed-1"]).toBe(true);
    expect(stored["speed-3"]).toBe(true);
  });

  // ---------------------------------------------------------------------------
  // Reset section
  // ---------------------------------------------------------------------------

  it("resets only the active section when Reset is clicked", () => {
    render(<S24ToolsPage />);
    // Check two tasks
    const checkboxes = screen.getAllByLabelText('Mark complete');
    fireEvent.click(checkboxes[0]);
    fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
    expect(screen.getByText("2 of 7 tasks completed")).toBeInTheDocument();

    // Reset
    fireEvent.click(screen.getByText("Reset"));
    expect(screen.getByText("0 of 7 tasks completed")).toBeInTheDocument();
  });
});
