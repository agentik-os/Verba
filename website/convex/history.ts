import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const push = mutation({
  args: {
    uid: v.string(), ts: v.number(),
    original: v.string(), reprompted: v.string(), profileName: v.string(), engine: v.string(),
  },
  handler: async (ctx, a) => {
    // Dedup by (uid, ts): don't insert the same dictation twice from multiple devices.
    const dup = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) return;
    await ctx.db.insert("history", a);
  },
});

export const pull = query({
  args: { uid: v.string() },
  handler: async (ctx, a) => {
    const rows = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows
      .sort((x, y) => y.ts - x.ts)
      .slice(0, 400)
      .map((r) => ({ ts: r.ts, original: r.original, reprompted: r.reprompted, profileName: r.profileName, engine: r.engine }));
  },
});
