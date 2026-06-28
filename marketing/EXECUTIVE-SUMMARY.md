# Verba — Executive Summary

> **For: the prospective marketing co-founder.** One page. The play, and the path to €5–15k/mo.
> Everything below is grounded in the live product (verba.run) and the repo — no invented features.
> Date: 2026-06-11 · **Last updated: 2026-06-12** (post-JARVIS: Verba is now **voice → action**) · Backing detail: `market-research.md` · `../.agents/product-marketing.md` · `gtm-strategy.md` · `content-strategy.md`

## The product, in one line
**Verba turns your rambling speech into clean, ship-ready text anywhere on your Mac — and now *acts* on what you say** —
press a key, talk, and Claude restructures it where your cursor is; say *"create the Linear issue, email the team,"*
confirm, done. *Speak it. Send it clean.* ($9.99/mo · macOS · live at verba.run)

## What just changed (June 2026 — the JARVIS wave)
Action mode became **JARVIS**, a confirm-gated voice agent on **1,000+ connected apps** (Gmail, Slack, Notion, Linear,
GitHub…) plus native Mac actions — it plans the steps, asks when ambiguous, shows exactly what it will do, and executes
only after you confirm (commits 5ae8804, 7452012; `ActionExecutor.swift`). The **plan is generated on-device by the
user's own Claude Code / local model — never our server key** (d86685b), and every proposed action is schema-validated
and auto-repaired across the hardened full catalog (989 toolkits / 36,998 tools — 0bec783, 83da81b). This moves Verba's
category from "dictation + AI cleanup" to **voice → action** — a slot no dictation competitor occupies.

## Why now (the market is validated and hot)
- **A $2B incumbent proves the category.** Wispr Flow — the cloud tool Verba benchmarks against — is raising **~$260M at a
  ~$2B valuation** (May 2026), ~3× its valuation six months earlier.
- **The market is big and compounding:** AI speech-to-text *tools* ≈ **$3.87B in 2026 → $16.4B by 2035 (17% CAGR)**.
- **A second wave is unique to us:** **Claude Code** is the most-loved developer tool (reportedly 46% of 15,000 devs, Pragmatic Engineer survey, Feb 2026) and at a reported
  **$2.5B+ run rate.** Verba's signature feature lets those developers **reuse the Claude subscription they already pay for —
  no API key, no markup.** *We are the voice layer for the Claude Code generation.*

## The wedge & the moat — why Verba wins
The market's mental model is *"cloud → Wispr, local → Superwhisper, transcription → MacWhisper."* **Nobody owns "local + real
AI restructuring + bring-your-own-Claude" — and nobody at all owns "voice that *acts*."** Four differentiators, three of them category-of-one:
1. **Bring your own AI — including your Claude Code sub, with no key.** *No competitor has this.* Zero inference cost to us.
2. **Voice → action (JARVIS).** Dictate the intent; it plans on-device, you confirm, it executes — across **1,000+
   connected apps** + native Mac actions. *No dictation competitor executes* (the closest, TalkTastic, stops at Mac-local
   commands). The demo — "I said it, it did it" — is the viral asset.
3. **Private by default** — on-device transcription, **your audio never leaves the Mac and is never uploaded** (cloud sync is
   text-only; local history has an off switch) — and **even the action planner runs on-device with the user's own AI**. Beats every cloud tool, which uploads every word; vs Superwhisper the edge is
   Keychain-stored keys + an off switch (both keep local history by default).
4. **Does what others can't** — reads your screen (Context/vision), hour-long structured Notes, live Translate, stacked
   chained dictations. Most rivals only transcribe.
Priced **below** the cloud incumbents ($9.99 vs $12–17) while doing more — and at a **very high gross margin** (users bring the AI — even for action planning — so zero inference cost). The app now ships **localized in 14 languages** (998 UI strings), opening the international expansion lane.

## The go-to-market motion (self-serve, not sales)
**Land narrow → expand.** Beachhead = **Claude Code-native Mac developers** (concentrated in HN, r/macapps, r/ClaudeAI,
Cursor/Claude Discords, dev YouTube; reachable with **zero ad spend** — and JARVIS makes *their own Claude Code* the
action planner). Then expand to privacy-first professionals → voice-first operators (the new JARVIS segment) →
multilingual workers (app ships in 14 languages) → long-form note-takers. Three compounding engines:
- **Comparison & use-case SEO + GEO** (the rebuilt 24-feature × 10-brand `/compare` matrix + `/vs` pages already ship,
  with JSON-LD, `/llms.txt` and AI-crawler-ready robots — high-intent, bottom-funnel, and cited by LLMs).
- **Community & launch** (Show HN, Product Hunt, founder building-in-public — and the JARVIS clip: *"I dictate 'create
  the issue and email the team' — it shows both actions, I confirm, done"* is the stop-scrolling demo).
- **Creators** (dev/Mac reviewers; "speak-vs-type, it reuses your Claude sub — and it *acts*" sells itself).
**Conversion** runs on a smart **forced-value trial** already in the product (33 free dictations → paywall → 7-day Pro trial),
plus **two growth loops already coded**: a referral "Free Month" and a public leaderboard. *Turn them on and make them visible.*

## The path to €5–15k/mo (it's a distribution problem, not a market problem)
At current pricing the target is a **tiny, concrete subscriber count** — under **0.1% of the category**:

| Monthly recurring | Paying subscribers (blended ~€7.6/mo) | Downloads needed @ 7% convert |
|---|---|---|
| **€5,000** | **~660** | ~9,400 |
| **€10,000** | **~1,320** | ~19,000 |
| **€15,000** | **~1,975** | ~28,000 |

For scale: one indie competitor (MacWhisper) shows ~1,900 paying-tier reviews alone. **~600–2,000 subscribers is achievable**
in 9–12 months with the engine above — and because there's no inference cost, that revenue is near-pure margin that funds the
founder off product instead of consulting.

## The first 90 days (where a marketing co-founder starts)
1. **Fix two residual copy gaps (both ~1-day, high leverage; re-verified 2026-06-12, still open):** the site now says "33 dictations" everywhere except the web
   Try-It demo endpoint (`api/try/route.ts`), which still nudges "10,000 words/month"; and keep the privacy claim accurate —
   audio is kept in local history by default (`History.swift`), so never say "nothing written to disk." Both are credibility fixes before spend.
2. **Nail first-run activation** (zero-key Claude Code path + instant offline Parakeet; first dictation < 60s — then first connected app + first confirmed action) and instrument the funnel.
3. **Launch to developers** — comparison + "voice for Claude Code" + voice-actions content, Show HN, seed 10–20 creators, ship the 60-sec demo **ending on a JARVIS action**, add a Lifetime/Founder tier as the launch hook.

## Why this is a good co-founder bet
A **real, shipped product** in a **$2B-validated, fast-growing category**, with **three category-of-one moats** (BYO-Claude,
voice → action on 1,000+ apps, screen-vision Context), a **very high gross
margin** (zero inference COGS — even the action planner runs on the user's own AI), and **growth loops already built** (referral, leaderboard, full gamification) — run by a founder who builds agentic systems and markets in public. The product
risk is largely behind us; the open game is **distribution and conversion** — exactly the seat we're offering. The market
existence question is settled. The only question left is execution, and that's the job.

---
*Full package: this folder (`marketing/`) + the positioning SSOT at `../.agents/product-marketing.md`. Start with `README.md`.*
