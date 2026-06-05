"use client";

import { useState } from "react";
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";
import LiveDemo from "@/components/LiveDemo";
import Reveal from "@/components/Reveal";
import TryIt from "@/components/TryIt";
import { getRef } from "@/components/RefCapture";

const PRICE = {
  monthly: { amount: "$9.99", sub: "/month", note: "billed monthly · cancel anytime" },
  annual: { amount: "$84", sub: "/year", note: "≈ $7/mo · save 30%" },
};
const DOWNLOAD_URL = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export default function Home() {
  return (
    <main className="relative mx-auto max-w-6xl px-6">
      <div className="aurora" />
      <Nav />
      <Hero />
      <LogosStrip />
      <TryNow />
      <ModesModels />
      <Features />
      <How />
      <CompareTeaser />
      <Pricing />
      <FAQ />
      <Footer />
    </main>
  );
}

function Logo() {
  return (
    <div className="flex items-center gap-2.5">
      <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-white/15">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
          <path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" />
          <path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" />
        </svg>
      </span>
      <span className="text-[17px] font-semibold tracking-tight">Verba</span>
    </div>
  );
}

function Nav() {
  return (
    <nav className="flex items-center justify-between py-6">
      <Logo />
      <div className="hidden items-center gap-7 text-sm muted sm:flex">
        <a href="#features" className="hover:text-white">Features</a>
        <a href="#how" className="hover:text-white">How it works</a>
        <Link href="/compare" className="hover:text-white">Compare</Link>
        <a href="#pricing" className="hover:text-white">Pricing</a>
        <a href="/account" className="hover:text-white">Account</a>
      </div>
      <div className="flex items-center gap-3">
        <SignedOut>
          <SignInButton mode="modal">
            <button className="text-sm muted hover:text-white">Sign in</button>
          </SignInButton>
        </SignedOut>
        <SignedIn>
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
        <a href={DOWNLOAD_URL} className="rounded-full bg-white px-4 py-2 text-sm font-medium text-black hover:bg-white/90">
          Download
        </a>
      </div>
    </nav>
  );
}

function Hero() {
  return (
    <section className="py-20 text-center sm:py-28">
      <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">
        For macOS · Apple Silicon
      </div>
      <h1 className="mx-auto max-w-3xl text-balance text-5xl font-semibold leading-[1.05] tracking-tight sm:text-7xl">
        Speak it.<br />Send it clean.
      </h1>
      <p className="mx-auto mt-6 max-w-xl text-lg muted text-balance">
        Verba turns your voice into clear, well-structured text — anywhere on your Mac.
        Press a key, talk, and it lands polished in whatever app you’re in.
      </p>
      <div className="mt-10 flex items-center justify-center gap-3">
        <a href={DOWNLOAD_URL} className="rounded-full bg-white px-7 py-3 font-medium text-black hover:bg-white/90">
          Download for macOS
        </a>
        <a href="#how" className="rounded-full glass px-7 py-3 font-medium hover:bg-white/10">See how it works</a>
      </div>
      <p className="mt-4 text-xs muted">Free to start · 7-day Pro trial · cancel anytime</p>

      <div className="mt-16">
        <LiveDemo />
      </div>
    </section>
  );
}

function LogosStrip() {
  const apps = ["Slack", "Mail", "Notes", "VS Code", "Messages", "Notion", "Safari", "Terminal", "Cursor", "Linear", "Figma", "Obsidian"];
  return (
    <section className="overflow-hidden border-y hairline py-8">
      <p className="text-center text-xs uppercase tracking-widest muted">Works in the apps you already use</p>
      <div className="relative mt-5">
        <div className="marquee gap-x-10 text-sm muted">
          {[...apps, ...apps].map((a, i) => (
            <span key={i} className="whitespace-nowrap">{a}</span>
          ))}
        </div>
      </div>
    </section>
  );
}

function TryNow() {
  return (
    <section id="try" className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Try it right now</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          No download, no sign-up. Record a rambling message and watch Verba turn it into clean text —
          the exact same pipeline the app uses.
        </p>
      </Reveal>
      <div className="mt-10"><TryIt /></div>
    </section>
  );
}

