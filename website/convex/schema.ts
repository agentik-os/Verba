import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  scores: defineTable({
    uid: v.string(), alias: v.string(),
    words: v.number(), wpm: v.number(), streak: v.number(), saved: v.optional(v.number()), updated: v.number(),
  }).index("by_uid", ["uid"]),

  wishlist: defineTable({
    text: v.string(), author: v.string(), votes: v.number(),
    voters: v.array(v.string()), created: v.number(),
  }),

  history: defineTable({
    uid: v.string(),
    ts: v.number(),               // dictation timestamp (ms), used as the dedup key
    original: v.string(),
    reprompted: v.string(),
    profileName: v.string(),
    engine: v.string(),
  }).index("by_uid", ["uid"]),
});
