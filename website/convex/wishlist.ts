import { internalMutation, mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { deviceOk, requireDevice } from "./auth";

// S1/S12: never return the voters uid list. Callers that pass a valid uid+secret get
// `mine: true` on items they voted for.
export const list = query({
  args: { uid: v.optional(v.string()), secret: v.optional(v.string()) },
  handler: async (ctx, a) => {
    const all = await ctx.db.query("wishlist").collect();
    const isMe = a.uid && a.secret && (await deviceOk(ctx, a.uid, a.secret));
    return all
      .sort((x, y) => y.votes - x.votes)
      .map((w) => ({
        id: w._id, text: w.text, author: w.author, votes: w.votes,
        mine: isMe ? w.voters.includes(a.uid!) : false,
        shipped: w.shipped === true,
        shippedAt: w.shippedAt ?? null,
      }));
  },
});

// Persist a wish's shipped status (called server-side once its Linear issue is Done) so the green
// "shipped" badge survives Linear board/workspace changes. Idempotent; never un-ships.
export const setShipped = mutation({
  args: { id: v.id("wishlist"), at: v.optional(v.number()) },
  handler: async (ctx, a) => {
    const w = await ctx.db.get(a.id);
    if (!w || w.shipped === true) return;
    await ctx.db.patch(a.id, { shipped: true, shippedAt: a.at ?? Date.now() });
  },
});

export const add = mutation({
  args: { uid: v.string(), secret: v.string(), alias: v.string(), text: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const text = a.text.trim().slice(0, 280);
    if (!text) return;
    await ctx.db.insert("wishlist", { text, author: a.alias, votes: 1, voters: [a.uid], created: Date.now() });
  },
});

// Admin-only moderation (internal = NOT callable from the public client API; run via
// `npx convex run wishlist:remove '{"id":"…"}' --prod`). Used to clean up test/spam wishes.
export const remove = internalMutation({
  args: { id: v.id("wishlist") },
  handler: async (ctx, a) => {
    await ctx.db.delete(a.id);
  },
});

// Admin-only: set every wishlist item's author to one of the provided handles (round-robin),
// so the seeded wishes match the real names visible on the leaderboard. internalMutation = NOT
// publicly callable (a public mutation here would let anyone rewrite every author).
export const reauthor = internalMutation({
  args: { authors: v.array(v.string()) },
  handler: async (ctx, a) => {
    if (a.authors.length === 0) return 0;
    const all = await ctx.db.query("wishlist").collect();
    for (let i = 0; i < all.length; i++) {
      await ctx.db.patch(all[i]._id, { author: a.authors[i % a.authors.length] });
    }
    return all.length;
  },
});

// Admin-only: wipe every wishlist item (used to reset the board). Internal-only.
export const wipe = internalMutation({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("wishlist").collect();
    for (const w of all) await ctx.db.delete(w._id);
    return all.length;
  },
});

// Admin-only: seed an item with an explicit vote count + creation time. Returns its id so the
// caller can file the matching Linear issue (convexId marker) that drives the `shipped` flag.
export const seed = internalMutation({
  args: { text: v.string(), author: v.string(), votes: v.number(), created: v.number() },
  handler: async (ctx, a) => {
    const n = Math.max(0, Math.round(a.votes));
    const voters = Array.from({ length: n }, (_, i) => `seed-${i}`);
    return await ctx.db.insert("wishlist", {
      text: a.text, author: a.author, votes: n, voters, created: a.created,
    });
  },
});

export const upvote = mutation({
  args: { id: v.id("wishlist"), uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const w = await ctx.db.get(a.id);
    if (!w) return;
    if (w.voters.includes(a.uid)) {
      await ctx.db.patch(a.id, { votes: Math.max(0, w.votes - 1), voters: w.voters.filter((u) => u !== a.uid) });
    } else {
      await ctx.db.patch(a.id, { votes: w.votes + 1, voters: [...w.voters, a.uid] });
    }
  },
});
