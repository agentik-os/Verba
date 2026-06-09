import { mutation } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

/// "Delete all my cloud data" (S14): wipes history + notes (tombstoned so deletions
/// stick across devices) and stats + leaderboard score for the uid.
export const wipe = mutation({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    for (const table of ["history", "notes"]) {
      const rows = await ctx.db.query(table as any).withIndex("by_uid", (q: any) => q.eq("uid", a.uid)).collect();
      for (const r of rows) {
        await ctx.db.insert(`${table}_deleted` as any, { uid: a.uid, ts: (r as any).ts });
        await ctx.db.delete(r._id);
      }
    }
    for (const table of ["stats", "scores"]) {
      const rows = await ctx.db.query(table as any).withIndex("by_uid", (q: any) => q.eq("uid", a.uid)).collect();
      for (const r of rows) await ctx.db.delete(r._id);
    }
    // device_auth rows stay: the device keeps the right to push tombstone-respecting data later.
  },
});
