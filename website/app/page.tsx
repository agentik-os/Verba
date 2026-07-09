"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";
import LiveDemo from "@/components/LiveDemo";
import WaveLine from "@/components/WaveLine";
import SpeedRace from "@/components/SpeedRace";
import Reveal from "@/components/Reveal";
import TryIt from "@/components/TryIt";
import JokeBubbles from "@/components/JokeBubbles";
import Icon from "@/components/Icon";
import { getRef } from "@/components/RefCapture";
import { Logo, MicMark, MicGlyph, HeadLeft, HeadCenter, PanelCaption, CrossRule } from "@/components/Brand";
import ThemeToggle from "@/components/ThemeToggle";
import SiteNav from "@/components/SiteNav";
import SiteFooter from "@/components/SiteFooter";
import { FEATURES } from "@/lib/features";

const PRICE = {
  monthly: { amount: "$9.99", sub: "/month", note: "billed monthly · cancel anytime" },
  annual: { amount: "$84", sub: "/year", note: "≈ $7/mo · save 30%" },
};
const DOWNLOAD_URL = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export default function Home() {
  return (
    <main className="relative mx-auto max-w-6xl px-6">
      <SiteNav />
      <Hero />
      <Moat />
      <JarvisAction />
      <SpeedProof />
      <LogosStrip />
      <Personas />
      <Testimonials />
      <TryNow />
      <FeatureGrid />
      <GrowsWithYou />
      <WhyBest />
      <Jokes />
      <Features />
      <Personalize />
      <Shortcuts />
      <How />
      <CompareTeaser />
      <Pricing />
      <FAQ />
      <SiteFooter />
    </main>
  );
}

/* THE MOAT — Private · Acts · Confirms, the one combination no rival holds together.
   Cloud writers only write text and upload your voice; the closest agentic rival acts
   but is cloud with no confirm gate. This 3-pillar block states the through-line plainly,
   high on the page. The confirm proof itself lives in the JARVIS section right below. */
