import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireDevice } from "./auth";

// User-created reprompting modes (custom Profiles), synced per account so the
// same modes exist on every device. Built-in modes stay client-side; ts = identity.
// Optional Mac Profile extras carried verbatim (see schema.ts). Patched only when present so a
// mobile push (which omits them) never wipes the Mac's bundle matches / hotkeys / etc.
const macExtras = {
  matchBundleIDs: v.optional(v.array(v.string())),
  hotkeyCode: v.optional(v.number()),
  hotkeyMods: v.optional(v.number()),
  vision: v.optional(v.boolean()),
  targetLanguage: v.optional(v.string()),
  seedHash: v.optional(v.string()),
  explainer: v.optional(v.string()),
};

export const push = mutation({
  args: {
    uid: v.string(), secret: v.string(), ts: v.number(),
    name: v.string(), system: v.string(), raw: v.boolean(),
    model: v.optional(v.string()),
    ...macExtras,
  },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    // Only patch keys that were actually sent, so a client that omits a field leaves it intact.
    const opt: Record<string, unknown> = {};
    for (const k of ["model", "matchBundleIDs", "hotkeyCode", "hotkeyMods", "vision", "targetLanguage", "seedHash", "explainer"] as const) {
      if ((a as any)[k] !== undefined) opt[k] = (a as any)[k];
    }
    const dup = await ctx.db.query("modes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (dup) {
      await ctx.db.patch(dup._id, { name: a.name, system: a.system, raw: a.raw, ...opt });
      return;
    }
    const tomb = await ctx.db.query("modes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (tomb) return;
    const { secret, ...doc } = a;
    await ctx.db.insert("modes", doc);
  },
});

export const pull = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("modes").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.sort((x, y) => x.ts - y.ts).slice(0, 100)
      .map((r) => ({
        ts: r.ts, name: r.name, system: r.system, raw: r.raw, model: r.model,
        matchBundleIDs: r.matchBundleIDs, hotkeyCode: r.hotkeyCode, hotkeyMods: r.hotkeyMods,
        vision: r.vision, targetLanguage: r.targetLanguage, seedHash: r.seedHash, explainer: r.explainer,
      }));
  },
});

// Deletion tombstones so every device drops a mode deleted elsewhere (mirrors notes:tombstones).
export const tombstones = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const rows = await ctx.db.query("modes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid)).collect();
    return rows.map((r) => r.ts);
  },
});

export const remove = mutation({
  args: { uid: v.string(), secret: v.string(), ts: v.number() },
  handler: async (ctx, a) => {
    await requireDevice(ctx, a.uid, a.secret);
    const row = await ctx.db.query("modes").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (row) await ctx.db.delete(row._id);
    const tomb = await ctx.db.query("modes_deleted").withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .filter((q) => q.eq(q.field("ts"), a.ts)).first();
    if (!tomb) await ctx.db.insert("modes_deleted", { uid: a.uid, ts: a.ts });
  },
});
