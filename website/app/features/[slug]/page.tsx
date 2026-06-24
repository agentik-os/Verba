import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import SiteNav from "@/components/SiteNav";
import Reveal from "@/components/Reveal";
import { FEATURES, getFeature } from "@/lib/features";

import SiteFooter from "@/components/SiteFooter";
const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export function generateStaticParams() {
  return FEATURES.map((f) => ({ slug: f.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const f = getFeature(slug);
  if (!f) return {};
  return {
    title: f.metaTitle,
    description: f.metaDescription,
    alternates: { canonical: `/features/${slug}` },
    openGraph: { title: f.metaTitle, description: f.metaDescription, url: `/features/${slug}`, type: "article", images: ["/opengraph-image"] },
    twitter: { card: "summary_large_image", title: f.metaTitle, description: f.metaDescription, images: ["/opengraph-image"] },
  };
}

export default async function FeaturePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const f = getFeature(slug);
  if (!f) notFound();

  const others = FEATURES.filter((x) => x.slug !== slug);
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "TechArticle",
        headline: f.h1,
        description: f.metaDescription,
        url: `https://verba.run/features/${slug}`,
        inLanguage: "en",
        about: { "@type": "SoftwareApplication", name: "Verba", operatingSystem: "macOS 14+" },
        publisher: { "@id": "https://verba.run/#org" },
      },
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Home", item: "https://verba.run/" },
          { "@type": "ListItem", position: 2, name: "Features", item: "https://verba.run/features" },
          { "@type": "ListItem", position: 3, name: f.navLabel, item: `https://verba.run/features/${slug}` },
        ],
      },
      {
        "@type": "FAQPage",
        mainEntity: f.faq.map((q) => ({
          "@type": "Question",
          name: q.q,
          acceptedAnswer: { "@type": "Answer", text: q.a },
        })),
      },
    ],
  };

  return (
    <main className="relative mx-auto max-w-5xl px-6 pb-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <div className="aurora" />
      <SiteNav />

      <article className="mx-auto max-w-3xl py-12">
        <Reveal>
          <Link href="/features" className="text-xs font-semibold uppercase tracking-wide muted hover:text-[var(--fg)]">← All features</Link>
          <p className="mt-4 mono-meta">{f.eyebrow}</p>
          <h1 className="mt-2 text-balance text-4xl font-semibold tracking-tight sm:text-5xl">{f.h1}</h1>
          <p className="mt-5 text-lg leading-relaxed muted">{f.lead}</p>
          <div className="mt-7 flex flex-wrap gap-3">
            <a href={DOWNLOAD} className="rounded-full bg-[var(--fg)] px-6 py-2.5 text-sm font-medium text-[var(--bg)] hover:opacity-90">Download for macOS</a>
            <Link href="/#pricing" className="rounded-full glass px-6 py-2.5 text-sm font-medium hover:opacity-90">Pricing</Link>
          </div>
        </Reveal>

        <div className="mt-12 space-y-5">
          {f.sections.map((s, i) => (
            <Reveal key={s.h2} delay={i * 30}>
              <section className="glass lift rounded-3xl p-6 sm:p-7">
                <h2 className="text-xl font-semibold tracking-tight">{s.h2}</h2>
                <p className="mt-3 text-sm leading-relaxed muted">{s.body}</p>
                {s.bullets && (
                  <ul className="mt-4 space-y-2">
                    {s.bullets.map((b) => (
                      <li key={b} className="flex gap-3 text-sm leading-relaxed">
                        <span className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--fg)] opacity-50" />
                        <span className="muted">{b}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            </Reveal>
          ))}
        </div>

        {/* FAQ, visible + already in FAQPage schema above */}
        <div className="mt-14">
          <h2 className="text-2xl font-semibold tracking-tight">Questions, answered</h2>
          <div className="mt-6 grid gap-2.5">
            {f.faq.map((q) => (
              <details key={q.q} className="group card r-card px-6 py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium">
                  {q.q}
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full border border-[var(--border)] bg-[var(--tint)] text-lg leading-none transition-transform duration-300 group-open:rotate-45">+</span>
                </summary>
                <p className="mt-4 text-sm leading-relaxed muted">{q.a}</p>
              </details>
            ))}
          </div>
        </div>

        {/* Cross-links to the other feature pages, internal linking + discovery */}
        <div className="mt-16">
          <p className="mono-meta">More features</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {others.map((o) => (
              <Link key={o.slug} href={`/features/${o.slug}`} className="glass lift rounded-2xl p-5 transition hover:opacity-90">
                <div className="text-sm font-semibold">{o.navLabel}</div>
                <div className="mt-1 text-xs muted line-clamp-2">{o.metaDescription}</div>
              </Link>
            ))}
          </div>
        </div>
      </article>
    <SiteFooter />
    </main>
  );
}
