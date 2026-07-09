import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/// Record an iPhone TestFlight beta-test signup. Server-gated by APP_TOKEN_SECRET (the same
/// pattern as feedback:record / ratelimit:bump) so the public can't insert rows by hitting Convex
/// directly — only our /api/beta-signup route can. Deduped by email (upsert): a repeat signup
/// refreshes the existing row instead of creating a duplicate. Returns the row id.
export const submit = mutation({
  args: {
    serverKey: v.string(),
    email: v.string(),
    alias: v.optional(v.string()),
    appVersion: v.optional(v.string()),
    uid: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const email = a.email.trim().toLowerCase().slice(0, 254);
    if (!email) throw new Error("empty");
    const existing = await ctx.db
      .query("beta_signups")
      .withIndex("by_email", (q) => q.eq("email", email))
      .unique();
    if (existing) {
      // Upsert: keep the earliest `created`/`invited` state, refresh the light context.
      await ctx.db.patch(existing._id, {
        alias: a.alias ?? existing.alias,
        appVersion: a.appVersion ?? existing.appVersion,
        uid: a.uid ?? existing.uid,
      });
      return existing._id;
    }
    return await ctx.db.insert("beta_signups", {
      email,
      alias: a.alias,
      appVersion: a.appVersion,
      uid: a.uid,
      created: Date.now(),
      status: "pending",
      invited: false,
    });
  },
});

/// Admin listing, gated by the ADMIN_SECRET Convex env var (same pattern as feedback:adminList).
/// Returns [] on a wrong/missing secret; on success, all signups newest-first.
export const list = query({
  args: { secret: v.string() },
  handler: async (ctx, a) => {
    if (!process.env.ADMIN_SECRET || a.secret !== process.env.ADMIN_SECRET) return [];
    const rows = await ctx.db.query("beta_signups").collect();
    rows.sort((x, y) => y.created - x.created);
    return rows.map((r) => ({
      id: r._id,
      email: r.email,
      alias: r.alias ?? null,
      appVersion: r.appVersion ?? null,
      created: r.created,
      status: r.status,
      invited: r.invited,
      invitedAt: r.invitedAt ?? null,
    }));
  },
});

/// Stamp a signup as invited to TestFlight. Called by the testflight-invite helper once it has
/// successfully added the tester to the beta group. Server-gated by APP_TOKEN_SECRET.
export const markInvited = mutation({
  args: { serverKey: v.string(), email: v.string() },
  handler: async (ctx, a) => {
    if (!process.env.APP_TOKEN_SECRET || a.serverKey !== process.env.APP_TOKEN_SECRET) {
      throw new Error("unauthorized");
    }
    const email = a.email.trim().toLowerCase();
    const row = await ctx.db
      .query("beta_signups")
      .withIndex("by_email", (q) => q.eq("email", email))
      .unique();
    if (!row) return false;
    await ctx.db.patch(row._id, { invited: true, invitedAt: Date.now(), status: "invited" });
    return true;
  },
});
