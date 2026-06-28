# Verba — Go-to-Market Strategy

> Deliverable 3 of the Verba GTM package · Skill: `/omg-marketing-strategist` (R-MARKETING: the strategist lens)
> Reads: `.agents/product-marketing.md` + `marketing/market-research.md`. Scope: **Verba only**.
> Date: 2026-06-11 · **Last updated: 2026-06-12** (post-JARVIS: voice → action, on-device planning, /compare rebuild) · Author: Oracle (OmegaOS)

**Honest framing (L2).** The strategist skill is written for **B2B SaaS** (demand gen, ABM, sales-led). Verba is a
**self-serve B2C / prosumer Mac app at $9.99/mo with no sales team and no App Store**. So we apply the skill's
*strategic principles* — lead with strategy, **own the narrative / create the category**, measure revenue not vanity,
scale with systems — through a **Product-Led + Community + Creator** motion. No enterprise ABM. The goal is a repeatable
self-serve engine, not a pipeline org.

---

## 1. The one-sentence strategy

> **Win the privacy-and-cost-conscious Mac power-user — starting with the Claude Code developer — by being the only
> dictation app that *acts* on what you say (JARVIS: dictate → confirm → done, across 1,000+ connected apps) while
> keeping audio *and the action planning* on the device and letting them reuse the AI subscription they already pay for;
> distribute through developer communities, comparison SEO, and creator demos — with the "I dictate → it creates the
> Linear issue / sends the email" demo as the viral asset; convert via a forced-value free trial; and compound with the
> referral + leaderboard loops already in the product.**

Everything below serves that sentence and the north star: **€5–15k/mo recurring (≈ 600–2,000 paying subs).**

---

## 2. Positioning & narrative — don't fight Wispr, reframe the category

Wispr Flow is a **$2B cloud incumbent**. We will not out-spend it or beat it at cross-platform cloud. We **reframe**:

- **Category we play in (theirs):** "AI dictation." We lose here — they own the word.
- **Category we *create* (ours):** **"The private, bring-your-own-AI voice workspace for the Mac — that *acts*"** — *the
  Claude Code voice layer, and the first credible Jarvis for the Mac.* The frame: *"Cloud dictation tools upload your
  voice and charge you a markup on AI you already pay for — and at the end, all they do is type. Verba runs on your Mac,
  reuses your Claude subscription, and when you say 'create the issue, email the team' — it does it, after you confirm."*
  The JARVIS wave (commits 5ae8804…ebcdcff) widens the wedge from *dictation + restructuring* to **voice → action**:
  a category no dictation competitor occupies (market-research §3).

**Positioning statement (canonical, use everywhere):**
> *For Mac power-users who think faster than they type and care about privacy and cost, **Verba** is the voice app
> that turns rambling speech into clean, ship-ready text anywhere on your Mac — **and acts on what you say** (dictate
> the intent, confirm, done — across 1,000+ connected apps). Uniquely **private by default** (on-device — even the
> action planning runs on your Mac) and **bring-your-own-AI** (reuse your Claude Code subscription, no markup).
> Unlike Wispr Flow and other cloud tools, Verba does more than transcribe, never uploads your voice, and never acts
> without your confirmation.*

