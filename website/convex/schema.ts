import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  scores: defineTable({
    uid: v.string(), alias: v.string(),
    words: v.number(), wpm: v.number(), streak: v.number(), updated: v.number(),
  }).index("by_uid", ["uid"]),

  wishlist: defineTable({
    text: v.string(),
    author: v.string(),     // alias only, never email
    votes: v.number(),
    voters: v.array(v.string()),  // uids who upvoted
    created: v.number(),
  }),
});
