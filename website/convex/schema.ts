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

  settings: defineTable({   // Customize/appearance settings (app + widget), synced across the user's Macs
    uid: v.string(),
    appr: v.string(),       // JSON blob of all verba.appr.* / widget.appr.* values
    updated: v.number(),
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

  device_auth: defineTable({   // uid → sha256(device secret); multiple rows = multiple devices
    uid: v.string(),
    secretHash: v.string(),    // hex sha256 of the 64-char hex secret string
    created: v.number(),
  }).index("by_uid", ["uid"]),

  ratelimits: defineTable({    // shared counters that survive serverless instances
    key: v.string(),           // e.g. "try:ip:1.2.3.4:2026-06-10", "try:global:2026-06-10"
    n: v.number(),
    updated: v.number(),
  }).index("by_key", ["key"]),

  profiles: defineTable({      // public gamification profile, so others can see your level + badges
    uid: v.string(),
    alias: v.string(),
    level: v.number(),
    xp: v.number(),
    league: v.string(),
    badges: v.array(v.string()),   // earned achievement ids
    referrals: v.optional(v.number()),  // people who joined via this user's code
    updated: v.number(),
  }).index("by_uid", ["uid"]).index("by_alias", ["alias"]),
});