function Moat() {
  const pillars = [
    { tag: "Private", title: "It runs on your Mac", body: "Your speech is transcribed on-device, so your audio never leaves your Mac. Nothing is uploaded, and nobody resells your words." },
    { tag: "Acts", title: "It does the thing, in 1,000+ apps", body: "Not just clean text. Send the email, create the event, post to Slack or Notion. Real actions across the apps you already use." },
    { tag: "Confirms", title: "Only when you say so", body: "It shows you exactly what it will do, then waits. Nothing happens until you confirm. You are always the one who presses go." },
  ];
  return (
    <section id="moat" className="py-16">
      <Reveal>
        <HeadCenter
          eyebrow="Private · Acts · Confirms"
          title="The only voice agent that does all three"
          lead="Most voice tools make you pick two. Private, but it only writes text. Or it acts, but your voice goes to the cloud with no way to say no. Verba is on-device, acts across your apps, and always asks before it acts."
        />
      </Reveal>
      <div className="mx-auto mt-12 grid max-w-5xl gap-3 sm:grid-cols-3">
        {pillars.map((p, i) => (
          <Reveal key={p.tag} delay={i * 60}>
            <div className="card lift r-card flex h-full flex-col p-6">
              <div className="flex items-center gap-2.5">
                <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[var(--fg)] text-[var(--bg)]">
                  <MicGlyph size={10} />
                </span>
                <p className="mono-meta">{p.tag}</p>
              </div>
              <h3 className="mt-3 font-medium">{p.title}</h3>
              <p className="mt-1.5 text-sm muted">{p.body}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* SOCIAL PROOF — testimonials. The scaffold is wired and styled; QUOTES is intentionally
   empty until we have REAL, attributed user quotes. Add entries to QUOTES to switch the
   grid on. NEVER ship invented names or made-up quotes here — the empty state is an honest
   invite, not fake praise. */
function Testimonials() {
  const QUOTES: { quote: string; name: string; role: string }[] = [
    // Real quotes go here, e.g.:
    // { quote: "I stopped typing emails. I just talk and confirm.", name: "Full Name", role: "Role, Company" },
  ];
  return (
    <section id="testimonials" className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Social proof"
          title="What people say"
          lead="Real, attributed quotes from people who use Verba every day land here."
        />
      </Reveal>
      {QUOTES.length > 0 ? (
        <div className="mx-auto mt-12 grid max-w-5xl gap-3 sm:grid-cols-3">
          {QUOTES.map((q, i) => (
            <Reveal key={i} delay={i * 60}>
              <figure className="card r-card flex h-full flex-col p-6">
                <blockquote className="text-sm leading-relaxed pf-90">&ldquo;{q.quote}&rdquo;</blockquote>
                <figcaption className="mt-4 flex items-center gap-2.5">
                  <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[var(--fg)] text-[var(--bg)]"><MicGlyph size={10} /></span>
                  <span className="text-sm"><span className="font-medium">{q.name}</span> <span className="muted">· {q.role}</span></span>
                </figcaption>
              </figure>
            </Reveal>
          ))}
        </div>
      ) : (
        /* Honest empty state until real quotes exist — an invite, not invented praise. */
        <Reveal delay={60}>
          <div className="mx-auto mt-10 max-w-2xl">
            <div className="card r-card flex flex-col items-center gap-4 p-8 text-center sm:flex-row sm:justify-between sm:text-left">
              <div>
                <p className="font-medium">Using Verba? We&apos;d love your story.</p>
                <p className="mt-1 text-sm muted">Tell us what changed when you started talking instead of typing. Real quotes, with your name, go right here.</p>
              </div>
              <a href="https://t.me/verbarun" target="_blank" rel="noopener" className="btn-ghost shrink-0 px-6 py-3">Share your story</a>
            </div>
          </div>
        </Reveal>
      )}
    </section>
  );
}

// Compact capabilities grid, replaces the long inline feature sections; each card deep-links to a
// dedicated, SEO-targeted feature page (shorter landing + more indexable pages).
function FeatureGrid() {
  return (
    <section id="features-overview" className="py-28">
      <Reveal>
        <HeadCenter eyebrow="Features" index="06" title="Everything Verba does" lead="Speak, and Verba turns it into clean text, a note, a translation, an organized task list, or a real action across your apps. Go deep on any of them." />
      </Reveal>
      <div className="mx-auto mt-12 grid max-w-5xl gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f, i) => (
          <Reveal key={f.slug} delay={i * 40}>
            <Link href={`/features/${f.slug}`} className="card r-card lift block h-full px-6 py-6 transition hover:opacity-95">
              <p className="mono-meta">{f.eyebrow}</p>
              <h3 className="mt-2 text-base font-semibold tracking-tight">{f.navLabel}</h3>
              <p className="mt-2 text-sm leading-relaxed muted line-clamp-3">{f.metaDescription}</p>
              <span className="mt-4 inline-block text-sm font-medium">Learn more →</span>
            </Link>
          </Reveal>
        ))}
      </div>
      <div className="mt-8 text-center">
        <Link href="/features" className="inline-flex items-center gap-2 rounded-full glass px-6 py-2.5 text-sm font-medium hover:opacity-90">See all features →</Link>
      </div>
    </section>
  );
}

// "Verba grows with you" — the 3-level story that mirrors the in-app Features page (roadmap §10).
function GrowsWithYou() {
  const levels = [
    { tag: "Essentials", tagline: "On from day one. Press Fn and talk.", items: ["Raw dictation", "Polish", "Translate", "Prompt"] },
    { tag: "Advanced", tagline: "Turn on when you need them.", items: ["Notes", "Tasks", "Advanced modes", "Transcribe files"] },
    { tag: "Power", tagline: "The deep end. Your voice, everywhere.", items: ["JARVIS", "Snippets", "Transforms"] },
  ];
  return (
    <section id="grows-with-you" className="py-28">
      <Reveal>
        <HeadCenter eyebrow="Grows with you" index="07" title="Start simple. Add power when you want it." lead="New Macs begin with the four essentials, press Fn and talk. Everything else is one click away in the Features page, whenever you're ready. Nothing to wade through on day one." />
      </Reveal>
      <div className="mx-auto mt-12 grid max-w-5xl gap-4 sm:grid-cols-3">
        {levels.map((lv, i) => (
          <Reveal key={lv.tag} delay={i * 60}>
            <div className="card r-card h-full px-6 py-6">
              <p className="mono-meta">{lv.tag}</p>
              <p className="mt-1 text-sm muted">{lv.tagline}</p>
              <ul className="mt-4 space-y-2">
                {lv.items.map((it) => (
                  <li key={it} className="flex items-center gap-2 text-sm">
                    <span aria-hidden className="opacity-60">→</span>
                    {it}
                  </li>
                ))}
              </ul>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

const JARVIS_APPS = [
  "gmail", "slack", "notion", "googlecalendar", "github", "googlesheets", "googledocs",
  "googledrive", "outlook", "linear", "jira", "asana", "trello", "hubspot", "salesforce",
  "stripe", "shopify", "figma", "discord", "zoom", "dropbox", "airtable", "todoist",
  "calendly", "intercom", "zendesk", "mailchimp", "twitter", "linkedin", "reddit",
  "youtube", "spotify", "telegram", "clickup", "gitlab", "sentry", "supabase", "posthog",
  "docusign", "webflow", "canva", "hubspot",
];

function JarvisAction() {
  return (
    <section id="jarvis" className="py-28">
      <Reveal>
        <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] lg:items-center">
          <HeadLeft
            eyebrow="New · JARVIS"
            index="00"
            anchor
            title={<>Speak it.<br />JARVIS does it.</>}
            lead="Action mode is now JARVIS, a voice agent that understands what you mean, however you phrase it. It plans the steps, asks a quick question when something is ambiguous or missing, shows you exactly what it will do, and only acts once you confirm, on your Mac and across 1,000+ connected apps."
          />
          <div>
            <PanelCaption>00 · JARVIS, Action feed</PanelCaption>
            <div className="panel r-panel p-6">
              <div className="flex items-center gap-2 pf-55">
                <span aria-hidden>✦</span>
                <span className="mono-meta">JARVIS</span>
              </div>
              <div className="ptint mt-4 rounded-xl border pborder p-4">
                <div className="text-[13px] font-medium pf-90">Email the team I&apos;m running late</div>
                <div className="mt-1 text-[12px] pf-55">&ldquo;send an email to the team that I&apos;m running 10 minutes late&rdquo;</div>
                <div className="mt-3 flex gap-2">
                  <span className="rounded-full border pborder px-3 py-1 text-[11px] pf-55">Cancel</span>
                  <span className="rounded-full bg-[var(--fg)] px-3 py-1 text-[11px] font-semibold text-[var(--bg)]">✓ Confirm · Gmail</span>
                </div>
              </div>
              <ul className="mt-5 space-y-2 text-[13px] pf-70">
                <li>Understands what you mean, however you phrase it.</li>
                <li>Asks when it&apos;s unsure: a Google Meet, or just a calendar block?</li>
                <li>Missing a detail? It shows editable fields to fill in.</li>
                <li>It never writes anything until you confirm.</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mt-14">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">Connect 1,000+ apps</h3>
            <span className="muted text-sm">one secure tap to connect</span>
          </div>
          <div className="mt-5 grid grid-cols-6 gap-3 sm:grid-cols-9 lg:grid-cols-11">
            {JARVIS_APPS.map((s, i) => (
              <div
                key={`${s}-${i}`}
                className="flex aspect-square items-center justify-center rounded-xl glass p-2 transition-transform duration-150 hover:scale-110"
                title={s}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={`https://logos.composio.dev/api/${s}`} alt={s} className="h-7 w-7 object-contain" loading="lazy" />
              </div>
            ))}
            <div className="flex aspect-square items-center justify-center rounded-xl glass p-2 text-center text-[12px] font-semibold muted">
              +1000
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

function Nav() {
  return (
    <nav className="anim-nav sticky top-3 z-50 mt-3 flex items-center justify-between rounded-full glass px-5 py-2.5">
      <Logo />
      <div className="hidden items-center gap-7 text-sm muted sm:flex">
        <a href="#jarvis" className="transition-colors duration-150 hover:text-[var(--fg)]">JARVIS</a>
        <a href="#why" className="transition-colors duration-150 hover:text-[var(--fg)]">Why Verba</a>
        <a href="#notes" className="transition-colors duration-150 hover:text-[var(--fg)]">Notes</a>
        <a href="#translate" className="transition-colors duration-150 hover:text-[var(--fg)]">Translate</a>
        <a href="#features" className="transition-colors duration-150 hover:text-[var(--fg)]">Features</a>
        <a href="#shortcuts" className="transition-colors duration-150 hover:text-[var(--fg)]">Shortcuts</a>
        <Link href="/compare" className="transition-colors duration-150 hover:text-[var(--fg)]">Compare</Link>
        <Link href="/docs" className="transition-colors duration-150 hover:text-[var(--fg)]">Docs</Link>
        <Link href="/changelog" className="transition-colors duration-150 hover:text-[var(--fg)]">Changelog</Link>
        <a href="#pricing" className="transition-colors duration-150 hover:text-[var(--fg)]">Pricing</a>
      </div>
      <div className="flex items-center gap-3">
        <span aria-hidden className="hidden h-4 w-px bg-[var(--border)] sm:block" />
        <SignedOut>
          <SignInButton mode="modal">
            <button className="text-sm muted hover:text-[var(--fg)]">Sign in</button>
          </SignInButton>
        </SignedOut>
        <SignedIn>
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
        <ThemeToggle />
        <a href={DOWNLOAD_URL} className="btn-primary px-4 py-2 text-sm">
          Download
        </a>
      </div>
    </nav>
  );
}

function Hero() {
  return (
    <section className="relative grid gap-12 pb-16 pt-20 sm:pt-32 lg:grid-cols-[minmax(0,1.25fr)_minmax(0,0.82fr)] lg:items-center lg:gap-16">
      {/* Discreet full-bleed sound wave: light, simple, spans the WHOLE viewport width
          (left-1/2 + w-screen breaks out of the max-w container), edge-faded so it never
          fights the copy. No particles, no dots. Sits below everything. */}
      <div
        aria-hidden
        className="pointer-events-none absolute -z-10 left-1/2 top-1/2 hidden h-[26rem] w-screen -translate-x-1/2 -translate-y-1/2 sm:block"
        style={{
          maskImage: "linear-gradient(to right, transparent, #000 16%, #000 84%, transparent)",
          WebkitMaskImage: "linear-gradient(to right, transparent, #000 16%, #000 84%, transparent)",
        }}
      >
        <WaveLine className="h-full w-full" />
      </div>

      {/* Left: opinionated, tight copy column */}
      <div className="relative">
        <div className="anim-h1 mb-6 inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--tint)] px-3 py-1.5 font-mono text-[11px] uppercase tracking-wide muted">
          <MicGlyph size={12} />
          Private · Acts · Confirms
        </div>
        <h1 className="anim-h1 t-display text-balance">
          Speak it. It acts.<br />
          <span className="text-[var(--fg-dim)]">Only when you say so.</span>
        </h1>
        <p className="anim-sub t-lead mt-7 max-w-xl">
          The private voice agent for your Mac. Talk, and it acts across 1,000+ apps: send the email,
          create the event, post to Slack. Your audio never leaves your Mac, and it always shows you
          the action and waits for you to confirm before anything happens.
        </p>
        {/* Privacy + control claims, first-class near the hero. These are the two things
            cloud voice tools cannot honestly say (audio stays local; you approve first). */}
        <div className="anim-sub mt-6 flex flex-wrap gap-2 text-[12px]">
          <span className="inline-flex items-center gap-1.5 rounded-full border border-[var(--border)] bg-[var(--tint)] px-3 py-1.5 muted">
            <span className="rec-dot" /> On-device, nothing uploaded
          </span>
          <span className="inline-flex items-center gap-1.5 rounded-full border border-[var(--border)] bg-[var(--tint)] px-3 py-1.5 muted">
            <span aria-hidden>✓</span> It asks before it acts
          </span>
        </div>
        <div className="anim-cta mt-9 flex flex-wrap items-center gap-3">
          <a href={DOWNLOAD_URL} className="btn-primary px-7 py-3">
            Download for free
          </a>
          <a href="#how" className="btn-ghost px-7 py-3">See how it works</a>
        </div>
        <p className="anim-cta mt-4 font-mono text-[11px] tracking-wide muted tnum">Download free · Unlimited raw dictation, free forever, no card · Pro unlocks every AI mode</p>
        <p className="anim-cta mt-2 font-mono text-[11px] tracking-wide muted tnum">Already have an AI plan? Zero setup, no markup <span className="faint">· Apple Silicon · macOS 14+</span></p>
        <div className="anim-cta mt-8 flex flex-wrap gap-x-6 gap-y-2 text-[13px] muted">
          {["Acts across 1,000+ apps", "Reads your screen", "Hour-long notes", "Translate live", "Runs offline", "Learns your voice"].map((p) => (
            <span key={p} className="flex items-center gap-2">
              <span className="h-1 w-1 rounded-full bg-[var(--accent-line)]" />{p}
            </span>
          ))}
        </div>
      </div>

      {/* Right: THE focal artifact, the live talk → clean text demonstration,
          layered above the flux backdrop. */}
      <div className="anim-demo relative z-10 lg:pl-2">
        <div className="glow-rec" />
        <LiveDemo />
      </div>
    </section>
  );
}

/* SPEED-PROOF, your mouth is faster than your hands. The SpeedRace canvas makes
   the 150 vs 40 wpm gap visceral, sitting inside product chrome near the top. */
function SpeedProof() {
  return (
    <section className="pb-8 pt-6 sm:pt-10">
      <Reveal>
        <div className="grid gap-8 lg:grid-cols-[minmax(0,0.95fr)_minmax(0,1.05fr)] lg:items-center lg:gap-12">
          <div>
            <p className="eyebrow">The case for talking</p>
            <h2 className="t-section mt-3 text-balance">Your mouth is faster than your hands. Use it.</h2>
            <p className="mt-4 text-[15px] leading-relaxed muted max-w-md">
              You think out loud all day. Verba just writes it down, cleaned up and ready to
              send, while you keep moving. Speaking is roughly 3x faster than typing.
            </p>
            <div className="mt-6 flex items-center gap-8">
              <div>
                <div className="text-3xl font-semibold tracking-tight tnum">150<span className="ml-1 text-base font-normal muted">wpm</span></div>
                <p className="mt-0.5 text-xs muted">Speaking</p>
              </div>
              <div className="h-10 w-px bg-[var(--border)]" />
              <div>
                <div className="text-3xl font-semibold tracking-tight tnum faint">40<span className="ml-1 text-base font-normal faint">wpm</span></div>
                <p className="mt-0.5 text-xs faint">Typing</p>
              </div>
            </div>
          </div>
          <div className="panel r-panel p-7">
            <p className="mono-meta">Voice vs typing · live</p>
            <SpeedRace className="mt-4 h-40 w-full" wordsPerMinVoice={150} wordsPerMinType={40} />
          </div>
        </div>
      </Reveal>
    </section>
  );
}

/* PERSONAS, who it's for, in one line each. Benefit-led, talk once and move on. */
function Personas() {
  const personas: { name: string; line: string }[] = [
    { name: "Engineers", line: "Dictate a rambling thought into a clean prompt in Cursor or your coding tool. Say \"create the issue, email the team\", confirm, done." },
    { name: "Founders", line: "Clear the inbox, the doc, and the standup notes between meetings. Talk once, send clean, move on." },
    { name: "Writers", line: "Capture the draft at the speed you think it. An hour of voice becomes a structured document you can actually edit." },
    { name: "Support and ops", line: "Answer every ticket in your own tone, per app. Verba matches how you write in Slack, Mail, and Notion." },
    { name: "Multilingual teams", line: "Think in your language, write in theirs. Speak French, send English. Every time, no prefix, no second tab." },
    { name: "Busy everyone", line: "Reply to the email on your screen, build a to-do list by voice, set a reminder, run your Mac. All from one key." },
  ];
  return (
    <section className="py-16">
      <Reveal>
        <HeadCenter
          eyebrow="Who it's for"
          title="One key, for the way you actually work"
          lead="Built first for developers who live in the terminal, Verba is the complete voice OS for anyone who thinks faster than they type. It doesn't just transcribe: it reads your screen, files your tasks, translates as you speak, and acts on what it hears."
        />
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {personas.map(({ name, line }, i) => (
          <Reveal key={name} delay={(i % 3) * 60}>
            <div className="card lift r-card flex h-full flex-col p-6">
              <div className="flex items-center gap-2.5">
                <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[var(--fg)] text-[var(--bg)]">
                  <MicGlyph size={10} />
                </span>
                <h3 className="font-medium">{name}</h3>
              </div>
              <p className="mt-3 text-sm muted">{line}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function LogosStrip() {
  const apps = ["Slack", "Mail", "Notes", "VS Code", "Messages", "Notion", "Safari", "Terminal", "Cursor", "Linear", "Figma", "Obsidian"];
  return (
    <>
    <CrossRule />
    <section className="overflow-hidden py-8">
      <p className="mono-meta text-center">Works in the apps you already use</p>
      <div className="relative mt-5 [mask-image:linear-gradient(90deg,transparent,#000_12%,#000_88%,transparent)]">
        <div className="marquee gap-x-10 font-mono text-[11px] uppercase tracking-[0.18em] muted">
          {[...apps, ...apps].map((a, i) => (
            <span key={i} className="whitespace-nowrap">{a}</span>
          ))}
        </div>
      </div>
    </section>
    <CrossRule />
    </>
  );
}

function TryNow() {
  return (
    <section id="try" className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Live, in your browser"
          title="Try it right now"
          lead="No download, no sign-up. Record a rambling message and watch it come back clean. This is the same pipeline the app ships with."
        />
      </Reveal>
      <div className="mt-12"><TryIt /></div>
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
    <section className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="While Verba works"
          index="09"
          title="Loading screens that make you smile"
          lead="While Verba rewrites your words, it shows you a one-liner. 17 humor themes, an Off switch, and never the same joke twice in a day."
        />
      </Reveal>

      <div className="panel r-panel relative mt-10 overflow-hidden">
        <JokeBubbles />
      </div>

      <div className="mt-8 flex flex-wrap justify-center gap-2">
        {themes.map((t) => (
          <span key={t} className="card lift r-card px-4 py-1.5 text-sm muted">{t}</span>
        ))}
      </div>
    </section>
  );
}

function Bento() {
  return (
    <section className="py-28">
      <Reveal>
        <HeadLeft
          eyebrow="Private by design"
          index="06"
          anchor
          title="Your voice stays yours"
          lead="Verba runs private speech models right on your Mac. Your audio is never uploaded, and nobody resells your words. Here is what that gets you."
        />
      </Reveal>

      <div className="mt-12 grid auto-rows-[150px] grid-cols-2 gap-3 lg:grid-cols-4">
        {/* hero bento tile, solid product chrome, carries the headline number */}
        <Reveal className="col-span-2 row-span-2">
          <div className="panel r-panel flex h-full flex-col justify-between p-7">
            <span className="rec-dot" />
            <div>
              <div className="t-anchor tnum">0&nbsp;bytes</div>
              <p className="mt-3 font-medium">of audio leave your Mac</p>
              <p className="mt-1.5 max-w-sm text-sm pf-55">On-device mode transcribes locally, so your audio never leaves the Mac. Transcripts go to your local history, which you can switch off or auto-delete. Other dictation tools send your audio to their servers; Verba doesn't have to.</p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={60}><BentoStat big="99+" label="languages, on-device" sub="Runs worldwide" /></Reveal>
        <Reveal delay={120}><BentoStat big="$9.99" label="a month, all in" sub="plus the AI you already use" /></Reveal>
        <Reveal delay={180}><BentoStat big="Free" label="raw dictation, unlimited forever" sub="no card, ever" /></Reveal>
        <Reveal delay={240}><BentoStat big="100%" label="works offline" sub="no internet required" /></Reveal>

        <Reveal delay={120} className="col-span-2">
          <div className="card lift r-card flex h-full items-center gap-4 p-7">
            <Icon name="key" className="h-7 w-7 shrink-0 text-[var(--fg-dim)]" />
            <div>
              <p className="font-medium">Connect the AI account you already use</p>
              <p className="mt-1 text-sm muted">Private AI on your Mac, or connect an AI account you already pay for, or run a fully local model. You never pay a vendor markup.</p>
            </div>
          </div>
        </Reveal>
        <Reveal delay={180} className="col-span-2">
          <div className="card lift r-card flex h-full items-center gap-4 p-7">
            <Icon name="bolt" className="h-7 w-7 shrink-0 text-[var(--fg-dim)]" />
            <div>
              <p className="font-medium">Modes, the right model each time</p>
              <p className="mt-1 text-sm muted">Raw (verbatim), Polish (hears what you meant), Intent, Translate, Context (vision), and Prompt (turn what you say into an optimized AI prompt). Lighter AI for everyday modes, more capable AI for prompts. Edit any prompt, or describe a need and let AI build you a custom mode.</p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

function BentoStat({ big, label, sub }: { big: string; label: string; sub: string }) {
  return (
    <div className="card lift r-card flex h-full flex-col justify-center p-6">
      <div className="text-3xl font-semibold tracking-tight tnum">{big}</div>
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
  const [hero, ...rest] = examples;
  return (
    <section id="context-mode" className="py-28">
      <Reveal>
        <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] lg:items-center">
          <HeadLeft
            eyebrow="New · Context mode"
            index="01"
            anchor
            title={<>Your voice meets<br />your screen</>}
            lead="Press your shortcut, glance at the screen, and talk. Verba captures what you are looking at and writes from it. Reply to the email in front of you, summarize a document, comment on a photo, without touching the clipboard."
          />
          {/* weighted hero tile, the focal example, in product chrome */}
          <div>
          <PanelCaption>01 · Context mode</PanelCaption>
          <div className="panel r-panel p-7">
            <div className="flex items-center gap-3 pf-55">
              <Icon name={hero.icon} className="h-5 w-5" />
              <span className="mono-meta">{hero.label}</span>
            </div>
            <p className="mt-5 text-lg leading-relaxed pf-90">"{hero.prompt}"</p>
            <div className="mt-6 flex items-center gap-2 text-[12px] pf-40">
              <span className="rec-dot" /> Reads your screen, then writes the reply in place.
            </div>
          </div>
          </div>
        </div>
      </Reveal>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {rest.map(({ icon, label, prompt }, i) => (
          <Reveal key={label} delay={i * 50}>
            <div className="card lift r-card flex h-full flex-col gap-2.5 p-5">
              <Icon name={icon} className="h-5 w-5 text-[var(--fg-dim)]" />
              <p className="font-medium">{label}</p>
              <p className="text-sm muted italic">"{prompt}"</p>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={100}>
        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <div className="card r-card p-7">
            <p className="eyebrow">How it works</p>
            <p className="mt-3 text-sm muted leading-relaxed">
              Context mode takes a screenshot the moment you stop talking, analyzes it with a vision-capable model,
              and combines what it sees with what you said. The result is grounded in your actual screen content,
              not a generic template.
            </p>
          </div>
          <div className="card r-card p-7">
            <p className="eyebrow">Requirements</p>
            <ul className="mt-3 space-y-1.5 text-sm muted">
              <li className="flex gap-2"><span className="text-[var(--accent-line)]">·</span>macOS Screen Recording permission</li>
              <li className="flex gap-2"><span className="text-[var(--accent-line)]">·</span>A connected AI account that supports vision</li>
            </ul>
          </div>
        </div>
      </Reveal>

      <Reveal delay={120}>
        <div className="card r-card mt-4 p-7">
          <div className="flex items-start gap-4">
            <div className="mt-0.5 shrink-0 rounded-md border border-[var(--border-strong)] bg-[var(--tint)] px-2.5 py-1 text-xs font-medium">Labs</div>
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
    <>
    <CrossRule />
    <section id="notes" className="bg-[var(--bg-2)] py-28">
      <Reveal>
        <HeadLeft
          eyebrow="Flagship feature"
          index="02"
          anchor
          title={<>Talk for an hour,<br />get a clean document</>}
          lead="Open the Notes tab, pick a format, and talk. An hour of speech becomes a structured document you can read, edit and copy. File it with #hashtags that fold into a Bear-style nested tag tree in the sidebar, with counts. It syncs across your Macs."
        />
      </Reveal>

      <Reveal delay={60}>
        <div className="mt-12">
        <PanelCaption>02 · One hour of voice, one document</PanelCaption>
        <div className="panel r-panel overflow-hidden">
          <div className="grid sm:grid-cols-2">
            <div className="p-8 sm:border-r sm:pborder">
              <p className="mono-meta">Example</p>
              <p className="mt-3 text-[17px] font-medium leading-snug pf-90">
                "So the standup ran long today, we decided to push the API milestone to next Friday,
                the auth bug is now Alex's, and I need to follow up with design about the onboarding
                flow by Thursday..."
              </p>
              <p className="mt-3 flex items-center gap-2 text-sm pf-45"><span className="rec-dot" /> 40 seconds of voice · Meeting notes format</p>
            </div>
            <div className="p-8">
              <p className="mono-meta">Verba produces</p>
              <div className="mt-3 rounded-lg border pborder pbg p-4 font-mono text-sm leading-relaxed">
                <p className="font-semibold pf-90">## Standup notes</p>
                <p className="mt-1 pf-55">**API milestone** pushed to next Friday</p>
                <p className="pf-55">**Auth bug** assigned to Alex</p>
                <p className="pf-55">**Action:** follow up with design on onboarding flow by Thursday</p>
              </div>
              <p className="mt-3 text-xs pf-40">Rendered markdown · editable · copyable · filed in a Bear-style tag tree · synced.</p>
            </div>
          </div>
        </div>
        </div>
      </Reveal>

      <div className="mt-10">
        <Reveal delay={40}><p className="eyebrow">Choose your format before you record</p></Reveal>
        <div className="mt-4 grid gap-2.5 sm:grid-cols-3">
          {formats.map(({ icon, label }, i) => (
            <Reveal key={label} delay={i * 40}>
              <div className="card lift r-card flex items-center gap-3 px-5 py-4">
                <Icon name={icon} className="h-5 w-5 shrink-0 text-[var(--fg-dim)]" />
                <span className="text-sm font-medium">{label}</span>
              </div>
            </Reveal>
          ))}
        </div>
      </div>

      <Reveal delay={80}>
        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <div className="card lift r-card p-6">
            <p className="font-medium">Up to 60 minutes</p>
            <p className="mt-1 text-sm muted">Record a full meeting, a long brainstorm, or a detailed voice memo. Verba handles the whole thing.</p>
          </div>
          <div className="card lift r-card p-6">
            <p className="font-medium">#Hashtag filing</p>
            <p className="mt-1 text-sm muted">Tag any note with #hashtags to organize and filter, exactly the way Bear works. Your notes find themselves.</p>
          </div>
          <div className="card lift r-card p-6">
            <p className="font-medium">Synced across Macs</p>
            <p className="mt-1 text-sm muted">Your notes follow your account. Sign in on another Mac and they are all there, instantly.</p>
          </div>
        </div>
      </Reveal>
    </section>
    <CrossRule />
    </>
  );
}

function LanguageDetection() {
  // Spoken = raw speech (filler, no caps/punctuation); written = the same language,
  // cleaned. The mode tag shows this is Raw (verbatim), that's why it stays in your
  // language word-for-word, just tidied up.
  const pairs = [
    { mode: "Raw · FR", spoken: "euh bonjour j'aurais besoin d'aide avec mon compte", written: "Bonjour, j'ai besoin d'aide avec mon compte." },
    { mode: "Raw · ES", spoken: "hola eh quiero cancelar mi suscripción", written: "Hola, quiero cancelar mi suscripción." },
    { mode: "Raw · EN", spoken: "hey um can we like reschedule to thursday", written: "Hey, can we reschedule to Thursday?" },
    { mode: "Raw · DE", spoken: "ähm ich brauche die rechnung bis freitag", written: "Ich brauche die Rechnung bis Freitag." },
  ];
  return (
    <section className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Multilingual"
          index="08"
          title="French in, French out."
          lead="Every engine detects the language you are speaking and answers in it. Switch languages mid-session if you like, or say &quot;in English&quot; to override. There is no setting to change."
        />
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2">
        {pairs.map(({ mode, spoken, written }, i) => (
          <Reveal key={i} delay={i * 60}>
            <div className="card lift r-card p-5">
              <div className="flex items-center justify-between">
                <p className="eyebrow">You say</p>
                <span className="rounded-full border pborder ptint px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide pf-55">{mode}</span>
              </div>
              <p className="mt-1.5 text-sm muted italic">"{spoken}"</p>
              <p className="mt-3 eyebrow">Verba writes</p>
              <p className="mt-1.5 text-sm">{written}</p>
            </div>
          </Reveal>
        ))}
      </div>
      <Reveal delay={80}>
        <p className="mt-6 text-center text-sm muted">
          On-device transcription covers 99+ languages, with a faster option optimized for 25 European languages.
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
    <section id="todos" className="py-28">
      <Reveal>
        <HeadLeft
          eyebrow="New · Voice task manager"
          index="03"
          anchor
          title="A Task Manager you just talk to"
          lead="Press a key, talk, and Verba builds projects, tasks and sub-tasks, sets real deadlines, reminds you, and checks things off. All by voice, including generating a whole list when you ask for one. No other dictation app ships a task manager."
        />
      </Reveal>

      <Reveal delay={60}>
        <div className="mt-12">
        <PanelCaption>03 · Voice task manager</PanelCaption>
        <div className="panel r-panel overflow-hidden">
          <div className="grid sm:grid-cols-2">
            <div className="p-8 sm:border-r sm:pborder">
              <p className="mono-meta">You say</p>
              <p className="mt-3 text-[17px] font-medium leading-snug pf-90">
                "Add to my groceries: tomatoes, pasta and parmesan. Oh and I already bought the bread.
                Pay the electricity bill Friday at 6pm."
              </p>
              <p className="mt-3 flex items-center gap-2 text-sm pf-45"><span className="rec-dot" /> One press, one sentence.</p>
            </div>
            <div className="p-8">
              <p className="mono-meta">Verba does</p>
              <div className="mt-3 space-y-2 rounded-lg border pborder pbg p-4 text-sm pf-85">
                <p className="font-semibold text-white">Groceries</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border pborder30" /> Tomatoes</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border pborder30" /> Pasta</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border pborder30" /> Parmesan</p>
                <p className="flex items-center gap-2 pf-40 line-through"><Icon name="check" className="h-4 w-4 text-[#6ee7a8]" /> Bread</p>
                <p className="mt-2 font-semibold text-white">Bills</p>
                <p className="flex items-center gap-2"><span className="inline-flex h-4 w-4 items-center justify-center rounded-full border pborder30" /> Pay electricity <span className="rounded ptint10 px-1.5 py-0.5 font-mono text-xs tnum">Fri 18:00</span></p>
              </div>
              <p className="mt-3 text-xs pf-40">Filed, dated, and one already checked, automatically.</p>
            </div>
          </div>
        </div>
        </div>
      </Reveal>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map(({ icon, label, text }, i) => (
          <Reveal key={label} delay={i * 60}>
            <div className="card lift r-card flex h-full flex-col gap-2.5 p-6">
              <Icon name={icon} className="h-5 w-5 text-[var(--fg-dim)]" />
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
    <>
    <CrossRule />
    <section id="translate" className="bg-[var(--bg-2)] py-28">
      <Reveal>
        <HeadLeft
          eyebrow="New mode · Translate"
          index="04"
          anchor
          title={<>Think in your language,<br />write in theirs</>}
          lead="Pick a target language once. Then just talk, in whatever language is natural to you, and Verba writes it out fluently in the one you chose. No &quot;translate this&quot; prefix, no copy-paste into another tab. Speak French, send English. Every single time."
        />
      </Reveal>

      <div className="mt-12 grid gap-3 sm:grid-cols-3">
        {pairs.map((p, i) => (
          <Reveal key={i} delay={i * 70}>
            <div className="card lift r-card flex h-full flex-col p-6">
              <div className="flex items-center gap-2">
                <span className="rounded border border-[var(--border-strong)] bg-[var(--tint)] px-1.5 py-0.5 font-mono text-[10px] font-semibold tracking-wider">{p.code}</span>
                <p className="eyebrow">{p.from}</p>
              </div>
              <p className="mt-3 text-sm muted italic">"{p.said}"</p>
              <div className="my-4 h-px bg-[var(--border)]" />
              <p className="eyebrow">Verba writes (English)</p>
              <p className="mt-1.5 text-sm">{p.out}</p>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={80}>
        <div className="card r-card mt-4 p-8">
          <p className="eyebrow text-center">Choose any target language</p>
          <div className="mt-5 flex flex-wrap justify-center gap-2">
            {langs.map((l) => (
              <span key={l} className="rounded-full border border-[var(--border)] bg-[var(--tint)] px-3.5 py-1.5 text-sm transition-colors duration-150 hover:border-[var(--border-strong)]">{l}</span>
            ))}
          </div>
          <p className="mx-auto mt-6 max-w-2xl text-center text-sm muted text-balance">
            Set it per mode, or make a dedicated mode per language and auto-switch by app.
            Tone, intent, names, numbers and code are all preserved. Uses your default model.
          </p>
        </div>
      </Reveal>
    </section>
    <CrossRule />
    </>
  );
}

function WhyBest() {
  const edges = [
    ["Does what others can't", "Reads your screen (Context), takes hour-long structured Notes, translates live, and runs agentic actions (Calendar, Reminders, email drafts). Most rivals only transcribe."],
    ["Cheaper, and honest about it", "$9.99/mo, or $7/mo billed annually, while most other dictation apps run $15 to $17. Raw dictation is free forever and unlimited, no card ever; Pro adds every AI mode and feature."],
    ["Private AI on your Mac", "Run AI privately on-device, or connect the AI account you already use, with no key needed at all. You're never locked into our markup."],
    ["Actually private", "On-device transcription runs locally, your audio never leaves the Mac. Account credentials live in the macOS Keychain, and your history is yours to control: switch it off entirely or auto-delete it after 7, 30, or 90 days."],
    ["Works with no internet", "The on-device engine ships inside the app and transcribes offline, instantly, in 25 languages. Pair it with a local AI model and the entire pipeline runs on your Mac."],
    ["Six modes, plus your own", "Raw, Polish, Intent, Translate, Context and Prompt, routed to lighter or more capable AI so you only pay for power where it matters. Edit any prompt, or describe a need and AI builds you a custom mode."],
    ["It learns you", "Auto-learns your vocabulary from your edits, matches your writing tone per app, and remembers how you phrase things. It sounds like you, not a template."],
    ["One press, then done", "Tap Fn, talk, and clean text lands where your cursor is. Hands-free formatting, redo in another mode, edit the last result by voice. No app switching, ever."],
  ];
  return (
    <section id="why" className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Why Verba"
          index="07"
          title="The complete voice OS for your Mac"
          lead="It doesn't just transcribe. It reads your screen, files your tasks, translates as you speak, and acts on what it hears. On your Mac, in every app, with your own AI."
        />
      </Reveal>

      {/* Social-proof bar, truthful, verifiable signals of a serious, live product. */}
      <Reveal delay={40}>
        <div className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {[
            ["Shipping constantly", "40+ public releases and counting, all on the live changelog."],
            ["230+ achievements to earn", "1,000 levels, daily streaks and a live leaderboard, see your rank and percentile among everyone using Verba."],
            ["Works in every app", "If your cursor is there, Verba writes there. No window, no paste."],
            ["Your AI, or fully offline", "Connect your own AI account or run on-device. No vendor markup, no uploads."],
          ].map(([t, d]) => (
            <div key={t} className="card r-card p-5">
              <p className="flex items-center gap-2 font-medium"><span className="rec-dot" />{t}</p>
              <p className="mt-1.5 text-sm muted">{d}</p>
            </div>
          ))}
        </div>
      </Reveal>

      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        {edges.map(([t, d], i) => (
          <Reveal key={t} delay={(i % 2) * 60}>
            <div className="card lift r-card flex h-full gap-4 p-6">
              <span className="mt-0.5 inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[var(--fg)] text-[var(--bg)]">
                <MicGlyph size={11} />
              </span>
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

function ModesModels() {
  const rows = [
    ["Raw", "No AI", "Verbatim transcription, no rewriting. Your words, exactly as spoken, cleaned up for punctuation only."],
    ["Polish", "Standard AI", "Hears what you meant. It follows your self-corrections to the final version, drops the parts you took back, and writes finished prose, not a transcript of thinking out loud."],
    ["Intent", "Standard AI", "State the goal at the start: \"turn this into a bug report\", \"rewrite as a formal email\". Verba follows your lead."],
    ["Translate", "Standard AI", "Pick a target language once. Speak in any language and Verba writes it in the one you chose, every time."],
    ["Context", "Standard AI", "Takes a screenshot of your screen and acts on what it sees, based on what you say. Reply to the email on screen, summarize a document, comment on a photo."],
    ["Prompt", "Advanced AI", "Turns what you say into an optimized prompt for any AI tool: an image generator, a chat assistant, or a coding agent like Cursor."],
  ];
  return (
    <section className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="The routing"
          index="05"
          title="Six modes, plus the ones you build"
          lead="Every mode routes to the model that fits: cheap and instant for quick polish, more powerful where it matters. You stay in control of cost and quality."
        />
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {rows.map(([mode, model, desc], i) => {
          const isContext = mode === "Context";
          return (
          <Reveal key={mode} delay={i * 60}>
            <div className={`${isContext ? "panel" : "card lift"} r-card flex h-full flex-col p-6 ${isContext ? "col-span-full sm:col-span-2 lg:col-span-3" : ""}`}>
              <div className="flex items-center justify-between">
                <h3 className={`font-medium ${isContext ? "text-white" : ""}`}>{mode}</h3>
                <span className={`rounded-full px-2.5 py-1 font-mono text-[11px] tnum ${isContext ? "border pborder ptint pf-70" : "border border-[var(--border)] bg-[var(--tint)]"}`}>{model}</span>
              </div>
              <p className={`mt-2 text-sm ${isContext ? "pf-60" : "muted"}`}>{desc}</p>
            </div>
          </Reveal>
          );
        })}
      </div>
    </section>
  );
}

function CompareTeaser() {
  return (
    <section className="py-28">
      <Reveal>
        {/* THE INVERSION, the page's single light surface [G7] */}
        <div className="r-panel relative overflow-hidden border border-black/10 bg-[#f4f2ee] px-8 py-16 text-center text-[#0a0a0c] sm:px-12 sm:py-20" style={{ boxShadow: "var(--panel-shadow)" }}>
          <div className="mx-auto mb-7 w-fit"><MicMark size={40} glyph={20} /></div>
          <h2 className="t-statement mx-auto max-w-3xl text-balance">Other dictation tools upload your voice. Verba doesn't.</h2>
          <p className="mx-auto mt-5 max-w-xl text-balance text-black/55">
            The popular dictation tools send every word to their servers, and most run $15 to $17 a month.
            Verba runs on your Mac, lets you connect the AI account you already use, and costs $9.99.
          </p>
          <Link href="/compare" className="mt-9 inline-flex items-center gap-2 rounded-[10px] bg-[#0a0a0c] px-7 py-3 font-medium text-white transition-opacity duration-150 hover:opacity-90">
            See the full comparison
          </Link>
          <p className="mt-4 text-sm">
            <Link href="/vs/wispr-flow" className="font-medium text-black/60 underline decoration-black/20 underline-offset-4 transition-colors hover:text-black">Verba vs Wispr Flow →</Link>
          </p>
        </div>
      </Reveal>
    </section>
  );
}

/* The eight core pillars, framed benefit-led: the problem people live with,
   then exactly how Verba removes it. Truthful to shipped features. */
function FeatureBlurbs() {
  const blurbs: { name: string; problem: string; example: string }[] = [
    { name: "Dictate anywhere", problem: "Switching to a transcription window breaks your flow and means copy-paste every time.", example: "Press Fn in Slack, Mail, VS Code, anywhere. Clean text lands right at your cursor. No window, no paste." },
    { name: "Context mode reads your screen", problem: "Most dictation tools are blind. They can only transcribe, never act on what you're looking at.", example: "Glance at an email, say \"reply that I'll be there,\" and Verba drafts it from what's on screen. No copy-paste." },
    { name: "Talk an hour, get a document", problem: "Long voice memos pile up as raw transcripts nobody wants to clean afterward.", example: "Open Notes, pick Meeting notes, talk for 40 minutes. Out comes a structured, tagged, editable markdown doc." },
    { name: "A task manager you just talk to", problem: "Capturing to-dos means stopping, opening an app, and typing the thing you already said out loud.", example: "\"Pay the invoice Friday at 6pm\" files a dated task. \"I bought the tomatoes\" ticks it off. By voice, no tapping." },
    { name: "Translate as you speak", problem: "Writing in a second language means drafting, copying into a translator, then pasting back. Three steps, every message.", example: "Pick a target language once. Speak French, Verba writes fluent English in place. Tone, names, and numbers preserved." },
    { name: "Private AI on your Mac", problem: "Other dictation tools lock you into their model and charge a markup on every word.", example: "Run AI privately on-device, or connect the AI account you already use, with no key needed at all." },
    { name: "It learns how you write", problem: "Generic rewriters flatten your voice into the same corporate template every time.", example: "Correct a word once and Verba remembers it. It matches your tone per app, so you in Slack still sounds like you." },
    { name: "Chain dictations, never wait", problem: "Other tools make you sit through processing before you can speak again.", example: "Fire off dictation after dictation: each one still working stacks up as a little chip above the pill, 10 or 20 at a time, and lands the moment it's ready." },
    { name: "Runs fully offline", problem: "Other tools upload every word you speak and stop working the moment your connection drops.", example: "The on-device engine ships inside the app and transcribes on-device, instantly, in 25 languages. Pair a local model and nothing leaves your Mac." },
  ];
  return (
    <section className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="The whole picture"
          title="Eight reasons it replaces your keyboard"
          lead="Other apps stop at transcription. Each of these starts from a problem you live with, and ends with one key press."
        />
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2">
        {blurbs.map(({ name, problem, example }, i) => (
          <Reveal key={name} delay={(i % 2) * 60}>
            <div className="card lift r-card flex h-full flex-col p-6">
              <div className="flex items-center gap-2.5">
                <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[var(--fg)] text-[var(--bg)]">
                  <MicGlyph size={10} />
                </span>
                <h3 className="font-medium">{name}</h3>
              </div>
              <p className="mt-3 text-sm faint">{problem}</p>
              <p className="mt-2 text-sm muted">{example}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function Features() {
  const items = [
    ["Dictate in any app", "Press your shortcut anywhere. The polished text lands right where your cursor is. No copy-paste, no app switching."],
    ["Your messy speech, cleaned up", "Verba reorders your thoughts, fixes punctuation, and removes the filler so a rambling voice note becomes a clean, ready-to-send message."],
    ["Keeps your voice", "Switch between modes for coding, work, and personal writing. Verba matches the right tone instead of flattening everything."],
    ["Hands-free formatting", "Say \"new line\", \"bullet point\", or \"scratch that\" and watch real formatting appear. Bold, headings, and lists paste through, ready to go."],
    ["Three transcription engines", "An online engine (fastest and most accurate), an on-device engine (every size, including the largest and most accurate), and a lightweight on-device engine built for speed and strong on EU languages. The on-device engines ship inside the app, work offline instantly, and need no setup."],
    ["Private by default", "On-device mode runs entirely on your Mac and your audio never leaves the device. Transcripts are saved to your local history. Turn it off entirely or auto-delete entries after 7, 30, or 90 days in Settings. API keys live in your macOS Keychain."],
    ["Flexible AI options", "Connect the AI account you already use, or run a fully local AI model that works offline. Verba can auto-install and start a local AI model for you."],
    ["Recording indicator choices", "A floating glass pill (default), or Menu bar only (no overlay, the menu-bar icon turns into a red REC dot while recording). Pick the one that stays out of your way."],
    ["Auto-learn dictionary", "When you correct a word on the review screen, Verba remembers it and applies the fix automatically next time. Your vocabulary, learned silently."],
    ["Edit the last result by voice", "After a dictation, say \"make it shorter\", \"more formal\", or \"translate to English\" and Verba rewrites the result on the spot. No need to re-record."],
    ["Redo in another mode", "Changed your mind about the format? Re-run your last recording through any other mode without speaking again."],
    ["Tone match per app", "Verba learns how you write in each app from your recent messages there and matches your personal tone automatically. Slack sounds like you in Slack. Mail sounds like you in Mail."],
    ["Smart formatting per app", "Rich text and markdown in apps that render it (Mail, Notion, Notes, Obsidian). Plain text in code editors and terminals. Verba detects the context and formats accordingly."],
    ["Custom sound cues", "Subtle audio cues signal recording start, paste, and errors. Adjust the volume or swap out sounds. Everything is customizable, or turn it off entirely."],
    ["Synced to your account", "Sign in and your history, notes, and stats follow you to your other Macs. Signed out, everything stays on this device. Nothing is uploaded."],
    ["Automatic language detection", "Every transcription engine detects the language you are speaking and writes the result in that same language. No settings to change."],
  ];
  const [hero, ...rest] = items;
  return (
    <section id="features" className="py-28">
      <HeadLeft
        eyebrow="The full kit"
        index="10"
        anchor
        title="Everything you say, written better"
        lead="Sixteen more things Verba does once your cursor is in the box. The headline move is dictation anywhere; these are why people stay."
      />
      <div className="mt-12 grid gap-3 lg:grid-cols-3">
        {/* hero feature, weighted, in product chrome, breaks the equal grid */}
        <div className="lg:row-span-2">
        <PanelCaption>10 · The core move</PanelCaption>
        <div className="panel r-card flex h-full flex-col justify-between p-7">
          <div className="flex items-center gap-3">
            <span className="mic-mark" style={{ width: 34, height: 34, borderRadius: 9 }}><MicGlyph size={16} /></span>
          </div>
          <div className="mt-10">
            <h3 className="text-xl font-semibold text-white">{hero[0]}</h3>
            <p className="mt-2.5 text-[15px] leading-relaxed pf-60">{hero[1]}</p>
          </div>
        </div>
        </div>
        {rest.map(([t, d]) => (
          <div key={t} className="card lift r-card p-6">
            <h3 className="font-medium">{t}</h3>
            <p className="mt-2 text-sm muted">{d}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function Personalize() {
  const cards = [
    { icon: "key", label: "Make it yours", text: "A dedicated Customize area: glass materials, accent color, recording indicator, sounds, and hotkeys. Tune Verba until it feels like your Mac, not a stock app." },
    { icon: "check", label: "macOS widget", text: "Pin your to-dos to the desktop or Notification Center. Your next tasks stay one glance away, updated as you check things off by voice." },
  ];
  return (
    <section id="customize" className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Make it yours"
          title="Personalize Verba, and keep it close"
          lead="A full Customize area to tune the look, sounds and shortcuts, plus a macOS widget that keeps your tasks one glance away."
        />
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2">
        {cards.map(({ icon, label, text }, i) => (
          <Reveal key={label} delay={i * 60}>
            <div className="card lift r-card flex h-full gap-4 p-7">
              <Icon name={icon} className="mt-0.5 h-6 w-6 shrink-0 text-[var(--fg-dim)]" />
              <div>
                <h3 className="font-medium">{label}</h3>
                <p className="mt-1.5 text-sm muted">{text}</p>
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function Shortcuts() {
  // groups of shortcuts: keys render as little glass keycaps, plus a use case that makes the power click.
  const groups: { title: string; blurb: string; rows: { keys: string[]; desc: string; use: string }[] }[] = [
    {
      title: "Dictate",
      blurb: "Start, pause, cancel. One key does the talking.",
      rows: [
        { keys: ["fn"], desc: "Tap or hold to dictate", use: "Tap once and talk, or set it to hold-to-talk. No window to open, text lands at your cursor." },
        { keys: ["⌃"], desc: "Pause and resume while recording", use: "Someone walks in. Hit Control, handle it, hit Control again, keep going." },
        { keys: ["⎋"], desc: "Cancel the recording or processing", use: "Changed your mind halfway through a sentence. Press Escape and nothing is pasted." },
      ],
    },
    {
      title: "Switch modes and styles",
      blurb: "Flip between Raw, Intent, Translate and your own modes mid-thought.",
      rows: [
        { keys: ["fn", "⇥"], desc: "Next mode, add ⇧ for previous", use: "Mid-dictation you decide this should be a Slack message, not an email. Fn + Tab, keep talking." },
        { keys: ["fn", "1-9"], desc: "Jump to a mode by number", use: "Fn + 3 drops you straight into Translate without hunting through a list." },
        { keys: ["⌥"], desc: "Next mode hands-free while recording", use: "Tap Option to cycle modes without ever leaving the recording." },
        { keys: ["⌃", "⌥", "1-6"], desc: "Each mode's own dedicated shortcut", use: "Bind Prompt to ⌃⌥5 and reach it from anywhere, no cycling." },
        { keys: ["fn", "]"], desc: "Next Style, Fn + [ for previous", use: "Same mode, new tone. Flick from neutral to formal as a layer on top." },
      ],
    },
    {
      title: "Capture",
      blurb: "Notes, to-dos and a quick glance, all by voice.",
      rows: [
        { keys: ["fn", "T"], desc: "Add a to-do by voice, Fn + § on ISO", use: "\"Pay the invoice Friday at 6pm\" files a dated task without opening anything." },
        { keys: ["fn", "Z"], desc: "Capture a voice note", use: "A 20-minute brain dump becomes one clean, structured document in Notes." },
        { keys: ["fn"], desc: "Stop an in-progress note or to-do", use: "Done talking. One tap of Fn closes the capture." },
        { keys: ["⌥", "fn"], desc: "Today's to-dos, quick glance", use: "Option + Fn shows what's due today, then dismiss it the same way." },
      ],
    },
    {
      title: "Transform and control",
      blurb: "Rewrite any selection, or speak a command that runs your Mac.",
      rows: [
        { keys: ["⌥", "X"], desc: "Transform picker on selected text", use: "Select a clumsy paragraph anywhere, press it, pick a numbered transform, and it rewrites in place." },
        { keys: ["fn", "X"], desc: "JARVIS, an assistant that acts for you", use: "Speak any request, however it comes out. Verba works out what you mean, plans the steps, and acts, on your Mac or your connected apps (Gmail, Slack, Notion, Calendar…), always confirmed before it does anything." },
      ],
    },
  ];
  return (
    <section id="shortcuts" className="py-28">
      <Reveal>
        <HeadCenter
          eyebrow="Every shortcut, every power"
          title="One keyboard, the whole app"
          lead="Verba lives under your fingers. Start a dictation, switch modes, capture a note, rewrite a selection, or speak a command that runs your Mac, all without leaving the keyboard. These are only suggested defaults, every shortcut is yours to choose in the app."
        />
      </Reveal>

      <div className="mt-12 grid gap-3 lg:grid-cols-2">
        {groups.map((g, gi) => (
          <Reveal key={g.title} delay={(gi % 2) * 60}>
            <div className="card lift r-card flex h-full flex-col p-7">
              <div>
                <h3 className="font-medium">{g.title}</h3>
                <p className="mt-1.5 text-sm muted">{g.blurb}</p>
              </div>
              <div className="mt-5 space-y-4">
                {g.rows.map((r, ri) => (
                  <div key={ri} className="border-t border-[var(--border)] pt-4 first:border-0 first:pt-0">
                    <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1.5">
                      <span className="flex shrink-0 items-center gap-1">
                        {r.keys.map((k, ki) => (
                          <span key={ki} className="flex items-center gap-1">
                            {ki > 0 && <span className="faint text-xs">+</span>}
                            <kbd className="kbd">{k}</kbd>
                          </span>
                        ))}
                      </span>
                      <span className="text-sm font-medium">{r.desc}</span>
                    </div>
                    <p className="mt-1.5 text-sm muted">{r.use}</p>
                  </div>
                ))}
              </div>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal delay={80}>
        <div className="card r-card mt-3 flex items-start gap-4 p-7">
          <Icon name="key" className="mt-0.5 h-6 w-6 shrink-0 text-[var(--fg-dim)]" />
          <div>
            <p className="font-medium">Make it yours</p>
            <p className="mt-1.5 text-sm muted">
              Every one of these is rebindable in Settings, Triggers and chords. The primary trigger, change-mode,
              styles, add-to-do, record-note, the glance, Action mode, and the transform key. Don't use Fn? Bind a
              custom shortcut and run the entire app from keys you already love.
            </p>
          </div>
        </div>
      </Reveal>
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
    <section id="how" className="py-28">
      <HeadCenter eyebrow="How it works"
        index="11" title="From voice to done in one press" />
      <div className="mt-12 grid gap-3 sm:grid-cols-3">
        {steps.map(([t, d], i) => (
          <div key={t} className="card r-card relative p-7">
            <div className="flex items-center justify-between">
              <span className="text-3xl font-semibold tabular-nums text-[var(--faint)]">{i + 1}</span>
              {i === 0 && <span className="rec-dot pulse" />}
            </div>
            <h3 className="mt-4 font-medium">{t === "Press" ? <>Press <kbd className="kbd">fn</kbd></> : t}</h3>
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
  const [error, setError] = useState("");
  const [justSignedIn, setJustSignedIn] = useState(false);
  const proRef = useRef<HTMLDivElement>(null);
  const plan = annual ? "annual" : "monthly";

  // After signing in via the Pro CTA, the user is redirected back to /#pricing.
  // Scroll them to the Pro card and confirm they're signed in and ready to start.
  useEffect(() => {
    if (isSignedIn && typeof window !== "undefined" && window.location.hash === "#pricing") {
      setJustSignedIn(true);
      const t = setTimeout(() => proRef.current?.scrollIntoView({ behavior: "smooth", block: "center" }), 150);
      return () => clearTimeout(t);
    }
  }, [isSignedIn]);

  async function checkout(p: "monthly" | "annual" | "founder" = plan) {
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan: p, ref: getRef() }),
      });
      const data = await res.json();
      if (data.url) window.location.href = data.url;
      else setError(data.error ?? "Checkout unavailable. Please try again.");
    } catch {
      setError("Checkout unavailable. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section id="pricing" className="py-28">
      <HeadCenter eyebrow="Pricing"
        index="13" title={<>Start free. Go Pro when you&rsquo;re hooked.</>} />
      <div className="mx-auto mt-8 flex w-fit items-center gap-1 rounded-full border border-[var(--border)] bg-[var(--tint)] p-1 text-sm">
        {[["Monthly", false], ["Annual · save 30%", true]].map(([label, a]) => (
          <button
            key={String(label)}
            onClick={() => setAnnual(a as boolean)}
            className={`rounded-full px-5 py-2 transition-colors duration-150 ${annual === a ? "bg-[var(--fg)] text-[var(--bg)] font-medium" : "muted"}`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="mx-auto mt-10 grid max-w-3xl gap-4 sm:grid-cols-2">
        {/* Free, flat supporting card */}
        <div className="card r-panel p-8">
          <h3 className="text-lg font-medium">Free</h3>
          <div className="mt-3 font-mono text-4xl font-semibold tnum">$0</div>
          <p className="mt-1 text-sm muted">Unlimited raw dictation, free forever, for everyone. No card, ever. Pro unlocks everything else.</p>
          <ul className="mt-6 space-y-2.5 text-sm muted">
            {["Unlimited raw dictation, free forever", "On-device or online transcription", "No card, ever", "Pro unlocks every AI mode + feature"].map((b) => (
              <li key={b} className="flex gap-2.5"><span className="text-[var(--accent-line)]">·</span>{b}</li>
            ))}
          </ul>
          <a href={DOWNLOAD_URL} className="btn-ghost mt-7 block w-full px-6 py-3 text-center">
            Download free
          </a>
          <p className="mt-3 text-center font-mono text-[11px] tracking-wide faint tnum">Requires Apple Silicon · macOS 14+</p>
        </div>

        {/* Pro, the ONE glass-budget moment among pricing: solid panel chrome */}
        <div ref={proRef} className="panel r-panel p-8" style={{ borderColor: "var(--border-warm)" }}>
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium">Pro</h3>
            <span className="flex items-center gap-1.5 rounded-full border pborder ptint px-2.5 py-1 text-xs pf-70">
              <span className="rec-dot" /> Most popular
            </span>
          </div>
          <div className="mt-3 flex items-end gap-1">
            <span className="font-mono text-4xl font-semibold tnum">{PRICE[plan].amount}</span>
            <span className="mb-1 text-sm pf-50">{PRICE[plan].sub}</span>
          </div>
          <p className="mt-1 text-sm pf-50 tnum">{PRICE[plan].note} · 7-day trial, card required</p>
          <p className="mt-2 text-xs pf-50">Audio stays on your Mac · your own AI, no markup · cancel anytime.</p>
          <ul className="mt-6 space-y-2.5 text-sm pf-85">
            {["Every AI mode: Polish, Intent, Translate, Context, Prompt", "Notes: long recordings, structured for you", "Tasks: speak straight into a task manager", "JARVIS: act across 1,000+ connected apps by voice", "Snippets, Transforms and Styles", "Custom modes + editable system prompts", "Voice-command formatting", "Sync across your Macs", "Priority support"].map((b) => (
              <li key={b} className="flex items-center gap-2.5"><span className="inline-flex h-4 w-4 items-center justify-center rounded-[4px] bg-[var(--fg)] text-[var(--bg)]"><MicGlyph size={8} /></span>{b}</li>
            ))}
          </ul>
          {isSignedIn ? (
            <>
              {justSignedIn && (
                <p className="mt-6 flex items-center gap-2 rounded-lg border pborder ptint px-3 py-2 text-xs pf-75">
                  <span className="inline-block h-1.5 w-1.5 rounded-full bg-[#6ee7a8]" />
                  You&rsquo;re signed in. Start your 7-day trial below.
                </p>
              )}
              <button onClick={() => checkout()} disabled={loading} className="mt-7 w-full rounded-[10px] bg-white px-6 py-3 font-medium text-black transition hover:opacity-90 disabled:opacity-60">
                {loading ? "Redirecting…" : "Start 7-day trial"}
              </button>
            </>
          ) : (
            <SignInButton mode="modal" forceRedirectUrl="/#pricing">
              <button className="mt-7 w-full rounded-[10px] bg-white px-6 py-3 font-medium text-black transition hover:opacity-90">
                Sign in to start trial
              </button>
            </SignInButton>
          )}
          {error && (
            <p role="alert" className="mt-3 rounded-lg border border-[#ff5f57]/30 bg-[#ff5f57]/10 px-3 py-2 text-xs text-[#ff8a84]">
              {error}
            </p>
          )}
        </div>
      </div>

      {/* Founder's Edition, the one-time anchor below the two recurring plans. A full-width
          warm band keeps Pro as the only solid-panel moment while reading as the premium offer. */}
      <div className="mx-auto mt-4 max-w-3xl">
        <div className="card r-panel relative overflow-hidden p-7 sm:p-8" style={{ borderColor: "var(--border-warm)" }}>
          <div aria-hidden className="pointer-events-none absolute inset-0 opacity-[0.6]" style={{ background: "radial-gradient(120% 150% at 100% 0%, rgba(244,237,224,0.07), transparent 62%)" }} />
          <div className="relative flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
            <div className="max-w-sm">
              <span className="inline-flex items-center gap-1.5 rounded-full border pborder ptint px-2.5 py-1 text-[10px] font-medium uppercase tracking-[0.2em] pf-70">
                <span className="rec-dot" /> Founder&rsquo;s Edition
              </span>
              <h3 className="mt-3.5 text-lg font-medium">Lifetime, pay once, yours forever</h3>
              <p className="mt-1.5 text-sm muted">Everything in Pro, no subscription. One payment, every future update included.</p>
              <div className="mt-4 flex items-end gap-2">
                <span className="font-mono text-4xl font-semibold tnum">$149</span>
                <span className="mb-1 text-sm muted">one-time</span>
              </div>
            </div>
            <div className="shrink-0">
              {isSignedIn ? (
                <button
                  onClick={() => checkout("founder")}
                  disabled={loading}
                  className="group inline-flex items-center gap-2.5 rounded-full bg-white py-3 pl-6 pr-3 font-medium text-black transition duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] hover:opacity-90 active:scale-[0.98] disabled:opacity-60"
                >
                  {loading ? "Redirecting…" : "Get lifetime access"}
                  <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-black/5 transition-transform duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] group-hover:translate-x-0.5 group-hover:-translate-y-px">
                    <svg width="11" height="11" viewBox="0 0 12 12" fill="none" aria-hidden><path d="M3.5 8.5L8.5 3.5M8.5 3.5H4.25M8.5 3.5V7.75" stroke="currentColor" strokeWidth="1.25" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  </span>
                </button>
              ) : (
                <SignInButton mode="modal" forceRedirectUrl="/#pricing">
                  <button className="group inline-flex items-center gap-2.5 rounded-full bg-white py-3 pl-6 pr-3 font-medium text-black transition duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] hover:opacity-90 active:scale-[0.98]">
                    Sign in for lifetime
                    <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-black/5 transition-transform duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] group-hover:translate-x-0.5 group-hover:-translate-y-px">
                      <svg width="11" height="11" viewBox="0 0 12 12" fill="none" aria-hidden><path d="M3.5 8.5L8.5 3.5M8.5 3.5H4.25M8.5 3.5V7.75" stroke="currentColor" strokeWidth="1.25" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    </span>
                  </button>
                </SignInButton>
              )}
              <p className="mt-2.5 text-center font-mono text-[11px] tracking-wide faint tnum">Limited Founder&rsquo;s release</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function FAQ() {
  const qa = [
    ["Does it work in every app?", "Yes, Verba pastes into whatever you’re typing in: editors, browsers, chat apps, mail, notes. If your cursor is there, Verba can write there."],
    ["Can it work offline?", "Yes. On-device transcription runs entirely on your Mac, no internet needed, and your audio never leaves the device."],
    ["What languages does it understand?", "On-device transcription covers ~99 languages worldwide, with a faster option for 25 European languages. It writes back in the language you spoke."],
    ["How do the AI modes work?", "Verba ships six modes: Raw (verbatim, no AI, the default), Polish (resolves your self-corrections), Intent, Translate, Context, and Prompt (turns what you say into an optimized prompt for any AI, including coding agents). Each mode is a system prompt that shapes how the model rewrites your speech. Context also takes a screenshot to ground the output in what is on your screen. You can edit any prompt, or just describe what you need and AI builds you a custom mode."],
    ["Do I need to set anything up?", "No. Verba can run fully private AI on-device, or connect the AI account you already use, with no extra setup. You never pay a markup on someone else's servers."],
    ["What is Context mode?", "Context mode takes a screenshot of your screen, analyzes it with a vision model, and writes based on what you say and what it sees. Say \"reply to this email\" and it drafts a reply to the message on screen. It requires macOS Screen Recording permission and a connected AI account that supports vision."],
    ["Can it handle long recordings?", "Yes, talk for twenty minutes and Verba turns the whole thing into clean, well-ordered text."],
    ["Is my data private?", "In on-device mode your audio never leaves your Mac. Transcripts are saved to your local history by default. You can turn history off entirely (nothing written, nothing synced) or auto-delete entries after 7, 30, or 90 days. When you sign in, your history, notes, and stats sync to your account so they follow you across Macs; signed out, nothing is uploaded. API keys live in your macOS Keychain, and you can delete all your account data at any time."],
    ["Can Verba take notes?", "Yes. The Notes tab lets you record up to a full hour of speech and Verba turns it into a clean, structured document. Pick a format before you start: Clean note, Brain dump to outline, Summary, Meeting notes, Journal, Email, Code task, To-do list, or Article outline. Markdown is rendered (headings, bold, checkboxes). You can tag notes with #hashtags to file and filter them, edit the result in place, and copy it anywhere."],
    ["Can it create calendar events or reminders?", "Yes, with the Labs toggle on in Context mode. Say \"create an event tomorrow at 3pm\", \"remind me to call the bank\", or \"draft a reply to this email\" and Verba creates the Calendar event, Reminder, or email draft for you. It always asks you to confirm before doing anything."],
    ["Do my notes sync across my Macs?", "Yes. Notes are tied to your Verba account, so they follow you when you sign in on another Mac. No iCloud setup needed."],
    ["How does the Translate mode work?", "Pick a target language once in the Translate mode (English, French, Spanish, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean, Arabic, Hindi, Turkish, Polish). Then just speak in whatever language is natural to you and Verba writes the result in your chosen language, every time, preserving tone, names, numbers and code. You can also make a dedicated mode per language and auto-switch it by app."],
    ["How much does Verba cost?", "Raw dictation is free forever and unlimited, with no card. Pro is $9.99 per month or $84 per year (a saving versus monthly), or a one-time $149 Founder's Edition lifetime license, all billed securely through Stripe. Pro has a 7-day trial, and you connect the AI plan you already use so there are no hidden token charges."],
    ["Is Verba accurate, and how good is the transcription?", "Verba uses state-of-the-art on-device speech models for fast, high-accuracy voice-to-text on Apple Silicon Macs. Its AI cleanup layer then automatically fixes filler words, punctuation, and formatting in whatever app you're typing in, so the final text reads polished rather than raw."],
    ["Does Verba have a free trial or refund?", "Yes - raw dictation is free forever and unlimited with no card, so you can use Verba indefinitely without paying. The paid AI features have a 7-day Pro trial (card required), then $9.99/mo, $84/yr, or a $149 one-time lifetime. Billing is handled through Stripe, so subscriptions can be managed and cancelled at any time."],
    ["Does Verba work offline?", "Yes - in on-device mode Verba transcribes your voice locally, so core dictation works without an internet connection and your audio never leaves your Mac. You only need a connection for AI features like AI cleanup with a hosted model, live translation, or the JARVIS agent (a fully local AI model lets you run AI offline too)."],
    ["Is my data and audio private with Verba?", "Yes - in on-device mode your audio never leaves your Mac, since transcription runs entirely locally. With JARVIS, the action plan is generated on your Mac by your own AI (your own AI plan, your key, or a local model), never a server key, and every action runs only after you confirm. The keys that connect your apps are held by a secure relay, never on your Mac, and you can run AI fully locally for maximum privacy."],
    ["What can the JARVIS voice agent actually do?", "JARVIS is Verba's voice agent that takes action across 1,000+ connected apps - so you can speak commands to send emails, create calendar events, update tasks, and more without leaving your current app. It plans on your Mac with your own AI, shows you the steps, and only acts once you confirm. The keys that connect your apps are held by a secure relay, never on your Mac."],
  ];
  // FAQPage structured data, Google FAQ rich results + LLM/AI-search (GEO) citation.
  const faqJsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: qa.map(([q, a]) => ({
      "@type": "Question",
      name: q,
      acceptedAnswer: { "@type": "Answer", text: a },
    })),
  };
  return (
    <section className="py-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} />
      <Reveal>
        <HeadCenter
          eyebrow="FAQ"
          index="14"
          title="Questions, answered"
          lead="Everything you'd want to know before you press the key."
        />
      </Reveal>
      <div className="mx-auto mt-12 grid max-w-3xl gap-2.5">
        {qa.map(([q, a], i) => (
          <Reveal key={q} delay={i * 40}>
            <details className="group card r-card px-6 py-5 transition">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium">
                {q}
                <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full border border-[var(--border)] bg-[var(--tint)] text-lg leading-none transition-transform duration-300 group-open:rotate-45">+</span>
              </summary>
              <p className="faq-body mt-4 text-sm leading-relaxed muted">{a}</p>
            </details>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function Footer() {
  return (
    <>
    <CrossRule />
    <footer className="pb-10 pt-16 text-sm">
      <div className="grid gap-12 lg:grid-cols-[1.2fr_1fr]">
        {/* Statement, low-contrast display [C4] */}
        <div>
          <Logo />
          <p className="t-anchor mt-8 max-w-md text-[var(--faint)]">Speak it.<br />Send it clean.</p>
        </div>
        {/* Instrument panel: mono-labelled columns [C1, C4] */}
        <div className="grid grid-cols-2 gap-8 sm:grid-cols-3">
          <div>
            <p className="mono-meta mb-4">Product</p>
            <ul className="space-y-2.5 muted">
              <li><a href={DOWNLOAD_URL} className="link-quiet">Download</a></li>
              <li><a href="#pricing" className="link-quiet">Pricing</a></li>
              <li><Link href="/compare" className="link-quiet">Compare</Link></li>
              <li><Link href="/changelog" className="link-quiet">Changelog</Link></li>
            </ul>
          </div>
          <div>
            <p className="mono-meta mb-4">Resources</p>
            <ul className="space-y-2.5 muted">
              <li><Link href="/features" className="link-quiet">Features</Link></li>
              <li><Link href="/docs" className="link-quiet">Documentation</Link></li>
              <li><Link href="/features/jarvis-voice-agent" className="link-quiet">JARVIS voice agent</Link></li>
              <li><Link href="/features/voice-notes" className="link-quiet">Voice notes</Link></li>
              <li><Link href="/acknowledgements" className="link-quiet">Acknowledgements</Link></li>
            </ul>
          </div>
          <div>
            <p className="mono-meta mb-4">Company</p>
            <ul className="space-y-2.5 muted">
              <li><Link href="/account" className="link-quiet">Account</Link></li>
              <li><a href="https://t.me/verbarun" target="_blank" rel="noopener" className="link-quiet">Community (Telegram)</a></li>
              <li><Link href="/best-mac-dictation-app" className="link-quiet">Best Mac dictation app</Link></li>
              <li><Link href="/privacy" className="link-quiet">Privacy</Link></li>
              <li><Link href="/terms" className="link-quiet">Terms</Link></li>
              <li><Link href="/contact" className="link-quiet">Contact</Link></li>
            </ul>
          </div>
        </div>
      </div>
      {/* Bottom row: status + meta, all mono [C4, the trust surface] */}
      <div className="mt-14 flex flex-wrap items-center justify-between gap-4 border-t hairline pt-6">
        <span className="mono-meta flex items-center gap-2">
          <span className="inline-block h-1.5 w-1.5 rounded-full bg-[#6ee7a8]" />
          All systems operational
        </span>
        <span className="mono-meta">© 2026 Verba · Runs on-device with open models</span>
      </div>
    </footer>
    </>
  );
}
