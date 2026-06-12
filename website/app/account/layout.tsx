import type { Metadata } from "next";

// Account is a private, authenticated surface — keep it out of the index (defense-in-depth
// alongside the robots.txt Disallow) and give it a self-referencing canonical.
export const metadata: Metadata = {
  title: "Account — Verba",
  description: "Manage your Verba subscription and account.",
  robots: { index: false, follow: false },
  alternates: { canonical: "/account" },
};

export default function AccountLayout({ children }: { children: React.ReactNode }) {
  return children;
}
