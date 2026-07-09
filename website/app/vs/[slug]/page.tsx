import Link from "next/link";
import ThemeToggle from "@/components/ThemeToggle";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { competitors, getCompetitor, VERBA, onDeviceLabel } from "@/lib/competitors";

import SiteFooter from "@/components/SiteFooter";
const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export function generateStaticParams() {
  return competitors.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const c = getCompetitor(slug);
  if (!c) return {};
  const title = `Verba vs ${c.name}, which dictation app should you use?`;
  const description = `${c.name}: ${c.tagline} See how Verba (local-first, $9.99/mo, bring your own AI) compares.`;
  return {
    title,
    description,
    alternates: { canonical: `/vs/${slug}` },
    openGraph: { title, description, url: `/vs/${slug}`, type: "article", images: ["/opengraph-image"] },
    twitter: { card: "summary_large_image", title, description, images: ["/opengraph-image"] },
  };
}

// 3-4 quotable Q&A per competitor → FAQPage schema for AI search + a visible FAQ block.
function vsFaq(c: { name: string; price: string; onDevice: string }) {
  const local =
    c.onDevice === "yes"
      ? `Both run on-device. Verba adds AI cleanup, live translation, and JARVIS, a voice agent that acts on 1,000+ connected apps.`
      : `Verba transcribes on-device by default, so your audio never has to leave your Mac; ${c.name} sends audio to the cloud.`;
  return [
    { q: `Is Verba a good ${c.name} alternative?`, a: `Yes. Verba is a native Mac dictation app at $9.99/mo with on-device transcription, AI cleanup in any app, live translation, and a voice agent for 1,000+ apps. ${local}` },
    { q: `Verba vs ${c.name}: which is more private?`, a: local },
    { q: `How much does Verba cost vs ${c.name}?`, a: `Verba is $9.99/mo (or $84/year, or a $149 one-time lifetime), and raw dictation is free forever and unlimited with no card, plus a 7-day Pro trial; ${c.name} is ${c.price}. Verba lets you bring your own AI key or use a local model, with no markup.` },
  ];
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

  const faq = vsFaq(c);
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Home", item: "https://verba.run/" },
          { "@type": "ListItem", position: 2, name: "Compare", item: "https://verba.run/compare" },
          { "@type": "ListItem", position: 3, name: `Verba vs ${c.name}`, item: `https://verba.run/vs/${slug}` },
        ],
      },
      {
        "@type": "FAQPage",
        mainEntity: faq.map((f) => ({
          "@type": "Question",
          name: f.q,
          acceptedAnswer: { "@type": "Answer", text: f.a },
        })),
      },
    ],
  };

  return (
    <main className="relative mx-auto max-w-5xl px-6 pb-24">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
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
          <Link href="/compare" className="text-sm muted hover:text-[var(--fg)]">All comparisons →</Link>
        </div>
      </nav>

      <section className="py-14 text-center">
        <p className="text-xs uppercase tracking-widest muted">Comparison</p>
        <h1 className="mx-auto mt-3 max-w-3xl text-balance text-4xl font-semibold tracking-tight sm:text-6xl">
          Verba <span className="muted">vs</span> {c.name}
        </h1>
        <p className="mx-auto mt-5 max-w-2xl text-lg muted text-balance">{c.tagline}</p>
      </section>

      {/* Side-by-side */}
      <div className="table-scrim glass rounded-2xl">
      <div className="overflow-x-auto">
        <table className="table-pin w-full min-w-[640px] border-collapse text-left text-sm">
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

      <section className="mt-16">
        <h2 className="text-center text-2xl font-semibold tracking-tight">Verba vs {c.name}, FAQ</h2>
        <div className="mx-auto mt-8 grid max-w-3xl gap-2.5">
          {faq.map((f) => (
            <details key={f.q} className="group glass rounded-xl px-6 py-5">
              <summary className="cursor-pointer list-none font-medium">{f.q}</summary>
              <p className="mt-3 text-sm muted">{f.a}</p>
            </details>
          ))}
        </div>
      </section>

      <div className="mt-16 text-center">
        <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
          Try Verba free
        </a>
        <p className="mt-6 text-xs muted">Unlimited raw dictation free forever · Pro $9.99/mo</p>
      </div>
    <SiteFooter />
    </main>
  );
}
