import type { MetadataRoute } from "next";
import { competitors } from "@/lib/competitors";

const BASE = "https://verba.run";

export default function sitemap(): MetadataRoute.Sitemap {
  const staticPages: MetadataRoute.Sitemap = [
    { url: `${BASE}/`, changeFrequency: "weekly", priority: 1 },
    { url: `${BASE}/compare`, changeFrequency: "monthly", priority: 0.8 },
    { url: `${BASE}/changelog`, changeFrequency: "weekly", priority: 0.6 },
    { url: `${BASE}/acknowledgements`, changeFrequency: "yearly", priority: 0.3 },
  ];

  const vsPages: MetadataRoute.Sitemap = competitors.map((c) => ({
    url: `${BASE}/vs/${c.slug}`,
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  return [...staticPages, ...vsPages];
}
