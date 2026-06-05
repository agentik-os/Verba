"use client";

import { useEffect } from "react";

/// Captures the ?ref=<code> affiliate parameter on any landing and stores it, so the
/// checkout call can attribute the subscription to the referrer.
export default function RefCapture() {
  useEffect(() => {
    try {
      const ref = new URLSearchParams(window.location.search).get("ref");
      if (ref) {
        localStorage.setItem("verba_ref", ref.slice(0, 64));
        document.cookie = `verba_ref=${encodeURIComponent(ref.slice(0, 64))}; path=/; max-age=${60 * 60 * 24 * 60}`;
      }
    } catch {}
  }, []);
  return null;
}

export function getRef(): string | undefined {
  try {
    return localStorage.getItem("verba_ref") ?? undefined;
  } catch {
    return undefined;
  }
}
