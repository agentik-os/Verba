"use client";

import { useEffect, useRef } from "react";

const JOKES = [
  "Reticulating splines…", "Bribing the language model…", "Downloading more RAM…",
  "git commit -m 'words'…", "Petting Schrödinger's cat…", "Counting to 42…",
  "Arr, hoistin' the transcript…", "Forsooth, polishing thy words…", "Buffering brilliance…",
  "Loot dropped: +1 clarity…", "Reducing the sauce…", "You got this, champ…",
  "Synergizing the verbiage…", "The vowels know too much…", "Aligning the tensors…",
  "Untangling your sentences…", "Casting Detect Typos…", "Warming up the GPUs…",
];

export default function JokeBubbles() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const cv = ref.current;
    if (!cv) return;
    const c = cv.getContext("2d");
    if (!c) return;

    let fg = "#f3f4f7", border = "rgba(255,255,255,0.1)", tint = "rgba(255,255,255,0.12)";
    const readColors = () => {
      const css = getComputedStyle(document.documentElement);
      fg = css.getPropertyValue("--fg").trim() || fg;
      border = css.getPropertyValue("--border").trim() || border;
      // A clearly-visible bubble fill in BOTH themes (tint-strong is too faint on white).
      tint = (document.documentElement.getAttribute("data-theme") === "light")
        ? "rgba(10,10,20,0.05)" : "rgba(255,255,255,0.085)";
    };
    readColors();
    const themeObs = new MutationObserver(readColors);
    themeObs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

    let w = 0, h = 0;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const resize = () => {
      const r = cv.getBoundingClientRect();
      w = r.width; h = r.height;
      cv.width = w * dpr; cv.height = h * dpr;
      c.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();
    const ro = new ResizeObserver(resize); ro.observe(cv);

    type B = { text: string; x: number; y: number; vx: number; vy: number; age: number; ttl: number; s: number };
    const bubbles: B[] = [];
    // Adaptive density: fewer chips on narrow screens so they never pile up.
    const MAX = () => (w < 520 ? 4 : w < 900 ? 6 : 9);
    // No two identical jokes on screen at once.
    const inUse = () => new Set(bubbles.map((b) => b.text));
    const pickJoke = () => {
      const used = inUse();
      const free = JOKES.filter((j) => !used.has(j));
      const pool = free.length ? free : JOKES;
      return pool[Math.floor(Math.random() * pool.length)];
    };
    // Lane-based placement: each slot owns a horizontal band, so chips drift but don't stack.
    const spawn = (lane: number, lanes: number): B => {
      const s = 13 + Math.random() * 4;
      const text = pickJoke();
      c.font = `${s}px -apple-system, system-ui, sans-serif`;
      const rw = c.measureText(text).width + 32;            // chip width incl. padding
      const half = rw / 2 + 6;
      const x = half + Math.random() * Math.max(1, w - half * 2);   // fully inside, never clipped
      const bandH = h / lanes;
      const y = bandH * (lane + 0.5) + (Math.random() - 0.5) * bandH * 0.3;
      return {
        text, x, y,
        vx: (Math.random() - 0.5) * 0.22, vy: (Math.random() - 0.5) * 0.12,
        age: 0, ttl: 5 + Math.random() * 4, s,
      };
    };
    for (let i = 0; i < MAX(); i++) { const b = spawn(i, MAX()); b.age = Math.random() * b.ttl; bubbles.push(b); }

    let raf = 0, last = performance.now();
    const frame = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000); last = now;
      c.clearRect(0, 0, w, h);
      // Keep the population in sync with the responsive cap.
      while (bubbles.length > MAX()) bubbles.pop();
      while (bubbles.length < MAX()) bubbles.push(spawn(bubbles.length, MAX()));
      for (let i = 0; i < bubbles.length; i++) {
        const b = bubbles[i];
        b.age += dt; b.x += b.vx; b.y += b.vy;
        if (b.age > b.ttl) { bubbles[i] = spawn(i, bubbles.length); continue; }
        const fadeIn = Math.min(1, b.age / 1.1);
        const fadeOut = Math.min(1, (b.ttl - b.age) / 1.6);
        const a = Math.max(0, Math.min(1, fadeIn * fadeOut));
        c.font = `${b.s}px -apple-system, system-ui, sans-serif`;
        const tw = c.measureText(b.text).width;
        const padX = 16, padY = 9, rw = tw + padX * 2, rh = b.s + padY * 2, r = rh / 2;
        // Soft walls: drifting chips bounce instead of clipping at the card edge.
        const lim = rw / 2 + 6;
        if (b.x < lim) { b.x = lim; b.vx = Math.abs(b.vx); }
        if (b.x > w - lim) { b.x = w - lim; b.vx = -Math.abs(b.vx); }
        if (b.y < rh) { b.y = rh; b.vy = Math.abs(b.vy); }
        if (b.y > h - rh) { b.y = h - rh; b.vy = -Math.abs(b.vy); }
        const x = b.x - rw / 2, y = b.y - rh / 2;
        c.globalAlpha = a;
        c.beginPath();
        c.roundRect(x, y, rw, rh, r);
        c.fillStyle = tint; c.fill();
        c.strokeStyle = border; c.lineWidth = 1; c.stroke();
        c.fillStyle = fg; c.globalAlpha = a * 0.85;
        c.textBaseline = "middle";
        c.fillText(b.text, x + padX, b.y);
        c.globalAlpha = 1;
      }
      raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    return () => { themeObs.disconnect(); cancelAnimationFrame(raf); ro.disconnect(); };
  }, []);

  return <canvas ref={ref} className="h-[340px] w-full" aria-hidden />;
}
