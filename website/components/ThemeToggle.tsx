"use client";

import { useEffect, useState } from "react";

type Mode = "light" | "dark";

/// Floating light/dark switch. Defaults to the machine preference; the user's choice is
/// remembered in localStorage and applied to <html data-theme>.
export default function ThemeToggle() {
  const [mode, setMode] = useState<Mode | null>(null);

  useEffect(() => {
    const stored = (localStorage.getItem("verba_theme") as Mode | null) ?? null;
    const sys = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    setMode(stored ?? sys);
  }, []);

  function apply(next: Mode) {
    setMode(next);
    document.documentElement.setAttribute("data-theme", next);
    try { localStorage.setItem("verba_theme", next); } catch {}
  }

  if (!mode) return null;

  return (
    <button
      aria-label="Toggle theme"
      onClick={() => apply(mode === "dark" ? "light" : "dark")}
      className="fixed right-4 top-4 z-50 grid h-10 w-10 place-items-center rounded-full glass transition hover:bg-[var(--tint-strong)]"
    >
      {mode === "dark" ? (
        // sun
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19" />
        </svg>
      ) : (
        // moon
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
          <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
        </svg>
      )}
    </button>
  );
}
