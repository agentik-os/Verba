"use client";

import { useEffect, useState } from "react";

type Mode = "light" | "dark";

/// Light/dark switch (LiquidPad-style: lives inline in the top nav). Defaults to dark;
/// the user's choice is remembered in localStorage and applied to <html data-theme>.
/// `variant="floating"` keeps the old fixed-corner placement for pages without a nav.
export default function ThemeToggle({ variant = "inline" }: { variant?: "inline" | "floating" }) {
  const [mode, setMode] = useState<Mode | null>(null);

  useEffect(() => {
    const stored = (localStorage.getItem("verba_theme") as Mode | null) ?? null;
    setMode(stored ?? "dark");   // dark by default
  }, []);

  function apply(next: Mode) {
    setMode(next);
    document.documentElement.setAttribute("data-theme", next);
    try { localStorage.setItem("verba_theme", next); } catch {}
  }

  // Reserve the slot before hydration so the nav doesn't shift.
  if (!mode) return <span className={variant === "inline" ? "h-8 w-8" : undefined} aria-hidden />;

  const placement =
    variant === "floating"
      ? "fixed bottom-5 right-5 z-50 h-9 w-9 rounded-full glass"
      : "h-8 w-8 rounded-full";

  return (
    <button
      aria-label="Toggle theme"
      onClick={() => apply(mode === "dark" ? "light" : "dark")}
      className={`grid place-items-center text-[var(--muted)] transition hover:bg-[var(--tint-strong)] hover:text-[var(--fg)] ${placement}`}
    >
      {mode === "dark" ? (
        // sun
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19" />
        </svg>
      ) : (
        // moon
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
          <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
        </svg>
      )}
    </button>
  );
}
