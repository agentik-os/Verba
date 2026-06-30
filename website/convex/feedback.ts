import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

/// Issue a short-lived upload URL the app PUTs the screenshot PNG to.
/// S15: only a registered device may mint one (stops anonymous storage abuse).
export const generateUploadUrl = mutation({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    return await ctx.storage.generateUploadUrl();
  },
});

/// Insert a feedback row. Screenshot is the storageId returned by the upload URL PUT.
export const submit = mutation({
  args: {
    uid: v.string(),
    secret: v.string(),
    alias: v.string(),
    text: v.string(),
    version: v.optional(v.string()),
    screenshotId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const text = a.text.trim().slice(0, 4000);
    if (!text) return;
    await ctx.db.insert("feedback", {
      uid: a.uid,
      alias: a.alias,
      text,
      version: a.version,
      screenshot: a.screenshotId,
      createdAt: Date.now(),
      status: "new",
    });
  },
});

/// Durable record written by the web /api/feedback route, BEFORE it calls Linear, so a Linear
/// outage never loses a feedback again. Server-gated by APP_TOKEN_SECRET (same pattern as
/// ratelimit:bump) — the public can't insert rows by hitting this directly. Returns the row id.
export const record = mutation({
  args: {
    serverKey: v.string(),
    uid: v.optional(v.string()),
    alias: v.optional(v.string()),
    text: v.string(),
    version: v.optional(v.string()),
    os: v.optional(v.string()),
    engine: v.optional(v.string()),
    mode: v.optional(v.string()),
    email: v.optional(v.string()),
    screenshotUrl: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const text = a.text.trim().slice(0, 4000);
    if (!text) throw new Error("empty");
    return await ctx.db.insert("feedback", {
      uid: a.uid ?? "",
      alias: a.alias ?? "",
      text,
      version: a.version,
      os: a.os,
      engine: a.engine,
      mode: a.mode,
      email: a.email,
      screenshotUrl: a.screenshotUrl,
      createdAt: Date.now(),
      status: "new",
      synced: false,
    });
  },
});

/// Stamp a recorded feedback as filed in Linear (server-gated). Best-effort from the route: a
/// failure here just leaves synced:false — still a durable, recoverable record.
export const markSynced = mutation({
  args: {
    serverKey: v.string(),
    id: v.id("feedback"),
    linearId: v.optional(v.string()),
    linearUrl: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    await ctx.db.patch(a.id, { synced: true, linearId: a.linearId, linearUrl: a.linearUrl });
  },
});

/// Admin-only listing, gated by the ADMIN_SECRET Convex env var (S15: the old
/// hardcoded constant is burned in git history — the env value must be a NEW secret).
/// Returns [] on a wrong/missing secret. On success: all feedback newest-first,
/// each with a resolvable screenshot URL (or null).
export const adminList = query({
  args: { secret: v.string() },
  handler: async (ctx, a) => {
    if (!process.env.ADMIN_SECRET || a.secret !== process.env.ADMIN_SECRET) return [];
    const rows = await ctx.db.query("feedback").collect();
    rows.sort((x, y) => y.createdAt - x.createdAt);
    return await Promise.all(
      rows.map(async (r) => ({
        id: r._id,
        uid: r.uid,
        alias: r.alias,
        text: r.text,
        version: r.version ?? null,
        status: r.status ?? null,
        createdAt: r.createdAt,
        screenshotUrl: r.screenshot ? await ctx.storage.getUrl(r.screenshot) : null,
      }))
    );
  },
});
