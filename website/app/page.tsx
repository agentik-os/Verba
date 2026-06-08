"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";
import LiveDemo from "@/components/LiveDemo";
import Reveal from "@/components/Reveal";
import TryIt from "@/components/TryIt";
import JokeBubbles from "@/components/JokeBubbles";
import Icon from "@/components/Icon";
import { getRef } from "@/components/RefCapture";

// WebGL sound-wave backdrop; client-only (no SSR for the canvas).
const WaveField = dynamic(() => import("@/components/WaveField"), { ssr: false });

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
      <ContextMode />
      <NotesTab />
      <VoiceTodos />
      <TranslateMode />
      <ModesModels />
      <Bento />
      <WhyBest />
      <LanguageDetection />
      <Jokes />
      <Features />
      <How />
      <CompareTable />
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
      <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
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
    <nav className="sticky top-3 z-50 mt-3 flex items-center justify-between rounded-full glass px-5 py-2.5">
      <Logo />
      <div className="hidden items-center gap-7 text-sm muted sm:flex">
        <a href="#why" className="hover:text-[var(--fg)]">Why Verba</a>
        <a href="#notes" className="hover:text-[var(--fg)]">Notes</a>
        <a href="#translate" className="hover:text-[var(--fg)]">Translate</a>
        <a href="#features" className="hover:text-[var(--fg)]">Features</a>
        <Link href="/compare" className="hover:text-[var(--fg)]">Compare</Link>
        <Link href="/changelog" className="hover:text-[var(--fg)]">Changelog</Link>
        <a href="#pricing" className="hover:text-[var(--fg)]">Pricing</a>
      </div>
      <div className="flex items-center gap-3">
        <SignedOut>
          <SignInButton mode="modal">
            <button className="text-sm muted hover:text-[var(--fg)]">Sign in</button>
          </SignInButton>
        </SignedOut>
        <SignedIn>
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
        <a href={DOWNLOAD_URL} className="rounded-full bg-[var(--fg)] px-4 py-2 text-sm font-medium text-[var(--bg)] hover:opacity-90">
          Download
        </a>
      </div>
    </nav>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden py-20 text-center sm:py-28">
      <WaveField className="absolute left-1/2 top-[-40px] -z-10 h-[560px] w-[150%] -translate-x-1/2 opacity-55 [mask-image:radial-gradient(ellipse_55%_60%_at_50%_45%,#000_35%,transparent_78%)]" />
      <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">
        For macOS · Apple Silicon
      </div>
      <h1 className="mx-auto max-w-3xl text-balance text-5xl font-semibold leading-[1.05] tracking-tight sm:text-7xl">
        Speak it.<br />Send it clean.
      </h1>
      <p className="mx-auto mt-6 max-w-2xl text-lg muted text-balance">
        The most complete voice-to-text on the Mac. Press a key, talk, and Verba lands polished,
        formatted, on-brand text wherever your cursor is. It reads your screen, takes hour-long
        notes, translates on the fly, runs offline, and uses the AI account you already pay for.
      </p>
      <div className="mt-7 flex flex-wrap items-center justify-center gap-2">
        {["Dictate anywhere", "Reads your screen", "Hour-long notes", "Translate live", "Runs offline", "Bring your own AI"].map((p) => (
          <span key={p} className="rounded-full glass px-3.5 py-1.5 text-xs muted">{p}</span>
        ))}
      </div>
      <div className="mt-10 flex items-center justify-center gap-3">
        <a href={DOWNLOAD_URL} className="rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
          Download for macOS
        </a>
        <a href="#how" className="rounded-full glass px-7 py-3 font-medium hover:bg-[var(--tint-strong)]">See how it works</a>
      </div>
      <p className="mt-4 text-xs muted">Free to start · 7-day Pro trial · cancel anytime · $9.99/mo</p>

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
          No download, no sign-up. Record a rambling message and watch Verba turn it into clean text, the exact same pipeline the app uses.
        </p>
      </Reveal>
      <div className="mt-10"><TryIt /></div>
    </section>
  );
}

function Jokes() {
  const themes = [
    "Geek", "Dad jokes", "Dry & deadpan", "Absurdist", "Sarcastic", "Wholesome",
    "Corporate", "Film-noir", "Pirate", "Shakespeare", "Zen", "Sci-fi",
    "Gamer", "Cooking show", "Motivational", "Conspiracy", "Surreal", "Off",
  ];
  return (
    <section className="py-24">
      <Reveal>
        <p className="text-center text-xs uppercase tracking-widest muted">While Claude works</p>
        <h2 className="mt-3 text-center text-3xl font-semibold tracking-tight sm:text-4xl">Loading screens that make you smile</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Every time Verba is restructuring your words, it shows a short, ever-changing one-liner.
          Pick from 17 humor themes, or switch it off. It's never the same joke twice in a day.
        </p>
      </Reveal>

      <div className="relative mt-8 overflow-hidden rounded-3xl glass-strong">
        <JokeBubbles />
      </div>

      <div className="mt-8 flex flex-wrap justify-center gap-2">
        {themes.map((t) => (
          <span key={t} className="glass rounded-full px-4 py-1.5 text-sm muted">{t}</span>
        ))}
      </div>
    </section>
  );
}

