import Link from "next/link";
import ThemeToggle from "@/components/ThemeToggle";
import type { Metadata } from "next";
import { competitors } from "@/lib/competitors";
import { COMPARE } from "@/lib/compare-matrix";

export const metadata: Metadata = {
  title: "Verba vs Wispr Flow, superwhisper & more — Mac dictation",
  description:
    "An honest, sourced comparison of Verba vs Wispr Flow, superwhisper, Aqua Voice, MacWhisper and 5 more — 24 dictation features, side by side.",
  alternates: { canonical: "/compare" },
  openGraph: {
    title: "Verba vs the rest — Mac dictation comparison",
    description: "Honest, sourced: 24 features across 10 Mac dictation apps, side by side.",
    url: "/compare",
    type: "article",
    images: ["/opengraph-image"],
  },
  twitter: { card: "summary_large_image", images: ["/opengraph-image"] },
};

// Breadcrumb so search/AI engines see Home › Compare as the navigation path.
const BREADCRUMB_JSONLD = {
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Home", item: "https://verba.run/" },
    { "@type": "ListItem", position: 2, name: "Compare", item: "https://verba.run/compare" },
  ],
};

// Render one matrix cell from a normalized value (yes / no / partial / ? / short text).
function Cell({ v, verba }: { v: string; verba?: boolean }) {
  const yes = v.startsWith("yes");
  const qual = yes && v.includes(":") ? v.split(":")[1] : "";
  if (yes)
    return (
      <span className={`inline-flex items-center gap-1 ${verba ? "font-semibold" : ""}`}>
        <span className="tick">✓</span>
        {qual && <span className="text-[11px] muted">{qual}</span>}
      </span>
    );
  if (v === "no") return <span className="cross">✗</span>;
  if (v === "partial") return <span className="text-[12px]" style={{ color: "var(--fg-50)" }}>~ partial</span>;
  if (v === "?") return <span className="muted">–</span>;
  return <span className={`text-[12px] ${verba ? "font-medium" : "muted"}`}>{v}</span>;
}

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";


export default function Compare() {
  return (
    <main className="mx-auto max-w-6xl px-6 pb-24">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(BREADCRUMB_JSONLD) }} />
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
          Verba vs the rest, feature by feature
        </h1>
        <p className="mx-auto mt-5 max-w-2xl text-lg muted text-balance">
          An honest, sourced comparison across 24 features. Verba is the only Mac dictation app that
          runs on-device by default, lets you bring your own AI (or your Claude plan with no key),
          and ships JARVIS — a voice agent that acts on 1,000+ connected apps. Every value below is
          verified from each vendor; nothing inflated.
        </p>
      </section>

      {/* Features-as-rows / brands-as-columns honest matrix */}
      <div className="table-scrim glass rounded-2xl">
        <div className="overflow-x-auto">
          <table className="table-pin w-full min-w-[1040px] border-collapse text-left text-sm">
            <thead>
              <tr>
                <th className="sticky left-0 z-10 bg-[var(--bg)] p-3 text-left font-medium muted">Feature</th>
                {COMPARE.columns.map((slug) => {
                  const isV = slug === "verba";
                  const inner = (
                    <span className="block text-[13px] font-semibold leading-tight">{COMPARE.names[slug]}</span>
                  );
                  return (
                    <th
                      key={slug}
                      className={`p-3 text-center align-bottom ${isV ? "bg-[var(--tint)]" : ""}`}
                    >
                      {isV ? inner : <Link href={`/vs/${slug}`} className="hover:underline">{inner}</Link>}
                      <span className="mt-1 block text-[10px] muted">{COMPARE.prices[slug]}</span>
                    </th>
                  );
                })}
              </tr>
            </thead>
            <tbody>
              {COMPARE.rows.map((row) => (
                <tr key={row.feature} className="grid-row">
                  <td className="sticky left-0 z-10 bg-[var(--bg)] p-3 text-[13px] font-medium">{row.feature}</td>
                  {COMPARE.columns.map((slug) => (
                    <td key={slug} className={`p-3 text-center ${slug === "verba" ? "bg-[var(--tint)]" : ""}`}>
                      <Cell v={(row.cells as Record<string, string>)[slug]} verba={slug === "verba"} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <p className="mt-3 text-center text-xs muted">
        Verified mid-2026 from each vendor&apos;s site, pricing page and public reviews. Found an error?
        Tell us and we&apos;ll fix it — this table stays honest.
      </p>

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
