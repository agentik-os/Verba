"use client";

import { useState } from "react";

// Display prices only — the real charge comes from the Stripe price ID.
// TODO: confirm final pricing with the user.
const PRICE = {
  monthly: { amount: "$8", period: "/mo" },
  annual: { amount: "$6", period: "/mo", note: "billed $72/yr" },
};
const DOWNLOAD_URL = "https://github.com/agentik-os/Verba/releases/latest/download/Verba.dmg";

export default function Home() {
  const [plan, setPlan] = useState<"monthly" | "annual">("annual");
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);

  async function checkout() {
    setLoading(true);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan, email }),
      });
      const data = await res.json();
      if (data.url) window.location.href = data.url;
      else alert(data.error ?? "Checkout unavailable. Add Stripe keys.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-6xl px-6">
      {/* Nav */}
      <nav className="flex items-center justify-between py-6">
        <div className="flex items-center gap-2 font-semibold text-lg">
          <Logo /> Verba
        </div>
        <div className="flex items-center gap-6 text-sm text-white/70">
          <a href="#features" className="hover:text-white">Features</a>
          <a href="#pricing" className="hover:text-white">Pricing</a>
          <a href="/account" className="hover:text-white">Account</a>
          <a href={DOWNLOAD_URL} className="rounded-full glass px-4 py-2 text-white hover:bg-white/10">Download</a>
        </div>
      </nav>

      {/* Hero */}
      <section className="py-20 text-center">
        <p className="mb-4 text-sm uppercase tracking-widest text-white/50">macOS menu-bar dictation</p>
        <h1 className="mx-auto max-w-3xl text-5xl font-bold leading-tight sm:text-6xl">
          Talk like a mess.<br />
          <span className="text-gradient">Claude makes it clean.</span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-lg text-white/70">
          Press a key, ramble, release. Verba transcribes you — on-device or via OpenAI —
          then Claude restructures the stream-of-consciousness into a tidy prompt or message,
          and pastes it right where you’re typing.
        </p>
        <div className="mt-10 flex items-center justify-center gap-4">
          <a href={DOWNLOAD_URL} className="rounded-full bg-white px-7 py-3 font-semibold text-black hover:bg-white/90">
            Download for macOS
          </a>
          <a href="#how" className="rounded-full glass px-7 py-3 font-medium hover:bg-white/10">See how it works</a>
        </div>
        <p className="mt-4 text-sm text-white/40">Apple Silicon · macOS 14+ · bring your own API keys</p>
      </section>

      {/* Features */}
      <section id="features" className="grid gap-5 py-16 sm:grid-cols-3">
        {[
          ["Two transcription engines", "OpenAI gpt-4o-transcribe for top accuracy, or fully on-device WhisperKit — free, offline, and no length limit. 20-minute monologues welcome."],
          ["Claude does the thinking", "Your transcript is restructured by Claude (Sonnet, Haiku, or Opus). It reorders your thoughts, fixes self-corrections, and keeps every detail."],
          ["Profiles that fit the app", "Vibe-coding for your editor, clean messages for Slack & email, or your own custom prompts — auto-picked from whatever app is in front."],
          ["Paste anywhere", "Auto-pastes into the active field, or copies to the clipboard. Review and edit before it lands if you want."],
          ["Your keys, your data", "Bring your own OpenAI + Anthropic keys, stored in the macOS Keychain. Verba makes no calls of its own."],
          ["Full history", "Every dictation kept with the raw transcript, the cleaned version, and the audio — searchable, reusable."],
        ].map(([t, d]) => (
          <div key={t} className="glass rounded-2xl p-6">
            <h3 className="text-lg font-semibold">{t}</h3>
            <p className="mt-2 text-sm text-white/65">{d}</p>
          </div>
        ))}
      </section>

      {/* How it works */}
      <section id="how" className="py-16">
        <h2 className="text-center text-3xl font-bold">From ramble to result in one keypress</h2>
        <div className="mt-10 grid gap-5 sm:grid-cols-3">
          {[
            ["1 · Hold the key", "Press your shortcut (or hold the Fn key) and just talk — for ten seconds or twenty minutes."],
            ["2 · Verba transcribes", "On-device or via OpenAI, in your language. Long audio is chunked automatically."],
            ["3 · Claude cleans & pastes", "A tidy prompt or message appears in your active field, ready to send."],
          ].map(([t, d]) => (
            <div key={t} className="glass-strong rounded-2xl p-6">
              <div className="text-gradient text-2xl font-bold">{t.split(" · ")[0]}</div>
              <h3 className="mt-1 font-semibold">{t.split(" · ")[1]}</h3>
              <p className="mt-2 text-sm text-white/65">{d}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-16">
        <h2 className="text-center text-3xl font-bold">Simple pricing</h2>
        <p className="mt-2 text-center text-white/60">14-day free trial. Cancel anytime. You bring your own API keys.</p>

        <div className="mx-auto mt-8 flex w-fit items-center gap-1 rounded-full glass p-1 text-sm">
          {(["monthly", "annual"] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPlan(p)}
              className={`rounded-full px-5 py-2 capitalize transition ${plan === p ? "bg-white text-black" : "text-white/70"}`}
            >
              {p}{p === "annual" && " · save 25%"}
            </button>
          ))}
        </div>

        <div className="mx-auto mt-8 max-w-md glass-strong rounded-3xl p-8 text-center">
          <div className="flex items-end justify-center gap-1">
            <span className="text-5xl font-bold">{PRICE[plan].amount}</span>
            <span className="mb-1 text-white/60">{PRICE[plan].period}</span>
          </div>
          {plan === "annual" && <p className="mt-1 text-sm text-white/50">{PRICE.annual.note}</p>}
          <ul className="mx-auto mt-6 space-y-2 text-left text-sm text-white/75">
            {["Unlimited dictations", "Cloud + on-device transcription", "Claude reprompting & custom profiles", "Auto-paste, history, and review", "Free updates"].map((b) => (
              <li key={b} className="flex gap-2"><span className="text-teal-brand">✓</span>{b}</li>
            ))}
          </ul>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@email.com"
            className="mt-6 w-full rounded-xl bg-black/30 px-4 py-3 text-center outline-none ring-1 ring-white/10 focus:ring-white/30"
          />
          <button
            onClick={checkout}
            disabled={loading}
            className="mt-3 w-full rounded-xl bg-white px-6 py-3 font-semibold text-black hover:bg-white/90 disabled:opacity-60"
          >
            {loading ? "Redirecting…" : "Start free trial"}
          </button>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-16">
        <h2 className="text-center text-3xl font-bold">Questions</h2>
        <div className="mx-auto mt-8 max-w-2xl space-y-3">
          {[
            ["Do I need my own API keys?", "Yes — Verba is bring-your-own-keys. Add your OpenAI and Anthropic keys once; they’re stored in your macOS Keychain and never leave your Mac. Your subscription is just for the app."],
            ["Does it work offline?", "Yes. The on-device WhisperKit engine transcribes without any network. Claude reprompting needs internet (it calls Anthropic with your key)."],
            ["What languages?", "Whatever Whisper / gpt-4o-transcribe support — 90+ languages, including excellent French. Claude restructures in the same language you spoke."],
            ["Can it handle a 20-minute recording?", "Yes — that’s the point. Long audio is chunked automatically, and Claude reorders the whole thing into a clean brief."],
          ].map(([q, a]) => (
            <details key={q} className="glass rounded-2xl p-5">
              <summary className="cursor-pointer font-medium">{q}</summary>
              <p className="mt-2 text-sm text-white/65">{a}</p>
            </details>
          ))}
        </div>
      </section>

      <footer className="flex flex-col items-center gap-2 border-t border-white/10 py-10 text-sm text-white/40">
        <div className="flex items-center gap-2"><Logo /> Verba</div>
        <p>© 2026 Agentik · Dafnck Studio</p>
      </footer>
    </main>
  );
}

function Logo() {
  return (
    <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg"
      style={{ background: "linear-gradient(135deg,#6651F2,#33B3D9)" }}>
      <svg width="15" height="15" viewBox="0 0 24 24" fill="white">
        <path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" />
        <path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" />
      </svg>
    </span>
  );
}
