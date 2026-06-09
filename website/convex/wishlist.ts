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
      }));
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
