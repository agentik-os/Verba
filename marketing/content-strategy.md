# Verba — Content Strategy

> Deliverable 4 of the Verba GTM package · Skill: `/omg-content-strategy` (R-MARKETING: upstream of social & ad-creative)
> Reads: `.agents/product-marketing.md` + `marketing/gtm-strategy.md`. Scope: **Verba only**.
> Date: 2026-06-11 · **Last updated: 2026-06-12** (post-JARVIS: adds the voice → action pillar P5) · Author: Oracle (OmegaOS)

**Goal of content:** capture existing high-intent demand (searchable) *and* create demand by spreading three ideas
(shareable): *"your voice shouldn't leave your Mac,"* *"stop paying twice for AI you already own,"* and — new with
JARVIS — *"your voice shouldn't just type; it should* do." Search first
(it's the compounding foundation), then shareable on top. Every piece maps to the beachhead (Claude Code devs) before
widening. Distribution follows GTM Engines A (SEO+GEO), B (community/launch), C (creators).

---

## 1. Content pillars (the 5 topics Verba will own)

| # | Pillar | What it owns | Searchable / Shareable | Connects to product via |
|---|---|---|---|---|
| **P1** | **Voice-driven coding** (the wedge) | "dictate to Claude Code / Cursor," "speak your spec," vibe-coding by voice | Both | Coding mode (Opus) + reuse-your-Claude-Code-sub (no key) |
| **P2** | **Private, on-device dictation** | "local voice-to-text Mac," "does my dictation app upload my audio," privacy | Searchable-led | On-device Whisper/Parakeet, audio never uploaded, Keychain — and on-device action planning |
| **P3** | **Bring-your-own-AI / no markup** | "use my Claude sub without an API key," "stop paying AI markups" | Shareable-led | BYOK: Claude Code / Anthropic / OpenRouter / local Ollama |
| **P4** | **Best Mac dictation app / comparisons** | "Wispr Flow alternative," "X vs Y," "best Mac dictation 2026" | Searchable (bottom-funnel) | The whole product; **already built** at `/compare` (24-feature × 10-brand matrix) + `/vs/[slug]` |
| **P5** | **Voice → action / "Jarvis for Mac"** *(new)* | "voice assistant that actually does things," "control apps by voice Mac," "create Linear issue by voice," "voice agent" | Shareable-led (the viral demo) + emerging search | JARVIS Action agent: on-device plan → confirm → execute on 1,000+ connected apps (`ActionExecutor.swift`, commit 5ae8804) |

Pillars 1, 3 & 5 are *category-of-one* (no competitor can write them credibly) — over-index there. Pillar 4 is already a
shipped asset; **expand it, don't rebuild it.** Pillar 2 is the broadest evergreen search base. P5 is the youngest
search market (queries are still forming) — win it with demos and own the vocabulary early.

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

**P4 · Comparisons (expand the built asset)** — *hub:* `/compare` (live — rebuilt as a 24-feature × 10-brand honest matrix, ebcdcff)
- Spokes (live): Verba vs Wispr Flow, Superwhisper, MacWhisper, Aqua, Willow, VoiceInk, Apple Dictation, Otter, TalkTastic
- **New spokes to add:** "Best Mac dictation app 2026 (honest comparison)," "Wispr Flow alternatives that run offline,"
  "Cheapest AI dictation apps that don't upload your voice," "Superwhisper alternative that keeps audio off your disk,"
  "Dictation apps that can *act* on what you say (spoiler: one)"

**P5 · Voice → action ("Jarvis for Mac")** — *hub:* "Your Mac, by voice: the complete guide to voice actions"
- Spoke (shareable, the flagship): **"I ran my morning by voice"** — create the Linear issue, send the email, schedule
  the call — each action shown and confirmed on camera *(demo-led, designed for X/HN/YouTube)*
- Spoke: "Create Linear issues / send Gmail / post to Slack by voice on the Mac" *(one per top connected app — programmatic potential across the 1,000+ catalog)*
- Spoke: "What a voice agent should never do without asking — how confirm-gated actions work" *(trust content; mirrors the read/write fail-safe design)*
- Spoke: "Siri can't, JARVIS can: what 'voice assistant' actually means in 2026"
- Spoke (P2 crossover): "An agent that plans on your Mac — why the planner runs on your own AI, not our server"

---

## 3. Keyword map by buyer stage

Using the skill's proven modifiers (awareness → consideration → decision → implementation):

| Stage | Modifiers | Verba target queries | Pillar |
|---|---|---|---|
| **Awareness** | what is, how to, guide | "how to dictate faster on Mac," "how to code by voice," "what is on-device transcription," "voice assistant that does things Mac" | P1, P2, P5 |
| **Consideration** | best, top, vs, alternatives | "best Mac dictation app," "Wispr Flow alternative," "Superwhisper vs," "private dictation app," "Jarvis for Mac" | P4, P2, P5 |
| **Decision** | pricing, review, trial, download | "Verba review," "Verba pricing," "Verba vs Wispr Flow," "download Mac dictation app" | P4 |
| **Implementation** | setup, tutorial, how to use | "set up voice-to-text for Claude Code," "dictation Cursor setup," "run dictation offline Mac," "create Linear issue by voice," "send email by voice Mac" | P1, P3, P5 |

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
| 11 | **"I ran my morning by voice" — the JARVIS demo story** *(new)* | Shareable | 10 | 10 | 4 | 7 | **8.9** |
| 12 | **Create Linear issues / send Gmail / Slack by voice (per-app how-tos)** *(new)* | Impl/Search | 8 | 9 | 6 | 8 | **7.9** |
| 13 | **How confirm-gated voice actions work (trust explainer)** *(new)* | Searchable | 7 | 9 | 5 | 8 | **7.3** |

**Start with #2, #1, #11, #3, #4** — highest total *and* they map to the beachhead. #2, #3 and #11 are category-of-one
(defensible moat). #11 doubles as the canonical demo video script (GTM Engines B+C).

---

## 5. 90-day editorial calendar (mapped to GTM phases)

**Weeks 1–4 — Foundation (GTM Phase 0).** *Fix funnel, build the high-intent base.*
- Publish: "Best Mac dictation app 2026 (honest)" [#1] · "Use your Claude Code sub for dictation, no key" [#2] · expand
  3 `/vs` pages with fresh data · ship the canonical **60-sec demo video — speak-vs-type, ending on a JARVIS action**
  ("…and when I say 'create the issue,' it does it") (reuse across every channel).
- Foundation: one true free-tier message live everywhere (33 dictations — `api/try/route.ts` is the last holdout); analytics on the funnel.

**Weeks 5–8 — Beachhead launch (GTM Phase 1).** *Win the developers.*
- Publish: "Dictate prompts to Claude Code / Cursor (hub)" [#3] · "Wispr Flow alternatives that run offline" [#4].
- Distribute: **Show HN**, r/macapps, r/ClaudeAI, Lobsters; **building-in-public** thread on X (founder's agentic-builder story);
  seed 10–20 dev creators with the demo video.
- Shareable drops: **"You're paying twice for AI — the math"** [#5] (original cost-breakdown → designed for HN/X) ·
  **"I ran my morning by voice"** [#11] (the JARVIS flagship — actions shown + confirmed on camera; the X/HN/YouTube clip).

**Weeks 9–12 — Compound & widen (GTM Phase 1→2).**
- Publish: "Does your dictation app upload your audio?" [#6] · "Private dictation for lawyers/doctors/journalists" [#8] ·
  "I dictated for a week instead of typing" [#7, shareable] · first per-app voice-action how-tos [#12: Linear, Gmail, Slack]
  + the confirm-gating trust explainer [#13].
- Distribute: prep **Product Hunt** (reviews + demo + lifetime/Founder tier as the launch hook); turn on referral + leaderboard
  share prompts; first multilingual/notes spoke for Expand segments.

*Cadence:* ~2 searchable + ~1 shareable per fortnight is enough — quality and distribution beat volume for a solo/founder team.

---

## 6. Formats & channels (match the audience)

- **Written/SEO** (owned site `/blog`, `/compare`, `/vs`, use-case pages) — the compounding core. Most posts live under
  `/blog/post-title`; only P1/P4 warrant hub/spoke URL depth.
- **Short video / GIF** — the product is *visually* demoable. One canonical 60-sec demo + 15-sec clips per mode (Coding,
  Context, Translate, Notes) **+ per-action JARVIS clips** ("say it → confirm → done" in Linear, Gmail, Slack, Calendar —
  the most shareable unit Verba has). Fuel for X, Reddit, PH, YouTube, creator outreach.
- **Building-in-public (X / dev blog)** — founder voice; the single highest-trust channel for the dev beachhead.
- **Community posts** — Show HN, r/macapps, r/ClaudeAI, Lobsters, Cursor/Claude Discords. Lead with the demo, never a pitch.
- **AI/LLM discoverability (GEO)** — *substantially shipped (ebcdcff):* site-wide JSON-LD (SoftwareApplication,
  Organization, FAQPage), an `/llms.txt` fact sheet, and robots.ts welcoming AI crawlers (GPTBot, ClaudeBot,
  PerplexityBot, Google-Extended). Keep new content structured the same way so LLMs cite Verba for "best private Mac
  dictation app / Wispr Flow alternative / Jarvis for Mac" (a fast-growing discovery surface).

## 7. Ideation engine (keep the pipeline full)

- **Forum mining:** `site:reddit.com/r/macapps dictation`, `site:reddit.com/r/ClaudeAI voice`, HN, Indie Hackers — harvest real
  questions/objections → FAQ + blog posts (voice-of-customer phrasing already captured in `.agents/product-marketing.md`).
- **Competitor gaps:** none of the competitors can write Pillars 1 or 3 honestly — publish there relentlessly.
- **Support/sales input:** as install volume grows, route repeated questions (BYOK setup, "is it private," "Mac-only?") straight
  into content. The wishlist feature in-app (`WishlistView.swift`) is a built-in idea source.

---

## 8. Guardrails (voice & integrity)

- **Honesty as the brand** — keep the `/vs` "where they still win" sections and the /compare matrix's "this table stays
  honest" sourcing; it's why developers trust the comparisons.
- **Never claim a feature the product doesn't ship** — everything maps to `.agents/product-marketing.md`. (iOS is *scaffolded*,
  not shipped — don't market it yet.)
- **Name the agent right:** the public names are **JARVIS** and **connected apps** — never "Composio" in public copy
  (deliberately removed from app + site, commit 5ae8804; Composio is internal infrastructure).
- **Never show an unconfirmed write in a demo.** The confirm step *is* the trust story — keep it in every clip; "it asks
  before it acts" is a feature, not friction to edit out.
- **Words:** on-device, private, your AI, your Claude sub, no markup, clean, offline, vibe coding, voice agent, confirm,
  connected apps. **Avoid:** "uploads,"
  "cloud-only," "we train on your data," "transcription" alone (Verba *restructures* — and now *acts*), "fully autonomous" (it's confirm-gated by design).
- **One canonical free-tier story** in every asset (33-dictation trial) until/unless the product changes.
