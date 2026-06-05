"use client";

import { useRef, useState } from "react";

type State = "idle" | "recording" | "working" | "done" | "error";

/// A real, in-browser taste of Verba: record up to ~45s, we transcribe + clean it with
/// the same pipeline the app uses. Limited to 2 free runs (cookie + IP) to deter farming.
export default function TryIt() {
  const [state, setState] = useState<State>("idle");
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
      stopTimer.current = setTimeout(() => stop(), 45_000); // hard cap ~45s
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
      const res = await fetch("/api/try", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) { setError(data.error ?? "Something went wrong."); setState("error"); return; }
      setOriginal(data.original); setResult(data.result);
      setRemaining(data.remaining ?? null);
      setState("done");
    } catch {
      setError("Network error — try again."); setState("error");
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <div className="glass-strong rounded-3xl p-8 text-center">
        <button
          onClick={state === "recording" ? stop : start}
          disabled={state === "working"}
          className={`group relative mx-auto flex h-20 w-20 items-center justify-center rounded-full transition ${
            state === "recording" ? "bg-red-500" : "bg-white text-black hover:scale-105"
          } disabled:opacity-50`}
        >
          {state === "recording" ? (
            <span className="h-6 w-6 rounded-[4px] bg-white" />
          ) : state === "working" ? (
            <span className="h-6 w-6 animate-spin rounded-full border-2 border-black/30 border-t-black" />
          ) : (
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          )}
          {state === "recording" && <span className="absolute inset-0 animate-ping rounded-full bg-red-500/40" />}
        </button>
        <p className="mt-4 text-sm muted">
          {state === "idle" && "Tap to record — ramble a message, then tap to stop."}
          {state === "recording" && "Listening… tap to stop (max 45s)."}
          {state === "working" && "Transcribing and cleaning it up…"}
          {state === "done" && (remaining !== null ? `${remaining} free demo${remaining === 1 ? "" : "s"} left.` : "Done.")}
          {state === "error" && <span className="text-red-300">{error}</span>}
        </p>

        {(original || result) && (
          <div className="mt-6 grid gap-3 text-left sm:grid-cols-2">
            <div className="rounded-2xl bg-black/30 p-4">
              <p className="text-xs uppercase tracking-widest muted">You said</p>
              <p className="mt-1 text-sm text-white/70">{original}</p>
            </div>
            <div className="rounded-2xl bg-white/10 p-4">
              <p className="text-xs uppercase tracking-widest muted">Verba writes</p>
              <p className="mt-1 whitespace-pre-line text-sm">{result}</p>
            </div>
          </div>
        )}
      </div>
      <p className="mt-3 text-center text-xs muted">No sign-up needed · 2 free tries · your clip isn't stored.</p>
    </div>
  );
}
