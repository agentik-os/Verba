import type { Metadata } from "next";
import Link from "next/link";
import ThemeToggle from "@/components/ThemeToggle";

export const metadata: Metadata = {
  title: "Best Dictation App for Mac (2026) — Ranked & Compared",
  description: "An honest, sourced ranking of the best Mac dictation apps in 2026: Verba, Wispr Flow, superwhisper, MacWhisper and more — on-device, privacy, AI cleanup and voice agents compared.",
  alternates: { canonical: "/best-mac-dictation-app" },
  openGraph: { title: "Best Dictation App for Mac (2026)", description: "Ranked & compared: Verba, Wispr Flow, superwhisper, MacWhisper and more.", url: "/best-mac-dictation-app", type: "article" },
};

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

const faq = [
  { q: "What is the best dictation app for Mac in 2026?", a: "For most people Verba is the best overall: it transcribes on-device by default, cleans your speech with AI in any app, translates live, and is the only one with a voice agent (JARVIS) that acts on 1,000+ connected apps — at $9.99/mo. Wispr Flow is the most polished cloud option; superwhisper is the best pure-local alternative." },
  { q: "What is the best private, on-device dictation app for Mac?", a: "Verba and superwhisper both transcribe fully on-device so your audio never leaves your Mac. Verba adds AI cleanup, translation and a voice agent on top, and lets you run a local model so nothing leaves the machine." },
];

