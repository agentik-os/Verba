import Link from "next/link";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import ThemeToggle from "@/components/ThemeToggle";

import SiteFooter from "@/components/SiteFooter";
export const metadata: Metadata = {
  title: "Documentation, Verba AI Dictation for Mac",
  description:
    "Verba's technical documentation: install & permissions, what Free and Pro each include, dictation modes, AI engines and bring-your-own-AI setup, the JARVIS voice agent, Notes, Tasks, scheduling, connecting apps, shortcuts, privacy and troubleshooting.",
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
  | { kind: "keys"; rows: [string, string][] }
  // Example phrases the user can literally say out loud.
  | { kind: "say"; items: string[] }
  | { kind: "table"; head: [string, string, string]; rows: [string, string, string][] };

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
      { kind: "p", text: "Raw dictation is free forever and unlimited, with no card. Everything else is Pro, see Plans below." },
    ],
  },
  {
    id: "plans",
    title: "Plans, Free and Pro",
    blurb: "What Free gives you, what Pro adds, and what happens when the free AI allowance runs out.",
    blocks: [
      { kind: "table", head: ["", "Free", "Pro"], rows: [
        ["Raw dictation", "Unlimited, forever, no card", "Unlimited"],
        ["AI modes (Polish, Intent, Translate, Context, Prompt, custom)", "33 dictations included, then Pro", "Unlimited"],
        ["Notes, Tasks, JARVIS", "Pro", "Included"],
        ["Dictionary, Transforms, History, 15 languages", "Included", "Included"],
        ["Price", "$0", "$9.99/month, $84/year, or $149 one-time (Founder's Edition)"],
      ] },
      { kind: "p", text: "Raw dictation is never paywalled. When the included AI allowance runs out, Verba does not stop working: it offers to upgrade, and you can keep dictating in Raw forever, on the same Fn key, with no card." },
      { kind: "p", text: "Two different things get called \"the trial\", so here they are apart:" },
      { kind: "ul", items: [
        "The included AI allowance: 33 AI-mode dictations, enforced on your Mac, no card, no clock. It is spent by your dictation count, so raw dictations count toward it even though raw itself is never blocked.",
        "The 7-day Pro trial: card required, starts when you check out, and is run by Stripe. During it you have full Pro.",
      ] },
      { kind: "p", text: "Billing runs on Stripe, which is the single source of truth. Verba asks verba.run for your status; only an explicit \"no subscription\" moves you back to Free. If Verba cannot reach the server, or the server cannot reach Stripe, your current plan is kept as-is, so an outage or a plane ride never revokes Pro." },
      { kind: "p", text: "Restore a subscription: if you subscribed with a different email than the one you signed into the app with, open Settings ▸ Plan ▸ Restore a subscription, type the email you used at checkout, and press Verify. You must be signed in for this to work, it only ever reads your own subscription." },
      { kind: "ul", items: [
        "Signed out: Verba cannot check a subscription at all, so Pro features stay locked and raw dictation keeps working. Sign in from Settings ▸ Account, then press Verify.",
        "\"Please sign in again\": your app session expired. Nothing was cancelled and Pro is not lost, click Sign in again to restore it.",
        "\"Billing unavailable\" or a failed upgrade button: the billing service is not reachable right now. Your existing Pro is unaffected, try the upgrade again later or email hello@agentik-os.com.",
        "Manage, change or cancel a plan: Settings ▸ Plan ▸ Manage subscription, or verba.run/account, both open the Stripe billing portal.",
      ] },
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
        "Raw, verbatim, no AI rewriting (the default). This is the free one, unlimited forever.",
        "Polish, resolves your self-corrections into finished prose.",
        "Intent, you give an instruction and Verba writes to it.",
        "Translate, pick a target language once; speak any language, it writes the target.",
        "Context, screenshots your screen and writes from what it sees (needs Screen Recording + a vision model).",
        "Prompt, turns what you say into an optimized prompt for any AI (ChatGPT, Claude, an image generator, or a coding agent like Cursor / Claude Code).",
        "Custom modes, describe what you need and Verba's AI builds a new mode; edit any prompt freely.",
      ] },
      { kind: "p", text: "Switch modes with Fn+1…9 or the menu-bar picker; the choice sticks for every next dictation until you change it. Writing Styles (Fn+] / Fn+[) layer tone/format on top of any mode." },
      { kind: "p", text: "Every mode except Raw is a Pro feature. On Free you get 33 AI-mode dictations included, then Verba offers to upgrade and keeps dictating in Raw. See Plans above." },
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
        "Fully local, the private default: Verba can auto-install and run a local model on your Mac, offline, with no key and no markup.",
        "Your Claude subscription via Claude Code, no API key needed.",
        "Your own API key (OpenAI, Anthropic, or OpenRouter).",
      ] },
      { kind: "p", text: "Verba is strictly bring-your-own-AI: there is no company-hosted \"included\" AI and it never makes a billed API call on your behalf. All keys are stored in the macOS Keychain, never on Verba's servers." },
    ],
  },
  {
    id: "jarvis",
    title: "JARVIS, the voice agent",
    blurb: "Action mode (Fn+X) plans, asks to clarify, and acts on 1,000+ connected apps after you confirm.",
    blocks: [
      { kind: "p", text: "Press Fn+X, say a goal however it comes out. JARVIS recovers your intent, resolves times in your timezone, reads context when it needs to, shows exactly what it will do, and only then acts. Pro feature." },
      { kind: "say", items: [
        "Remind me in 10 minutes to grab the cake.",
        "Find a free hour tomorrow afternoon and book a call with Marie about the onboarding rewrite.",
        "Send Marie a Slack message saying the onboarding review moved to Thursday.",
        "What did Marie email me about the invoice?",
      ] },
      { kind: "p", text: "Confirmation behavior, the rule is simple: anything that WRITES is confirmed, anything that only READS is not. A write action (sending, booking, creating, editing, deleting) always stops on a confirmation card showing the exact action, the app it targets and every field it will use, and nothing happens until you accept. You can edit the fields on that card first, or dismiss it and nothing is sent. Read-only lookups (checking your calendar, searching an inbox) run straight away, since they change nothing." },
      { kind: "ul", items: [
        "Multi-step goals are planned as a sequence and confirmed before they run.",
        "When something is ambiguous or missing, JARVIS asks a short question or shows editable fields instead of guessing.",
        "After a successful action it can propose a follow-up (\"Invite people to the event?\"), which is itself confirmed before it runs.",
      ] },
    ],
  },
  {
    id: "scheduling",
    title: "Scheduling meetings",
    blurb: "Book a meeting by voice, review the exact event, then confirm it.",
    blocks: [
      { kind: "p", text: "Scheduling is JARVIS (Fn+X) with a calendar. It works against your Mac's own Calendar, and against Google Calendar or Outlook once you connect them. Pro feature." },
      { kind: "steps", items: [
        "Connect a calendar in Settings ▸ Connected apps if you want more than the local Calendar app, then press Fn+X.",
        "Say the meeting in plain words. Relative times (\"tomorrow afternoon\", \"in 20 minutes\", \"next Tuesday\") resolve in your own timezone.",
        "JARVIS reads your calendar to find the slot, then shows a confirmation card with the title, date, time, duration and invitees.",
        "Change anything you want on the card, then confirm. The event is created only at that point. Dismiss it and nothing is booked.",
      ] },
      { kind: "say", items: [
        "Book a 30 minute call with Marie tomorrow at 2pm about the onboarding rewrite.",
        "Find a free hour this week for a design review and invite the team.",
        "Move my 3pm to Thursday morning and let the attendees know.",
      ] },
    ],
  },
  {
    id: "connected-apps",
    title: "Connecting apps",
    blurb: "Give JARVIS Gmail, Slack, Notion, Calendar, Linear, GitHub and 1,000+ more.",
    blocks: [
      { kind: "steps", items: [
        "Open Settings ▸ Connected apps. Search the catalog by name, or filter by category.",
        "Tap Connect. OAuth apps (Gmail, Slack, Notion, Google Calendar…) open a secure browser sign-in; the many API-key apps open a small in-app form asking for exactly the keys they need, and nothing more.",
        "Tap any connected app to see every action it exposes, each with example phrases you can say to JARVIS.",
        "Say what you want with Fn+X. JARVIS picks the right app and action, and confirms before any write.",
      ] },
      { kind: "say", items: [
        "Send Marie a Slack message saying the onboarding review moved to Thursday.",
        "Create a Linear issue for the paywall copy fix and put it in the current cycle.",
        "Draft a reply to the last email from accounting and leave it in my drafts.",
      ] },
      { kind: "ul", items: [
        "Connection keys are relayed server-side and are never stored on your Mac.",
        "Disconnect any app at any time from the same screen, which revokes Verba's access to it.",
        "Planning runs on your own AI engine (a local model, your Claude subscription, or your own key), so your requests never burn a shared cloud key.",
        "Connected apps and JARVIS are Pro features. Raw dictation keeps working on Free without any of this.",
      ] },
    ],
  },
  {
    id: "notes",
    title: "Notes",
    blurb: "Record up to an hour and turn it into a clean, structured document.",
    blocks: [
      { kind: "p", text: "Press Fn+Z, pick a format, talk, then tap to stop. Verba transcribes the whole recording and rewrites it into the format you chose. Pro feature." },
      { kind: "say", items: [
        "Kickoff with the design team. We agreed to ship the onboarding rewrite first, Marie owns the copy, and we review Thursday. Tag it hashtag product.",
        "Brain dump on pricing: I think we are too cheap for teams, but the single-seat price is right, and the annual discount is doing the work.",
      ] },
      { kind: "p", text: "Nothing is sent anywhere and nothing is confirmed: a note is written to your own library, where you can edit it in place, rename it, or delete it." },
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
      { kind: "p", text: "Press Fn+T and describe what you need in one breath. Verba builds the whole project, task and sub-task hierarchy for you, no forms. Pro feature." },
      { kind: "say", items: [
        "Make a Cooking project with a Chocolate cake task and the full shopping list as sub-tasks.",
        "Add a task to send the investor update, due Friday, under the Fundraising project.",
        "Mark the onboarding copy task as done and add a sub-task to review it with Marie.",
      ] },
      { kind: "p", text: "Tasks are created straight in your own list, so there is no confirmation step. Everything stays editable: rename, re-parent, check off or delete any item afterwards. Asking JARVIS (Fn+X) to act on a task in another app, for example creating the matching Linear issue, is a write action and is confirmed on a card first." },
      { kind: "ul", items: [
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
        ["⌃ + ⌥ + X", "Toggle the Actions widget"],
        ["⌃ + ⌥ + Z", "Toggle the To-dos widget"],
        ["⌃ + ⌥ + C", "Toggle the Notes widget"],
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
        "Still stuck? Email hello@agentik-os.com or join the community on Telegram.",
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
  if (b.kind === "say")
    return (
      <div className="mt-3 space-y-2">
        {b.items.map((it) => (
          <p key={it} className="rounded-2xl border border-[var(--border)] bg-[var(--tint)]/40 px-4 py-3 text-sm italic leading-relaxed">
            <span className="mr-1.5 not-italic opacity-50">Say</span>
            &ldquo;{it}&rdquo;
          </p>
        ))}
      </div>
    );
  if (b.kind === "table")
    return (
      <div className="mt-4 overflow-x-auto rounded-2xl border border-[var(--border)]">
        <table className="w-full min-w-[34rem] text-sm">
          <thead>
            <tr className="bg-[var(--tint)]/60">
              {b.head.map((h) => (
                <th key={h} className="p-3 text-left font-semibold">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {b.rows.map((r, i) => (
              <tr key={r[0]} className={i % 2 ? "bg-[var(--tint)]/40" : ""}>
                <td className="p-3 align-top font-medium">{r[0]}</td>
                <td className="p-3 align-top muted">{r[1]}</td>
                <td className="p-3 align-top muted">{r[2]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
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
            Read the FAQ on the homepage, email <a href="mailto:hello@agentik-os.com" className="underline">hello@agentik-os.com</a>, or join the community on <a href="https://t.me/verbarun" target="_blank" rel="noopener" className="underline">Telegram</a>.
          </p>
        </div>
      </section>
    <SiteFooter />
    </main>
  );
}
