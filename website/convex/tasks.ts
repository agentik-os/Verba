import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Lightweight task manager synced per account (created from dictation or typed),
// mirroring the notes.ts upsert-by-ts + tombstone pattern.
export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    text: v.string(), done: v.boolean(),
    due: v.optional(v.number()),
    // Mac extras (see schema.ts) — patched only when sent so a mobile push never wipes them.
    subtasks: v.optional(v.string()),
    project: v.optional(v.string()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const opt: Record<string, unknown> = {};
    for (const k of ["due", "subtasks", "project"] as const) {
      if ((a as any)[k] !== undefined) opt[k] = (a as any)[k];
    }
    const dup = await ctx.db.query("tasks").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      await ctx.db.patch(dup._id, { text: a.text, done: a.done, ...opt });
      return;
    }
    const tomb = await ctx.db.query("tasks_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    const { secret, ...doc } = a;
    await ctx.db.insert("tasks", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("tasks").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 500)
      .map((r) => ({ ts: r.ts, text: r.text, done: r.done, due: r.due, subtasks: r.subtasks, project: r.project }));
  },
});

// Deletion tombstones so every device drops a task deleted elsewhere (mirrors notes:tombstones).
export const tombstones = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("tasks_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => r.ts);
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("tasks").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("tasks_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("tasks_deleted", { uid: a.uid, ts: a.ts });
  },
});
