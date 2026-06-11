import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Public gamification profiles: each user pushes their level / XP / league / earned badges so
// others can view them from the leaderboard. Keyed by uid (device-auth gated to write); read by
// alias (the public handle shown on the leaderboard).

export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), alias: v.string(),
    level: v.number(), xp: v.number(), league: v.string(),
    badges: v.array(v.string()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const doc = {
      uid: a.uid, alias: a.alias, level: a.level, xp: a.xp,
      league: a.league, badges: a.badges, updated: Date.now(),
    };
    const existing = await ctx.db.query("profiles").withIndex("by_uid", (q) => q.eq("uid", a.uid)).unique();
    if (existing) await ctx.db.patch(existing._id, doc);
    else await ctx.db.insert("profiles", { ...doc, referrals: 0 });
  },
});

// Read a public profile by its leaderboard alias (most-recently-updated wins on a rare collision).
export const byAlias = query({
  args: { alias: v.string() },
  handler: async (ctx, a) => {
    const rows = await ctx.db.query("profiles").withIndex("by_alias", (q) => q.eq("alias", a.alias)).collect();
    if (rows.length === 0) return null;
    const r = rows.sort((x, y) => y.updated - x.updated)[0];
    return { alias: r.alias, level: r.level, xp: r.xp, league: r.league, badges: r.badges, referrals: r.referrals ?? 0 };
  },
});

// Lightweight map of alias -> { level, badgeCount } for decorating the whole leaderboard at once.
export const summary = query({
  args: {},
  handler: async (ctx) => {
    const rows = await ctx.db.query("profiles").collect();
    return rows.map((r) => ({ alias: r.alias, level: r.level, badges: r.badges.length, league: r.league }));
  },
});