**Three narrative pillars (the only three messages we repeat):**
1. **Private by default** — your voice never leaves your Mac; **even the action planner runs on-device with your own AI**, never our key (d86685b). (vs all cloud tools + Superwhisper's disk writes)
2. **Bring your own AI** — reuse your Claude Code sub, no key, no markup — for restructuring *and* for planning actions. (*category-of-one*)
3. **Voice → action: it doesn't just type, it *does*** — JARVIS plans, asks when unsure, shows the action, and executes on your confirm across 1,000+ connected apps; plus screen vision, hour-long notes, live translate. (*category-of-one; the demo that wins every channel*)

---

## 3. Segmentation & sequencing — land narrow, expand deliberately

| Phase | Segment | Why first | Where they are | The hook |
|---|---|---|---|---|
| **Beachhead** | **Claude Code-native Mac developers** | Largest *reachable* + fastest-growing pool; the BYO-Claude wedge is built for them; zero-ad channels; **JARVIS makes their Claude Code the action planner** | HN, Lobsters, r/macapps, r/ClaudeAI, X dev, Cursor/Claude Discords, dev YouTube | "The voice layer for Claude Code — speak your spec, or just say 'create the issue' and confirm. Your sub does the planning." |
| **Expand 1** | **Privacy-first professionals** (legal, medical, founders, journalists) | Highest willingness-to-pay; "your audio never leaves your Mac" is decisive — and now "the agent plans on your Mac too" | Niche newsletters, prosumer Mac press, LinkedIn, privacy communities | "On-device dictation — your audio never leaves your Mac, never uploaded; even the action planning runs on-device; local history with an off switch." |
| **Expand 2** | **Voice-first operators** (founders, PMs, exec-without-an-EA) *(new — opened by JARVIS)* | The "real Jarvis" demand pocket; no dictation competitor executes; high WTP for time saved | Productivity YouTube, indie-founder X, r/productivity, newsletter sponsorships | "Say it once: 'schedule it, send it, file it.' It shows you the action, you confirm, it's done — across 1,000+ apps." |
| **Expand 3** | **Multilingual knowledge workers** (EU/LatAm) | Translate mode is a standalone wedge; underserved; the app now ships in 14 languages (b3dd02c) | Localized SEO, regional creators | "Think in your language, write in theirs — every time." |
| **Expand 4** | **Long-form thinkers / note-takers** | Notes tab is a second product inside the app | Productivity/PKM communities (Obsidian, Notion, r/productivity) | "Talk for an hour, get a clean document." |

**Rule:** do not market all five at once. Win the developers first (concentration + word-of-mouth), then widen the message.
The product already serves all five — sequencing is a *messaging* decision, not a build decision.

---

## 4. Channel strategy — three compounding engines, zero paid-first

Verba's economics (zero inference COGS, $9.99) and audience (developers, privacy folks) favor **earned + owned** over paid.

**Engine A — Comparison & use-case SEO + GEO (compounding, owned).** *Already substantially built — upgraded 2026-06-12.*
- The repo ships programmatic `/vs/[slug]` pages for 9 competitors (`website/lib/competitors.ts`) **and the rebuilt
  `/compare`: an honest 24-feature × 10-brand matrix** (`website/lib/compare-matrix.ts`, commit ebcdcff) where the
  voice→action rows are Verba-only. "Wispr Flow alternative," "Superwhisper vs," "local Mac dictation" are high-intent,
  bottom-funnel queries.
- **GEO (AI-answer optimization) shipped** (ebcdcff): site-wide JSON-LD (SoftwareApplication, Organization, FAQPage),
  an `/llms.txt` fact sheet for ChatGPT/Claude/Perplexity/AI Overviews, and robots.ts explicitly welcoming AI crawlers —
  positioned to be *the cited answer* for "best private Mac dictation app" as LLM search grows.
- **Action:** expand to use-case pages ("dictation for coding," "voice to text for Cursor/Claude Code," "private dictation
  for lawyers," **"Jarvis for Mac / control your apps by voice"**) and keep the /vs + matrix data honest and current.
  This is the **content-strategy** deliverable (next doc).

**Engine B — Community & launch (spiky, earned).**
- **Developer communities** are the beachhead's home: Show HN, r/macapps, r/ClaudeAI, Lobsters, X. The product is
  inherently demoable — and JARVIS upgrades the demo from impressive to **viral**: *"watch me dictate 'create the Linear
  issue for this bug and email the team a summary' — Verba plans it, shows me both actions, I hit confirm, done."*
  A voice agent acting on real tools, planned by the viewer's own Claude Code, is a stop-scrolling clip.
- **Product Hunt launch** when activation + reviews are solid (MacWhisper got ~1,900 PH reviews — the surface works for this category). The JARVIS wave is the natural headline ("the Mac dictation app that became a voice agent").
- **Founder-led building-in-public** on X / a dev blog: Gareth is an agentic-systems builder — that story (one founder,
  agentic dev, privacy-first, shipping a confirm-gated agent) *is* marketing to this exact crowd.

**Engine C — Creators & demos (leveraged, earned→paid later).**
- Dev/Mac/productivity YouTubers, streamers, and newsletter writers who already review dictation tools. Seed licenses;
  two demos sell themselves: "speak vs type, 4× faster, and it reuses your Claude sub" **and the JARVIS clip — "I said
  it, it did it (after asking)."** The second one travels beyond the dictation niche into the much larger
  agent/productivity audience.
- Later, a small affiliate/referral % stacked on the **built-in referral loop**.

**Paid (only after organic proves conversion):** retarget /compare visitors; search ads on "Wispr Flow alternative" /
"Mac dictation." Because COGS≈0, even modest LTV supports paid — but earn the playbook organically first.

---

## 5. The funnel & conversion model

**The journey (and where to instrument):**
```
Discover (SEO / community / creator)
  → Download DMG (GitHub Releases)        ← TOP-OF-FUNNEL metric
    → Activate: first dictation < 60s     ← ACTIVATION (the make-or-break)
      → Use 33 free dictations (value)    ← HABIT
        → Hit paywall                     ← MONETIZATION TRIGGER (already built)
          → Start 7-day Pro trial
            → Convert to paid $9.99/$84    ← REVENUE
              → Refer a friend (Free Month) / leaderboard  ← LOOP
```

**The two conversion levers that matter most:**
1. **Activation (first-run).** BYOK is the #1 friction. The **zero-key Claude Code path** must be the hero of onboarding
   ("Have Claude Code? You're ready — no key"), with **offline Parakeet** as the instant no-setup fallback. Target: first
   successful dictation in under 60 seconds, no card, no key.
2. **The 33-dictation paywall.** This is a *forced-value* trial — users hit the wall only after they've felt the magic 33×.
   That's a strong design; protect it. (First, **fix the residual copy gap** — the site now says "33 dictations" everywhere
   except the web Try-It demo endpoint `api/try/route.ts`, which still says "10,000 words/month" — *re-verified 2026-06-12,
   still unfixed*; align it. Also keep the privacy
   claim accurate — audio is in local history by default (`History.swift`), so never say "nothing written to disk." See market research §6.)

**New activation moment (instrument it):** the **first confirmed action** — connecting one app in Settings ▸ Connected
apps and dictating a first "create / send / schedule" that executes. A user whose spoken words have *done something*
has crossed a switching-cost line no pure dictation tool can match; measure "time to first confirmed action" alongside
"time to first dictation."

**Illustrative unit-economics model** (planning assumptions, to be replaced by real funnel data):
| Lever | Conservative | Base | Strong |
|---|---|---|---|
| Download → paid conversion | 4% | 7% | 10% |
| Downloads needed for ~1,320 paid (≈€10k/mo blended) | ~33,000 | ~19,000 | ~13,200 |
| Blended revenue / paying sub / mo | €7.6 | €7.6 | €7.6 |
| Inference COGS / sub | €0 (BYOK) | €0 | €0 |

A 33-use forced-value trial plausibly lands **7–10%** download→paid (well above the 2–5% of un-gated freemium). The job is
to drive **~13–33k cumulative downloads** over 9–12 months — squarely achievable for this category via Engines A–C.

---

## 6. Pricing & packaging recommendations

Keep the core ($9.99/mo · $84/yr · 7-day trial — unchanged in code and on the site as of 2026-06-12: `Entitlement.swift`,
`website/app/page.tsx`). JARVIS ships **inside the same price** — a voice agent on 1,000+ apps at $9.99 while the cloud
incumbents charge $12–17 to *type* is the value story; don't price-segment the agent yet (it's the differentiator, not an
upsell). Three moves to discuss:

