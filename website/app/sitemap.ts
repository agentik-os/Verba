import type { MetadataRoute } from "next";
import { competitors } from "@/lib/competitors";

const BASE = "https://verba.run";

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  const staticPages: MetadataRoute.Sitemap = [
    { url: `${BASE}/`, lastModified: now, changeFrequency: "weekly", priority: 1 },
    { url: `${BASE}/compare`, lastModified: now, changeFrequency: "weekly", priority: 0.9 },
    { url: `${BASE}/changelog`, lastModified: now, changeFrequency: "daily", priority: 0.8 },
    { url: `${BASE}/acknowledgements`, lastModified: now, changeFrequency: "yearly", priority: 0.3 },
  ];

  const vsPages: MetadataRoute.Sitemap = competitors.map((c) => ({
    url: `${BASE}/vs/${c.slug}`,
    lastModified: now,
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  return [...staticPages, ...vsPages];
}
