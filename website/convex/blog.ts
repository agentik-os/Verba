import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Blog articles synced from Outrank.so. The web /api/outrank-webhook route validates Outrank's
// Bearer access token, then writes here through `upsert`/`remove` — both server-gated by
// APP_TOKEN_SECRET (same pattern as feedback:record / ratelimit:bump) so nothing but our own
// server can mutate the blog. The public /blog pages read via `list` / `bySlug` / `slugs`.

function assertServer(serverKey: string) {
  if (!process.env.APP_TOKEN_SECRET || serverKey !== process.env.APP_TOKEN_SECRET) {
    throw new Error("unauthorized");
  }
}

/// Insert or update one Outrank article (dedupe by outrankId). Idempotent: re-delivering the same
/// article just rewrites it, so Outrank retries never create duplicates.
export const upsert = mutation({
  args: {
    serverKey: v.string(),
    outrankId: v.string(),
    slug: v.string(),
    title: v.string(),
    contentHtml: v.string(),
    contentMarkdown: v.optional(v.string()),
    metaDescription: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
    tags: v.optional(v.array(v.string())),
    createdAt: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    assertServer(a.serverKey);
    const now = Date.now();
    const existing = await ctx.db
      .query("blog_articles")
      .withIndex("by_outrankId", (q) => q.eq("outrankId", a.outrankId))
      .first();
    const fields = {
      outrankId: a.outrankId,
      slug: a.slug,
      title: a.title,
      contentHtml: a.contentHtml,
      contentMarkdown: a.contentMarkdown,
      metaDescription: a.metaDescription,
      imageUrl: a.imageUrl,
      tags: a.tags ?? [],
      createdAt: a.createdAt,
      updatedAt: now,
    };
    if (existing) {
      await ctx.db.patch(existing._id, fields);
      return existing._id;
    }
    return await ctx.db.insert("blog_articles", { ...fields, receivedAt: now });
  },
});

/// Remove an article Outrank unpublished/deleted (by its Outrank id). No-op if unknown.
export const remove = mutation({
  args: { serverKey: v.string(), outrankId: v.string() },
  handler: async (ctx, a) => {
    assertServer(a.serverKey);
    const existing = await ctx.db
      .query("blog_articles")
      .withIndex("by_outrankId", (q) => q.eq("outrankId", a.outrankId))
      .first();
    if (existing) await ctx.db.delete(existing._id);
    return existing ? 1 : 0;
  },
});

function sortKey(r: { createdAt?: string; receivedAt: number }): number {
  const t = r.createdAt ? Date.parse(r.createdAt) : NaN;
  return Number.isNaN(t) ? r.receivedAt : t;
}

/// Public: the article index, newest first. Omits the (large) body — just what the list cards need.
export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("blog_articles").collect();
    return all
      .sort((x, y) => sortKey(y) - sortKey(x))
      .map((r) => ({
        slug: r.slug,
        title: r.title,
        metaDescription: r.metaDescription ?? null,
        imageUrl: r.imageUrl ?? null,
        tags: r.tags,
        createdAt: r.createdAt ?? new Date(r.receivedAt).toISOString(),
      }));
  },
});

/// Public: one full article by slug (or null).
export const bySlug = query({
  args: { slug: v.string() },
  handler: async (ctx, a) => {
    const r = await ctx.db
      .query("blog_articles")
      .withIndex("by_slug", (q) => q.eq("slug", a.slug))
      .first();
    if (!r) return null;
    return {
      slug: r.slug,
      title: r.title,
      contentHtml: r.contentHtml,
      metaDescription: r.metaDescription ?? null,
      imageUrl: r.imageUrl ?? null,
      tags: r.tags,
      createdAt: r.createdAt ?? new Date(r.receivedAt).toISOString(),
      updatedAt: new Date(r.updatedAt).toISOString(),
    };
  },
});

/// Public: slugs + last-modified, for generateStaticParams and the sitemap.
export const slugs = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("blog_articles").collect();
    return all.map((r) => ({
      slug: r.slug,
      updatedAt: new Date(r.updatedAt).toISOString(),
    }));
  },
});
