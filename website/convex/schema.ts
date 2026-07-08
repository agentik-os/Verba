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
    // Shipped status persisted here (set when the linked Linear issue goes Done) so the green
    // "shipped" badge survives even if the Linear board/workspace changes.
    shipped: v.optional(v.boolean()),
    shippedAt: v.optional(v.number()),
  }),

  history: defineTable({
    uid: v.string(), ts: v.number(),
    original: v.string(), reprompted: v.string(), profileName: v.string(), engine: v.string(),
    // Where the dictation happened ("note" = dictated into a long-form note). The note
    // safety net: a note's dictated text stays recoverable here if the note is deleted.
    source: v.optional(v.string()),
    // Version clock (ms): set when a "Re-run" rewrites `reprompted`, so a device that
    // missed the re-run can never clobber it back with the old text (see history:push).
    updatedAt: v.optional(v.number()),
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

  notes: defineTable({   // long-form Notes, synced text-only across the user's devices
    uid: v.string(), ts: v.number(),
    original: v.string(), formatted: v.string(), formatName: v.string(),
    tags: v.array(v.string()),
    title: v.optional(v.string()),    // user-set note title (the Mac has pushed this since 5b69e1e)
    // Per-note password lock: when locked, `formatted` is the AES-GCM ciphertext and
    // `salt` is that note's own salt — synced so any signed-in device can decrypt
    // with the note's password (key = SHA-256(salt ‖ password), all on-device).
    salt: v.optional(v.string()),
    locked: v.optional(v.boolean()),
    // Per-note version clock (ms since epoch, client-set; server clock as fallback).
    // Lets every device refuse stale overwrites in BOTH directions — a pull must never
    // clobber newer local edits, a push must never clobber a newer cloud copy.
    updatedAt: v.optional(v.number()),
  }).index("by_uid", ["uid"]),

  notes_deleted: defineTable({   // tombstones so note deletions stick across devices
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),

  tasks: defineTable({   // lightweight synced task manager (mobile-first; ts = identity)
    uid: v.string(), ts: v.number(),
    text: v.string(), done: v.boolean(),
    due: v.optional(v.number()),
    // Mac TodoTask extras (Stores.swift): subtasks as a JSON string + the owning project name,
    // so the Mac's Projects▸Tasks▸Sub-tasks structure round-trips LOSSLESSLY. Mobile reads the
    // flat {text,done,due} and ignores these; all optional for older/mobile-made rows.
    subtasks: v.optional(v.string()),
    project: v.optional(v.string()),
  }).index("by_uid", ["uid"]),

  tasks_deleted: defineTable({
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),

  dict: defineTable({   // personal dictionary terms (mirrors the Mac's DictTerm)
    uid: v.string(), ts: v.number(),
    spoken: v.string(), written: v.string(), auto: v.boolean(),
  }).index("by_uid", ["uid"]),

  dict_deleted: defineTable({
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),

  modes: defineTable({   // user-created reprompting modes, synced per account
    uid: v.string(), ts: v.number(),
    name: v.string(), system: v.string(), raw: v.boolean(),
    model: v.optional(v.string()),
    // Mac Profile extras (Settings.swift): carried so a Mac↔cloud round-trip is LOSSLESS.
    // The mobile client ignores fields it doesn't use; all optional for older rows.
    matchBundleIDs: v.optional(v.array(v.string())),
    hotkeyCode: v.optional(v.number()),
    hotkeyMods: v.optional(v.number()),
    vision: v.optional(v.boolean()),
    targetLanguage: v.optional(v.string()),
    seedHash: v.optional(v.string()),
    explainer: v.optional(v.string()),
  }).index("by_uid", ["uid"]),

  modes_deleted: defineTable({
    uid: v.string(), ts: v.number(),
  }).index("by_uid", ["uid"]),

  styles: defineTable({   // tone/format layer on top of modes (mirrors the Mac's Style)
    uid: v.string(), ts: v.number(),
    name: v.string(), prompt: v.string(),
  }).index("by_uid", ["uid"]),
  styles_deleted: defineTable({ uid: v.string(), ts: v.number() }).index("by_uid", ["uid"]),

  snippets: defineTable({   // text-expansion shortcuts (trigger → expansion)
    uid: v.string(), ts: v.number(),
    trigger: v.string(), expansion: v.string(),
  }).index("by_uid", ["uid"]),
  snippets_deleted: defineTable({ uid: v.string(), ts: v.number() }).index("by_uid", ["uid"]),

  transforms: defineTable({   // named voice actions on selected text
    uid: v.string(), ts: v.number(),
    name: v.string(), prompt: v.string(),
  }).index("by_uid", ["uid"]),
  transforms_deleted: defineTable({ uid: v.string(), ts: v.number() }).index("by_uid", ["uid"]),

  feedback: defineTable({   // free-form user feedback (admin-reviewed), optional screenshot
    uid: v.string(), alias: v.string(), text: v.string(),
    version: v.optional(v.string()),
    screenshot: v.optional(v.id("_storage")),
    createdAt: v.number(),
    status: v.optional(v.string()),
    // Durable record written by the web /api/feedback route BEFORE the Linear call, so a Linear
    // outage (e.g. a dead API key) never loses a feedback again. Context + the Linear sync outcome.
    os: v.optional(v.string()),
    engine: v.optional(v.string()),
    mode: v.optional(v.string()),
    email: v.optional(v.string()),
    screenshotUrl: v.optional(v.string()),
    linearId: v.optional(v.string()),
    linearUrl: v.optional(v.string()),
    synced: v.optional(v.boolean()),
  }).index("by_synced", ["synced"]),

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
    avatar: v.optional(v.string()),     // profile photo URL (Clerk image), synced across devices
    // Public analytics snapshot, so a tapped profile shows the same Insights the owner sees
    // (words today, streak, totals…). Optional: older profiles predate it.
    stats: v.optional(v.object({
      wordsToday: v.number(),
      streak: v.number(),
      longestStreak: v.number(),
      wordsThisWeek: v.number(),
      totalWords: v.number(),
      dictations: v.number(),
      wpm: v.number(),
      timeSavedMinutes: v.number(),
      bestDayWords: v.number(),
    })),
    updated: v.number(),
  }).index("by_uid", ["uid"]).index("by_alias", ["alias"]),

  blog_articles: defineTable({   // articles pushed by Outrank.so via the /api/outrank-webhook receiver
    outrankId: v.string(),       // Outrank's article id — the dedupe/upsert key
    slug: v.string(),            // URL slug → /blog/<slug>
    title: v.string(),
    contentHtml: v.string(),     // rendered body (Outrank content_html, else markdown→html)
    contentMarkdown: v.optional(v.string()),
    metaDescription: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
    tags: v.array(v.string()),
    createdAt: v.optional(v.string()),   // ISO timestamp from Outrank (publish date)
    receivedAt: v.number(),              // when our webhook first stored it (ms)
    updatedAt: v.number(),               // last time the webhook rewrote it (ms)
  }).index("by_slug", ["slug"]).index("by_outrankId", ["outrankId"]),
});
