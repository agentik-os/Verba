import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  scores: defineTable({
    uid: v.string(), alias: v.string(),
    words: v.number(), wpm: v.number(), streak: v.number(),
    saved: v.optional(v.number()), updated: v.number(),
  }).index("by_uid", ["uid"]),

  wishlist: defineTable({
    text: v.string(), author: v.string(), votes: v.number(),
    voters: v.array(v.string()), created: v.number(),
  }),

  history: defineTable({
    uid: v.string(), ts: v.number(),
    original: v.string(), reprompted: v.string(), profileName: v.string(), engine: v.string(),
  }).index("by_uid", ["uid"]),

  history_deleted: defineTable({   // tombstones so deletions stick across devices
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),
});
