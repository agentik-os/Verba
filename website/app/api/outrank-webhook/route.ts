import { NextRequest, NextResponse } from "next/server";
import { timingSafeEqual } from "crypto";
import { marked } from "marked";
import { convexCall } from "@/lib/convex";

export const runtime = "nodejs";

// Outrank.so webhook receiver. When an article is published (or deleted) in Outrank, Outrank POSTs
// here with `Authorization: Bearer <access token>`. We validate the token against
// OUTRANK_WEBHOOK_TOKEN (server-side only, never in committed code), then persist the articles to
// Convex (blog_articles), which the public /blog pages read. Convex is our durable store — the same
// pattern the feedback pipeline uses — so a published article is never lost between deploys.
//
// Payload (Outrank "Custom Integration" webhook):
//   { "event_type": "publish_articles", "timestamp": "...", "data": { "articles": [ {
//       id, title, content_markdown, content_html, meta_description, created_at, image_url,
//       slug, tags: [] } ] } }
//   { "event_type": "delete_articles", "data": { "article_ids": ["..."] } }
//
// Set the webhook URL in Outrank to:  https://verba.run/api/outrank-webhook

type OutrankArticle = {
  id?: string;
  title?: string;
  content_markdown?: string;
  content_html?: string;
  meta_description?: string;
  created_at?: string;
  image_url?: string;
  slug?: string;
  tags?: string[];
};

type OutrankPayload = {
  event_type?: string;
  timestamp?: string;
  data?: {
    articles?: OutrankArticle[];
    article_ids?: string[];
  };
};

/** Constant-time Bearer-token check against OUTRANK_WEBHOOK_TOKEN. */
function tokenValid(authHeader: string | null): boolean {
  const expected = process.env.OUTRANK_WEBHOOK_TOKEN;
  if (!expected) return false;
  const got = (authHeader ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!got) return false;
  const a = Buffer.from(got);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

/** Best-effort slug: use Outrank's slug, else derive one from the title. */
function slugify(article: OutrankArticle): string {
  if (article.slug && article.slug.trim()) return article.slug.trim();
  return (article.title ?? "untitled")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "untitled";
}

export async function POST(req: NextRequest) {
  if (!process.env.OUTRANK_WEBHOOK_TOKEN || !process.env.APP_TOKEN_SECRET) {
    return NextResponse.json({ ok: false, error: "Webhook not configured" }, { status: 503 });
  }
  if (!tokenValid(req.headers.get("authorization"))) {
    return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
  }

  let body: OutrankPayload;
  try {
    body = (await req.json()) as OutrankPayload;
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
  }

  const serverKey = process.env.APP_TOKEN_SECRET;
  const event = body.event_type ?? "publish_articles";

  try {
    // Deletions: Outrank sends article ids to unpublish.
    if (event === "delete_articles") {
      const ids = body.data?.article_ids ?? [];
      let removed = 0;
      for (const id of ids) {
        if (!id) continue;
        removed += await convexCall<number>("mutation", "blog:remove", {
          serverKey,
          outrankId: String(id),
        });
      }
      return NextResponse.json({ ok: true, event, removed });
    }

    // Publish (default): upsert each article.
    const articles = body.data?.articles ?? [];
    let processed = 0;
    for (const art of articles) {
      const outrankId = art.id ? String(art.id) : slugify(art);
      const contentHtml =
        (art.content_html && art.content_html.trim())
          ? art.content_html
          : (art.content_markdown ? (marked.parse(art.content_markdown, { async: false }) as string) : "");
      await convexCall("mutation", "blog:upsert", {
        serverKey,
        outrankId,
        slug: slugify(art),
        title: (art.title ?? "Untitled").trim(),
        contentHtml,
        contentMarkdown: art.content_markdown,
        metaDescription: art.meta_description,
        imageUrl: art.image_url,
        tags: Array.isArray(art.tags) ? art.tags : [],
        createdAt: art.created_at,
      });
      processed++;
    }
    return NextResponse.json({ ok: true, event, processed });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to store articles";
    return NextResponse.json({ ok: false, error: msg }, { status: 502 });
  }
}

// A quick liveness probe (no secret) so you can confirm the route is deployed.
export async function GET() {
  return NextResponse.json({
    ok: true,
    receiver: "outrank-webhook",
    configured: Boolean(process.env.OUTRANK_WEBHOOK_TOKEN && process.env.APP_TOKEN_SECRET),
  });
}
