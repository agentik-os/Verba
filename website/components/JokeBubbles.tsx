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

    const css = getComputedStyle(document.documentElement);
    const fg = css.getPropertyValue("--fg").trim() || "#f3f4f7";
    const border = css.getPropertyValue("--border").trim() || "rgba(255,255,255,0.1)";
    const tint = css.getPropertyValue("--tint-strong").trim() || "rgba(255,255,255,0.12)";

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
    const MAX = 9;
    const spawn = (): B => {
      const s = 13 + Math.random() * 4;
      return {
        text: JOKES[Math.floor(Math.random() * JOKES.length)],
        x: Math.random() * w, y: h * 0.15 + Math.random() * h * 0.7,
        vx: (Math.random() - 0.5) * 0.25, vy: (Math.random() - 0.5) * 0.25,
        age: 0, ttl: 5 + Math.random() * 4, s,
      };
    };
    for (let i = 0; i < MAX; i++) { const b = spawn(); b.age = Math.random() * b.ttl; bubbles.push(b); }

    let raf = 0, last = performance.now();
    const frame = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000); last = now;
      c.clearRect(0, 0, w, h);
      for (let i = 0; i < bubbles.length; i++) {
        const b = bubbles[i];
        b.age += dt; b.x += b.vx; b.y += b.vy;
        if (b.age > b.ttl) { bubbles[i] = spawn(); continue; }
        const fadeIn = Math.min(1, b.age / 1.1);
        const fadeOut = Math.min(1, (b.ttl - b.age) / 1.6);
        const a = Math.max(0, Math.min(1, fadeIn * fadeOut));
        c.font = `${b.s}px -apple-system, system-ui, sans-serif`;
        const tw = c.measureText(b.text).width;
        const padX = 16, padY = 9, rw = tw + padX * 2, rh = b.s + padY * 2, r = rh / 2;
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
    return () => { cancelAnimationFrame(raf); ro.disconnect(); };
  }, []);

  return <canvas ref={ref} className="h-[340px] w-full" aria-hidden />;
}
