"use client";

import { useEffect, useRef, useState } from "react";
import { MicGlyph } from "./Brand";

type Mode = {
  name: string;
  model: string;
  said: string;
  wrote: string;
  app: string;
};

const MODES: Mode[] = [
  {
    name: "Context",
    model: "Sonnet 4.6",
    app: "Mail",
    said:
      "reply to this email say we'll have the proposal ready by friday and ask if they need a call",
    wrote:
      "Hi Sarah,\n\nThanks for reaching out. We'll have the proposal ready by Friday. Would it be helpful to hop on a call before then?\n\nBest,\nAlex",
  },
  {
    name: "Coding",
    model: "Opus 4.8",
    app: "Cursor",
    said:
      "ok so uh the login button it doesn't work on mobile i think the onclick is wrong um and also make the spinner show while it loads",
    wrote:
      "Fix the mobile login button.\n\n- The onClick handler isn't firing on mobile, investigate and correct it.\n- Show the loading spinner while the request is in flight.",
  },
  {
    name: "Intent",
    model: "Sonnet 4.6",
    app: "Notion",
    said:
      "turn this into bullet points of decisions we agreed to ship dark mode we postponed billing and we hire a designer in q3",
    wrote:
      "Decisions:\n• Ship dark mode\n• Postpone billing\n• Hire a designer in Q3",
  },
];

/* Live waveform — the signature visual. Bars settle flat as the text resolves. */
function Bars({ active }: { active: boolean }) {
  const N = 36;
  return (
    <div className="flex h-9 items-center gap-[3px]">
      {Array.from({ length: N }).map((_, i) => {
        // a centered "voice envelope" so the field looks like real speech
        const center = 1 - Math.abs(i - (N - 1) / 2) / ((N - 1) / 2);
        return (
          <span
            key={i}
            className="w-[3px] rounded-full"
            style={{
              background: "rgba(255,255,255,0.55)",
              animation: active ? `bar ${720 + (i % 5) * 90}ms ease-in-out ${i * 32}ms infinite` : "none",
              height: active ? undefined : `${4 + center * 5}px`,
              opacity: active ? 0.45 + center * 0.55 : 0.22,
              transition: "opacity .5s, height .5s",
            }}
          />
        );
      })}
    </div>
  );
}

export default function LiveDemo() {
  const [mode, setMode] = useState(0);
  const [phase, setPhase] = useState<"listening" | "writing">("listening");
  const [typed, setTyped] = useState("");
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
    setPhase("listening");
    setTyped("");
    const m = MODES[mode];

    const startWriting = setTimeout(() => setPhase("writing"), 1500);
    timers.current.push(startWriting);

    const typeStart = 1800;
    for (let i = 0; i <= m.wrote.length; i++) {
      const t = setTimeout(() => setTyped(m.wrote.slice(0, i)), typeStart + i * 15);
      timers.current.push(t);
    }
    const next = setTimeout(
      () => setMode((x) => (x + 1) % MODES.length),
      typeStart + m.wrote.length * 15 + 2800
    );
    timers.current.push(next);

    return () => timers.current.forEach(clearTimeout);
  }, [mode]);

  const m = MODES[mode];
  const listening = phase === "listening";

  return (
    <div className="mx-auto w-full max-w-2xl">
      {/* mode tabs — quiet, sit above the chrome */}
      <div className="mb-4 flex flex-wrap items-center justify-center gap-1.5">
        {MODES.map((x, i) => (
          <button
            key={x.name}
            onClick={() => setMode(i)}
            className={`rounded-full px-3.5 py-1.5 text-[13px] transition ${
              i === mode
                ? "bg-[var(--fg)] text-[var(--bg)] font-medium"
                : "border border-[var(--border)] text-[var(--muted)] hover:text-[var(--fg)]"
            }`}
          >
            {x.name}
          </button>
        ))}
      </div>

      {/* THE hero artifact — solid product chrome, not frosted glass */}
      <div className="panel r-panel float overflow-hidden">
        {/* macOS title bar */}
        <div className="flex items-center justify-between border-b border-white/[0.06] px-5 py-3">
          <div className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
            <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
            <span className="h-3 w-3 rounded-full bg-[#28c840]" />
          </div>
          <div className="flex items-center gap-2 text-[12px] text-white/45">
            <span className={`rec-dot ${listening ? "pulse" : ""}`} style={{ opacity: listening ? 1 : 0.3 }} />
            {listening ? "Listening" : `Pasting into ${m.app}`}
          </div>
          <span className="rounded-md border border-white/10 bg-white/[0.04] px-2 py-1 text-[11px] font-medium text-white/70 tnum">
            {m.name} · {m.model}
          </span>
        </div>

        {/* body */}
        <div className="px-6 py-7 sm:px-8" style={{ color: "#f4f4f6" }}>
          {/* waveform sourced from the mic mark */}
          <div className="mb-6 flex items-center gap-4">
            <span className="mic-mark shrink-0" style={{ width: 38, height: 38, borderRadius: 10 }}>
              <MicGlyph size={18} />
            </span>
            <Bars active={listening} />
          </div>

          <p className="text-[11px] uppercase tracking-[0.16em] text-white/40">You say</p>
          <p className="mt-1.5 min-h-[3em] text-[15px] leading-relaxed text-white/55">"{m.said}"</p>

          <div className="my-5 h-px bg-white/[0.07]" />

          <p className="text-[11px] uppercase tracking-[0.16em] text-white/40">Verba writes</p>
          <p className="mt-1.5 min-h-[6.5em] whitespace-pre-line text-[15px] leading-relaxed">
            {typed}
            {phase === "writing" && typed.length < m.wrote.length && (
              <span className="ml-0.5 inline-block h-[1.05em] w-[2px] animate-pulse bg-white align-text-bottom" />
            )}
          </p>
        </div>
      </div>

      <p className="mt-4 text-center text-[13px] muted">
        Context reads your screen. Every other mode routes to the right model: Haiku to polish, Sonnet for intent, Opus for code.
      </p>
    </div>
  );
}
