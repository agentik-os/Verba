import type { Metadata } from "next";

// Sign-in surface — never index it (defense-in-depth alongside the robots.txt Disallow) and
// give it a self-referencing canonical instead of inheriting the homepage's.
export const metadata: Metadata = {
  title: "Sign in — Verba",
  description: "Sign in to Verba.",
  robots: { index: false, follow: false },
  alternates: { canonical: "/app-auth" },
};

export default function AppAuthLayout({ children }: { children: React.ReactNode }) {
  return children;
}
