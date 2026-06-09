import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Per-day dictation stats, keyed by account uid, so Insights / Total Words follow the user
// across Macs and survive a reinstall. The app holds the authoritative per-day total for the
// device; we store the MAX per (uid, day) so a re-push is idempotent and the common
// single-device-per-day case is exact (multi-device same-day takes the larger, a safe approx).
export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), day: v.string(),
    words: v.number(), seconds: v.number(), count: v.number(),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("stats").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("day"), a.day)).first();
    const now = Date.now();
    if (row) {
      await ctx.db.patch(row._id, {
        words: Math.max(row.words, a.words),
        seconds: Math.max(row.seconds, a.seconds),
        count: Math.max(row.count, a.count),
        updated: now,
      });
    } else {
      const { secret, ...doc } = a;
      await ctx.db.insert("stats", { ...doc, updated: now });
    }
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("stats").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => ({ day: r.day, words: r.words, seconds: r.seconds, count: r.count }));
  },
});