1. **Add a Lifetime / Founder tier (high priority).** The category has strong lifetime-deal behaviour — Superwhisper
   $249.99, MacWhisper ~$69, VoiceInk one-time. Verba has **no answer** today. A **one-time "Founder" license (~$149–199)**:
   (a) captures the anti-subscription buyer, (b) front-loads cash for a bootstrapped founder, (c) is a launch/PH lever.
   *Because COGS≈0, lifetime carries no ongoing cost risk* — unusually safe here.
2. **Push annual.** Annual buyers retain better and pre-pay runway. Make annual the default toggle (it already is) and add a
   first-week annual nudge. Trade-off: annual needs more subs for the same MRR (see research §7), but LTV and cash improve.
3. **Hold the line on price.** $9.99 already undercuts the cloud incumbents while doing more. Don't race Aqua/Superwhisper to
   the bottom — **compete on "does more + private + BYO-Claude," not on being cheapest.** Price is a *proof of honesty*, not the pitch.

---

## 7. Growth loops — activate what's already built

Verba ships two viral mechanics that most indie apps bolt on later. **Make them visible:**
- **Referral "Free Month"** (`FreeMonthView.swift`): one free Pro month per validated friend (3 friends = 3 months). *Surface
  it right after a delightful moment* (a great dictation, the 10th use) — not buried in settings. Add a share-sheet + a `?ref` link (the site already captures `?ref` → Stripe metadata).
