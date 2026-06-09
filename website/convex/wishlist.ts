import { internalMutation, mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("wishlist").collect();
    return all
      .sort((a, b) => b.votes - a.votes)
      .map((w) => ({ id: w._id, text: w.text, author: w.author, votes: w.votes, voters: w.voters }));
  },
});

export const add = mutation({
  args: { uid: v.string(), alias: v.string(), text: v.string() },
  handler: async (ctx, a) => {
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
  args: { id: v.id("wishlist"), uid: v.string() },
  handler: async (ctx, a) => {
    const w = await ctx.db.get(a.id);
    if (!w) return;
    if (w.voters.includes(a.uid)) {
      await ctx.db.patch(a.id, { votes: Math.max(0, w.votes - 1), voters: w.voters.filter((u) => u !== a.uid) });
    } else {
      await ctx.db.patch(a.id, { votes: w.votes + 1, voters: [...w.voters, a.uid] });
    }
  },
});
