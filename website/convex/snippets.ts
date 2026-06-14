import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Synced snippets (mirrors the Mac's local store; ts = identity, tombstoned deletes).
export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    trigger: v.string(), expansion: v.string(),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const dup = await ctx.db.query("snippets").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      await ctx.db.patch(dup._id, { trigger: a.trigger, expansion: a.expansion });
      return;
    }
    const tomb = await ctx.db.query("snippets_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    const { secret, ...doc } = a;
    await ctx.db.insert("snippets", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("snippets").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 500)
      .map((r) => ({ ts: r.ts, trigger: r.trigger, expansion: r.expansion }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("snippets").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("snippets_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("snippets_deleted", { uid: a.uid, ts: a.ts });
  },
});

// Deletion tombstones so every device drops a snippet deleted elsewhere (mirrors notes:tombstones).
export const tombstones = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("snippets_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => r.ts);
  },
});
