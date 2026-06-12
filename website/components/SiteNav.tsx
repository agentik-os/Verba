"use client";

import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs";
import { Logo } from "@/components/Brand";
import ThemeToggle from "@/components/ThemeToggle";
import { FEATURE_NAV, RESOURCE_NAV } from "@/lib/features";

const DOWNLOAD_URL = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

// Shared top navigation with two CSS-only dropdowns (Features, Resources). No JS state — the panel
// shows on hover and on keyboard focus-within, so it stays accessible without a client store.
function Dropdown({ label, items }: { label: string; items: { href: string; label: string; desc?: string }[] }) {
  return (
    <div className="group relative">
      <button className="flex items-center gap-1 transition-colors duration-150 hover:text-[var(--fg)] group-focus-within:text-[var(--fg)]">
        {label}
        <svg width="9" height="9" viewBox="0 0 10 10" className="mt-0.5 opacity-60" aria-hidden>
          <path d="M1 3l4 4 4-4" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>
      <div className="invisible absolute left-1/2 top-full z-50 w-64 -translate-x-1/2 pt-3 opacity-0 transition-all duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100">
        <div className="menu-panel rounded-2xl p-1.5">
          {items.map((it) => (
            <Link
              key={it.href}
              href={it.href}
              className="block rounded-xl px-3 py-2 transition-colors hover:bg-[var(--tint)]"
            >
              <div className="text-[13px] font-medium text-[var(--fg)]">{it.label}</div>
              {it.desc && <div className="mt-0.5 text-xs muted">{it.desc}</div>}
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function SiteNav() {
  return (
    <nav className="anim-nav sticky top-3 z-50 mt-3 flex items-center justify-between rounded-full glass px-5 py-2.5">
      <Link href="/" aria-label="Verba home"><Logo /></Link>
      <div className="hidden items-center gap-7 text-sm muted md:flex">
        <Dropdown label="Features" items={FEATURE_NAV} />
        <Dropdown label="Resources" items={RESOURCE_NAV} />
        <Link href="/#pricing" className="transition-colors duration-150 hover:text-[var(--fg)]">Pricing</Link>
      </div>
      <div className="flex items-center gap-3">
        <span aria-hidden className="hidden h-4 w-px bg-[var(--border)] sm:block" />
        <SignedOut>
          <SignInButton mode="modal">
            <button className="text-sm muted hover:text-[var(--fg)]">Sign in</button>
          </SignInButton>
        </SignedOut>
        <SignedIn>
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
        <ThemeToggle />
        <a href={DOWNLOAD_URL} className="btn-primary px-4 py-2 text-sm">Download</a>
      </div>
    </nav>
  );
}
