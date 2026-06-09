import Link from "next/link";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";

export const metadata: Metadata = {
  title: "Changelog, Verba",
  description:
    "Every Verba release since launch on June 5, 2026. Shipped in public, fast: 60+ releases in the first days, with dates and times.",
};

type Entry = { version?: string; time?: string; title: string; items: string[] };
type Day = { date: string; tag?: string; window?: string; summary: string; entries: Entry[] };

const DAYS: Day[] = [
  {
    date: "June 9, 2026",
    tag: "Today",
    summary:
      "A huge day: a redesigned site, hold-to-talk and reliable pause, mid-sentence mode switching, editable Note modes, layered writing Styles, smarter Transforms, a Transcripts library, concurrent sessions, and a sharper Task Manager agent.",
    entries: [
      {
        version: "0.1.85",
        title: "A redesigned site, and the controls fixed",
        items: [
          "New homepage: a signature hero that runs the live talk-to-clean-text demo, a monochrome macOS-grade look tied to the mic mark, real type hierarchy and varied layouts.",
          "Fixed Control pause so it never collides with other shortcuts, and made it reliable on every launch.",
          "Mid-recording mode switching is no longer ambiguous, with clear audio and visual feedback.",
          "Concurrent sessions hardened: a background session can no longer disturb the one you're recording, and an Esc-cancelled dictation never gets pasted.",
        ],
      },
      {
        version: "0.1.84",
        title: "Styles, Transforms, Transcripts library & concurrent sessions",
        items: [
          "Writing Styles: a tone/format layer on top of any mode, switch with Fn+[ / Fn+] or from the menu bar, add and edit your own (default “Normal” changes nothing).",
          "Transforms upgraded: select text and just say a short shortcut (“fix grammar”, “translate to English”) to run it in any app, with clearer wording (“Verbal Shortcut”).",
          "Transcripts library: imported transcripts are saved with tags and notes, history audio is exportable, and every transcript gets quick re-adapt actions + a voice intent.",
          "Run several at once: start a new dictation while a slow one is still processing; finished sessions wait in a list with a Copy button.",
          "Community → Feedback, a one-word “Add to Dictionary” from the review window, proper markdown on rich paste, and auto-paste that finds your field even across Spaces.",
        ],
      },
      {
        version: "0.1.83",
        title: "Hold-to-talk, pause, and mid-sentence mode switching",
        items: [
          "New Hold-to-talk style: hold the key to speak, release to send (alongside the press-to-lock style).",
          "Control reliably pauses and resumes a recording, every launch.",
          "Change mode while recording hands-free, long-press the key or click the mode on the overlay, without stopping.",
          "Notes record with the same on-screen widget (labelled “Note”, with pause / resume), and the note formats are now fully editable modes you can add, tweak and delete, plus an Intent mode.",
          "The Task Manager agent now builds real project ▸ task ▸ sub-task lists and generates them for you, “the shopping list for a chocolate cake in Cuisine” fills in the ingredients.",
          "Context (screen) mode simplified so it reliably sees your screen, and Dictionary gains a plain “add a word”.",
        ],
      },
      {
        version: "0.1.82",
        title: "Re-adapt any dictation, by voice",
        items: [
          "Every Recent card now expands to the full text (Show more / less) and opens an inline Adapt panel.",
          "One-click re-adapt through any mode (professional email, code, and more), or type a custom instruction.",
          "Or just press the mic and SAY how you want it changed, “make it a bug report”, and Verba transcribes and adapts it.",
          "The same Adapt panel now powers the History tab too.",
        ],
      },
      {
        version: "0.1.81",
        title: "Task Manager polish",
        items: [
          "Project tags sit cleanly inline on the title row (fixed a layout that clipped long task titles).",
          "A Keyboard Shortcuts cheat-sheet sits at the top of the menu-bar menu.",
        ],
      },
    ],
  },
  {
    date: "June 8, 2026",
    summary:
      "A full day of deep work: a complete Task Manager workspace with a generative AI agent, the franglais bug killed, instant capture, and dozens of rough edges sanded down.",
    entries: [
      {
        version: "0.1.68 – 0.1.80",
        title: "Task Manager grows up",
        items: [
          "To-dos is now the Task Manager, tucked under a new Tools section in the sidebar (Home · Insights · History, then Tools).",
          "A smarter AI agent that builds whole hierarchies from one request: “make a Cooking project, a Chocolate cake task, and the full shopping list” creates the project, the task, and a real ingredient list as sub-tasks.",
          "A clean, professional date & time picker with quick presets (Today 6pm, Tomorrow 9am, This weekend, Next week); sub-tasks can carry their own deadline now.",
          "Project tags moved inline onto the title row.",
          "⌥ + Fn pops a quick glance of today's tasks; a single Fn tap now stops a note or task voice capture.",
          "A Keyboard Shortcuts cheat-sheet right at the top of the menu-bar menu.",
        ],
      },
      {
        version: "0.1.67",
        title: "Task Manager, reimagined",
        items: [
          "A dedicated Task Manager workspace: projects ▸ tasks ▸ sub-tasks in clean accordion panels.",
          "Tags on projects with a filter bar, organize by Pro, Perso, Pense-bête, anything.",
          "A voice agent that turns a spoken request into a structured project, routed to the right list.",
          "Fn + § captures a task by voice from anywhere; a Capture by voice button in the app.",
        ],
      },
      {
        version: "0.1.66",
        title: "Reliability, speed & one language",
        items: [
          "Single-language output: no more franglais, the result is rewritten fully in the language you spoke, even in Flow.",
          "Instant capture: the recorder is pre-armed so it catches your very first word.",
          "Reliable cancel and a processing timeout, no more stuck spinners or force-quitting.",
          "Drag & drop into file transcription; WhatsApp .opus / Ogg voice notes now transcribe.",
          "History entries expand to full text, with one-tap adapt through any mode or a custom instruction.",
        ],
      },
      {
        version: "0.1.65",
        title: "Dictionary & Scratchpad",
        items: [
          "Add a word as a pure vocabulary hint (no replacement needed), with an Improve with AI button.",
          "Auto-learned terms are tagged so you can see what Verba picked up from your edits.",
          "Scratchpad transforms now actually run and surface errors instead of failing silently.",
          "Clear empty-state guidance across every section of the app.",
        ],
      },
      {
        version: "0.1.64",
        title: "Privacy on the leaderboard",
        items: [
          "Anonymous aliases by default, never your real name, with a shuffle and a one-line public reminder.",
          "An opt-out toggle to keep your profile off the leaderboard entirely.",
        ],
      },
      {
        version: "0.1.62 – 0.1.63",
        title: "Microphone, modes & layout",
        items: [
          "Pick your microphone source in a click, from the menu bar and the app.",
          "Fn + Tab to cycle modes, even mid-sentence; Fn + 1-6 to jump to a specific one.",
          "A taller default window and a customizable sidebar (show only the sections you use).",
        ],
      },
    ],
  },
  {
    date: "June 7, 2026",
    tag: "Polish & web",
    window: "23 public releases · 00:10 → 14:16",
    summary:
      "The macOS app stabilized across 23 public releases, and verba.run got a real craftsmanship pass.",
    entries: [
      {
        version: "website",
        time: "22:55",
        title: "A real Liquid Glass website",
        items: [
          "Redesigned verba.run with depth, specular edges and a native-macOS feel.",
          "Dropped every emoji for hand-built SVG icons; added a WebGL sound-wave hero.",
          "Wired Vercel Analytics.",
        ],
      },
      {
        version: "0.1.33 – 0.1.55",
        title: "Twenty-three releases in a day",
        items: [
          "Onboarding, entitlement sync, trial model and paywall tuning.",
          "The recording overlay, the Fn HUD suppression and the meter, refined release after release.",
          "Shipped continuously from 00:10 to 14:16.",
        ],
      },
    ],
  },
  {
    date: "June 6, 2026",
    tag: "It syncs, it learns",
    window: "24 public releases · 01:55 → 23:45",
    summary:
      "Verba grew a memory: cloud sync, a learning dictionary, offline reprompting and a real Dynamic Island.",
    entries: [
      {
        version: "0.1.1 – 0.1.32",
        title: "Sync, learning & local AI",
        items: [
          "Cloud history & stats sync, your Insights and totals follow your account across Macs.",
          "Auto-learning dictionary that remembers your corrections.",
          "File transcription and time-saved on the leaderboard.",
          "Local offline reprompting via Ollama (Qwen 2.5 7B), downloadable from Settings.",
          "A real Dynamic Island overlay; the iOS app scaffolded.",
          "Twenty-four public releases from 01:55 to 23:45.",
        ],
      },
    ],
  },
  {
    date: "June 5, 2026",
    tag: "Launch day",
    window: "first commit 14:07 · first release 21:20",
    summary:
      "Verba was born and shipped on the same day, native, on-device, and private from the first line.",
    entries: [
      {
        version: "0.1.0",
        time: "14:07",
        title: "Verba is born",
        items: [
          "Native Swift menu-bar dictation with Claude reprompting.",
          "Fn-key trigger, faithful reprompting, and modes: Coding, Intent, Flow, Custom.",
          "NVIDIA Parakeet on-device engine and a Claude Code (Max plan) backend.",
          "Sparkle auto-updates with a notarized release pipeline; full onboarding.",
          "Leaderboard (Convex), referral system, the verba.run landing site and Stripe billing.",
          "First public release at 21:20, the same day it began.",
        ],
      },
    ],
  },
];

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export default function Changelog() {
  return (
    <main className="relative mx-auto max-w-4xl px-6 pb-28">
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
      </nav>

      <section className="py-14 text-center">
        <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">
          Shipping in public, fast
        </div>
        <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-6xl">Changelog</h1>
        <p className="mx-auto mt-5 max-w-xl text-lg muted text-balance">
          Every release since launch, with dates and times. Verba went from first commit to a deep,
          polished app in days, and it keeps moving.
        </p>
        <div className="mx-auto mt-9 grid max-w-lg grid-cols-3 gap-3">
          {[
            ["June 5", "launched", "2026"],
            ["60+", "releases", "in days"],
            ["Daily", "shipping", "in public"],
          ].map(([big, label, sub]) => (
            <div key={label} className="glass rounded-2xl p-5">
              <div className="text-2xl font-semibold tracking-tight">{big}</div>
              <div className="mt-1 text-sm font-medium">{label}</div>
              <div className="text-xs muted">{sub}</div>
            </div>
          ))}
        </div>
      </section>

      <div className="relative mt-6 space-y-16">
        {DAYS.map((day) => (
          <section key={day.date}>
            <Reveal>
              <div className="flex flex-wrap items-baseline gap-x-4 gap-y-1">
                <h2 className="text-2xl font-semibold tracking-tight">{day.date}</h2>
                {day.tag && (
                  <span className="rounded-full bg-[var(--tint)] px-3 py-1 text-xs muted">{day.tag}</span>
                )}
                {day.window && <span className="text-xs muted">{day.window}</span>}
              </div>
              <p className="mt-2 max-w-2xl text-sm muted text-balance">{day.summary}</p>
            </Reveal>

            <div className="mt-6 space-y-4">
              {day.entries.map((e, i) => (
                <Reveal key={e.version + e.title} delay={i * 60}>
                  <div className="glass lift rounded-3xl p-6 sm:p-7">
                    <div className="flex flex-wrap items-center gap-3">
                      {e.version && (
                        <span className="rounded-full bg-[var(--fg)] px-2.5 py-1 font-mono text-xs font-semibold text-[var(--bg)]">
                          {e.version === "website" ? "web" : `v${e.version}`}
                        </span>
                      )}
                      <h3 className="text-lg font-medium">{e.title}</h3>
                      {e.time && <span className="ml-auto text-xs muted">{e.time}</span>}
                    </div>
                    <ul className="mt-4 space-y-2">
                      {e.items.map((it) => (
                        <li key={it} className="flex gap-3 text-sm">
                          <span className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--fg)] opacity-50" />
                          <span className="muted">{it}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </Reveal>
              ))}
            </div>
          </section>
        ))}
      </div>

      <section className="mt-20 text-center">
        <div className="glass-strong rounded-3xl p-10">
          <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">Built in the open, every day.</h2>
          <p className="mx-auto mt-3 max-w-md muted text-balance">
            This is the pace we hold ourselves to. Download Verba and watch it get better under you.
          </p>
          <a href={DOWNLOAD} className="mt-7 inline-block rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
            Download for macOS
          </a>
        </div>
      </section>
    </main>
  );
}
