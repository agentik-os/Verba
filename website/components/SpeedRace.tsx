"use client";

import { useEffect, useRef } from "react";

/**
 * SpeedRace — a small "voice vs typing" race meter for the speed-proof section.
 * Two horizontal tracks fill left-to-right toward a finish flag: VOICE sprints
 * (≈ wordsPerMinVoice), TYPING crawls (≈ wordsPerMinType). Voice's bar carries a
 * live, audio-like ripple + a warm "rec" leading dot; both show a tabular WPM
 * readout. The race auto-replays on a beat so it always feels alive.
 *
 * Plain Canvas2D (no WebGL, no deps) — cheap enough to sit inside a card. Themed
 * off the site's --fg / --muted / --rec / --border CSS vars and re-themed live on
 * light/dark toggle. SSR-safe ("use client", all DOM access inside useEffect),
 * paused offscreen, a single composed frame on prefers-reduced-motion,
 * DPR-aware, pointer-events: none, disposed on unmount.
 *
 * Usage:
 *   <SpeedRace className="w-full h-40" wordsPerMinVoice={150} wordsPerMinType={48} />
 */
export default function SpeedRace({
  className = "",
  wordsPerMinVoice = 150,
  wordsPerMinType = 48,
}: {
  className?: string;
  wordsPerMinVoice?: number;
  wordsPerMinType?: number;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    if (typeof window === "undefined") return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const css = (name: string, fallback: string) => {
      const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
      return v || fallback;
    };
    let colors = {
      fg: css("--fg", "#f4f4f6"),
      muted: css("--muted", "rgba(244,244,246,0.56)"),
      faint: css("--faint", "rgba(244,244,246,0.38)"),
      rec: css("--rec", "#ff5a4d"),
      border: css("--border", "rgba(255,255,255,0.08)"),
      tint: css("--tint-strong", "rgba(255,255,255,0.085)"),
    };
    const refreshColors = () => {
      colors = {
        fg: css("--fg", "#f4f4f6"),
        muted: css("--muted", "rgba(244,244,246,0.56)"),
        faint: css("--faint", "rgba(244,244,246,0.38)"),
        rec: css("--rec", "#ff5a4d"),
        border: css("--border", "rgba(255,255,255,0.08)"),
        tint: css("--tint-strong", "rgba(255,255,255,0.085)"),
      };
    };
    const themeObs = new MutationObserver(refreshColors);
    themeObs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

    let W = 1;
    let H = 1;
    const resize = () => {
      W = canvas.clientWidth || 1;
      H = canvas.clientHeight || 1;
      canvas.width = Math.round(W * dpr);
      canvas.height = Math.round(H * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    let visible = true;
    const io = new IntersectionObserver(([e]) => { visible = e.isIntersecting; }, { threshold: 0 });
    io.observe(canvas);

    // Race timing. Voice "wins" in DURATION seconds; typing finishes later in
    // proportion to the WPM ratio. A short hold + reset makes it loop.
    const DURATION = 2.6;                 // seconds for voice to finish
    const ratio = Math.max(wordsPerMinType, 1) / Math.max(wordsPerMinVoice, 1);
    const typeDuration = DURATION / ratio; // typing is slower => longer
    const HOLD = 1.4;                      // pause on the result before replay
    const cycle = typeDuration + HOLD;

    const easeOut = (x: number) => 1 - Math.pow(1 - Math.min(Math.max(x, 0), 1), 2.2);

    const drawTrack = (
      yCenter: number,
      label: string,
      progress: number,      // 0..1
      wpm: number,
      isVoice: boolean,
      time: number
    ) => {
      const padL = 14;
      const padR = 86;       // room for the WPM readout
      const trackX = padL;
      const trackW = Math.max(W - padL - padR, 10);
      const barH = 10;
      const y = yCenter - barH / 2;
      const r = barH / 2;

      // Label
      ctx.font = "600 11px ui-monospace, 'SF Mono', Menlo, monospace";
      ctx.textBaseline = "alphabetic";
      ctx.fillStyle = colors.muted;
      ctx.fillText(label, trackX, y - 8);

      // Track groove
      roundRect(ctx, trackX, y, trackW, barH, r);
      ctx.fillStyle = colors.tint;
      ctx.fill();
      ctx.lineWidth = 1;
      ctx.strokeStyle = colors.border;
      ctx.stroke();

      // Fill
      const fillW = Math.max(trackW * Math.min(progress, 1), barH);
      ctx.save();
      roundRect(ctx, trackX, y, fillW, barH, r);
      ctx.clip();

      if (isVoice) {
        const grad = ctx.createLinearGradient(trackX, 0, trackX + trackW, 0);
        grad.addColorStop(0, colors.fg);
        grad.addColorStop(1, colors.rec);
        ctx.fillStyle = grad;
        ctx.fillRect(trackX, y, fillW, barH);
        // Audio ripple riding on top of the voice bar.
        ctx.globalCompositeOperation = "overlay";
        ctx.strokeStyle = "rgba(255,255,255,0.5)";
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        const baseY = y + barH / 2;
        for (let px = 0; px <= fillW; px += 2) {
          const amp = (barH / 2 - 1.5) * (0.4 + 0.6 * Math.abs(Math.sin(px * 0.18 + time * 7)));
          const yy = baseY + Math.sin(px * 0.5 + time * 9) * amp * 0.4;
          px === 0 ? ctx.moveTo(trackX + px, yy) : ctx.lineTo(trackX + px, yy);
        }
        ctx.stroke();
      } else {
        ctx.fillStyle = colors.faint;
        ctx.fillRect(trackX, y, fillW, barH);
      }
      ctx.restore();

      // Leading dot
      const headX = trackX + fillW;
      if (isVoice) {
        const pulse = 0.6 + 0.4 * Math.sin(time * 6);
        ctx.beginPath();
        ctx.arc(headX, yCenter, 6 + pulse * 2, 0, Math.PI * 2);
        ctx.fillStyle = withAlpha(colors.rec, 0.18 + pulse * 0.12);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(headX, yCenter, 3.2, 0, Math.PI * 2);
        ctx.fillStyle = colors.rec;
        ctx.fill();
      }

      // WPM readout (counts up with progress)
      const shownWpm = Math.round(wpm * Math.min(progress, 1));
      ctx.font = "600 15px ui-monospace, 'SF Mono', Menlo, monospace";
      ctx.textBaseline = "middle";
      ctx.textAlign = "right";
      ctx.fillStyle = progress >= 1 ? colors.fg : colors.muted;
      ctx.fillText(`${shownWpm}`, W - 14, yCenter - 2);
      ctx.font = "400 9px ui-monospace, 'SF Mono', Menlo, monospace";
      ctx.fillStyle = colors.faint;
      ctx.fillText("WPM", W - 14, yCenter + 11);
      ctx.textAlign = "left";
    };

    const render = (elapsed: number) => {
      ctx.clearRect(0, 0, W, H);
      const t = elapsed % cycle;

      const voiceP = easeOut(t / DURATION);
      const typeP = easeOut(t / typeDuration);

      const topY = H * 0.34;
      const botY = H * 0.74;
      drawTrack(topY, "VOICE", voiceP, wordsPerMinVoice, true, elapsed);
      drawTrack(botY, "TYPING", typeP, wordsPerMinType, false, elapsed);

      // Finish line marker
      const padR = 86;
      const finishX = W - padR - 14;
      ctx.strokeStyle = colors.border;
      ctx.setLineDash([3, 4]);
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(finishX, H * 0.18);
      ctx.lineTo(finishX, H * 0.86);
      ctx.stroke();
      ctx.setLineDash([]);
    };

    let raf = 0;
    let start = performance.now();
    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);
      if (!visible) { start = now; return; } // freeze + rebase while offscreen
      render((now - start) / 1000);
    };

    if (reduced) {
      // One composed frame: voice finished, typing mid-way.
      render(DURATION);
    } else {
      raf = requestAnimationFrame(tick);
    }

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
      themeObs.disconnect();
    };
  }, [wordsPerMinVoice, wordsPerMinType]);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden
      className={className}
      style={{ pointerEvents: "none", display: "block" }}
    />
  );
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  const rr = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

/** Apply an alpha to a hex or rgb(a) color string, best-effort. */
function withAlpha(color: string, alpha: number): string {
  const c = color.trim();
  if (c.startsWith("#")) {
    let hex = c.slice(1);
    if (hex.length === 3) hex = hex.split("").map((ch) => ch + ch).join("");
    const n = parseInt(hex, 16);
    const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
  const m = c.match(/rgba?\(([^)]+)\)/);
  if (m) {
    const parts = m[1].split(",").map((s) => s.trim());
    return `rgba(${parts[0]}, ${parts[1]}, ${parts[2]}, ${alpha})`;
  }
  return c;
}
