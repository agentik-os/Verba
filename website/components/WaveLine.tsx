"use client";

import { useEffect, useRef } from "react";

/**
 * WaveLine — a discreet, light, full-width sound wave. A few thin translucent sine
 * lines drifting gently, drawn on a single Canvas2D (no Three.js, no particles, no dots).
 * Themed off the site's --fg color, edge-faded, paused offscreen and on reduced motion,
 * pointer-events off. Meant to sit full-bleed behind the hero copy.
 */
export default function WaveLine({ className = "" }: { className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas || typeof window === "undefined") return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let visible = true;
    let t = 0;

    // Read the themed line color from --fg (falls back to a neutral).
    const fg = getComputedStyle(document.documentElement).getPropertyValue("--fg").trim() || "#111";

    function size() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const r = canvas!.getBoundingClientRect();
      canvas!.width = Math.max(1, Math.floor(r.width * dpr));
      canvas!.height = Math.max(1, Math.floor(r.height * dpr));
      ctx!.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    size();
    const onResize = () => size();
    window.addEventListener("resize", onResize);

    const io = new IntersectionObserver(
      ([e]) => { visible = e.isIntersecting; if (visible && !raf) loop(); },
      { threshold: 0 }
    );
    io.observe(canvas);

    // Three gentle waves at slightly different frequencies / opacities.
    const WAVES = [
      { amp: 0.16, freq: 1.1, speed: 0.20, alpha: 0.16, y: 0.5 },
      { amp: 0.11, freq: 1.7, speed: 0.28, alpha: 0.10, y: 0.54 },
      { amp: 0.07, freq: 2.6, speed: 0.16, alpha: 0.07, y: 0.47 },
    ];

    function draw() {
      const w = canvas!.clientWidth;
      const h = canvas!.clientHeight;
      ctx!.clearRect(0, 0, w, h);
      ctx!.lineWidth = 1.25;
      for (const wv of WAVES) {
        ctx!.beginPath();
        const midY = h * wv.y;
        const a = h * wv.amp;
        for (let x = 0; x <= w; x += 6) {
          const p = (x / w) * Math.PI * 2 * wv.freq + t * wv.speed;
          // Envelope so the wave eases to flat at both horizontal edges (discreet).
          const env = Math.sin((x / w) * Math.PI);
          const y = midY + Math.sin(p) * a * env;
          if (x === 0) ctx!.moveTo(x, y); else ctx!.lineTo(x, y);
        }
        ctx!.strokeStyle = withAlpha(fg, wv.alpha);
        ctx!.stroke();
      }
    }

    function loop() {
      if (!visible) { raf = 0; return; }
      t += reduce ? 0 : 0.16;   // gentle, discreet drift (was too fast)
      draw();
      raf = reduce ? 0 : requestAnimationFrame(loop);
      if (reduce) draw();
    }
    loop();

    return () => {
      window.removeEventListener("resize", onResize);
      io.disconnect();
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return <canvas ref={ref} aria-hidden className={className} />;
}

/** Apply an alpha to a hex / rgb color string. */
function withAlpha(color: string, alpha: number): string {
  if (color.startsWith("#")) {
    let c = color.slice(1);
    if (c.length === 3) c = c.split("").map((x) => x + x).join("");
    const n = parseInt(c, 16);
    return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
  }
  if (color.startsWith("rgb")) return color.replace(/rgba?\(([^)]+)\)/, (_m, inner) => {
    const parts = inner.split(",").slice(0, 3).join(",");
    return `rgba(${parts}, ${alpha})`;
  });
  return `rgba(128,128,128,${alpha})`;
}
