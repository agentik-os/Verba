import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Long-form Notes synced text-only per account (audio stays on-device), mirroring history.ts.
export const push = mutation({
  args: {
    uid: v.string(), ts: v.number(),
    original: v.string(), formatted: v.string(), formatName: v.string(),
    tags: v.array(v.string()),
  },
  handler: async (ctx, a) => {
    const dup = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) { await ctx.db.patch(dup._id, { formatted: a.formatted, tags: a.tags }); return; }
    const tomb = await ctx.db.query("notes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    await ctx.db.insert("notes", a);
  },
});

export const pull = query({
  args: { uid: v.string() },
  handler: async (ctx, a) => {
    const rows = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 500)
      .map((r) => ({ ts: r.ts, original: r.original, formatted: r.formatted, formatName: r.formatName, tags: r.tags }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    const row = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("notes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("notes_deleted", { uid: a.uid, ts: a.ts });
  },
});
