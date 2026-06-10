"use client";

import { useEffect, useRef, useState } from "react";

/// Fades + lifts its children into view on scroll. Lightweight, no deps.
export default function Reveal({
  children,
  delay = 0,
  className = "",
}: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) {
          setShown(true);
          io.disconnect();
        }
      },
      { threshold: 0.15 }
    );
    io.observe(el);
    // Safety valve: never leave content hidden (full-page captures, crawlers,
    // anchor jumps). What the viewer reaches early still animates; the rest
    // settles in quietly off-screen.
    const fallback = setTimeout(() => setShown(true), 2500);
    return () => { io.disconnect(); clearTimeout(fallback); };
  }, []);

  return (
    <div
      ref={ref}
      className={className}
      style={{
        opacity: shown ? 1 : 0,
        transform: shown ? "none" : "translateY(14px)",
        transition: `opacity .55s cubic-bezier(0,0,0.2,1) ${Math.min(delay, 240)}ms, transform .55s cubic-bezier(0,0,0.2,1) ${Math.min(delay, 240)}ms`,
      }}
    >
      {children}
    </div>
  );
}
