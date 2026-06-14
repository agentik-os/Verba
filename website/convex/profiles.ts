import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Public gamification profiles: each user pushes their level / XP / league / earned badges so
// others can view them from the leaderboard. Keyed by uid (device-auth gated to write); read by
// alias (the public handle shown on the leaderboard).

const statsValidator = v.object({
  wordsToday: v.number(),
  streak: v.number(),
  longestStreak: v.number(),
  wordsThisWeek: v.number(),
  totalWords: v.number(),
  dictations: v.number(),
  wpm: v.number(),
  timeSavedMinutes: v.number(),
  bestDayWords: v.number(),
});

export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), alias: v.string(),
    level: v.number(), xp: v.number(), league: v.string(),
    badges: v.array(v.string()),
    stats: v.optional(statsValidator),
    avatar: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    // Alias-ownership guard (IDOR): refuse to publish under an alias another uid already holds,
    // so a user can't take over / overwrite someone else's public profile by spoofing their alias.
    const sameAlias = await ctx.db.query("profiles").withIndex("by_alias", (q) => q.eq("alias", a.alias)).collect();
    if (sameAlias.some((r: any) => r.uid !== a.uid)) throw new Error("alias taken");
    // Only set the avatar when the caller actually has one, so a device that pushes without
    // a photo (e.g. a fresh mobile session) never wipes one another device already published.
    const doc = {
      uid: a.uid, alias: a.alias, level: a.level, xp: a.xp,
      league: a.league, badges: a.badges, stats: a.stats, updated: Date.now(),
      ...(a.avatar ? { avatar: a.avatar } : {}),
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
    return { alias: r.alias, level: r.level, xp: r.xp, league: r.league, badges: r.badges, referrals: r.referrals ?? 0, stats: r.stats ?? null, avatar: r.avatar ?? null };
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
