import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/// Server-side admin secret. adminList is gated by an exact match against this
/// constant — anyone listing feedback must pass it. Rotate by regenerating.
const ADMIN_SECRET = "df407ce003d909a5e48505f32eed72f1e990d57cde596fcea91bdf7f4d39a2aa";

/// Issue a short-lived upload URL the app PUTs the screenshot PNG to.
export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});

/// Insert a feedback row. Screenshot is the storageId returned by the upload URL PUT.
export const submit = mutation({
  args: {
    uid: v.string(),
    alias: v.string(),
    text: v.string(),
    version: v.optional(v.string()),
    screenshotId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, a) => {
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

/// Admin-only listing. Gated by a secret compared to the server-side ADMIN_SECRET.
/// Returns [] on a wrong/missing secret. On success: all feedback newest-first,
/// each with a resolvable screenshot URL (or null).
export const adminList = query({
  args: { secret: v.string() },
  handler: async (ctx, a) => {
    if (a.secret !== ADMIN_SECRET) return [];
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
