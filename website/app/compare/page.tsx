import Link from "next/link";
import ThemeToggle from "@/components/ThemeToggle";
import type { Metadata } from "next";
import { competitors, VERBA, onDeviceLabel } from "@/lib/competitors";

export const metadata: Metadata = {
  title: "Verba vs the rest, dictation app comparison",
  description:
    "How Verba compares to Wispr Flow, Superwhisper, MacWhisper, Aqua Voice, Willow, VoiceInk, Apple Dictation and Otter. Local-first, private, $9.99/mo.",
};

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export default function Compare() {
  return (
    <main className="mx-auto max-w-6xl px-6 pb-24">
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

      <section className="py-14 text-center">
        <h1 className="mx-auto max-w-3xl text-balance text-4xl font-semibold tracking-tight sm:text-6xl">
          How Verba compares
        </h1>
        <p className="mx-auto mt-5 max-w-xl text-lg muted text-balance">
          Most dictation apps send your voice to the cloud and bake the AI cost into a $12-17/mo
          bill. Verba runs on-device, lets you bring your own AI account, and costs $9.99.
        </p>
      </section>

      {/* Master matrix */}
      <div className="table-scrim glass rounded-2xl">
      <div className="overflow-x-auto">
        <table className="table-pin w-full min-w-[760px] border-collapse text-left text-sm">
          <thead>
            <tr className="muted">
              <th className="p-4 font-medium">App</th>
              <th className="p-4 font-medium">Price</th>
              <th className="p-4 font-medium">On-device</th>
              <th className="p-4 font-medium">Transcription</th>
              <th className="p-4 font-medium">Privacy default</th>
            </tr>
          </thead>
          <tbody>
            <tr className="grid-row bg-[var(--tint)]">
              <td className="p-4 font-semibold">Verba</td>
              <td className="p-4">{VERBA.price}</td>
              <td className="p-4 tick">Yes</td>
              <td className="p-4">{VERBA.transcription}</td>
              <td className="p-4">On-device: audio stays on your Mac; local history, synced only when signed in</td>
            </tr>
            {competitors.map((c) => (
              <tr key={c.slug} className="grid-row">
                <td className="p-4">
                  <Link href={`/vs/${c.slug}`} className="font-medium hover:underline">{c.name}</Link>
                </td>
                <td className="p-4 muted">{c.price}</td>
                <td className={`p-4 ${c.onDevice === "yes" ? "tick" : "cross"}`}>{onDeviceLabel(c.onDevice)}</td>
                <td className="p-4 muted">{c.transcription}</td>
                <td className="p-4 muted">{c.privacy.split(".")[0]}.</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      </div>

      {/* Per-competitor cards */}
      <h2 className="mt-20 text-center text-3xl font-semibold tracking-tight">Head-to-head</h2>
      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {competitors.map((c) => (
          <Link key={c.slug} href={`/vs/${c.slug}`} className="glass rounded-2xl p-6 transition hover:bg-[var(--tint-strong)]">
            <h3 className="font-medium">Verba vs {c.name}</h3>
            <p className="mt-2 text-sm muted">{c.tagline}</p>
            <span className="mt-4 inline-block text-sm">Compare →</span>
          </Link>
        ))}
      </div>

      <div className="mt-20 text-center">
        <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
          Download Verba for macOS
        </a>
        <p className="mt-6 text-xs muted">33 free dictations · Pro $9.99/mo · cancel anytime</p>
      </div>

      <footer className="mt-24 flex flex-col items-center gap-3 border-t hairline pt-12 text-sm muted">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[15px] font-semibold tracking-tight text-[var(--fg)]">Verba</span>
        </Link>
        <p>Speak it. Send it clean.</p>
        <div className="flex flex-wrap justify-center gap-5">
          <Link href="/" className="hover:text-[var(--fg)]">Home</Link>
          <Link href="/#pricing" className="hover:text-[var(--fg)]">Pricing</Link>
          <Link href="/acknowledgements" className="hover:text-[var(--fg)]">Acknowledgements</Link>
          <a href={DOWNLOAD} className="hover:text-[var(--fg)]">Download</a>
        </div>
        <p className="text-xs">© 2026 Verba · Runs on-device with open models</p>
      </footer>
    </main>
  );
}
