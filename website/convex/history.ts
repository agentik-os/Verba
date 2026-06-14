import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    original: v.string(), reprompted: v.string(), profileName: v.string(), engine: v.string(),
    // "note" = dictated into a long-form note (the History safety net for deleted notes).
    source: v.optional(v.string()),
    // Version clock (ms), only sent by "Re-run" — see below.
    updatedAt: v.optional(v.number()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const dup = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      // "Re-run" rewrites the restructured text after the first push — adopt it ONLY with
      // a strictly newer version clock: a plain pushAll from a device that missed the
      // re-run carries no clock and must never clobber the rewritten text back.
      if (a.updatedAt !== undefined && (dup.updatedAt === undefined || a.updatedAt > dup.updatedAt)
          && dup.reprompted !== a.reprompted) {
        await ctx.db.patch(dup._id, {
          reprompted: a.reprompted, updatedAt: a.updatedAt,
          ...(a.source !== undefined ? { source: a.source } : {}),
        });
      }
      return;
    }
    const tomb = await ctx.db.query("history_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;   // don't resurrect a deleted entry
    const { secret, ...doc } = a;
    await ctx.db.insert("history", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 400)
      .map((r) => ({ ts: r.ts, original: r.original, reprompted: r.reprompted, profileName: r.profileName, engine: r.engine, source: r.source, updatedAt: r.updatedAt }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("history_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("history_deleted", { uid: a.uid, ts: a.ts });
  },
});

// The account's history deletion tombstones, so every device can drop a row deleted elsewhere
// and stop re-pushing it (mirrors notes:tombstones). Added for Mac↔mobile delete propagation.
export const tombstones = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("history_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => r.ts);
  },
});

// S10 + S14: delete-with-tombstones — wipe the whole cloud history for a uid.
export const wipe = mutation({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    for (const r of rows) {
      await ctx.db.insert("history_deleted", { uid: a.uid, ts: r.ts });
      await ctx.db.delete(r._id);
    }
  },
});

// Retention: drop rows older than beforeTs, tombstoned so they stay gone across devices.
export const prune = mutation({
  args: { uid: v.string(), secret: v.string(), beforeTs: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    for (const r of rows.filter((r) => r.ts < a.beforeTs)) {
      await ctx.db.insert("history_deleted", { uid: a.uid, ts: r.ts });
      await ctx.db.delete(r._id);
    }
  },
});
