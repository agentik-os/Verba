import Link from "next/link";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import ThemeToggle from "@/components/ThemeToggle";
import SiteFooter from "@/components/SiteFooter";
import { convexCall } from "@/lib/convex";

// Rebuild at most every 5 min; new articles arrive via the Outrank webhook and are picked up on
// the next regeneration (or immediately on a cache miss for a brand-new slug).
export const revalidate = 300;

export const metadata: Metadata = {
  title: "Blog, Verba, the Mac Voice Agent",
  description:
    "Guides, deep dives and updates on private on-device dictation, the JARVIS voice agent, and getting more done by voice on your Mac.",
  alternates: { canonical: "/blog" },
  openGraph: {
    title: "Verba Blog, dictation and voice agents for Mac",
    description:
      "Guides and deep dives on private on-device dictation, the JARVIS voice agent, and doing more by voice on your Mac.",
    url: "/blog",
    type: "website",
    images: ["/opengraph-image"],
  },
  twitter: { card: "summary_large_image", images: ["/opengraph-image"] },
};

type ListItem = {
  slug: string;
  title: string;
  metaDescription: string | null;
  imageUrl: string | null;
  tags: string[];
  createdAt: string;
};

async function getArticles(): Promise<ListItem[]> {
  try {
    return await convexCall<ListItem[]>("query", "blog:list", {});
  } catch {
    return [];
  }
}

function fmtDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
}

const Mark = () => (
  <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
    <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
  </span>
);

export default async function Blog() {
  const articles = await getArticles();

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: "Verba Blog",
    url: "https://verba.run/blog",
    publisher: { "@type": "Organization", name: "Agentik OS", logo: "https://verba.run/icon.png" },
    blogPost: articles.slice(0, 20).map((a) => ({
      "@type": "BlogPosting",
      headline: a.title,
      url: `https://verba.run/blog/${a.slug}`,
      datePublished: a.createdAt,
      ...(a.metaDescription ? { description: a.metaDescription } : {}),
      ...(a.imageUrl ? { image: a.imageUrl } : {}),
    })),
  };

  return (
    <main className="relative mx-auto max-w-4xl px-6 pb-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <Mark />
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
        </div>
      </nav>

      <section className="py-14 text-center">
        <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">
          The Verba blog
        </div>
        <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-6xl">Blog</h1>
        <p className="mx-auto mt-5 max-w-xl text-lg muted text-balance">
          Guides and deep dives on private, on-device dictation, the JARVIS voice agent, and getting
          more done by voice on your Mac.
        </p>
      </section>

      {articles.length === 0 ? (
        <div className="glass mb-20 rounded-3xl p-10 text-center sm:mb-28">
          <p className="muted">New articles are on the way. Check back soon.</p>
        </div>
      ) : (
        // mb-* keeps the last row off the footer; every other page gets that gap from its CTA section.
        <div className="mb-20 grid gap-5 sm:mb-28 sm:grid-cols-2">
          {articles.map((a, i) => (
            <Reveal key={a.slug} delay={i * 60}>
              <Link href={`/blog/${a.slug}`} className="group block h-full">
                <article className="glass lift flex h-full flex-col overflow-hidden rounded-3xl">
                  {a.imageUrl && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={a.imageUrl}
                      alt={a.title}
                      loading="lazy"
                      className="aspect-[16/9] w-full object-cover"
                    />
                  )}
                  <div className="flex flex-1 flex-col p-6">
                    <div className="flex flex-wrap items-center gap-2">
                      {a.createdAt && <span className="mono-meta">{fmtDate(a.createdAt)}</span>}
                      {a.tags.slice(0, 2).map((t) => (
                        <span key={t} className="rounded-full bg-[var(--tint)] px-2.5 py-0.5 text-xs muted">{t}</span>
                      ))}
                    </div>
                    <h2 className="mt-3 text-xl font-semibold tracking-tight group-hover:text-[var(--fg)]">{a.title}</h2>
                    {a.metaDescription && (
                      <p className="mt-2 line-clamp-3 text-sm leading-relaxed muted">{a.metaDescription}</p>
                    )}
                    <span className="mt-4 inline-flex items-center gap-1 text-sm font-medium">
                      Read
                      <span aria-hidden className="transition-transform group-hover:translate-x-0.5">→</span>
                    </span>
                  </div>
                </article>
              </Link>
            </Reveal>
          ))}
        </div>
      )}

      <SiteFooter />
    </main>
  );
}
