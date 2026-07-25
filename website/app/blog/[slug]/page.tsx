import Link from "next/link";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import ThemeToggle from "@/components/ThemeToggle";
import SiteFooter from "@/components/SiteFooter";
import { convexCall } from "@/lib/convex";

export const revalidate = 300;

type Article = {
  slug: string;
  title: string;
  contentHtml: string;
  metaDescription: string | null;
  imageUrl: string | null;
  tags: string[];
  createdAt: string;
  updatedAt: string;
};

async function getArticle(slug: string): Promise<Article | null> {
  try {
    return await convexCall<Article | null>("query", "blog:bySlug", { slug });
  } catch {
    return null;
  }
}

// Pre-render known slugs at build; unknown/new ones render on demand (dynamicParams default true).
export async function generateStaticParams(): Promise<{ slug: string }[]> {
  try {
    const rows = await convexCall<{ slug: string }[]>("query", "blog:slugs", {});
    return rows.map((r) => ({ slug: r.slug }));
  } catch {
    return [];
  }
}

export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> }
): Promise<Metadata> {
  const { slug } = await params;
  const article = await getArticle(slug);
  if (!article) return { title: "Article not found, Verba" };
  const description = article.metaDescription ?? undefined;
  const canonical = `/blog/${article.slug}`;
  const images = article.imageUrl ? [article.imageUrl] : ["/opengraph-image"];
  return {
    title: `${article.title}, Verba`,
    description,
    alternates: { canonical },
    openGraph: {
      title: article.title,
      description,
      url: canonical,
      type: "article",
      publishedTime: article.createdAt,
      modifiedTime: article.updatedAt,
      images,
    },
    twitter: { card: "summary_large_image", title: article.title, description, images },
  };
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

export default async function BlogArticle(
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const article = await getArticle(slug);
  if (!article) notFound();

  // Rough word count off the rendered body: search and AI engines use it to judge depth.
  const wordCount = article.contentHtml.replace(/<[^>]*>/g, " ").split(/\s+/).filter(Boolean).length;

  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BlogPosting",
        headline: article.title,
        url: `https://verba.run/blog/${article.slug}`,
        datePublished: article.createdAt,
        dateModified: article.updatedAt,
        inLanguage: "en",
        wordCount,
        isPartOf: { "@type": "Blog", "@id": "https://verba.run/blog" },
        mainEntityOfPage: { "@type": "WebPage", "@id": `https://verba.run/blog/${article.slug}` },
        author: { "@type": "Organization", name: "Agentik OS", url: "https://verba.run" },
        publisher: {
          "@type": "Organization",
          name: "Agentik OS",
          logo: { "@type": "ImageObject", url: "https://verba.run/icon.png" },
        },
        ...(article.tags.length ? { keywords: article.tags.join(", ") } : {}),
        ...(article.metaDescription ? { description: article.metaDescription } : {}),
        ...(article.imageUrl ? { image: article.imageUrl } : {}),
      },
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Verba", item: "https://verba.run" },
          { "@type": "ListItem", position: 2, name: "Blog", item: "https://verba.run/blog" },
          {
            "@type": "ListItem",
            position: 3,
            name: article.title,
            item: `https://verba.run/blog/${article.slug}`,
          },
        ],
      },
    ],
  };

  return (
    <main className="relative mx-auto max-w-3xl px-6 pb-28">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <Mark />
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/blog" className="text-sm muted hover:text-[var(--fg)]">← Blog</Link>
        </div>
      </nav>

      <article className="py-8">
        <header>
          <div className="flex flex-wrap items-center gap-2">
            {article.createdAt && <span className="mono-meta">{fmtDate(article.createdAt)}</span>}
            {article.tags.map((t) => (
              <span key={t} className="rounded-full bg-[var(--tint)] px-2.5 py-0.5 text-xs muted">{t}</span>
            ))}
          </div>
          <h1 className="mt-4 text-balance text-4xl font-semibold tracking-tight sm:text-5xl">{article.title}</h1>
          {article.metaDescription && (
            <p className="mt-5 text-lg leading-relaxed muted text-balance">{article.metaDescription}</p>
          )}
        </header>

        {article.imageUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={article.imageUrl}
            alt={article.title}
            // Intrinsic 16:9 so the browser reserves the box before the image lands (no CLS).
            // This is the LCP element, so it loads eagerly at high priority.
            width={1600}
            height={900}
            fetchPriority="high"
            className="mt-8 w-full rounded-3xl border hairline object-cover"
          />
        )}

        {/* Body is Outrank-authored HTML (Bearer-authenticated source). Styled via .article-body. */}
        <div
          className="article-body mt-10"
          dangerouslySetInnerHTML={{ __html: article.contentHtml }}
        />
      </article>

      <section className="mt-16 text-center">
        <div className="glass-strong rounded-3xl p-10">
          <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">Dictate. It acts.</h2>
          <p className="mx-auto mt-3 max-w-md muted text-balance">
            Verba is the private Mac voice agent, on-device voice-to-text that acts across 1,000+ apps.
          </p>
          <a
            href="https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg"
            className="mt-7 inline-block rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90"
          >
            Download for macOS
          </a>
        </div>
      </section>

      <SiteFooter />
    </main>
  );
}
