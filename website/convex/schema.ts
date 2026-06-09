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

  stats: defineTable({   // per-day dictation stats, synced so Insights/Total Words follow the account
    uid: v.string(), day: v.string(),   // day = "yyyy-MM-dd"
    words: v.number(), seconds: v.number(), count: v.number(), updated: v.number(),
  }).index("by_uid", ["uid"]),

  notes: defineTable({   // long-form Notes, synced text-only across the user's Macs
    uid: v.string(), ts: v.number(),
    original: v.string(), formatted: v.string(), formatName: v.string(),
    tags: v.array(v.string()),
  }).index("by_uid", ["uid"]),

  notes_deleted: defineTable({   // tombstones so note deletions stick across devices
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),

  feedback: defineTable({   // free-form user feedback (admin-reviewed), optional screenshot
    uid: v.string(), alias: v.string(), text: v.string(),
    version: v.optional(v.string()),
    screenshot: v.optional(v.id("_storage")),
    createdAt: v.number(),
    status: v.optional(v.string()),
  }),
});
