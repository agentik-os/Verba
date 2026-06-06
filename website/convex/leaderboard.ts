import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("scores").collect();
    return all
      .sort((a, b) => b.words - a.words)
      .map((w) => ({ uid: w.uid, alias: w.alias, words: w.words, wpm: w.wpm, streak: w.streak, saved: w.saved ?? 0 }));
  },
});

export const board = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("scores").collect();
    return all.map((s) => ({ uid: s.uid, alias: s.alias, words: s.words, wpm: s.wpm, streak: s.streak, saved: s.saved ?? 0 }));
  },
});

export const submit = mutation({
  args: {
    uid: v.string(), alias: v.string(),
    words: v.number(), wpm: v.number(), streak: v.number(), saved: v.optional(v.number()),
  },
  handler: async (ctx, a) => {
    const existing = await ctx.db.query("scores").withIndex("by_uid", (q) => q.eq("uid", a.uid)).unique();
    const doc = { uid: a.uid, alias: a.alias, words: a.words, wpm: a.wpm, streak: a.streak, saved: a.saved ?? 0, updated: Date.now() };
    if (existing) await ctx.db.patch(existing._id, doc);
    else await ctx.db.insert("scores", doc);
  },
});

// Remove a stale score row (used to clean the device-minted uid after sign in).
export const remove = mutation({
  args: { uid: v.string() },
  handler: async (ctx, a) => {
    const row = await ctx.db.query("scores").withIndex("by_uid", (q) => q.eq("uid", a.uid)).unique();
    if (row) await ctx.db.delete(row._id);
  },
});
