import Link from "next/link";
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
        <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
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
      <div className="glass overflow-x-auto rounded-2xl">
        <table className="w-full min-w-[760px] border-collapse text-left text-sm">
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
              <td className="p-4">Local, audio never leaves your Mac</td>
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
        <p className="mt-3 text-xs muted">Free 10,000 words/month · Pro $9.99/mo · cancel anytime</p>
      </div>
    </main>
  );
}
