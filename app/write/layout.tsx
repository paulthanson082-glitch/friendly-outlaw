import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Hanson's Writing Assistant",
  description: "Templates, AI-assisted drafting, and polish styles for counseling, academic, personal, and creative writing.",
};

export default function WriteLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
