import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/// Durable, DEDUPED store for auto error/crash reports written by the web /api/diagnostics route.
/// One row per distinct `signature`; repeats just bump the counters. Server-gated by
/// APP_TOKEN_SECRET (same pattern as feedback:record) so the public can't insert directly.
///
/// Returns enough for the route to decide what to do in Linear:
///   • isNew          — first time we've ever seen this signature → the route files a Linear issue.
///   • seenNewVersion — a version not previously recorded reported it → the route adds a comment
///                       ("still happening in vX"), which is exactly how we tell whether a fix landed.
export const record = mutation({
  args: {
    serverKey: v.string(),
    signature: v.string(),
    kind: v.string(),
    message: v.string(),
    version: v.optional(v.string()),
    os: v.optional(v.string()),
    context: v.optional(v.string()),
    uid: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const now = Date.now();
    const version = (a.version ?? "").slice(0, 32);
    const existing = await ctx.db
      .query("diagnostics")
      .withIndex("by_signature", (q) => q.eq("signature", a.signature))
      .unique();

    if (!existing) {
      const id = await ctx.db.insert("diagnostics", {
        signature: a.signature,
        kind: a.kind,
        message: a.message.slice(0, 4000),
        count: 1,
        users: a.uid ? 1 : 0,
        versions: version ? [version] : [],
        lastOS: a.os,
        lastContext: a.context,
        createdAt: now,
        updatedAt: now,
      });
      return { isNew: true, seenNewVersion: false, count: 1, id, linearId: null as string | null };
    }

    const seenNewVersion = !!version && !existing.versions.includes(version);
    await ctx.db.patch(existing._id, {
      count: existing.count + 1,
      users: existing.users + (a.uid ? 1 : 0),   // best-effort (double-counts a repeat from one uid)
      versions: seenNewVersion ? [...existing.versions, version].slice(-20) : existing.versions,
      lastOS: a.os ?? existing.lastOS,
      lastContext: a.context ?? existing.lastContext,
      updatedAt: now,
    });
    return {
      isNew: false,
      seenNewVersion,
      count: existing.count + 1,
      id: existing._id,
      linearId: existing.linearId ?? null,
    };
  },
});

/// Attach the filed Linear issue id/url to a diagnostics row (called right after issueCreate).
export const attachLinear = mutation({
  args: { serverKey: v.string(), signature: v.string(), linearId: v.string(), linearUrl: v.string() },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const row = await ctx.db
      .query("diagnostics")
      .withIndex("by_signature", (q) => q.eq("signature", a.signature))
      .unique();
    if (row) await ctx.db.patch(row._id, { linearId: a.linearId, linearUrl: a.linearUrl });
  },
});

/// Admin read: the top error signatures by count (gated by ADMIN_SECRET).
export const top = query({
  args: { adminSecret: v.string(), limit: v.optional(v.number()) },
  handler: async (ctx, a) => {
    if (!process.env.ADMIN_SECRET || a.adminSecret !== process.env.ADMIN_SECRET) {
      throw new Error("unauthorized");
    }
    const rows = await ctx.db.query("diagnostics").collect();
    rows.sort((x, y) => y.count - x.count);
    return rows.slice(0, a.limit ?? 50);
  },
});
