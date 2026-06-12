import Link from "next/link";
import type { Metadata } from "next";
import SiteNav from "@/components/SiteNav";
import Reveal from "@/components/Reveal";
import { FEATURES } from "@/lib/features";

export const metadata: Metadata = {
  title: "Features — Verba AI Dictation for Mac",
  description:
    "Everything Verba does: the JARVIS voice agent, AI dictation modes, voice notes, voice tasks, live translation, and screen-aware Context mode — all on your Mac.",
  alternates: { canonical: "/features" },
  openGraph: {
    title: "Verba Features — AI Dictation for Mac",
    description: "JARVIS voice agent, dictation modes, voice notes, voice tasks, live translation, and Context mode.",
    url: "/features",
    type: "website",
    images: ["/opengraph-image"],
  },
  twitter: { card: "summary_large_image", images: ["/opengraph-image"] },
};

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

const JSONLD = {
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Home", item: "https://verba.run/" },
    { "@type": "ListItem", position: 2, name: "Features", item: "https://verba.run/features" },
  ],
};

export default function FeaturesHub() {
  return (
    <main className="relative mx-auto max-w-5xl px-6 pb-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(JSONLD) }} />
      <div className="aurora" />
      <SiteNav />

      <section className="py-14 text-center">
        <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">Features</div>
        <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-5xl">Everything Verba does</h1>
        <p className="mx-auto mt-5 max-w-2xl text-lg muted text-balance">
          Speak, and Verba turns it into clean text, a structured note, a translated message, an
          organized task list, or a real action across your apps. Pick a capability to go deep.
        </p>
        <div className="mt-7 flex justify-center gap-3">
          <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-6 py-2.5 text-sm font-medium text-[var(--bg)] hover:opacity-90">Download for macOS</a>
          <Link href="/compare" className="rounded-full glass px-6 py-2.5 text-sm font-medium hover:opacity-90">Compare</Link>
        </div>
      </section>

      <div className="grid gap-4 sm:grid-cols-2">
        {FEATURES.map((f, i) => (
          <Reveal key={f.slug} delay={i * 40}>
            <Link href={`/features/${f.slug}`} className="glass lift block h-full rounded-3xl p-6 transition hover:opacity-95">
              <p className="mono-meta">{f.eyebrow}</p>
              <h2 className="mt-2 text-lg font-semibold tracking-tight">{f.h1}</h2>
              <p className="mt-2 text-sm leading-relaxed muted">{f.metaDescription}</p>
              <span className="mt-4 inline-block text-sm font-medium">Learn more →</span>
            </Link>
          </Reveal>
        ))}
      </div>
    </main>
  );
}
