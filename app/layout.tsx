import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "AI Town",
  description: "A virtual town where AI residents live, chat, and socialize",
};

/**
 * Root layout component that renders the top-level HTML document structure and places the app content in the body.
 *
 * @param children - The React nodes to render inside the document's <body>.
 * @returns The root HTML element containing the provided children.
 */
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
