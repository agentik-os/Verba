"use client";

import { useRef, useState } from "react";

type State = "idle" | "recording" | "working" | "done" | "error";

const MODES = [
  { key: "flow", label: "Flow", model: "No AI", tip: "Raw dictation. Your exact words, transcribed with no AI rewriting." },
  { key: "intent", label: "Intent", model: "Sonnet 4.6", tip: "Say how you want it handled first (e.g. make this bullet points), then the content. Verba obeys." },
  { key: "coding", label: "Coding", model: "Sonnet 4.6", tip: "Turns rambling feedback into a precise prompt for a coding agent, keeping every detail." },
  { key: "custom", label: "Custom", model: "Sonnet 4.6", tip: "Write your own instruction and test it live." },
];

const darkCard = { color: "#f4f5f8", "--muted": "rgba(244,245,248,0.55)" } as Record<string, string>;

/// In-browser taste of Verba: pick a mode (or write a custom one), record ~45s, we transcribe
/// + restructure with the same pipeline the app uses. 7 free runs (cookie + IP).
export default function TryIt() {
  const [state, setState] = useState<State>("idle");
  const [mode, setMode] = useState("intent");
  const [custom, setCustom] = useState("Rewrite this as a friendly tweet, keep it under 200 characters.");
  const [result, setResult] = useState("");
  const [original, setOriginal] = useState("");
  const [error, setError] = useState("");
  const [remaining, setRemaining] = useState<number | null>(null);
  const rec = useRef<MediaRecorder | null>(null);
  const chunks = useRef<Blob[]>([]);
  const stopTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  async function start() {
    setError(""); setResult(""); setOriginal("");
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mr = new MediaRecorder(stream);
      chunks.current = [];
      mr.ondataavailable = (e) => { if (e.data.size) chunks.current.push(e.data); };
      mr.onstop = () => { stream.getTracks().forEach((t) => t.stop()); upload(); };
      rec.current = mr;
      mr.start();
      setState("recording");
      stopTimer.current = setTimeout(() => stop(), 45_000);
    } catch {
      setError("Microphone access is needed for the live demo.");
      setState("error");
    }
  }

  function stop() {
    if (stopTimer.current) clearTimeout(stopTimer.current);
    rec.current?.state === "recording" && rec.current.stop();
  }

  async function upload() {
    setState("working");
    try {
      const blob = new Blob(chunks.current, { type: "audio/webm" });
      const fd = new FormData();
      fd.append("audio", blob, "clip.webm");
      fd.append("mode", mode);
      if (mode === "custom") fd.append("customPrompt", custom);
      const res = await fetch("/api/try", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) { setError(data.error ?? "Something went wrong."); setState("error"); return; }
      setOriginal(data.original); setResult(data.result);
      setRemaining(data.remaining ?? null);
      setState("done");
    } catch {
      setError("Network error, try again."); setState("error");
    }
  }

  const current = MODES.find((x) => x.key === mode)!;
  const busy = state === "recording" || state === "working";

  return (
    <div className="mx-auto max-w-2xl">
      {/* mode picker with tooltips */}
      <div className="mb-3 flex flex-wrap items-center justify-center gap-2">
        {MODES.map((x) => (
          <button
            key={x.key}
            title={x.tip}
            onClick={() => setMode(x.key)}
            disabled={busy}
            className={`rounded-full px-4 py-1.5 text-sm transition disabled:opacity-50 ${
              x.key === mode ? "bg-[var(--fg)] text-[var(--bg)]" : "glass muted hover:text-[var(--fg)]"
            }`}
          >
            {x.label}
          </button>
        ))}
      </div>
      <p className="mb-4 text-center text-xs muted">{current.tip}</p>

      {mode === "custom" && (
        <textarea
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
          disabled={busy}
          rows={2}
          placeholder="Your instruction, e.g. summarize this as 3 bullet points"
          className="mb-4 w-full resize-none rounded-2xl glass px-4 py-3 text-sm outline-none placeholder:opacity-50"
        />
      )}

      <div className="glass-strong rounded-3xl p-8 text-center">
        <div className="mb-4 text-xs muted">{current.label} · {current.model}</div>
        <button
          onClick={state === "recording" ? stop : start}
          disabled={state === "working"}
          className={`group relative mx-auto flex h-20 w-20 items-center justify-center rounded-full transition ${
            state === "recording" ? "bg-red-500 text-white" : "bg-[var(--fg)] text-[var(--bg)] hover:scale-105"
          } disabled:opacity-50`}
        >
          {state === "recording" ? (
            <span className="h-6 w-6 rounded-[4px] bg-white" />
          ) : state === "working" ? (
            <span className="h-6 w-6 animate-spin rounded-full border-2 border-current/40 border-t-current" />
          ) : (
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          )}
          {state === "recording" && <span className="absolute inset-0 animate-ping rounded-full bg-red-500/40" />}
        </button>
        <p className="mt-4 text-sm muted">
          {state === "idle" && "Tap to record, ramble a message, then tap to stop."}
          {state === "recording" && "Listening… tap to stop (max 45s)."}
          {state === "working" && "Transcribing and cleaning it up…"}
          {state === "done" && (remaining !== null ? `${remaining} free ${remaining === 1 ? "try" : "tries"} left.` : "Done.")}
          {state === "error" && <span className="text-red-400">{error}</span>}
        </p>

        {(original || result) ? (
          <div className="mt-6 grid gap-3 text-left sm:grid-cols-2">
            <div className="rounded-2xl bg-[#0c0c10] p-4" style={darkCard}>
              <p className="text-xs uppercase tracking-widest muted">You said</p>
              <p className="mt-1 text-sm">{original}</p>
            </div>
            <div className="rounded-2xl bg-[#0c0c10] p-4" style={darkCard}>
              <p className="text-xs uppercase tracking-widest muted">Verba writes</p>
              <p className="mt-1 whitespace-pre-line text-sm">{result}</p>
            </div>
          </div>
        ) : (
          state === "idle" && (
            <div className="mt-6 grid gap-3 text-left opacity-55 sm:grid-cols-2" aria-hidden>
              <div className="rounded-2xl bg-[#0c0c10] p-4" style={darkCard}>
                <p className="text-xs uppercase tracking-widest muted">You'll say something like</p>
                <p className="mt-1 text-sm italic">"um so basically can we uh move the call to thursday instead, something came up"</p>
              </div>
              <div className="rounded-2xl bg-[#0c0c10] p-4" style={darkCard}>
                <p className="text-xs uppercase tracking-widest muted">Verba writes</p>
                <p className="mt-1 text-sm">Can we move the call to Thursday instead? Something came up.</p>
              </div>
            </div>
          )
        )}
      </div>
      <p className="mt-3 text-center text-xs muted">No sign-up needed · 7 free tries · your clip isn't stored.</p>
    </div>
  );
}
