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