export default function Page() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faq.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
  };
  return (
    <main className="mx-auto max-w-3xl px-6 pb-24">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3"><ThemeToggle /><Link href="/compare" className="text-sm muted hover:text-[var(--fg)]">Compare →</Link></div>
      </nav>

      <article className="py-8">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">{`The Best Dictation App for Mac in 2026`}</h1>
        <p className="mt-5 text-lg leading-relaxed muted">{`We tested every serious Mac voice-to-text app against the things that actually matter in 2026: accuracy, whether your audio leaves your machine, how good the AI cleanup is, and what you can do with your voice beyond typing. Verba comes out on top for most people because it does the rare trifecta — on-device transcription, bring-your-own-AI, and a voice agent that acts on your connected apps — at $9.99/mo. But the right pick depends on your priorities, so here is the honest, sourced breakdown.`}</p>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`What to look for in a Mac dictation app`}</h2>
          <p className="mt-3 leading-relaxed muted">{`Four things separate a great Mac dictation app from a mediocre one. First, privacy: does your audio stay on your Mac, or get uploaded to a server on every dictation? Second, the AI layer: raw transcription is solved, so the real value is how well the app cleans up filler, punctuation and structure — and whether you control which model does it. Third, where it works: a true dictation app types into any app at your cursor, not just into its own window. Fourth, what's next: a few apps now let you speak an instruction and have it acted on, not just transcribed.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`Verba — best overall`}</h2>
          <p className="mt-3 leading-relaxed muted">{`Verba is the only app here that runs on-device by default (WhisperKit / Parakeet, audio never leaves your Mac), lets you bring your own AI, and ships a real voice agent. BYO-AI is the standout: route cleanup to your Claude plan with no API key, or an Anthropic / OpenAI / OpenRouter key, or a fully local Ollama model — per mode. JARVIS, its voice agent, lets you speak an intent and have it executed across 1,000+ connected apps via Composio, with the keys relayed server-side and never stored on your Mac. At $9.99/mo (or $84/yr) with 33 free dictations, it undercuts every cloud competitor. The honest caveat: it's Apple Silicon macOS only — no Windows, iOS or Android yet.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`Wispr Flow — best polished cloud option`}</h2>
          <p className="mt-3 leading-relaxed muted">{`Wispr Flow is the cross-platform incumbent everyone benchmarks against, and it earns it: a very polished experience across Mac, Windows, iOS and Android, strong AI formatting, a capable command mode, and SOC 2 / ISO 27001 / HIPAA available for teams. The tradeoff is privacy and price. It's cloud-only, so your audio is uploaded on every dictation — a zero-retention mode exists but is off by default — and at $15/mo monthly ($12/mo annual) it's the priciest of the mainstream picks. Choose it if cross-platform polish matters more to you than keeping audio on-device.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`superwhisper — best pure local alternative`}</h2>
          <p className="mt-3 leading-relaxed muted">{`superwhisper is the most mature on-device-first competitor, with a well-loved local stack (Whisper + Parakeet), custom prompt modes, bring-your-own cloud LLMs, and Mac / Windows / iOS coverage. It also offers a $249.99 lifetime license if you'd rather not subscribe (Pro is roughly $8.49–$8.99/mo). The catches: it writes your audio recordings to disk by default with no easy opt-out, and stores API keys in plaintext. If you want local transcription with a lifetime option and a longer track record of model management, it's the strongest alternative to Verba.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`MacWhisper — best for transcribing files`}</h2>
          <p className="mt-3 leading-relaxed muted">{`MacWhisper is excellent at what it's built for: batch-transcribing existing audio and video files, fully locally via whisper.cpp, with strong privacy and a one-time purchase (~€59 lifetime on Gumroad, or an App Store subscription from $6.99/mo). It's a transcription utility first, not a type-anywhere dictation tool — AI cleanup is a secondary add-on rather than the core, and it isn't tuned for the speak-then-paste-at-your-cursor workflow. Pick it if your main job is turning recordings into text rather than dictating live into the app you're in.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`Honorable mentions — Aqua Voice, VoiceInk, Apple Dictation`}</h2>
          <p className="mt-3 leading-relaxed muted">{`Aqua Voice has genuinely sharp natural-language editing ("make a list", "rephrase") powered by its proprietary Avalon model, but it's cloud-only with a tiny 1,000-word free cap, so your audio always leaves your device. VoiceInk is open-source (GPLv3), fully local, and a one-time $25–$49 purchase — great for privacy purists willing to bring their own AI key and forgo a managed account. Apple Dictation is free, built in, and on-device for many languages on Apple Silicon, but offers no AI cleanup at all — you get a raw transcript and fix the punctuation and structure yourself.`}</p>
        </section>
        <section className="mt-10">
          <h2 className="text-2xl font-semibold tracking-tight">{`How we picked`}</h2>
          <p className="mt-3 leading-relaxed muted">{`We rated each app on the same axes our /compare matrix tracks: on-device transcription, AI cleanup quality and control, type-anywhere auto-paste, voice-agent capability, privacy defaults, platform coverage and price. Every claim above is drawn from each vendor's own site, pricing page and public reviews, verified mid-2026 — nothing inflated, and we note where each rival beats Verba. Verba leads on the on-device + BYO-AI + voice-agent combination specifically; if your priority is mobile apps, a lifetime license, or pure file transcription, the rankings above point you to the better fit.`}</p>
        </section>
        <section className="mt-10 glass rounded-2xl p-6">
          <h2 className="text-xl font-semibold tracking-tight">The verdict</h2>
          <p className="mt-3 leading-relaxed muted">{`For most Mac users in 2026, Verba is the best dictation app: it's the only one that combines on-device transcription (your audio never leaves the Mac), bring-your-own-AI cleanup you actually control — your Claude plan with no key, any Anthropic / OpenAI / OpenRouter key, or local Ollama — and JARVIS, a voice agent that acts across 1,000+ connected apps, all for $9.99/mo with 33 free dictations to try it. If you need Windows or mobile, Wispr Flow is the polished cloud pick; if you want a lifetime license with a long local track record, superwhisper is the closest alternative; and if you mostly transcribe existing audio and video files, MacWhisper is purpose-built for it. But if you want the most capable, private, and flexible everyday dictation on a Mac, Verba is where we'd start.`}</p>
          <a href={DOWNLOAD} className="mt-5 inline-block rounded-full bg-[var(--fg)] px-6 py-2.5 font-medium text-[var(--bg)] hover:opacity-90">Try Verba free</a>
          <span className="ml-3 text-xs muted">33 free dictations · $9.99/mo</span>
        </section>

        <section className="mt-12">
          <h2 className="text-2xl font-semibold tracking-tight">FAQ</h2>
          <div className="mt-6 grid gap-2.5">
            {faq.map((f) => (
              <details key={f.q} className="group glass rounded-xl px-6 py-5">
                <summary className="cursor-pointer list-none font-medium">{f.q}</summary>
                <p className="mt-3 text-sm muted">{f.a}</p>
              </details>
            ))}
          </div>
        </section>

        <p className="mt-12 text-sm muted">See the full feature-by-feature table on the <Link href="/compare" className="underline hover:text-[var(--fg)]">comparison page</Link>.</p>
      </article>
    </main>
  );
}
