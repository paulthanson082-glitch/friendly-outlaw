import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "AIMS",
  description: "AI Messaging System",
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
