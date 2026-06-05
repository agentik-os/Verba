import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { competitors, getCompetitor, VERBA, onDeviceLabel } from "@/lib/competitors";

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export function generateStaticParams() {
  return competitors.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const c = getCompetitor(slug);
  if (!c) return {};
  return {
    title: `Verba vs ${c.name}, which dictation app should you use?`,
    description: `${c.name}: ${c.tagline} See how Verba (local-first, $9.99/mo, bring your own AI) compares.`,
  };
}

function Row({ label, verba, them, verbaGood }: { label: string; verba: string; them: string; verbaGood?: boolean }) {
  return (
    <tr className="grid-row align-top">
      <td className="p-4 muted">{label}</td>
      <td className={`p-4 ${verbaGood ? "font-medium" : ""}`}>{verba}</td>
      <td className="p-4 muted">{them}</td>
    </tr>
  );
}

export default async function Vs({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const c = getCompetitor(slug);
  if (!c) notFound();

  return (
    <main className="relative mx-auto max-w-5xl px-6 pb-24">
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <Link href="/compare" className="text-sm muted hover:text-[var(--fg)]">All comparisons →</Link>
      </nav>

      <section className="py-14 text-center">
        <p className="text-xs uppercase tracking-widest muted">Comparison</p>
        <h1 className="mx-auto mt-3 max-w-3xl text-balance text-4xl font-semibold tracking-tight sm:text-6xl">
          Verba <span className="muted">vs</span> {c.name}
        </h1>
        <p className="mx-auto mt-5 max-w-2xl text-lg muted text-balance">{c.tagline}</p>
      </section>

      {/* Side-by-side */}
      <div className="glass overflow-x-auto rounded-2xl">
        <table className="w-full min-w-[640px] border-collapse text-left text-sm">
          <thead>
            <tr>
              <th className="p-4" />
              <th className="p-4 font-semibold">Verba</th>
              <th className="p-4 font-semibold muted">{c.name}</th>
            </tr>
          </thead>
          <tbody>
            <Row label="Price" verba={VERBA.price} them={c.price} verbaGood />
            <Row label="Platforms" verba={VERBA.platforms} them={c.platforms} />
            <Row label="On-device" verba="Yes, default" them={onDeviceLabel(c.onDevice)} verbaGood={c.onDevice !== "yes"} />
            <Row label="Transcription" verba={VERBA.transcription} them={c.transcription} />
            <Row label="AI editing" verba={VERBA.aiEditing} them={c.aiEditing} />
            <Row label="Privacy" verba={VERBA.privacy} them={c.privacy} verbaGood />
          </tbody>
        </table>
      </div>

      {/* Why Verba */}
      <div className="mt-16 grid gap-4 sm:grid-cols-2">
        <div className="glass-strong rounded-2xl p-7">
          <h2 className="text-lg font-medium">Why people switch to Verba</h2>
          <ul className="mt-4 space-y-3 text-sm">
            {c.verbaWins.map((w) => (
              <li key={w} className="flex gap-2.5"><span className="tick">✓</span><span>{w}</span></li>
            ))}
          </ul>
        </div>
        <div className="glass rounded-2xl p-7">
          <h2 className="text-lg font-medium">Where {c.name} still has an edge</h2>
          <ul className="mt-4 space-y-3 text-sm muted">
            {c.theirEdge.map((e) => (
              <li key={e} className="flex gap-2.5"><span className="cross">•</span><span>{e}</span></li>
            ))}
          </ul>
          <p className="mt-5 text-xs muted">We'd rather tell you the truth than oversell. If you need mobile or Windows today, those tools win, Verba is the best native macOS, privacy-first option.</p>
        </div>
      </div>

      <div className="mt-16 text-center">
        <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
          Try Verba free
        </a>
        <p className="mt-6 text-xs muted">10,000 words/month free · Pro $9.99/mo · 7-day trial</p>
      </div>
    </main>
  );
}
