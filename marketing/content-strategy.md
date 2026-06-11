# Verba — Content Strategy

> Deliverable 4 of the Verba GTM package · Skill: `/omg-content-strategy` (R-MARKETING: upstream of social & ad-creative)
> Reads: `.agents/product-marketing.md` + `marketing/gtm-strategy.md`. Scope: **Verba only**.
> Date: 2026-06-11 · Author: Oracle (OmegaOS)

**Goal of content:** capture existing high-intent demand (searchable) *and* create demand by spreading two ideas
(shareable): *"your voice shouldn't leave your Mac"* and *"stop paying twice for AI you already own."* Search first
(it's the compounding foundation), then shareable on top. Every piece maps to the beachhead (Claude Code devs) before
widening. Distribution follows GTM Engines A (SEO), B (community/launch), C (creators).

---

## 1. Content pillars (the 4 topics Verba will own)

| # | Pillar | What it owns | Searchable / Shareable | Connects to product via |
|---|---|---|---|---|
| **P1** | **Voice-driven coding** (the wedge) | "dictate to Claude Code / Cursor," "speak your spec," vibe-coding by voice | Both | Coding mode (Opus) + reuse-your-Claude-Code-sub (no key) |
| **P2** | **Private, on-device dictation** | "local voice-to-text Mac," "does my dictation app upload my audio," privacy | Searchable-led | On-device Whisper/Parakeet, audio never uploaded, Keychain |
| **P3** | **Bring-your-own-AI / no markup** | "use my Claude sub without an API key," "stop paying AI markups" | Shareable-led | BYOK: Claude Code / Anthropic / OpenRouter / local Ollama |
| **P4** | **Best Mac dictation app / comparisons** | "Wispr Flow alternative," "X vs Y," "best Mac dictation 2026" | Searchable (bottom-funnel) | The whole product; **already built** at `/compare` + `/vs/[slug]` |

Pillars 1 & 3 are *category-of-one* (no competitor can write them credibly) — over-index there. Pillar 4 is already a
shipped asset; **expand it, don't rebuild it.** Pillar 2 is the broadest evergreen search base.

---

## 2. Topic clusters (hub → spokes)

**P1 · Voice-driven coding** — *hub:* "How to code by voice with AI (the 2026 setup)"
- Spoke: "Dictate prompts to Claude Code without typing" *(decision/impl, category-of-one)*
- Spoke: "Voice-to-text for Cursor: speak your spec, ship faster"
- Spoke: "Turn a 20-minute voice ramble into a clean PR description"
- Spoke: "Hands-free coding: voice commands + dictation on the Mac"
- Spoke (shareable): "I dictated for a week instead of typing — here's what happened to my coding flow"

**P2 · Private, on-device dictation** — *hub:* "Private voice-to-text on the Mac: the complete guide"
- Spoke: "Does [Wispr Flow / Otter / Aqua] upload your audio? What 'on-device' really means"
- Spoke: "Offline dictation on a Mac (no internet, no cloud) — how it works"
- Spoke: "Dictation for lawyers / doctors / journalists: keeping audio confidential"
- Spoke: "Where dictation apps store your audio and API keys (and why it matters)" *(Superwhisper-disk angle)*

**P3 · Bring-your-own-AI / no markup** — *hub:* "Bring your own AI: stop paying a markup on dictation"
- Spoke (shareable): "You're paying twice for AI. Here's the math." *(original cost breakdown — data content)*
- Spoke: "Use your Claude Code subscription for dictation — no API key" *(category-of-one)*
- Spoke: "Anthropic key vs OpenRouter vs local Ollama for Mac dictation: which to pick"
- Spoke: "Run your entire dictation pipeline locally (Parakeet + Ollama), zero cloud"

**P4 · Comparisons (expand the built asset)** — *hub:* `/compare` (live)
- Spokes (live): Verba vs Wispr Flow, Superwhisper, MacWhisper, Aqua, Willow, VoiceInk, Apple Dictation, Otter, TalkTastic
- **New spokes to add:** "Best Mac dictation app 2026 (honest comparison)," "Wispr Flow alternatives that run offline,"
  "Cheapest AI dictation apps that don't upload your voice," "Superwhisper alternative that keeps audio off your disk"

---

## 3. Keyword map by buyer stage

Using the skill's proven modifiers (awareness → consideration → decision → implementation):

| Stage | Modifiers | Verba target queries | Pillar |
|---|---|---|---|
| **Awareness** | what is, how to, guide | "how to dictate faster on Mac," "how to code by voice," "what is on-device transcription" | P1, P2 |
| **Consideration** | best, top, vs, alternatives | "best Mac dictation app," "Wispr Flow alternative," "Superwhisper vs," "private dictation app" | P4, P2 |
| **Decision** | pricing, review, trial, download | "Verba review," "Verba pricing," "Verba vs Wispr Flow," "download Mac dictation app" | P4 |
| **Implementation** | setup, tutorial, how to use | "set up voice-to-text for Claude Code," "dictation Cursor setup," "run dictation offline Mac" | P1, P3 |

Bottom-funnel (consideration/decision) first — it converts now and Verba already half-owns it via `/vs`. Awareness content
compounds slower; layer it once the high-intent base ranks.

---

## 4. Priority scoring (skill's 4-factor model)

*Customer Impact 40% · Content-Market Fit 30% · Search Potential 20% · Resources 10% — scored 1–10.*

| # | Topic | Type | Impact | Fit | Search | Resources | **Total** |
|---|---|---|---|---|---|---|---|
| 1 | Best Mac dictation app 2026 (honest comparison) | Searchable | 9 | 9 | 9 | 7 | **8.8** |
| 2 | Use your Claude Code sub for dictation, no API key | Both | 10 | 10 | 7 | 8 | **9.1** |
| 3 | Dictate prompts to Claude Code / Cursor (hub) | Both | 9 | 10 | 7 | 7 | **8.6** |
| 4 | Wispr Flow alternatives that run offline | Searchable | 8 | 9 | 8 | 8 | **8.3** |
| 5 | "You're paying twice for AI" — the cost math | Shareable | 9 | 9 | 5 | 7 | **8.0** |
| 6 | Does your dictation app upload your audio? | Searchable | 8 | 8 | 8 | 8 | **8.0** |
| 7 | I dictated for a week instead of typing (story) | Shareable | 8 | 8 | 4 | 6 | **7.0** |
| 8 | Private dictation for lawyers/doctors/journalists | Searchable | 7 | 8 | 6 | 7 | **7.1** |
| 9 | Run dictation fully offline (Parakeet + Ollama) | Impl | 7 | 8 | 5 | 6 | **6.7** |
| 10 | Speak one language, send another (Translate) | Searchable | 6 | 7 | 6 | 7 | **6.4** |

**Start with #2, #1, #3, #4** — highest total *and* they map to the beachhead. #2 and #3 are category-of-one (defensible moat).

---

## 5. 90-day editorial calendar (mapped to GTM phases)

**Weeks 1–4 — Foundation (GTM Phase 0).** *Fix funnel, build the high-intent base.*
- Publish: "Best Mac dictation app 2026 (honest)" [#1] · "Use your Claude Code sub for dictation, no key" [#2] · expand
  3 `/vs` pages with fresh data · ship the canonical **60-sec "speak-vs-type" demo video** (reuse across every channel).
- Foundation: one true free-tier message live everywhere (33 dictations); analytics on the funnel.

**Weeks 5–8 — Beachhead launch (GTM Phase 1).** *Win the developers.*
- Publish: "Dictate prompts to Claude Code / Cursor (hub)" [#3] · "Wispr Flow alternatives that run offline" [#4].
- Distribute: **Show HN**, r/macapps, r/ClaudeAI, Lobsters; **building-in-public** thread on X (founder's agentic-builder story);
  seed 10–20 dev creators with the demo video.
- Shareable drop: **"You're paying twice for AI — the math"** [#5] (original cost-breakdown → designed for HN/X).

**Weeks 9–12 — Compound & widen (GTM Phase 1→2).**
- Publish: "Does your dictation app upload your audio?" [#6] · "Private dictation for lawyers/doctors/journalists" [#8] ·
  "I dictated for a week instead of typing" [#7, shareable].
- Distribute: prep **Product Hunt** (reviews + demo + lifetime/Founder tier as the launch hook); turn on referral + leaderboard
  share prompts; first multilingual/notes spoke for Expand segments.

*Cadence:* ~2 searchable + ~1 shareable per fortnight is enough — quality and distribution beat volume for a solo/founder team.

---

## 6. Formats & channels (match the audience)

- **Written/SEO** (owned site `/blog`, `/compare`, `/vs`, use-case pages) — the compounding core. Most posts live under
  `/blog/post-title`; only P1/P4 warrant hub/spoke URL depth.
- **Short video / GIF** — the product is *visually* demoable. One canonical 60-sec demo + 15-sec clips per mode (Coding,
  Context, Translate, Notes). Fuel for X, Reddit, PH, YouTube, creator outreach.
- **Building-in-public (X / dev blog)** — founder voice; the single highest-trust channel for the dev beachhead.
- **Community posts** — Show HN, r/macapps, r/ClaudeAI, Lobsters, Cursor/Claude Discords. Lead with the demo, never a pitch.
- **AI/LLM discoverability** — structure comparison + use-case pages with clear claims and schema so LLMs cite Verba when
  asked "best private Mac dictation app / Wispr Flow alternative" (a fast-growing discovery surface).

## 7. Ideation engine (keep the pipeline full)

- **Forum mining:** `site:reddit.com/r/macapps dictation`, `site:reddit.com/r/ClaudeAI voice`, HN, Indie Hackers — harvest real
  questions/objections → FAQ + blog posts (voice-of-customer phrasing already captured in `.agents/product-marketing.md`).
- **Competitor gaps:** none of the competitors can write Pillars 1 or 3 honestly — publish there relentlessly.
- **Support/sales input:** as install volume grows, route repeated questions (BYOK setup, "is it private," "Mac-only?") straight
  into content. The wishlist feature in-app (`WishlistView.swift`) is a built-in idea source.

---

## 8. Guardrails (voice & integrity)

- **Honesty as the brand** — keep the `/vs` "where they still win" sections; it's why developers trust the comparisons.
- **Never claim a feature the product doesn't ship** — everything maps to `.agents/product-marketing.md`. (iOS is *scaffolded*,
  not shipped — don't market it yet.)
- **Words:** on-device, private, your AI, your Claude sub, no markup, clean, offline, vibe coding. **Avoid:** "uploads,"
  "cloud-only," "we train on your data," "transcription" alone (Verba *restructures*).
- **One canonical free-tier story** in every asset (33-dictation trial) until/unless the product changes.
