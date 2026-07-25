import type { MetadataRoute } from "next";
import { competitors } from "@/lib/competitors";
import { FEATURES } from "@/lib/features";
import { convexCall } from "@/lib/convex";

const BASE = "https://verba.run";

// Regenerate at most every 5 min, same cadence as the blog pages. Without this the sitemap is
// frozen at build time, so an article pushed by the Outrank webhook would stay out of it until
// the next deploy.
export const revalidate = 300;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();
  const staticPages: MetadataRoute.Sitemap = [
    { url: BASE, lastModified: now, changeFrequency: "weekly", priority: 1 },
    { url: `${BASE}/best-mac-dictation-app`, lastModified: now, changeFrequency: "monthly", priority: 0.95 },
    { url: `${BASE}/compare`, lastModified: now, changeFrequency: "weekly", priority: 0.9 },
    { url: `${BASE}/features`, lastModified: now, changeFrequency: "weekly", priority: 0.9 },
    { url: `${BASE}/docs`, lastModified: now, changeFrequency: "weekly", priority: 0.8 },
    { url: `${BASE}/changelog`, lastModified: now, changeFrequency: "daily", priority: 0.8 },
    { url: `${BASE}/blog`, lastModified: now, changeFrequency: "daily", priority: 0.7 },
    { url: `${BASE}/acknowledgements`, lastModified: now, changeFrequency: "yearly", priority: 0.3 },
    { url: `${BASE}/privacy`, lastModified: now, changeFrequency: "yearly", priority: 0.3 },
    { url: `${BASE}/terms`, lastModified: now, changeFrequency: "yearly", priority: 0.3 },
    { url: `${BASE}/contact`, lastModified: now, changeFrequency: "yearly", priority: 0.3 },
  ];

  const vsPages: MetadataRoute.Sitemap = competitors.map((c) => ({
    url: `${BASE}/vs/${c.slug}`,
    lastModified: now,
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  const featurePages: MetadataRoute.Sitemap = FEATURES.map((f) => ({
    url: `${BASE}/features/${f.slug}`,
    lastModified: now,
    changeFrequency: "monthly",
    priority: 0.8,
  }));

  // Blog articles (pushed via the Outrank webhook, stored in Convex). Best-effort: an empty or
  // unreachable Convex just yields no blog entries rather than failing the whole sitemap.
  let blogPages: MetadataRoute.Sitemap = [];
  try {
    const rows = await convexCall<{ slug: string; updatedAt: string }[]>("query", "blog:slugs", {});
    blogPages = rows.map((r) => ({
      url: `${BASE}/blog/${r.slug}`,
      lastModified: new Date(r.updatedAt),
      changeFrequency: "monthly",
      priority: 0.7,
    }));
  } catch {
    blogPages = [];
  }

  return [...staticPages, ...featurePages, ...vsPages, ...blogPages];
}
