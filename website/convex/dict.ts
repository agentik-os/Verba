import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Personal dictionary (custom vocabulary / brand spellings) synced per account.
// Mirrors the Mac's DictTerm {spoken, written, auto}; identity = ts (creation ms).
export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    spoken: v.string(), written: v.string(), auto: v.boolean(),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const dup = await ctx.db.query("dict").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      await ctx.db.patch(dup._id, { spoken: a.spoken, written: a.written, auto: a.auto });
      return;
    }
    const tomb = await ctx.db.query("dict_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    const { secret, ...doc } = a;
    await ctx.db.insert("dict", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("dict").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => x.ts - y.ts).slice(0, 1000)
      .map((r) => ({ ts: r.ts, spoken: r.spoken, written: r.written, auto: r.auto }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("dict").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("dict_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("dict_deleted", { uid: a.uid, ts: a.ts });
  },
});

// Deletion tombstones so every device drops a term deleted elsewhere (mirrors notes:tombstones).
export const tombstones = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("dict_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => r.ts);
  },
});
