import { mutation } from "./_generated/server";
import { v } from "convex/values";

/// Shared daily counters for the Next.js API routes (try/feedback/wishlist/reprompt).
/// Server-only: callers must prove they hold APP_TOKEN_SECRET (our API routes have it
/// in env) so the public cannot burn counters by hitting this mutation directly.
export const bump = mutation({
  args: { key: v.string(), limit: v.number(), serverKey: v.string() },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const row = await ctx.db.query("ratelimits").withIndex("by_key", (q) => q.eq("key", a.key)).unique();
    const n = (row?.n ?? 0) + 1;
    if (n > a.limit) return { allowed: false, n };
    if (row) await ctx.db.patch(row._id, { n, updated: Date.now() });
    else await ctx.db.insert("ratelimits", { key: a.key, n, updated: Date.now() });
    return { allowed: true, n };
  },
});
