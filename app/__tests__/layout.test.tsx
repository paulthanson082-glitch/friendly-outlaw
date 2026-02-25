import { render, screen } from "@testing-library/react";
import RootLayout from "../layout";

// metadata is a Next.js export, not rendered — test the layout shell only
describe("RootLayout", () => {
  it("renders children inside the body", () => {
    render(
      <RootLayout>
        <p data-testid="child">Hello</p>
      </RootLayout>
    );
    expect(screen.getByTestId("child")).toBeInTheDocument();
  });

  it("renders an html element with lang=en", () => {
    const { container } = render(
      <RootLayout>
        <span />
      </RootLayout>
    );
    // jsdom wraps in <html> automatically; check the rendered attribute
    const html = container.closest("html") ?? container.querySelector("html");
    // Next.js layout renders <html lang="en"> — verify attribute on the element
    if (html) {
      expect(html).toHaveAttribute("lang", "en");
    } else {
      // When jsdom is already supplying the outer html tag we check the document
      expect(document.documentElement).toHaveAttribute("lang", "en");
    }
  });
});
