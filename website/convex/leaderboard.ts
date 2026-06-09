import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { deviceOk, requireDevice } from "./auth";

// S1: never return uids to clients. Callers that pass a valid uid+secret get `me: true`
// on their own row instead.
async function rows(ctx: any, uid?: string, secret?: string) {
  const all = await ctx.db.query("scores").collect();
  const isMe = uid && secret && (await deviceOk(ctx, uid, secret));
  return all.map((s: any) => ({
    alias: s.alias, words: s.words, wpm: s.wpm, streak: s.streak, saved: s.saved ?? 0,
    me: isMe ? s.uid === uid : false,
  }));
}

export const list = query({
  args: { uid: v.optional(v.string()), secret: v.optional(v.string()) },
  handler: async (ctx, a) => {
    const all = await rows(ctx, a.uid, a.secret);
    return all.sort((x: any, y: any) => y.words - x.words);
  },
});

export const board = query({
  args: { uid: v.optional(v.string()), secret: v.optional(v.string()) },
  handler: async (ctx, a) => {
    return await rows(ctx, a.uid, a.secret);
  },
});

export const submit = mutation({
  args: {
    uid: v.string(), secret: v.string(), alias: v.string(),
    words: v.number(), wpm: v.number(), streak: v.number(), saved: v.optional(v.number()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const existing = await ctx.db.query("scores").withIndex("by_uid", (q) => q.eq("uid", a.uid)).unique();
    const doc = { uid: a.uid, alias: a.alias, words: a.words, wpm: a.wpm, streak: a.streak, saved: a.saved ?? 0, updated: Date.now() };
    if (existing) await ctx.db.patch(existing._id, doc);
    else await ctx.db.insert("scores", doc);
  },
});

// Remove a stale score row (used to clean the device-minted uid after sign in).
// S8: only the device that owns the uid (its secret is registered under it) may remove it.
export const remove = mutation({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("scores").withIndex("by_uid", (q) => q.eq("uid", a.uid)).unique();
    if (row) await ctx.db.delete(row._id);
  },
});
