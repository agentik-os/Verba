import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Customize/appearance settings synced to the account so a fresh sign-in restores the exact
// look (app + widget) the user had before. Stored as one JSON blob keyed by uid, last-write-wins
// by the client-supplied `updated` timestamp.

export const push = mutation({
  args: { uid: v.string(), secret: v.string(), appr: v.string(), updated: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const existing = await ctx.db
      .query("settings")
      .withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .unique();
    if (existing) {
      // Ignore a stale push (an older snapshot racing a newer one).
      if (a.updated < (existing.updated ?? 0)) return;
      await ctx.db.patch(existing._id, { appr: a.appr, updated: a.updated });
    } else {
      await ctx.db.insert("settings", { uid: a.uid, appr: a.appr, updated: a.updated });
    }
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    const ok = await ctx.db
      .query("settings")
      .withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .unique();
    if (!ok) return null;
    // Device-auth is enforced on push; pull returns the user's own blob (uid is the key).
    return { appr: ok.appr, updated: ok.updated };
  },
});
