import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// Long-form Notes synced text-only per account (audio stays on-device), mirroring history.ts.
export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    original: v.string(), formatted: v.string(), formatName: v.string(),
    tags: v.array(v.string()),
    title: v.optional(v.string()),
    // Per-note lock state (see schema.ts): synced so other devices can decrypt/lock.
    salt: v.optional(v.string()),
    locked: v.optional(v.boolean()),
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const dup = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      await ctx.db.patch(dup._id, {
        formatted: a.formatted, tags: a.tags,
        ...(a.title !== undefined ? { title: a.title } : {}),
        // Lock transition: adopt original (cleared on lock, restored on unlock) and
        // salt together; an undefined salt on unlock removes the stale field.
        ...(a.locked !== undefined ? { locked: a.locked, original: a.original, salt: a.salt } : {}),
      });
      return;
    }
    const tomb = await ctx.db.query("notes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    const { secret, ...doc } = a;
    await ctx.db.insert("notes", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => y.ts - x.ts).slice(0, 500)
      .map((r) => ({
        ts: r.ts, original: r.original, formatted: r.formatted, formatName: r.formatName, tags: r.tags,
        title: r.title ?? "", salt: r.salt, locked: r.locked ?? false,
      }));
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("notes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("notes_deleted", { uid: a.uid, ts: a.ts });
  },
});

// Delete-with-tombstones — wipe all cloud notes for a uid.
export const wipe = mutation({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("notes").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    for (const r of rows) {
      await ctx.db.insert("notes_deleted", { uid: a.uid, ts: r.ts });
      await ctx.db.delete(r._id);
    }
  },
});