- **Leaderboard** (`Leaderboard.swift`, Convex): streaks, words dictated, time saved. *Make it shareable* ("I saved 14 hours
  this month with Verba") — turns power-users into broadcasters.
- **Full gamification layer** (`Gamification.swift`): XP, levels, unlockable achievements, daily goal, streak milestones, and
  weekly **league tiers**. A retention engine that also feeds the leaderboard's social reach — wire it into onboarding and notifications.
- **Compounding content (Engine A)** and **creator demos (Engine C)** are the third and fourth loops.

---

## 8. The roadmap to €5–15k/mo

**Phase 0 — Make it convert (weeks 0–4). Goal: a funnel that doesn't leak.**
- Fix the free-tier messaging to one true story (33 dictations) across hero / bento / compare / vs (one file left: `api/try/route.ts`).
- Nail first-run activation: zero-key Claude Code path + offline Parakeet fallback; first dictation < 60s. Then the
  second activation: first connected app + first confirmed action.
- Manufacture first proof: 10–20 seeded reviews/quotes, **the canonical demo video — now ending on a JARVIS action**
  ("…and when I say 'create the issue,' it does it"), 3 use-case pages.
- Instrument the funnel (download → activate → first action → paywall → trial → paid) — you can't scale what you can't see.

**Phase 1 — Win the developers (months 1–4). Goal: first €2–5k/mo.**
- Show HN + r/macapps + r/ClaudeAI + Lobsters; building-in-public on X; founder dev-blog. Lead with the JARVIS clip —
  "your Claude Code sub now runs your Mac by voice" is the thread hook.
- Ship the comparison + coding use-case + voice-actions SEO clusters (content-strategy doc).
- Seed 10–20 dev/Mac creators. Launch the Lifetime/Founder tier as a moment.
- Target: ~700 paying subs → ~€5k/mo. Watch download→paid; iterate onboarding.

**Phase 2 — Widen & compound (months 4–9). Goal: €10–15k/mo.**
- Product Hunt launch (once reviews + activation are strong) — headline: *the Mac dictation app that became a voice agent.*
- Turn on Expand segments 1–4 (privacy, voice-first operators, multilingual — the app ships in 14 languages, notes) with dedicated SEO + creators.
- Make referral + leaderboard prominent; add affiliate % for creators.
- Consider paid retargeting on /compare now that conversion is proven.
- Target: ~1,300–2,000 paying subs → €10–15k/mo.

**Phase 3 — Durability (months 9+).** iOS app (scaffolded) to answer the #1 objection (Mac-only); category-defining content
("the private, BYO-AI voice workspace"); retention/lifecycle email; protect the moat as Wispr/others copy features.

---

## 9. What we measure (revenue, not vanity)

- **North star:** **Weekly Active Dictators** (people who completed ≥1 dictation in the last 7 days) — it predicts both
  retention and conversion better than downloads.
- **Funnel KPIs:** download→activation %, activation→paywall %, paywall→trial %, trial→paid %, monthly **MRR** & paying subs,
  churn, **annual mix %**, referral coefficient (referred installs / active user).
- **Agent KPIs (new):** % of actives with ≥1 connected app, time-to-first-confirmed-action, confirmed actions / user / week
  — the leading indicators of the voice→action switching moat.
- **Channel KPIs:** /compare & /vs organic traffic + conversion, community launch installs, creator-attributed installs.
- **Guardrail:** gross margin stays very high (BYOK = zero inference COGS) — protect it; never introduce billed inference.
- **Cadence:** weekly funnel review; monthly cohort + channel review against the phase targets.

---

## 10. The strategist's bottom line for the co-founder

Verba is a **rare bootstrapped setup**: a real product in a **$2B-validated, 17–35%-CAGR category**, with **three
category-of-one wedges** (BYO-Claude + **voice → action / JARVIS on 1,000+ apps** + Context/vision), **zero inference
COGS** (even the action planner runs on the user's own AI), and **growth loops already coded**. The
€5–15k/mo target is **~600–2,000 subscribers — under 0.1% of the category.** The bet is **not** "is there a market" (there
demonstrably is); it's **"can we run a tight self-serve engine"**: sharp positioning to developers, honest comparison SEO,
creator demos, a forced-value trial, and the referral/leaderboard loops turned on. That is exactly the job a
marketing-owner co-founder would run — and the next document (content strategy) is the first quarter of its playbook.
