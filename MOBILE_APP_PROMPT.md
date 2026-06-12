# Verba Mobile — kickoff prompt

Copy everything below the line into a fresh Claude Code session (in a NEW empty folder,
e.g. `~/VerbaMobile`) to start building the Verba mobile app. It reuses the existing
Verba backend (verba.run API routes, Convex, Clerk, Composio relay) — no new backend.

---

You are building **Verba Mobile**, the iOS + Android companion to Verba, the macOS AI
dictation app (verba.run). Verba on Mac lets you speak and get clean text anywhere, keeps
long-form Notes, and has **JARVIS**, a voice agent that acts on 1,000+ connected apps. The
mobile app brings the same speak → clean text → act + your Notes/history to the phone.

## Product goal (MVP first)
A dictation app you open, tap once, speak, and get back clean, formatted text you can copy or
share into any app — plus your Notes synced from the Mac, and JARVIS for voice actions. Same
account, same data, on the go.

## Reuse the EXISTING backend — do NOT rebuild it
- **Account / auth:** Clerk (same project as verba.run). Sign in with the same account so data syncs.
- **Notes / history / stats:** Convex (same deployment). The Mac app already reads/writes these;
  mirror its document shapes. Notes support #hashtags (Bear-style tag tree) and per-note password
  lock (AES-GCM, salt per note) — match that model so locked notes stay locked across devices.
- **Sync contract — data-safety rules (NON-NEGOTIABLE, learned from a real data-loss incident):**
  1. `ts` (ms) is a note's identity; `updatedAt` (ms) is its version clock. Bump `updatedAt` on
     EVERY local edit and send it on every `notes:push`. The server refuses writes whose clock is
     ≤ the stored one; on pull, only adopt a cloud row whose `updatedAt` is strictly newer than
     the local clock. Never overwrite local content with an older or equal cloud copy.
  2. After every pull, reconcile: re-push any local note the cloud is missing or holds an older
     version of. A failed push must NEVER permanently strand a note on one device.
  3. Deletions: tombstones only (`notes:remove`, `notes:tombstones`); pull the tombstone list and
     drop local copies. Never hard-delete without a tombstone, never resurrect a tombstoned ts.
  4. Persist notes locally (offline-first); never keep a note only in memory or only in the cloud.
  5. Schema evolution: decode stored JSON field-by-field with per-field defaults — a missing key
     must NEVER fail the whole collection (this exact bug emptied users' Mac notes). If a stored
     file fails to decode anyway, park a rescue copy before any save can overwrite it.
  6. Dictating into a note ALSO appends the raw transcript to history with `source: "note"`
     (the recovery safety net shown in the Mac History tab).
  7. Never ship a client that sends an argument the deployed Convex validator doesn't accept —
     deploy the (optional-field) validator FIRST, ship the client after; a mismatch silently
     kills that sync for everyone.
- **JARVIS / connected apps:** the secure relay at `https://verba.run/api/composio/*`
  (`/agent-context`, `/agent-reads`, `/execute`, `/connect`, `/connections`). Auth = the user's
  app-session bearer token. Connected-app keys live server-side, never on the device.
- **Billing:** Stripe via verba.run (subscription is account-wide; respect entitlement).
- **AI/transcription:** on iOS, prefer on-device Speech (SFSpeechRecognizer) or Apple's newer
  SpeechAnalyzer for transcription; for cleanup/JARVIS planning, call the user's chosen engine
  (their key / a hosted relay) — never hardcode the company's Anthropic key (same rule as Mac:
  planning runs on the user's engine).

## Stack (opinionated, change only with reason)
- **Expo (React Native, TypeScript)** for one codebase on iOS + Android, EAS Build for releases.
- **@clerk/clerk-expo** for auth, **convex** React client for live data, **expo-av** /
  `expo-speech-recognition` (or native modules) for mic + transcription, **expo-secure-store**
  for the session token + any local secrets, **nativewind** (Tailwind) for styling matching the
  Verba dark, glassy aesthetic.
- Match Verba's brand: dark, minimal, rounded, the same accent. Keep it calm and fast.

## Core features, in build order
1. **Auth + sync:** Clerk sign-in → exchange for the app-session token → read Notes/stats from Convex.
2. **Dictate:** big mic button → record → transcribe (on-device) → AI cleanup (chosen engine) →
   result screen with Copy + Share-sheet. Offer the same modes (Flow/Polish/Intent/Translate).
3. **Notes:** list with the Bear-style nested #tag tree + search; open/edit; respect per-note
   password lock (prompt for the note's password to decrypt locally).
4. **JARVIS (Action):** hold-to-talk → POST /agent-context, run the plan on the user's engine,
   POST /agent-reads, show the proposed action, confirm → /execute. Same "always confirm writes" rule.
5. **Account:** plan status, connected apps (list/connect/disconnect via the relay), sign out.

## Hard rules
- Never ship the company's Anthropic/Composio keys in the app. The device holds only the user's
  session token (SecureStore) and, optionally, the user's own AI key.
- Locked notes: decrypt only in memory after the user enters that note's password; never persist plaintext.
- Writes (sending email, creating events, etc.) ALWAYS require explicit user confirmation.
- Match the macOS data shapes exactly so a note made on the phone shows correctly on the Mac and vice versa.

## First deliverable
Set up the Expo app, Clerk auth, Convex client, and a working **Dictate → clean text → Share**
flow on a physical iPhone (EAS dev build), reading the signed-in user's real account. Then Notes sync.

## Verification gate before "done" on any milestone
- `npx tsc --noEmit` clean, `eas build` (or `expo run:ios`) succeeds on device.
- Sign in with a real Verba account → a Note created on the phone appears in Convex and on the Mac.
- The dictate flow produces clean text end-to-end on a physical device (not just the simulator's fake mic).

Ask me for: the Clerk publishable key, the Convex deployment URL, and the verba.run base URL —
or read them from the Mac app's config if I point you at the Verba repo.