function Bento() {
  return (
    <section className="py-24">
      <Reveal>
        <p className="text-center text-xs uppercase tracking-widest muted">Private by design</p>
        <h2 className="mt-3 text-center text-3xl font-semibold tracking-tight sm:text-4xl">Your voice stays yours</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Verba runs open speech models (Whisper and Parakeet) right on your Mac. No servers, no
          uploads, no markup. Here is what that gets you.
        </p>
      </Reveal>

      <div className="mt-12 grid auto-rows-[150px] grid-cols-2 gap-4 lg:grid-cols-4">
        {/* big privacy tile */}
        <Reveal className="col-span-2 row-span-2">
          <div className="glass-strong flex h-full flex-col justify-between rounded-3xl p-7">
            <div className="text-5xl font-semibold tracking-tight">0 bytes</div>
            <div>
              <p className="font-medium">of audio leave your Mac</p>
              <p className="mt-1 text-sm muted">On-device mode transcribes locally and writes nothing to disk. Cloud tools upload every word; Verba doesn't have to.</p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={60}><BentoStat big="99+" label="languages, on-device" sub="Whisper runs worldwide" /></Reveal>
        <Reveal delay={120}><BentoStat big="$9.99" label="vs $15 at Wispr Flow" sub="and you bring your own AI" /></Reveal>
        <Reveal delay={180}><BentoStat big="10,000" label="free words / month" sub="no card, no trial clock" /></Reveal>
        <Reveal delay={240}><BentoStat big="100%" label="works offline" sub="no internet required" /></Reveal>

        <Reveal delay={120} className="col-span-2">
          <div className="glass lift flex h-full items-center gap-4 rounded-3xl p-7">
            <Icon name="key" className="h-8 w-8 shrink-0" />
            <div>
              <p className="font-medium">Bring your own AI account</p>
              <p className="mt-1 text-sm muted">Anthropic key, OpenRouter, your Claude Code subscription, or a fully local Ollama model. You never pay a vendor markup.</p>
            </div>
          </div>
        </Reveal>
        <Reveal delay={180} className="col-span-2">
          <div className="glass lift flex h-full items-center gap-4 rounded-3xl p-7">
            <Icon name="bolt" className="h-8 w-8 shrink-0" />
            <div>
              <p className="font-medium">Modes, the right model each time</p>
              <p className="mt-1 text-sm muted">Flow (verbatim), Intent, Coding, Translate, Custom, and Context (vision). Sonnet for intent, Opus for code. Edit any prompt or add your own.</p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

function BentoStat({ big, label, sub }: { big: string; label: string; sub: string }) {
  return (
    <div className="glass lift flex h-full flex-col justify-center rounded-3xl p-6">
      <div className="text-3xl font-semibold tracking-tight">{big}</div>
      <p className="mt-1 text-sm font-medium">{label}</p>
      <p className="text-xs muted">{sub}</p>
    </div>
  );
}

function ContextMode() {
  const examples = [
    { icon: "mail", label: "Email reply", prompt: "Reply to this email, keep it short and friendly." },
    { icon: "doc", label: "Summarize", prompt: "Summarize what is shown on screen." },
    { icon: "image", label: "Comment on photo", prompt: "Write a caption for this photo." },
    { icon: "question", label: "Answer a question", prompt: "Answer the question visible on screen." },
    { icon: "calendar", label: "Create event", prompt: "Create an event tomorrow at 3pm for the team sync." },
    { icon: "bell", label: "Set a reminder", prompt: "Remind me to call the bank this afternoon." },
    { icon: "pen", label: "Draft a reply", prompt: "Draft a reply to this email saying I'll be there." },
  ];
  return (
    <section id="context-mode" className="py-24">
      <Reveal>
        <div className="mx-auto mb-4 w-fit rounded-full glass px-4 py-1.5 text-xs muted">New feature</div>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">
          Context mode: your voice meets your screen
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Press your shortcut, glance at the screen, and talk. Verba captures what is on your screen
          and uses it to ground exactly what it writes. Reply to the email in front of you,
          summarize a document, comment on a photo. No copy-paste required.
        </p>
      </Reveal>

      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {examples.map(({ icon, label, prompt }, i) => (
          <Reveal key={label} delay={i * 60}>
            <div className="glass lift flex h-full flex-col gap-3 rounded-2xl p-6">
              <Icon name={icon} className="h-7 w-7" />
              <p className="font-medium">{label}</p>
              <p className="text-sm muted italic">"{prompt}"</p>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={100}>
        <div className="mt-8 glass-strong rounded-2xl p-7">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-8">
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">How it works</p>
              <p className="mt-2 text-sm muted leading-relaxed">
                Context mode takes a screenshot the moment you stop talking, analyzes it with a vision-capable model,
                and combines what it sees with what you said. The result is grounded in your actual screen content,
                not a generic template.
              </p>
            </div>
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">Requirements</p>
              <ul className="mt-2 space-y-1 text-sm muted">
                <li className="flex gap-2"><span>•</span>macOS Screen Recording permission</li>
                <li className="flex gap-2"><span>•</span>A vision-capable model: Anthropic API key or OpenRouter key</li>
              </ul>
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal delay={120}>
        <div className="mt-4 glass rounded-2xl p-7">
          <div className="flex items-start gap-4">
            <div className="mt-0.5 rounded-full bg-[var(--tint)] px-2.5 py-1 text-xs shrink-0">Labs</div>
            <div>
              <p className="font-medium">Agentic actions in Context mode</p>
              <p className="mt-1 text-sm muted leading-relaxed">
                With the Labs toggle on, Context mode can do more than write: say "create an event tomorrow at 3pm",
                "remind me to call the bank", or "draft a reply to this email" and Verba creates the Calendar event,
                Reminder, or email draft for you. It always asks you to confirm before doing anything.
              </p>
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

function NotesTab() {
  const formats = [
    { icon: "note", label: "Clean note" },
    { icon: "outline", label: "Brain dump to outline" },
    { icon: "bolt", label: "Summary / TL;DR" },
    { icon: "calendar", label: "Meeting notes" },
    { icon: "journal", label: "Journal" },
    { icon: "mail", label: "Email draft" },
    { icon: "ticket", label: "Code task / ticket" },
    { icon: "check", label: "To-do list" },
    { icon: "article", label: "Article outline" },
  ];
  return (
    <section id="notes" className="py-24">
      <Reveal>
        <div className="mx-auto mb-4 w-fit rounded-full glass px-4 py-1.5 text-xs muted">Flagship feature</div>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">
          Notes: talk for an hour, get a clean document
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Open the Notes tab, pick a format, and record. Verba transcribes up to a full hour of speech and
          shapes it into a structured document ready to read, edit, and copy. Tag it with #hashtags
          (Bear style) to file and filter. Notes sync across your Macs via your account.
        </p>
      </Reveal>

      <Reveal delay={60}>
        <div className="mt-10 glass-strong rounded-3xl p-8">
          <div className="flex flex-col gap-6 sm:flex-row sm:gap-10">
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">Example</p>
              <p className="mt-3 font-medium leading-snug">
                "So the standup ran long today, we decided to push the API milestone to next Friday,
                the auth bug is now Alex's, and I need to follow up with design about the onboarding
                flow by Thursday..."
              </p>
              <p className="mt-2 text-sm muted">40 seconds of voice, Meeting notes format selected.</p>
            </div>
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">Verba produces</p>
              <div className="mt-3 rounded-xl bg-[var(--tint)] p-4 text-sm font-mono leading-relaxed">
                <p className="font-semibold not-italic">## Standup notes</p>
                <p className="mt-1 muted">**API milestone** pushed to next Friday</p>
                <p className="muted">**Auth bug** assigned to Alex</p>
                <p className="muted">**Action:** follow up with design on onboarding flow by Thursday</p>
              </div>
              <p className="mt-2 text-xs muted">Rendered markdown. Editable. Copyable. Tagged and synced.</p>
            </div>
          </div>
        </div>
      </Reveal>

      <div className="mt-8 grid gap-3 sm:grid-cols-3 lg:grid-cols-3">
        <Reveal delay={40} className="sm:col-span-3">
          <p className="text-center text-xs uppercase tracking-widest muted">Choose your format before you record</p>
        </Reveal>
        {formats.map(({ icon, label }, i) => (
          <Reveal key={label} delay={i * 40}>
            <div className="glass lift flex items-center gap-3 rounded-2xl px-5 py-4">
              <Icon name={icon} className="h-6 w-6 shrink-0" />
              <span className="text-sm font-medium">{label}</span>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={80}>
        <div className="mt-8 grid gap-4 sm:grid-cols-3">
          <div className="glass lift rounded-2xl p-6">
            <p className="font-medium">Up to 60 minutes</p>
            <p className="mt-1 text-sm muted">Record a full meeting, a long brainstorm, or a detailed voice memo. Verba handles the whole thing.</p>
          </div>
          <div className="glass lift rounded-2xl p-6">
            <p className="font-medium">#Hashtag filing</p>
            <p className="mt-1 text-sm muted">Tag any note with #hashtags to organize and filter, exactly the way Bear works. Your notes find themselves.</p>
          </div>
          <div className="glass lift rounded-2xl p-6">
            <p className="font-medium">Synced across Macs</p>
            <p className="mt-1 text-sm muted">Your notes follow your account. Sign in on another Mac and they are all there, instantly.</p>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

function LanguageDetection() {
  const pairs = [
    { spoken: "Bonjour, j'ai besoin d'aide avec mon compte.", written: "Bonjour, j'ai besoin d'aide avec mon compte." },
    { spoken: "Hola, quiero cancelar mi suscripción.", written: "Hola, quiero cancelar mi suscripción." },
    { spoken: "Hey, can we reschedule to Thursday?", written: "Hey, can we reschedule to Thursday?" },
    { spoken: "Ich brauche die Rechnung bis Freitag.", written: "Ich brauche die Rechnung bis Freitag." },
  ];
  return (
    <section className="py-24">
      <Reveal>
        <p className="text-center text-xs uppercase tracking-widest muted">Multilingual</p>
        <h2 className="mt-3 text-center text-3xl font-semibold tracking-tight sm:text-4xl">Speak any language. It just works.</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Every transcription engine automatically detects the language you are speaking and writes the result
          in that same language. French in, French out. Spanish in, Spanish out.
          Switch mid-session, or say "in English" to override. No settings to change.
        </p>
      </Reveal>
      <div className="mt-10 grid gap-3 sm:grid-cols-2">
        {pairs.map(({ spoken, written }, i) => (
          <Reveal key={i} delay={i * 60}>
            <div className="glass rounded-2xl p-5">
              <p className="text-xs uppercase tracking-widest muted">You say</p>
              <p className="mt-1 text-sm muted italic">"{spoken}"</p>
              <p className="mt-3 text-xs uppercase tracking-widest muted">Verba writes</p>
              <p className="mt-1 text-sm">{written}</p>
            </div>
          </Reveal>
        ))}
      </div>
      <Reveal delay={80}>
        <p className="mt-6 text-center text-sm muted">
          Whisper covers 99+ languages. Parakeet is optimized for 25 European languages.
          Use Intent mode to override: "en francais", "in English", "auf Deutsch".
        </p>
      </Reveal>
    </section>
  );
}

function VoiceTodos() {
  const cards = [
    { icon: "pen", label: "Build whole lists", text: "“Make a Cooking project, a Chocolate cake task, and the full shopping list” → it creates the project, the task, and a real ingredient list as sub-tasks." },
    { icon: "calendar", label: "Deadlines by voice", text: "“Pay the invoice Friday at 3pm” → a task with a real date and time, shown red when it’s overdue." },
    { icon: "bell", label: "Reminders", text: "Get a notification 30 minutes before anything is due. Toggle it on or off in Settings." },
    { icon: "check", label: "Check off by voice", text: "“I bought the tomatoes” → Verba finds “Buy tomatoes” and ticks it. No tapping, no app-switching." },
  ];
  return (
    <section id="todos" className="py-24">
      <Reveal>
        <div className="mx-auto mb-4 w-fit rounded-full glass px-4 py-1.5 text-xs muted">New · Voice task manager</div>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">
          A Task Manager you just talk to
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-center muted text-balance">
          Press a key, talk, and Verba builds projects, tasks and sub-tasks, sets date-and-time
          deadlines, reminds you, and checks things off, all by voice, and it can even generate a
          whole list for you. No other dictation app has a built-in task manager, let alone one this smart.
        </p>
      </Reveal>

      <Reveal delay={60}>
        <div className="mt-10 glass-strong rounded-3xl p-8">
          <div className="flex flex-col gap-6 sm:flex-row sm:gap-10">
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">You say</p>
              <p className="mt-3 font-medium leading-snug">
                "Add to my groceries: tomatoes, pasta and parmesan. Oh and I already bought the bread.
                Pay the electricity bill Friday at 6pm."
              </p>
              <p className="mt-2 text-sm muted">One press, one sentence.</p>
            </div>
            <div className="flex-1">
              <p className="text-xs uppercase tracking-widest muted">Verba does</p>
              <div className="mt-3 space-y-2 rounded-xl bg-[var(--tint)] p-4 text-sm">
                <p className="font-semibold">Groceries</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-current opacity-40" /> Tomatoes</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-current opacity-40" /> Pasta</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-current opacity-40" /> Parmesan</p>
                <p className="flex items-center gap-2 muted line-through"><Icon name="check" className="h-4 w-4 text-green-500" /> Bread</p>
                <p className="mt-2 font-semibold">Bills</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-current opacity-40" /> Pay electricity <span className="rounded bg-[var(--tint-strong)] px-1.5 py-0.5 text-xs">Fri 18:00</span></p>
              </div>
              <p className="mt-2 text-xs muted">Filed, dated, and one already checked, automatically.</p>
            </div>
          </div>
        </div>
      </Reveal>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map(({ icon, label, text }, i) => (
          <Reveal key={label} delay={i * 60}>
            <div className="glass lift flex h-full flex-col gap-3 rounded-2xl p-6">
              <Icon name={icon} className="h-7 w-7" />
              <p className="font-medium">{label}</p>
              <p className="text-sm muted">{text}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function TranslateMode() {
  const langs = ["English", "Français", "Español", "Deutsch", "Italiano", "Português", "Nederlands",
                 "Русский", "中文", "日本語", "한국어", "العربية", "हिन्दी", "Türkçe", "Polski"];
  const pairs = [
    { code: "FR", from: "You speak French", said: "Salut, on peut décaler la réunion à jeudi ?", out: "Hi, can we move the meeting to Thursday?" },
    { code: "ES", from: "You speak Spanish", said: "Necesito la factura antes del viernes, por favor.", out: "I need the invoice before Friday, please." },
    { code: "DE", from: "You speak German", said: "Ich melde mich morgen mit den Details.", out: "I'll get back to you tomorrow with the details." },
  ];
  return (
    <section id="translate" className="py-24">
      <Reveal>
        <div className="mx-auto mb-4 w-fit rounded-full glass px-4 py-1.5 text-xs muted">New mode</div>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">
          Translate: think in your language, write in theirs
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Pick a target language once. Then just talk, in whatever language is natural to you,
          and Verba writes it out fluently in the one you chose. No "translate this" prefix,
          no copy-paste into another tab. Speak French, send English. Every single time.
        </p>
      </Reveal>

      <div className="mt-10 grid gap-3 sm:grid-cols-3">
        {pairs.map((p, i) => (
          <Reveal key={i} delay={i * 70}>
            <div className="glass lift flex h-full flex-col rounded-2xl p-6">
              <div className="flex items-center gap-2">
                <span className="rounded-md bg-[var(--tint)] px-1.5 py-0.5 font-mono text-[10px] font-semibold tracking-wider">{p.code}</span>
                <p className="text-xs uppercase tracking-widest muted">{p.from}</p>
              </div>
              <p className="mt-2 text-sm muted italic">"{p.said}"</p>
              <div className="my-3 h-px bg-[var(--border)]" />
              <p className="text-xs uppercase tracking-widest muted">Verba writes (English)</p>
              <p className="mt-1 text-sm">{p.out}</p>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={80}>
        <div className="mt-8 glass-strong rounded-3xl p-8">
          <p className="text-center text-xs uppercase tracking-widest muted">Choose any target language</p>
          <div className="mt-5 flex flex-wrap justify-center gap-2">
            {langs.map((l) => (
              <span key={l} className="rounded-full bg-[var(--tint)] px-3.5 py-1.5 text-sm">{l}</span>
            ))}
          </div>
          <p className="mt-6 text-center text-sm muted text-balance">
            Set it per mode, or make a dedicated mode per language and auto-switch by app.
            Tone, intent, names, numbers and code are all preserved. Uses your default model.
          </p>
        </div>
      </Reveal>
    </section>
  );
}

function WhyBest() {
  const edges = [
    ["Does what others can't", "Reads your screen (Context), takes hour-long structured Notes, translates live, and runs agentic actions (Calendar, Reminders, email drafts). Most rivals only transcribe."],
    ["Cheaper, and honest about it", "$9.99/mo, or ~$7 on annual. Wispr Flow is $12-15, others $15-17. And there's a real free tier: 10,000 words a month, no card."],
    ["Bring your own AI", "Use your Anthropic key, OpenRouter, your existing Claude Code subscription with no key at all, or a fully local Ollama model. You're never locked into our markup."],
    ["Actually private", "On-device transcription with Parakeet and Whisper, your audio never leaves the Mac. API keys live in the macOS Keychain. Cloud tools upload every word you speak."],
    ["Works with no internet", "Parakeet ships inside the app and transcribes offline, instantly, in 25 languages. Pair it with a local LLM and the entire pipeline runs on your Mac."],
    ["Six modes, the right model each", "Flow, Intent, Context, Coding, Translate, Custom, routed to Haiku, Sonnet, or Opus so you only pay for power where it matters. Edit any prompt or build your own."],
    ["It learns you", "Auto-learns your vocabulary from your edits, matches your writing tone per app, and remembers how you phrase things. It sounds like you, not a template."],
    ["One press, then done", "Tap Fn, talk, and clean text lands where your cursor is. Hands-free formatting, redo in another mode, edit the last result by voice. No app switching, ever."],
  ];
  return (
    <section id="why" className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Why Verba wins</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Other apps transcribe. Verba is a full voice workspace: it reads, writes, organizes,
          translates, and acts, on your terms, on your Mac, with your AI.
        </p>
      </Reveal>
      <div className="mt-12 grid gap-4 sm:grid-cols-2">
        {edges.map(([t, d], i) => (
          <Reveal key={t} delay={(i % 2) * 60}>
            <div className="glass lift flex h-full gap-4 rounded-2xl p-6">
              <span className="mt-0.5 inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[var(--fg)] text-xs font-semibold text-[var(--bg)]">✓</span>
              <div>
                <h3 className="font-medium">{t}</h3>
                <p className="mt-1.5 text-sm muted">{d}</p>
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function CompareTable() {
  const cols = ["Verba", "Wispr Flow", "superwhisper", "Aqua"];
  const rows: [string, (boolean | string)[]][] = [
    ["Dictate in any app", [true, true, true, true]],
    ["Runs fully offline", [true, false, true, false]],
    ["On-device, audio never uploaded", [true, false, true, false]],
    ["Bring your own AI key / no markup", [true, false, false, false]],
    ["Use Claude Code sub, no key", [true, false, false, false]],
    ["Reads your screen (vision)", [true, false, false, false]],
    ["Hour-long structured notes", [true, false, false, false]],
    ["Voice Task Manager (projects, sub-tasks, generated lists)", [true, false, false, false]],
    ["Live translation mode", [true, "limited", false, "limited"]],
    ["Agentic actions (calendar, reminders)", [true, false, false, false]],
    ["Auto-learn your vocabulary & tone", [true, "partial", false, false]],
    ["Free tier", ["10k words/mo", "limited", "trial", "limited"]],
    ["Price / month", ["$9.99", "$12-15", "$8.49", "$10-17"]],
  ];
  const cell = (v: boolean | string) =>
    v === true ? <span className="text-[var(--fg)]">✓</span>
      : v === false ? <span className="muted opacity-40">—</span>
      : <span className="text-xs muted">{v}</span>;
  return (
    <section className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">How Verba compares</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          The honest, side-by-side. Verba does more, keeps your data on your Mac, and costs less.
        </p>
      </Reveal>
      <Reveal delay={60}>
        <div className="mt-10 overflow-x-auto">
          <table className="w-full min-w-[640px] border-collapse text-sm">
            <thead>
              <tr className="border-b hairline">
                <th className="py-3 pr-4 text-left font-normal muted">Feature</th>
                {cols.map((c, i) => (
                  <th key={c} className={`px-3 py-3 text-center font-semibold ${i === 0 ? "text-[var(--fg)]" : "muted"}`}>{c}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map(([label, vals]) => (
                <tr key={label} className="border-b hairline">
                  <td className="py-3 pr-4 text-left">{label}</td>
                  {vals.map((v, i) => (
                    <td key={i} className={`px-3 py-3 text-center ${i === 0 ? "bg-[var(--tint)]" : ""}`}>{cell(v)}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Reveal>
      <Reveal delay={100}>
        <p className="mt-4 text-center text-xs muted">Competitor pricing and features as publicly listed; they change often. <Link href="/compare" className="underline hover:text-[var(--fg)]">Full comparison →</Link></p>
      </Reveal>
    </section>
  );
}

function ModesModels() {
  const rows = [
    ["Context", "Sonnet 4.6", "Takes a screenshot of your screen and acts on what it sees, based on what you say. Reply to the email on screen, summarize a document, comment on a photo."],
    ["Flow", "No AI", "Verbatim transcription, no rewriting. Your words, exactly as spoken, cleaned up for punctuation only."],
    ["Intent", "Sonnet 4.6", "State the goal at the start: \"turn this into a bug report\", \"rewrite as a formal email\". Verba follows your lead."],
    ["Coding", "Opus 4.8", "Turns rambling feedback into a precise prompt for Cursor or Claude Code."],
    ["Translate", "Sonnet 4.6", "Pick a target language once. Speak in any language and Verba writes it in the one you chose, every time."],
    ["Custom", "Your choice", "Define your own system prompt. Make Verba write exactly the way you need it to."],
  ];
  return (
    <section className="py-24">
      <Reveal>
        <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Six modes, the right model for each</h2>
        <p className="mx-auto mt-4 max-w-xl text-center muted text-balance">
          Every mode routes to the model that fits: cheap and instant for quick polish, more
          powerful where it matters. You stay in control of cost and quality.
        </p>
      </Reveal>
      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {rows.map(([mode, model, desc], i) => (
          <Reveal key={mode} delay={i * 60}>
            <div className={`glass lift flex h-full flex-col rounded-2xl p-6 ${mode === "Context" ? "ring-1 ring-[var(--border)] col-span-full sm:col-span-2 lg:col-span-3" : ""}`}>
              <div className="flex items-center justify-between">
                <h3 className="font-medium">{mode}</h3>
                <span className="rounded-full bg-[var(--tint)] px-2.5 py-1 text-xs">{model}</span>
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
            Wispr Flow, Aqua and Willow send every word to their servers and charge $12-17/mo.
            Verba runs on your Mac, lets you bring your own AI account, and costs $9.99.
          </p>
          <Link href="/compare" className="mt-8 inline-block rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
            See the full comparison
          </Link>
        </div>
      </Reveal>
    </section>
  );
}

function Features() {
  const items = [
    ["Dictate in any app", "Press your shortcut anywhere. The polished text lands right where your cursor is. No copy-paste, no app switching."],
    ["Your messy speech, cleaned up", "Verba reorders your thoughts, fixes punctuation, and removes the filler so a rambling voice note becomes a clean, ready-to-send message."],
    ["Keeps your voice", "Switch between modes for coding, work, and personal writing. Verba matches the right tone instead of flattening everything."],
    ["Hands-free formatting", "Say \"new line\", \"bullet point\", or \"scratch that\" and watch real formatting appear. Bold, headings, and lists paste through, ready to go."],
    ["Three transcription engines", "Cloud (OpenAI gpt-4o-transcribe, fastest and most accurate), WhisperKit (local Whisper, all sizes including large-v3), and Parakeet (NVIDIA Parakeet TDT v3, multilingual, strong on EU languages). Parakeet ships inside the app, works offline instantly, and needs no API key."],
    ["Private by default", "On-device mode runs entirely on your Mac. Your audio never leaves the device. API keys live in your macOS Keychain."],
    ["Flexible AI backends", "Use your Anthropic key, an OpenRouter key, your existing Claude Code subscription (no key needed), or a fully local Ollama model that runs offline. Verba can auto-install and start Ollama for you."],
    ["Recording indicator choices", "A floating glass pill (default), or Menu bar only (no overlay, the menu-bar icon turns into a red REC dot while recording). Pick the one that stays out of your way."],
    ["Auto-learn dictionary", "When you correct a word on the review screen, Verba remembers it and applies the fix automatically next time. Your vocabulary, learned silently."],
    ["Edit the last result by voice", "After a dictation, say \"make it shorter\", \"more formal\", or \"translate to English\" and Verba rewrites the result on the spot. No need to re-record."],
    ["Redo in another mode", "Changed your mind about the format? Re-run your last recording through any other mode without speaking again."],
    ["Tone match per app", "Verba learns how you write in each app from your recent messages there and matches your personal tone automatically. Slack sounds like you in Slack. Mail sounds like you in Mail."],
    ["Smart formatting per app", "Rich text and markdown in apps that render it (Mail, Notion, Notes, Obsidian). Plain text in code editors and terminals. Verba detects the context and formats accordingly."],
    ["Custom sound cues", "Subtle audio cues signal recording start, paste, and errors. Adjust the volume or swap out sounds. Everything is customizable, or turn it off entirely."],
    ["Synced to your account", "Your history, notes, and stats follow you. Sign in on another Mac and everything is there."],
    ["Automatic language detection", "Every transcription engine detects the language you are speaking and writes the result in that same language. No settings to change."],
  ];
  return (
    <section id="features" className="py-24">
      <h2 className="text-center text-3xl font-semibold tracking-tight sm:text-4xl">Everything you say, written better</h2>
      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {items.map(([t, d]) => (
          <div key={t} className="glass lift rounded-2xl p-6">
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
    ["Press", "Tap your shortcut, or the Fn key, from any app."],
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
            className={`rounded-full px-5 py-2 transition ${annual === a ? "bg-[var(--fg)] text-[var(--bg)]" : "muted"}`}
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
          <p className="mt-1 text-sm muted">Try everything, 33 dictations, no card.</p>
          <ul className="mt-6 space-y-2 text-sm muted">
            {["33 dictations to try, full Pro features", "On-device or cloud transcription", "All modes + voice formatting", "No card required"].map((b) => (
              <li key={b} className="flex gap-2"><span className="text-white/80">•</span>{b}</li>
            ))}
          </ul>
          <a href={DOWNLOAD_URL} className="mt-7 block w-full rounded-xl glass px-6 py-3 text-center font-medium hover:bg-[var(--tint-strong)]">
            Download free
          </a>
        </div>

        {/* Pro */}
        <div className="glass-strong rounded-3xl p-8 ring-1 ring-[var(--border)]">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium">Pro</h3>
            <span className="rounded-full bg-[var(--tint)] px-2.5 py-1 text-xs">Most popular</span>
          </div>
          <div className="mt-3 flex items-end gap-1">
            <span className="text-4xl font-semibold">{PRICE[plan].amount}</span>
            <span className="mb-1 text-sm muted">{PRICE[plan].sub}</span>
          </div>
          <p className="mt-1 text-sm muted">{PRICE[plan].note} · 7-day trial</p>
          <ul className="mt-6 space-y-2 text-sm">
            {["Unlimited dictation", "All modes + custom modes", "Voice-command formatting", "Sync across your Macs", "Priority support"].map((b) => (
              <li key={b} className="flex gap-2"><span className="text-[var(--fg)]">✓</span>{b}</li>
            ))}
          </ul>
          {isSignedIn ? (
            <button onClick={checkout} disabled={loading} className="mt-7 w-full rounded-xl bg-[var(--fg)] px-6 py-3 font-medium text-[var(--bg)] hover:opacity-90 disabled:opacity-60">
              {loading ? "Redirecting…" : "Start 7-day trial"}
            </button>
          ) : (
            <SignInButton mode="modal" forceRedirectUrl="/#pricing">
              <button className="mt-7 w-full rounded-xl bg-[var(--fg)] px-6 py-3 font-medium text-[var(--bg)] hover:opacity-90">
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
    ["Does it work in every app?", "Yes, Verba pastes into whatever you’re typing in: editors, browsers, chat apps, mail, notes. If your cursor is there, Verba can write there."],
    ["Can it work offline?", "Yes. On-device transcription (Whisper or Parakeet) runs entirely on your Mac, no internet needed, and your audio never leaves the device."],
    ["What languages does it understand?", "On-device Whisper covers ~99 languages worldwide. Parakeet is a faster option for 25 European languages. It writes back in the language you spoke."],
    ["How do the AI modes work?", "Verba has Flow (verbatim, no AI), Intent, Coding, Custom, and Context. Each mode is a system prompt that shapes how the model rewrites your speech. Context also takes a screenshot to ground the output in what is on your screen. You can edit any prompt or create your own Custom mode."],
    ["Do I need an API key?", "No. Verba uses your Claude Code plan if it is installed (no API key needed). You can also bring your own Anthropic key, an OpenRouter key, or run a local Ollama model entirely offline. You never pay a markup on someone’s cloud."],
    ["What is Context mode?", "Context mode takes a screenshot of your screen, analyzes it with a vision model, and writes based on what you say and what it sees. Say \"reply to this email\" and it drafts a reply to the message on screen. It requires macOS Screen Recording permission and a vision-capable model (Anthropic API key or OpenRouter key)."],
    ["Can it handle long recordings?", "Yes, talk for twenty minutes and Verba turns the whole thing into clean, well-ordered text."],
    ["Is my data private?", "On-device mode keeps everything local and writes nothing to disk. API keys live in your macOS Keychain. Your history is yours."],
    ["Can Verba take notes?", "Yes. The Notes tab lets you record up to a full hour of speech and Verba turns it into a clean, structured document. Pick a format before you start: Clean note, Brain dump to outline, Summary, Meeting notes, Journal, Email, Code task, To-do list, or Article outline. Markdown is rendered (headings, bold, checkboxes). You can tag notes with #hashtags to file and filter them, edit the result in place, and copy it anywhere."],
    ["Can it create calendar events or reminders?", "Yes, with the Labs toggle on in Context mode. Say \"create an event tomorrow at 3pm\", \"remind me to call the bank\", or \"draft a reply to this email\" and Verba creates the Calendar event, Reminder, or email draft for you. It always asks you to confirm before doing anything."],
    ["Do my notes sync across my Macs?", "Yes. Notes are tied to your Verba account, so they follow you when you sign in on another Mac. No iCloud setup needed."],
    ["How does the Translate mode work?", "Pick a target language once in the Translate mode (English, French, Spanish, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean, Arabic, Hindi, Turkish, Polish). Then just speak in whatever language is natural to you and Verba writes the result in your chosen language, every time, preserving tone, names, numbers and code. You can also make a dedicated mode per language and auto-switch it by app."],
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
            <details className="group glass rounded-2xl px-6 py-5 transition hover:bg-[var(--tint-strong)]">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium">
                {q}
                <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-[var(--tint)] text-lg leading-none transition-transform duration-300 group-open:rotate-45">+</span>
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
        <a href="/account" className="hover:text-[var(--fg)]">Account</a>
        <Link href="/compare" className="hover:text-[var(--fg)]">Compare</Link>
        <Link href="/changelog" className="hover:text-[var(--fg)]">Changelog</Link>
        <a href="#pricing" className="hover:text-[var(--fg)]">Pricing</a>
        <Link href="/acknowledgements" className="hover:text-[var(--fg)]">Acknowledgements</Link>
        <a href="https://t.me/verba_run" target="_blank" rel="noopener" className="hover:text-[var(--fg)]">Community</a>
        <a href={DOWNLOAD_URL} className="hover:text-[var(--fg)]">Download</a>
      </div>
      <p className="text-xs">© 2026 Verba · Runs on-device with open models</p>
    </footer>
  );
}
