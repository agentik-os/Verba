"use client";

import { useEffect, useRef, useState } from "react";

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

function Bars({ active }: { active: boolean }) {
  const N = 28;
  return (
    <div className="flex h-10 items-center justify-center gap-[3px]">
      {Array.from({ length: N }).map((_, i) => (
        <span
          key={i}
          className="w-[3px] rounded-full bg-white/70"
          style={{
            animation: `bar 900ms ease-in-out ${i * 45}ms infinite`,
            height: active ? undefined : "6px",
            opacity: active ? 1 : 0.25,
            transition: "opacity .4s",
          }}
        />
      ))}
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

    // type out the result
    const typeStart = 1800;
    for (let i = 0; i <= m.wrote.length; i++) {
      const t = setTimeout(() => setTyped(m.wrote.slice(0, i)), typeStart + i * 16);
      timers.current.push(t);
    }
    // auto-advance to the next mode
    const next = setTimeout(
      () => setMode((x) => (x + 1) % MODES.length),
      typeStart + m.wrote.length * 16 + 2600
    );
    timers.current.push(next);

    return () => timers.current.forEach(clearTimeout);
  }, [mode]);

  const m = MODES[mode];

  return (
    <div className="mx-auto max-w-2xl">
      {/* mode tabs */}
      <div className="mb-4 flex flex-wrap items-center justify-center gap-2">
        {MODES.map((x, i) => (
          <button
            key={x.name}
            onClick={() => setMode(i)}
            className={`rounded-full px-4 py-1.5 text-sm transition ${
              i === mode ? "bg-[var(--fg)] text-[var(--bg)]" : "glass muted hover:text-[var(--fg)]"
            }`}
          >
            {x.name}
          </button>
        ))}
      </div>

      <div className="glass-strong float rounded-3xl p-2">
        <div className="rounded-[20px] bg-[#0c0c10] p-6 sm:p-8"
             style={{ color: "#f4f5f8", "--fg": "#f4f5f8", "--muted": "rgba(244,245,248,0.55)", "--tint": "rgba(255,255,255,0.08)" } as Record<string, string>}>
          <div className="flex items-center justify-between text-xs muted">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full bg-red-400/80" />
              <span className="h-2.5 w-2.5 rounded-full bg-yellow-400/70" />
              <span className="h-2.5 w-2.5 rounded-full bg-green-400/70" />
              <span className="ml-2">{phase === "listening" ? "Listening…" : `Pasting into ${m.app}`}</span>
            </div>
            <span className="rounded-full bg-[var(--tint)] px-2.5 py-1 font-medium text-white/80">
              {m.name} · {m.model}
            </span>
          </div>

          <div className="my-5">
            <Bars active={phase === "listening"} />
          </div>

          <p className="text-xs uppercase tracking-widest muted">You say</p>
          <p className="mt-1 min-h-[3.2em] text-[15px] leading-relaxed text-white/70">"{m.said}"</p>

          <p className="mt-5 text-xs uppercase tracking-widest muted">Verba writes</p>
          <p className="mt-1 min-h-[6.5em] whitespace-pre-line text-[15px] leading-relaxed">
            {typed}
            {phase === "writing" && typed.length < m.wrote.length && (
              <span className="ml-0.5 inline-block h-4 w-[2px] animate-pulse bg-[var(--fg)] align-middle" />
            )}
          </p>
        </div>
      </div>
      <p className="mt-3 text-center text-xs muted">
        Context mode reads your screen. Every other mode routes to the right model: Haiku for quick polish, Sonnet for intent, Opus for code.
      </p>
    </div>
  );
}
