import Link from "next/link";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import ThemeToggle from "@/components/ThemeToggle";

import SiteFooter from "@/components/SiteFooter";
export const metadata: Metadata = {
  title: "Documentation, Verba AI Dictation for Mac",
  description:
    "Verba's technical documentation: install & permissions, dictation modes, AI engines and bring-your-own-AI setup, the JARVIS voice agent, Notes, Tasks, shortcuts, privacy and troubleshooting.",
  alternates: { canonical: "/docs" },
  openGraph: {
    title: "Verba Documentation, Mac AI Dictation",
    description:
      "How Verba works, end to end: setup, permissions, modes, AI engines, JARVIS, Notes, Tasks, every shortcut, privacy and troubleshooting.",
    url: "/docs",
    type: "article",
    images: ["/opengraph-image"],
  },
  twitter: { card: "summary_large_image", images: ["/opengraph-image"] },
};

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

type Block =
  | { kind: "p"; text: string }
  | { kind: "ul"; items: string[] }
  | { kind: "steps"; items: string[] }
  | { kind: "keys"; rows: [string, string][] };

type Section = { id: string; title: string; blurb: string; blocks: Block[] };

const SECTIONS: Section[] = [
  {
    id: "getting-started",
    title: "Getting started",
    blurb: "Install Verba, grant two permissions, and dictate your first sentence.",
    blocks: [
      { kind: "steps", items: [
        "Download Verba for macOS (Apple Silicon, macOS 14 or later) and drag it to Applications.",
        "Launch it. Verba lives in your menu bar, there is no Dock icon.",
        "Grant Microphone access (to hear you) and Accessibility access (to type into other apps via ⌘V). Both are requested on first run; you can re-grant them in System Settings ▸ Privacy & Security.",
        "Optional: grant Screen Recording only if you want Context mode (Verba reading your screen).",
        "Hold the Fn (globe) key, speak, release, your clean text is pasted where your cursor is.",
      ] },
      { kind: "p", text: "New installs include 33 full-feature dictations to try everything before subscribing. Verba is $9.99/month or $84/year, billed through Stripe." },
    ],
  },
  {
    id: "dictating",
    title: "Dictating",
    blurb: "The recording pill, push-to-talk vs hold-to-talk, pausing and cancelling.",
    blocks: [
      { kind: "ul", items: [
        "Push-to-talk (default): tap Fn to start, tap again to stop and send.",
        "Hold-to-talk: hold Fn while you speak, release to send. Choose your style in Settings ▸ Dictation.",
        "While recording, a small pill shows a live waveform. Press the × (or Esc) to cancel without pasting.",
        "Pause/resume mid-dictation with ⌃ (Control); both shortcuts are rebindable.",
        "Dictations stack: start the next one while the last is still processing, each in-flight job shows as a chip above the pill.",
      ] },
    ],
  },
  {
    id: "modes",
    title: "Modes & styles",
    blurb: "Six built-in modes plus custom AI-built modes, each is a prompt that shapes your speech.",
    blocks: [
      { kind: "ul", items: [
        "Raw, verbatim, no AI rewriting (the default).",
        "Polish, resolves your self-corrections into finished prose.",
        "Intent, you give an instruction and Verba writes to it.",
        "Translate, pick a target language once; speak any language, it writes the target.",
        "Context, screenshots your screen and writes from what it sees (needs Screen Recording + a vision model).",
        "Coding, formats for code and technical writing.",
        "Custom modes, describe what you need and Verba's AI builds a new mode; edit any prompt freely.",
      ] },
      { kind: "p", text: "Switch modes with Fn+1…9 or the menu-bar picker; the choice sticks for every next dictation until you change it. Writing Styles (Fn+] / Fn+[) layer tone/format on top of any mode." },
    ],
  },
  {
    id: "ai-engines",
    title: "AI engines & bring-your-own-AI",
    blurb: "Transcription and AI rewriting both run on engines you choose, local or your own keys.",
    blocks: [
      { kind: "p", text: "Transcription (speech → text):" },
      { kind: "ul", items: [
        "On-device by default: WhisperKit (~99 languages) or NVIDIA Parakeet (25 European languages, faster). Your audio never leaves your Mac.",
        "Optional cloud: OpenAI gpt-4o-transcribe with your own OpenAI key.",
      ] },
      { kind: "p", text: "AI rewriting (cleanup, modes):" },
      { kind: "ul", items: [
        "Your Claude subscription via Claude Code, no API key needed.",
        "Your own Anthropic API key, or an OpenRouter key.",
        "A fully local Ollama model, offline, no key, no markup.",
      ] },
      { kind: "p", text: "Verba is strictly bring-your-own-AI: it never makes a billed API call on your behalf. All keys are stored in the macOS Keychain, never on Verba's servers." },
    ],
  },
  {
    id: "jarvis",
    title: "JARVIS, the voice agent",
    blurb: "Action mode (Fn+X) plans, asks to clarify, and acts on 1,000+ connected apps after you confirm.",
    blocks: [
      { kind: "p", text: "Say a goal however it comes out, \"remind me in 10 to grab the cake\" or \"find me a free hour tomorrow and book it\". JARVIS recovers your intent, resolves times in your timezone, reads context when it needs to, shows exactly what it will do, and only acts on your confirmation." },
      { kind: "ul", items: [
        "Connect apps in Settings ▸ Connected apps: Gmail, Slack, Notion, Google Calendar, Linear, GitHub and 1,000+ more, via Composio.",
        "Most apps connect with an API key; OAuth apps open a browser sign-in.",
        "Connection keys are relayed server-side and never stored on your Mac.",
        "Planning runs on your own AI engine (Claude Code or a local model), your requests never burn a shared cloud key.",
      ] },
    ],
  },
  {
    id: "notes",
    title: "Notes",
    blurb: "Record up to an hour and turn it into a clean, structured document.",
    blocks: [
      { kind: "ul", items: [
        "Pick a format before you start: Clean note, Brain-dump→outline, Summary, Meeting notes, Journal, Email, Code task, To-do list, or Article outline, plus your own custom modes.",
        "Markdown is rendered (headings, bold, checkboxes). Edit the result in place.",
        "File and filter notes with #hashtags, they nest into a Bear-style tag tree in the sidebar.",
        "Lock a note with its own password, locked notes are encrypted on your Mac (AES-GCM, a separate key per note).",
        "Export any note as Markdown (.md) or plain text.",
      ] },
    ],
  },
  {
    id: "tasks",
    title: "Tasks",
    blurb: "A voice task manager: projects → tasks → sub-tasks, built by an AI agent.",
    blocks: [
      { kind: "ul", items: [
        "Describe a list, \"a Cooking project, a Chocolate cake task, and the full shopping list\", and Verba builds the whole hierarchy.",
        "Tags file into the same nested tree as Notes; filter by any tag and everything nested beneath it.",
        "⌥+Fn pops a quick glance of today's tasks; add or check off tasks by voice from there.",
      ] },
    ],
  },
  {
    id: "dictionary-transforms",
    title: "Dictionary & Transforms",
    blurb: "Teach Verba your vocabulary, and run quick text transforms anywhere.",
    blocks: [
      { kind: "ul", items: [
        "Add a word by voice (\"add to dictionary\") or in Settings, great for names and brands. Verba keeps the exact spelling, even through the AI rewrite.",
        "Auto-learn: correct a word in text Verba just wrote and it learns the spelling for next time.",
        "Transforms: select text in any app and say a short shortcut (\"fix grammar\", \"translate to English\"), or right-click ▸ Services ▸ Transform with Verba.",
      ] },
    ],
  },
  {
    id: "privacy",
    title: "History & privacy",
    blurb: "You decide what is stored, for how long, and what syncs.",
    blocks: [
      { kind: "ul", items: [
        "On-device mode keeps your audio on your Mac, it never leaves the device.",
        "Turn history off entirely (nothing written, nothing synced), or auto-delete entries after 7, 30, or 90 days.",
        "Optionally store only the text of each dictation, not the audio, to save disk.",
        "Signed in, your history, notes and stats sync across your Macs; signed out, nothing is uploaded.",
        "Delete all your cloud data with one click in Settings ▸ Privacy.",
      ] },
    ],
  },
  {
    id: "shortcuts",
    title: "Keyboard shortcuts",
    blurb: "Every trigger, and every one is customizable in Settings ▸ Shortcuts.",
    blocks: [
      { kind: "keys", rows: [
        ["Fn (hold or tap)", "Start / stop a dictation"],
        ["Fn + X", "Action mode (JARVIS)"],
        ["Fn + Z", "Record a Note"],
        ["Fn + T", "Capture a to-do by voice"],
        ["⌥ + Fn", "Glance at today's to-dos"],
        ["⌥ + X", "Transform the selected text"],
        ["Fn + 1…9", "Jump to a specific mode"],
        ["Fn + ] / Fn + [", "Next / previous writing style"],
        ["⌃ (Control)", "Pause / resume recording"],
        ["Esc or ×", "Cancel the current dictation"],
      ] },
    ],
  },
  {
    id: "languages-updates",
    title: "Languages & updates",
    blurb: "15 interface languages, and signed automatic updates.",
    blocks: [
      { kind: "ul", items: [
        "The interface is available in 15 languages (Arabic, German, English, Spanish, French, Hindi, Italian, Japanese, Korean, Dutch, Polish, Portuguese, Russian, Turkish, Simplified Chinese).",
        "Verba updates itself in the background via signed, notarized releases (Sparkle). Toggle automatic checks and downloads in Settings ▸ Updates, or read the full history on the Changelog.",
      ] },
    ],
  },
  {
    id: "troubleshooting",
    title: "Troubleshooting",
    blurb: "The few things that trip people up, and how to fix them.",
    blocks: [
      { kind: "ul", items: [
        "Nothing pastes: grant Accessibility in System Settings ▸ Privacy & Security ▸ Accessibility, then relaunch Verba.",
        "Context mode does nothing: it needs Screen Recording permission and a vision-capable model (Anthropic or OpenRouter key).",
        "The macOS emoji popup appears when you press Fn: set the globe/Fn key to \"Do Nothing\" in System Settings ▸ Keyboard.",
        "On AZERTY layouts, Fn+number switches modes; use the menu-bar picker if a layout intercepts the chord.",
        "Still stuck? Email hello@agentik-os.com or join the community on Discord.",
      ] },
    ],
  },
];

