import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  scores: defineTable({
    uid: v.string(),      // stable per-account id (referral code); never the email
    alias: v.string(),    // public display name
    words: v.number(),    // total words dictated
    wpm: v.number(),      // average words per minute
    streak: v.number(),   // consecutive-day streak
    updated: v.number(),
  }).index("by_uid", ["uid"]),
});
