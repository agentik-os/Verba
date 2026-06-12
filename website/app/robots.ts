import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: "*", allow: "/", disallow: ["/account", "/app-auth", "/api"] },
      // Explicitly welcome AI search / answer-engine crawlers (GEO): being citable in ChatGPT,
      // Claude, Perplexity and Google AI Overviews drives discovery for the dictation niche.
      {
        userAgent: [
          "GPTBot", "OAI-SearchBot", "ChatGPT-User", "ClaudeBot", "anthropic-ai", "Claude-Web",
          "PerplexityBot", "Perplexity-User", "Google-Extended", "Applebot-Extended", "CCBot",
        ],
        allow: "/",
        disallow: ["/account", "/app-auth", "/api"],
      },
    ],
    sitemap: "https://verba.run/sitemap.xml",
  };
}