function ModesModels() {
  const rows = [
    ["Coding", "Opus 4.8", "Turns rambling feedback into a precise prompt for Cursor or Claude Code."],
    ["Polish", "Haiku 4.5", "Fast, clean work messages and emails — your voice, tightened."],
    ["Casual", "Haiku 4.5", "Warm, natural texts to friends and family."],
    ["Intent", "Sonnet 4.6", "Say how you want it handled — “make this bullet points” — and it obeys."],
  ];
  return (
    <section className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">The right model for the job</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Every mode routes to the model that fits — cheap and instant for quick polish, more
          powerful where it matters. You stay in control of cost and quality.
        </p>
      </Reveal>
      <div className="mt-12 grid gap-4 sm:grid-cols-2">
        {rows.map(([mode, model, desc], i) => (
          <Reveal key={mode} delay={i * 80}>
            <div className="glass flex h-full flex-col rounded-2xl p-6">
              <div className="flex items-center justify-between">
                <h3 className="font-medium">{mode}</h3>
                <span className="rounded-full bg-white/10 px-2.5 py-1 text-xs">{model}</span>
              </div>
              <p className="mt-2 text-sm muted">{desc}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function CompareTeaser() {
  return (
    <section className="py-24">
      <Reveal>
        <div className="glass-strong overflow-hidden rounded-3xl p-10 text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">Cloud tools upload your voice. Verba doesn't.</h2>
          <p className="mx-auto mt-4 max-w-xl muted text-balance">
            Wispr Flow, Aqua and Willow send every word to their servers and charge $12–17/mo.
            Verba runs on your Mac, lets you bring your own AI account, and costs $9.99.
          </p>
          <Link href="/compare" className="mt-8 inline-block rounded-full bg-white px-7 py-3 font-medium text-black hover:bg-white/90">
            See the full comparison
          </Link>
        </div>
      </Reveal>
    </section>
  );
}

function Features() {
  const items = [
    ["Dictate in any app", "Press your shortcut anywhere — the polished text lands right where your cursor is. No copy-paste, no app switching."],
    ["Your messy speech, cleaned up", "Verba reorders your thoughts, fixes punctuation and removes the filler — so a rambling voice note becomes a clean, ready-to-send message."],
    ["Keeps your voice", "Switch between modes for coding, work, and personal writing — Verba matches the right tone instead of flattening everything."],
    ["Hands-free formatting", "Say “new line”, “bullet point” or “scratch that” and watch real formatting appear. Bold, headings and lists paste through, ready to go."],
    ["Private and fast", "An on-device option runs entirely on your Mac and works offline. Your words stay yours."],
    ["Synced to your account", "Your history follows you. Sign in on another Mac and everything’s there."],
  ];
  return (
    <section id="features" className="py-24">
      <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Everything you say, written better</h2>
      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {items.map(([t, d]) => (
          <div key={t} className="glass rounded-2xl p-6">
            <h3 className="font-medium">{t}</h3>
            <p className="mt-2 text-sm muted">{d}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function How() {
  const steps = [
    ["Press", "Tap your shortcut — or the Fn key — from any app."],
    ["Talk", "Say what you mean, for ten seconds or twenty minutes."],
    ["Done", "Clean, formatted text appears right where you were typing."],
  ];
  return (
    <section id="how" className="py-24">
      <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">From voice to done in one press</h2>
      <div className="mt-12 grid gap-4 sm:grid-cols-3">
        {steps.map(([t, d], i) => (
          <div key={t} className="glass-strong rounded-2xl p-7">
            <div className="text-2xl font-semibold tabular-nums">{i + 1}</div>
            <h3 className="mt-2 font-medium">{t}</h3>
            <p className="mt-1.5 text-sm muted">{d}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function Pricing() {
  const { isSignedIn } = useUser();
  const [annual, setAnnual] = useState(true);
  const [loading, setLoading] = useState(false);
  const plan = annual ? "annual" : "monthly";

  async function checkout() {
    setLoading(true);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan, ref: getRef() }),
      });
      const data = await res.json();
      if (data.url) window.location.href = data.url;
      else alert(data.error ?? "Checkout unavailable.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section id="pricing" className="py-24">
      <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Start free. Go Pro when you’re hooked.</h2>
      <div className="mx-auto mt-7 flex w-fit items-center gap-1 rounded-full glass p-1 text-sm">
        {[["Monthly", false], ["Annual · save 22%", true]].map(([label, a]) => (
          <button
            key={String(label)}
            onClick={() => setAnnual(a as boolean)}
            className={`rounded-full px-5 py-2 transition ${annual === a ? "bg-white text-black" : "muted"}`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="mx-auto mt-10 grid max-w-3xl gap-4 sm:grid-cols-2">
        {/* Free */}
        <div className="glass rounded-3xl p-8">
          <h3 className="text-lg font-medium">Free</h3>
          <div className="mt-3 text-4xl font-semibold">$0</div>
          <p className="mt-1 text-sm muted">To get the feel of it.</p>
          <ul className="mt-6 space-y-2 text-sm muted">
            {["Dictation in any app", "On-device or cloud", "10,000 words / month", "Built-in modes"].map((b) => (
              <li key={b} className="flex gap-2"><span className="text-white/80">•</span>{b}</li>
            ))}
          </ul>
          <a href={DOWNLOAD_URL} className="mt-7 block w-full rounded-xl glass px-6 py-3 text-center font-medium hover:bg-white/10">
            Download free
          </a>
        </div>

        {/* Pro */}
        <div className="glass-strong rounded-3xl p-8 ring-1 ring-white/15">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium">Pro</h3>
            <span className="rounded-full bg-white/10 px-2.5 py-1 text-xs">Most popular</span>
          </div>
          <div className="mt-3 flex items-end gap-1">
            <span className="text-4xl font-semibold">{PRICE[plan].amount}</span>
            <span className="mb-1 text-sm muted">{PRICE[plan].sub}</span>
          </div>
          <p className="mt-1 text-sm muted">{PRICE[plan].note} · 7-day trial</p>
          <ul className="mt-6 space-y-2 text-sm">
            {["Unlimited dictation", "All modes + custom modes", "Voice-command formatting", "Sync across your Macs", "Priority support"].map((b) => (
              <li key={b} className="flex gap-2"><span className="text-white">✓</span>{b}</li>
            ))}
          </ul>
          {isSignedIn ? (
            <button onClick={checkout} disabled={loading} className="mt-7 w-full rounded-xl bg-white px-6 py-3 font-medium text-black hover:bg-white/90 disabled:opacity-60">
              {loading ? "Redirecting…" : "Start 7-day trial"}
            </button>
          ) : (
            <SignInButton mode="modal" forceRedirectUrl="/#pricing">
              <button className="mt-7 w-full rounded-xl bg-white px-6 py-3 font-medium text-black hover:bg-white/90">
                Sign in to start trial
              </button>
            </SignInButton>
          )}
        </div>
      </div>
    </section>
  );
}

function FAQ() {
  const qa = [
    ["Does it work in every app?", "Yes — Verba pastes into whatever you’re typing in: editors, browsers, chat apps, mail, notes. If your cursor is there, Verba can write there."],
    ["Can it work offline?", "Yes. On-device transcription (Whisper or Parakeet) runs entirely on your Mac — no internet needed, and your audio never leaves the device."],
    ["What languages does it understand?", "On-device Whisper covers ~99 languages worldwide. Parakeet is a faster option for 25 European languages. It writes back in the language you spoke."],
    ["How do the AI modes work?", "Each mode is a system prompt that tells the model how to rewrite your speech, routed to the right model — Haiku for quick polish, Sonnet for intent, Opus for code. You can edit any prompt or create your own."],
    ["Do I need an API key?", "No. Verba uses your Claude Code plan if it's installed. Otherwise bring an OpenRouter or Anthropic key — you’re never paying a markup on someone’s cloud."],
    ["Can it handle long recordings?", "Yes — talk for twenty minutes and Verba turns the whole thing into clean, well-ordered text."],
    ["Is my data private?", "On-device mode keeps everything local and writes nothing to disk. API keys live in your macOS Keychain. Your history is yours."],
  ];
  return (
    <section className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Questions, answered</h2>
        <p className="mx-auto mt-4 max-w-lg text-center muted text-balance">Everything you’d want to know before you press the key.</p>
      </Reveal>
      <div className="mx-auto mt-12 grid max-w-3xl gap-3">
        {qa.map(([q, a], i) => (
          <Reveal key={q} delay={i * 50}>
            <details className="group glass rounded-2xl px-6 py-5 transition hover:bg-white/[0.07]">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium">
                {q}
                <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-white/10 text-lg leading-none transition-transform duration-300 group-open:rotate-45">+</span>
              </summary>
              <p className="mt-4 text-sm leading-relaxed muted">{a}</p>
            </details>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="flex flex-col items-center gap-3 border-t hairline py-12 text-sm muted">
      <Logo />
      <p>Speak it. Send it clean.</p>
      <div className="flex flex-wrap justify-center gap-5">
        <a href="/account" className="hover:text-white">Account</a>
        <Link href="/compare" className="hover:text-white">Compare</Link>
        <a href="#pricing" className="hover:text-white">Pricing</a>
        <Link href="/acknowledgements" className="hover:text-white">Acknowledgements</Link>
        <a href={DOWNLOAD_URL} className="hover:text-white">Download</a>
      </div>
      <p className="text-xs">© 2026 Verba · Runs on-device with open models</p>
    </footer>
  );
}