// TechArticle + BreadcrumbList so search/AI engines treat /docs as canonical reference content.
const JSONLD = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "TechArticle",
      headline: "Verba Documentation, AI Dictation for Mac",
      description:
        "Technical documentation for Verba: setup, permissions, dictation modes, AI engines, the JARVIS voice agent, Notes, Tasks, shortcuts, privacy and troubleshooting.",
      url: "https://verba.run/docs",
      inLanguage: "en",
      about: { "@type": "SoftwareApplication", name: "Verba", operatingSystem: "macOS 14+" },
      publisher: { "@id": "https://verba.run/#org" },
    },
    {
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Home", item: "https://verba.run/" },
        { "@type": "ListItem", position: 2, name: "Documentation", item: "https://verba.run/docs" },
      ],
    },
  ],
};

function BlockView({ b }: { b: Block }) {
  if (b.kind === "p") return <p className="mt-3 text-sm leading-relaxed muted">{b.text}</p>;
  if (b.kind === "ul")
    return (
      <ul className="mt-3 space-y-2">
        {b.items.map((it) => (
          <li key={it} className="flex gap-3 text-sm leading-relaxed">
            <span className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--fg)] opacity-50" />
            <span className="muted">{it}</span>
          </li>
        ))}
      </ul>
    );
  if (b.kind === "steps")
    return (
      <ol className="mt-3 space-y-2">
        {b.items.map((it, i) => (
          <li key={it} className="flex gap-3 text-sm leading-relaxed">
            <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-[var(--tint)] text-xs font-semibold">{i + 1}</span>
            <span className="muted">{it}</span>
          </li>
        ))}
      </ol>
    );
  // keys
  return (
    <div className="mt-4 overflow-hidden rounded-2xl border border-[var(--border)]">
      <table className="w-full text-sm">
        <tbody>
          {b.rows.map(([k, v], i) => (
            <tr key={k} className={i % 2 ? "bg-[var(--tint)]/40" : ""}>
              <td className="w-2/5 p-3 align-top">
                <kbd className="rounded-md border border-[var(--border)] bg-[var(--tint)] px-2 py-1 font-mono text-xs">{k}</kbd>
              </td>
              <td className="p-3 align-middle muted">{v}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function Docs() {
  return (
    <main className="relative mx-auto max-w-5xl px-6 pb-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(JSONLD) }} />
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
        </div>
      </nav>

      <section className="py-12 text-center">
        <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">Documentation</div>
        <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-5xl">How Verba works</h1>
        <p className="mx-auto mt-5 max-w-2xl text-lg muted text-balance">
          Everything from first launch to power use, setup and permissions, dictation modes, the AI
          engines you control, the JARVIS voice agent, Notes, Tasks, every shortcut, privacy, and the
          fixes for the few things that trip people up.
        </p>
        <div className="mt-7 flex justify-center gap-3">
          <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-6 py-2.5 text-sm font-medium text-[var(--bg)] hover:opacity-90">Download for macOS</a>
          <Link href="/compare" className="rounded-full glass px-6 py-2.5 text-sm font-medium hover:opacity-90">Compare</Link>
        </div>
      </section>

      <div className="grid gap-10 lg:grid-cols-[200px_1fr]">
        {/* Sticky table of contents */}
        <aside className="hidden lg:block">
          <nav className="sticky top-8 space-y-1.5 text-sm">
            <div className="mb-2 text-xs font-semibold uppercase tracking-wide muted">On this page</div>
            {SECTIONS.map((s) => (
              <a key={s.id} href={`#${s.id}`} className="block muted hover:text-[var(--fg)]">{s.title}</a>
            ))}
          </nav>
        </aside>

        <div className="space-y-5">
          {SECTIONS.map((s, i) => (
            <Reveal key={s.id} delay={i * 30}>
              <section id={s.id} className="glass lift scroll-mt-8 rounded-3xl p-6 sm:p-7">
                <h2 className="text-xl font-semibold tracking-tight">{s.title}</h2>
                <p className="mt-1 text-sm muted">{s.blurb}</p>
                {s.blocks.map((b, j) => <BlockView key={j} b={b} />)}
              </section>
            </Reveal>
          ))}
        </div>
      </div>

      <section className="mt-16 text-center">
        <div className="glass-strong rounded-3xl p-10">
          <h2 className="text-2xl font-semibold tracking-tight">Still have a question?</h2>
          <p className="mx-auto mt-3 max-w-md muted text-balance">
            Read the FAQ on the homepage, email <a href="mailto:hello@agentik-os.com" className="underline">hello@agentik-os.com</a>, or join the community on <a href="https://discord.gg/7xfkfQN9AR" target="_blank" rel="noopener" className="underline">Discord</a>.
          </p>
        </div>
      </section>
    <SiteFooter />
    </main>
  );
}
