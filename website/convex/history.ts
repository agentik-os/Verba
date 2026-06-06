import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const push = mutation({
  args: {
    uid: v.string(), ts: v.number(),
    original: v.string(), reprompted: v.string(), profileName: v.string(), engine: v.string(),
  },
  handler: async (ctx, a) => {
    const dup = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) return;
    const tomb = await ctx.db.query("history_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;   // don't resurrect a deleted entry
    await ctx.db.insert("history", a);
  },
});

export const pull = query({
  args: { uid: v.string() },
  handler: async (ctx, a) => {
    const rows = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 400)
      .map((r) => ({ ts: r.ts, original: r.original, reprompted: r.reprompted, profileName: r.profileName, engine: r.engine }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    const row = await ctx.db.query("history").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("history_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("history_deleted", { uid: a.uid, ts: a.ts });
  },
});
