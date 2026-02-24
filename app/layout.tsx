import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "AI Town",
  description: "A virtual town where AI residents live, chat, and socialize",
};

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
