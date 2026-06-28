# Verba — Launch Strategy

> Deliverable 5 of the Verba GTM package · Skill: `/omg-launch-strategy` (R-MARKETING: the launch-moment skill)
> Reads & builds on: `.agents/product-marketing.md` (positioning SSOT), `marketing/gtm-strategy.md` (3 engines + roadmap §8),
> `marketing/content-strategy.md` (90-day calendar §5), `marketing/market-research.md`. Scope: **Verba only** (verba.run).
> Date: 2026-06-27 · Author: Oracle (OmegaOS)

**This document does not restart the GTM — it sequences a single launch *moment* on top of it.** The GTM strategy already
defined the motion (Product-Led + Community + Creator), the beachhead (Claude Code-native Mac developers), the funnel, and
the phased roadmap. This is the dated, hour-by-hour campaign that executes **GTM §8 Phase 0 → Phase 1 → start of Phase 2**:
a flagship **Product Hunt** launch, anchored by a **Show HN** moment and a **building-in-public** cadence, with the **JARVIS
demo as the hero asset** and the **Lifetime/Founder tier as the launch lever**.

Every product claim below traces to the SSOT. **No invented features. iOS is scaffolded and is NOT marketed. The agent is
"JARVIS" / "connected apps" — never the internal vendor name.**

---

## 1. Launch thesis + the ONE narrative

**Thesis.** Verba has product depth but **no social proof yet** (`product-marketing.md` Proof Points: "Early-stage — no
public logos or testimonials yet"). A launch is how a bootstrapped, no-ad, no-App-Store product (`market-research.md` §6)
manufactures the first wave of proof, installs, and reviews in a compressed window — then converts the spike into the
*owned* loops already coded (referral, leaderboard, gamification — GTM §7). The launch is not the strategy; it is the
**ignition** of the compounding engines.

**The single launch narrative — repeat it everywhere, change nothing:**

> ### "The Mac dictation app that became a voice agent."

That sentence (lifted from GTM §8 Phase 2) is the headline for Product Hunt, Show HN, the X thread, the Reddit posts, the
demo video title, and the email subject line. It does three things at once:
1. Names the **familiar shelf** (Mac dictation) so people instantly know the base product.
2. Names the **category-of-one leap** (voice agent) so it's not "another Wispr clone."
3. Implies a **story arc** ("became") that rewards a building-in-public telling.

**The three messages underneath it** (the only three — straight from GTM §2 narrative pillars):
1. **Private by default** — your voice never leaves your Mac, never uploaded; even the action planning runs on-device with
   your own AI (`product-marketing.md` Differentiation #2; commit d86685b).
2. **Bring your own AI** — reuse your Claude Code subscription, no API key, no markup (category-of-one; `ClaudeCode.swift`).
3. **It doesn't just type — it *does*** — JARVIS plans, asks when unsure, shows the action, executes **only on your
   confirm**, across 1,000+ connected apps + native Mac actions (category-of-one; `ActionExecutor.swift`, commit 5ae8804).

**The hero asset (the viral unit).** The 60-second JARVIS demo: *"I dictate 'create the Linear issue for this bug and email
the team a summary' — Verba plans it, shows me both actions, I hit confirm, done."* (GTM §4 Engine B, content-strategy #11).
Every channel leads with a clip of this. **The confirm step is never edited out — it IS the trust story** (content-strategy §8).

---

## 2. The launch lever: the Lifetime / Founder tier

The single highest-leverage *new* asset for this launch is the **Lifetime "Founder" license at ~$149–199 one-time**
(GTM §6 move 1; `market-research.md` §5). Rationale, all from the SSOT:
- The category has **strong lifetime-deal behaviour** Verba currently can't answer: Superwhisper $249.99, MacWhisper ~$69,
  VoiceInk one-time (`market-research.md` §5). A no-card-monthly buyer has nowhere to spend money today.
- **Zero inference COGS** (BYOK — even the action planner runs on the user's own AI) means lifetime carries *no ongoing cost
  risk* — "unusually safe here" (GTM §6).
- It **front-loads cash** for a bootstrapped founder and creates urgency.

**Launch framing:** a capped, time-boxed **"Founder's Edition — first 200 / first 30 days."** Scarcity + the "support an
indie building in public" story this exact audience rewards. Price it at **$149** (under the Superwhisper $249.99 anchor,
above MacWhisper $69 — positions Verba as premium-but-fair). This is the PH special offer, the Show HN "and there's a
lifetime deal for HN" line, and the urgency in the X thread. **Gate before launch:** Stripe Founder SKU live + tested,
`?ref` attribution intact, license entitlement honored in-app.

---

## 3. Pre-launch checklist (the gates that must be green before T-0)

These are blocking. **A red item here moves the launch date — never launch on a leaky funnel** (GTM §8 Phase 0).

**Funnel integrity (GTM §5, market-research §6 — both fixes re-verified still open 2026-06-12):**
- [ ] **Free-tier copy gap CLOSED.** `website/app/api/try/route.ts` (lines 56/67) still nudges *"free up to 10,000
  words/month"* — the rest of the site standardises on **33 dictations** (`Entitlement.swift` `freeTrialDictations = 33`).
  Align that one file to the 33-dictation story. **This is the #1 pre-launch blocker** — one true free-tier message everywhere.
- [ ] **Privacy claim accurate everywhere.** No "nothing written to disk" phrasing. Audio is kept in **local history by
  default** (`History.swift`) but **never uploaded** (sync is text-only). Approved claim: *"your audio never leaves your Mac
  — local history with an off switch + auto-prune."* Scrub PH gallery, demo captions, HN comment, landing copy.

**Activation (the make-or-break — GTM §5 lever 1):**
- [ ] **First successful dictation in < 60 seconds, no card, no key.** Zero-key Claude Code path is the hero of first-run
  ("Have Claude Code? You're ready — no key"); **offline Parakeet** is the instant no-setup fallback. Test cold on a clean Mac.
- [ ] **First confirmed action path works cold** — connect one app in Settings ▸ Connected apps → dictate a "create/send/
  schedule" → see the plan → confirm → it executes. This is the second activation moment (GTM §5); it must not error on day one.

**The hero demo:**
- [ ] **60-sec canonical demo recorded, ending on a JARVIS action.** Speak-vs-type opener → a real dictation → finish on
  *"…and when I say 'create the issue,' it does it"* with the confirm step visible (content-strategy §5 weeks 1–4).
- [ ] **3–4 × 15-sec cutdowns** for X/Reddit/PH: one per JARVIS action (Linear, Gmail, Slack, Calendar) — "say it → confirm → done."

**Proof (manufacture the first credibility — there is none yet):**
- [ ] **10–20 seeded reviews / quotes** in hand (GTM §8 Phase 0). Sources: the internal-launch testers (Phase 1 of the
  five-phase model), seeded creators, dev-community early users. Honest, attributed, specific ("saved me from typing a
  300-word spec"). These become the PH first-comment social proof and landing-page testimonials.
- [ ] **A handful of seeded Founder-license buyers** lined up to convert in the first hour (warm list) so the offer has
  visible traction at launch, not a cold $149 ask.

**Product Hunt assets:**
- [ ] Listing: name + **tagline ≤ 60 chars** (see §5), description, topic tags (Mac, Developer Tools, Artificial
  Intelligence, Productivity).
- [ ] **Gallery**: 1st image = the JARVIS confirm moment (the hook), then speak-vs-type, the 6 modes, the /compare honesty
  matrix, the privacy/on-device frame, the pricing incl. Founder tier. **Video first in the gallery.**
- [ ] **Maker's first comment** drafted (see §5) — posted at 12:01am PT.
- [ ] **Hunter** secured (self-hunt is fine for dev tools; if a credible hunter in the Mac/dev space is reachable, better).
- [ ] PH "promo/offer" set: the Founder license + a launch-day code or first-month discount for monthly.

**Instrumentation (you can't scale what you can't see — GTM §5):**
- [ ] Funnel events live end-to-end: download → activate (first dictation) → first confirmed action → paywall → trial → paid
  → referral. Vercel Analytics on site; Convex stats in-app (already shipped per GTM §7). UTM/`?ref` on every launch link.

**Owned-channel readiness (ORB — owned first):**
- [ ] Email capture live on verba.run; any existing early list segmented and ready.
- [ ] In-app: referral "Free Month" surfaced after a delightful moment, leaderboard shareable, gamification wired to
  onboarding (GTM §7) — *staged to flip ON in the post-launch window, not before* (don't split attention on launch day).

---

## 4. Week-by-week timeline (T-4 → Launch → T+8)

**Launch Day (T-0) = Tuesday, 28 July 2026** (Tue–Thu are the strongest PH days; Tuesday chosen for a full work-week of
follow-through). Owners: **Founder** unless noted; "Helper" = a part-time community/VA hand for monitoring & scheduling.
Each phase lists its **entry gate** — do not start the phase until the gate is green.

### T-4 weeks — Foundation & funnel fix (Mon 29 Jun → Sun 5 Jul)
**Maps to GTM §8 Phase 0. Entry gate: this doc approved; launch date locked.**
- [ ] **Close the `api/try/route.ts` 10,000-words copy gap** (the #1 blocker). Deploy + verify live on verba.run. *(Founder)*
- [ ] Audit every public surface for the privacy claim; replace any "written to disk"/"nothing on disk" phrasing. *(Founder)*
- [ ] Cold-Mac activation test: first dictation < 60s via zero-key Claude Code path + Parakeet fallback. Fix what's slow. *(Founder)*
- [ ] Cold-Mac first-confirmed-action test (connect 1 app → dictate → confirm → executes). *(Founder)*
- [ ] Stand up funnel instrumentation end-to-end; verify events fire. *(Founder)*
- [ ] Stripe **Founder license SKU** built + test purchase + entitlement honored in-app + `?ref` attribution intact. *(Founder)*
- **Phase exit check:** funnel is no longer leaking; both messaging-integrity gaps closed live.

### T-3 weeks — Assets & proof (Mon 6 Jul → Sun 12 Jul)
**Entry gate: T-4 funnel fixes verified live.**
- [ ] Record the **60-sec canonical JARVIS demo** + 3–4 × 15-sec cutdowns (Linear / Gmail / Slack / Calendar). *(Founder)*
- [ ] Publish the two foundation posts (content-strategy §5 weeks 1–4): **"Best Mac dictation app 2026 (honest)"** [#1] and
  **"Use your Claude Code sub for dictation — no API key"** [#2]. *(Founder)*
- [ ] Refresh 3 `/vs` pages with current data; confirm the `/compare` 24×10 matrix is accurate. *(Founder)*
- [ ] Begin **internal/alpha seeding** (five-phase model Phase 1–2): hand the build to 10–20 trusted testers; ask for an
  honest one-line quote + permission to use it. *(Founder + Helper)*
- [ ] Draft the launch copy kit: PH tagline/description/first comment, HN title + comment, Reddit posts, X thread (§5). *(Founder)*

### T-2 weeks — Community warm-up & creator seeding (Mon 13 Jul → Sun 19 Jul)
**Entry gate: demo video done; ≥10 seeded quotes collected.**
- [ ] **Be present in the beachhead communities now, providing value — not pitching** (PH playbook "provide value before
  pitching"): answer dictation/voice questions on r/macapps, r/ClaudeAI, Lobsters, Cursor/Claude Discords. *(Founder + Helper)*
- [ ] Seed **10–20 dev / Mac / productivity creators** with a Founder license + the demo clip (GTM §4 Engine C). No paid asks
  — "thought you'd want to try this; the JARVIS bit is the interesting part." (TRMNL/Snazzy-Labs model, SKILL §Borrowed.) *(Founder)*
- [ ] Start the **building-in-public X thread cadence** (GTM §4 Engine B): "shipping a voice agent for the Mac, launching in
  2 weeks" — show the demo, show the confirm-gate, invite follows. *(Founder)*
- [ ] Line up a **warm list of Founder-license buyers** to convert in launch hour 1. *(Founder)*
- [ ] Email any existing list: "something big from Verba in 2 weeks" teaser → capture replies/interest. *(Founder)*

### T-1 week — Dress rehearsal & scheduling (Mon 20 Jul → Sun 26 Jul)
**Entry gate: PH listing fully built in draft; copy kit finalized; offer live & tested.**
- [ ] Final PH listing review: tagline ≤60 chars, gallery order (video first → JARVIS confirm image → modes → /compare →
  privacy → pricing+Founder), topics, maker comment, offer. *(Founder)*
- [ ] **Schedule the PH launch for 12:01am PT Tue 28 Jul.** *(Founder)*
- [ ] Pre-write & schedule: launch email, X launch thread, the Show HN post (held, not posted), the two Reddit posts (held). *(Founder)*
- [ ] Notify the warm list + seeded creators of the exact date/time + ask them to engage *authentically* in the first hours
  (PH forbids vote manipulation — ask for genuine support, comments, and shares, not "go upvote"). *(Founder + Helper)*
- [ ] Confirm support coverage for launch day (inbox, DMs, PH comments, HN, Reddit) — block the whole calendar day. *(Founder + Helper)*
- [ ] Final cold-Mac smoke test of the full golden path incl. a confirmed JARVIS action. *(Founder)*
- **Go/No-Go review (Fri 24 Jul):** all §3 gates green → GO. Any funnel/activation/offer item red → slip one week.

### Launch week (Mon 27 Jul → Sun 2 Aug)
- **Mon 27 Jul (T-1 day):** final asset check; pre-stage all posts; early night. Post a "tomorrow" teaser on X. *(Founder)*
- **Tue 28 Jul (T-0): LAUNCH DAY** — see the hour-by-hour runbook in §6. *(Founder + Helper, all day)*
- **Wed 29 Jul (T+1 day):** **Show HN goes live** (held deliberately ~1 day off PH so the two spikes don't collide and you're
  not splitting attention; HN audience overlaps the beachhead but rewards a different framing — see §5). Reply to every HN
  comment. Continue PH follow-through (thank-yous). *(Founder)*
- **Thu 30 Jul (T+2 day):** **r/macapps + r/ClaudeAI posts** (stagger by a few hours; lead with the demo, never a pitch —
  content-strategy §6). Post the launch recap on X. *(Founder + Helper)*
- **Fri 31 Jul:** follow up with everyone who engaged anywhere; send the "we launched" email to the full list; convert
  warm Founder-license interest. *(Founder)*
- **Weekend:** rest + light monitoring; draft the week-1 numbers post.

### T+1 → T+2 weeks — Capture the spike into owned loops (Mon 3 Aug → Sun 16 Aug)
**Entry gate: launch spike landed; funnel data flowing.**
- [ ] **Flip ON the in-app share prompts**: referral "Free Month" after a delightful moment (a great dictation / the 10th
  use), shareable leaderboard ("I saved 14 hours with Verba"), gamification milestones (GTM §7). *(Founder)*
- [ ] Onboarding email sequence active for all new installs (SKILL §Post-Launch): key modes, the zero-key Claude path, the
  first JARVIS action, the privacy story. *(Founder)*
- [ ] Publish the **building-in-public "what launch day looked like" post** (real numbers — this audience rewards transparency,
  GTM §4 Engine B) on X + dev blog. *(Founder)*
- [ ] Follow up with seeded creators who didn't post yet; convert interest into reviews/clips. *(Founder)*

### T+3 → T+5 weeks — Compounding content + creator wave (Mon 17 Aug → Sun 6 Sep)
- [ ] Publish content-strategy weeks 5–8 set: **"Dictate prompts to Claude Code / Cursor (hub)"** [#3], **"Wispr Flow
  alternatives that run offline"** [#4], and the two shareable drops — **"You're paying twice for AI — the math"** [#5] and
  **"I ran my morning by voice"** [#11] (the JARVIS flagship). *(Founder)*
- [ ] Roll out the per-app JARVIS how-tos [#12]: "Create Linear issues / send Gmail / post to Slack by voice." *(Founder)*
- [ ] Creator demos go live (the seeded wave matures — a strong review here is the TRMNL-style multiplier). *(Founder)*
- [ ] First weekly funnel review against GTM §9 KPIs; iterate onboarding on the weakest step. *(Founder)*

### T+6 → T+8 weeks — Widen & set up Phase 2 (Mon 7 Sep → Sun 27 Sep)
**Entry gate: download→paid conversion observed and trending toward the 7–10% model (GTM §5).**
- [ ] Begin **Expand-segment sequencing** (GTM §3 — messaging only, no rebuild): turn on **Expand 1 Privacy-first
  professionals** ("on-device dictation — even the action planning runs on your Mac") with the privacy spokes [#6, #8], then
  **Expand 2 Voice-first operators** ("say it once: schedule it, send it, file it — confirm, done") with the JARVIS how-tos.
  Hold multilingual/notes (Expand 3–4) for later. *(Founder)*
- [ ] Add the confirm-gating **trust explainer** [#13] (mirrors the read/write fail-safe design) — pre-empts the agent-trust
  objection at scale. *(Founder)*
- [ ] Evaluate a **second launch moment** for late Q3 (a feature drop or the Founder-tier "last call") to re-spike — the
  SKILL's core philosophy: "the best companies launch again and again." *(Founder)*
- [ ] Decision point: with conversion proven, consider modest **paid retargeting on /compare visitors** (GTM §4, §8 Phase 2). *(Founder)*

---

## 5. Ready-to-use copy (English — adapt voice to `product-marketing.md` §Brand Voice: confident, candid, witty, pro-user)

### Product Hunt
**Name:** Verba
**Tagline (≤60 chars):** `The Mac dictation app that became a voice agent` *(47 chars)*
**Alt taglines:**
- `Speak it. Send it clean. Then watch it act — on your Mac` *(56)*
- `Private Mac dictation that acts on what you say` *(47)*

**Description (PH listing body):**
> Verba is a macOS menu-bar dictation app — press a hotkey, talk, and it turns your rambling into clean, formatted text and
> pastes it exactly where your cursor is. Now it does more than type: **JARVIS**, Verba's voice agent, takes a spoken intent
> ("create the Linear issue and email the team a summary"), plans the steps on your Mac, shows you exactly what it'll do, and
> executes **only after you confirm** — across 1,000+ connected apps + native Mac actions.
>
> • **Private by default** — your audio never leaves your Mac, never uploaded (local history has an off switch).
> • **Bring your own AI** — reuse your Claude Code subscription with no API key, or Anthropic/OpenRouter/local Ollama. No markup.
> • **6 modes**, screen-vision Context mode, hour-long Notes, live Translate, 14-language UI.
> • **$9.99/mo or $84/yr**, 33-dictation full-Pro trial, no card to start.
>
> 🚀 **Founder's Edition for Product Hunt: a one-time $149 lifetime license — first 200 only.**

**Maker's first comment (posted 12:01am PT):**
> Hey Product Hunt 👋 I'm the founder of Verba.
>
> It started as the Mac dictation app I wanted — on-device, reuses the Claude subscription I already pay for, no markup. Then
> I realized: if my own AI can clean up what I say, it can also *act* on it. So I built JARVIS — say "create the Linear issue
> for this bug and email the team," and Verba plans it, shows me both actions, and does them **only after I confirm**.
>
> Two things I care about most: it's **private** (your voice never leaves your Mac) and it **never acts without asking** —
> every write is shown to you first. The demo above is one unedited take, confirm step included.
>
> For PH today there's a **$149 lifetime Founder's Edition (first 200)**. I'm here all day — ask me anything, and tell me
> what you'd want to do by voice.

### Show HN (post Wed 29 Jul, ~8–10am ET / morning PT — best HN window)
**Title options (HN rewards honest, specific, non-marketing titles):**
- `Show HN: Verba – Mac dictation that acts on what you say, using your own Claude` *(primary)*
- `Show HN: A private Mac voice agent that reuses your Claude Code sub (no API key)`
- `Show HN: I turned a Mac dictation app into a confirm-gated voice agent`

**Show HN body (honest framing — HN punishes hype, rewards candor; `product-marketing.md` §Brand Voice "radical honesty"):**
> Verba is a macOS dictation app I've been building. You press a hotkey, talk, and it restructures your speech into clean text
> wherever your cursor is. The part I want feedback on: it now *acts*. Say "create the Linear issue and email the team," and it
> plans the steps **on-device using your own AI** (your Claude Code subscription, an Anthropic/OpenRouter key, or local
> Ollama — never a key of mine), shows you the plan, and executes only after you confirm. 1,000+ connected apps + native Mac
> actions. Every write is confirm-gated; anything ambiguous is treated as a write and never auto-run.
>
> Honest limitations: it's **macOS-only** today. It's BYO-AI, so first-run means connecting an AI account (the zero-key
> Claude Code path is the easy one). Audio stays on your Mac (local history, with an off switch) — it's never uploaded.
>
> $9.99/mo, 33-dictation free trial, no card. There's a $149 lifetime for anyone who wants it. I'd genuinely like to hear
> where the agent breaks and what you'd want to do by voice. Demo: [link]

### Reddit
**r/macapps** (post Thu 30 Jul; lead with the demo, value-first):
> **Title:** I built a private Mac dictation app that can also *act* on what you say (JARVIS-style, but it asks before it does anything)
>
> Body: short, the demo GIF first, the privacy + BYO-AI points, "$9.99, 33 free dictations, no card; $149 lifetime if you
> hate subscriptions," and an honest "Mac-only, here's our /compare page that lists where rivals beat us." End with a question
> to invite discussion, not a CTA wall.

**r/ClaudeAI** (post Thu 30 Jul, a few hours after r/macapps):
> **Title:** Verba uses your Claude Code subscription to dictate *and* to run actions on your Mac — no API key
>
> Body: lead with the Claude-Code-as-planner angle (this sub's hook): "your Claude Code install is the action planner — the
> agent you already pay for now runs your Mac by voice, on-device." Demo clip, confirm-gate emphasis, free trial + lifetime.

### X / building-in-public thread (launch day)
> 1/ I shipped it: the Mac dictation app that became a voice agent. 🧵
> I dictate "create the Linear issue for this bug and email the team a summary." Verba plans it, shows me both actions, I hit
> confirm — done. One unedited take 👇 [video]
>
> 2/ It started as dictation: talk, get clean text where your cursor is. On-device. Reuses the Claude sub I already pay for —
> no API key, no markup.
>
> 3/ Then: if my own AI can clean up what I say, it can act on it. So Action mode became JARVIS — 1,000+ connected apps +
> native Mac actions.
>
> 4/ The rule I won't break: it **never acts without asking**. Every write is shown first; ambiguous = treated as a write,
> never auto-run. The confirm step is the feature.
>
> 5/ Private by design: your voice never leaves your Mac; the plan is generated on your Mac by your own AI — not my server.
>
> 6/ $9.99/mo, 33 free dictations, no card. And for launch: a $149 lifetime Founder's Edition, first 200.
> We're live on Product Hunt today — link below. Tell me what you'd want to do by voice. 👇

### Launch email (subject + hook)
- **Subject:** `Verba can now do what you say (not just type it)`
- **Hook:** the narrative line + the demo GIF + "we're on Product Hunt today" + the Founder lifetime offer.

---

## 6. Launch-day runbook — Tuesday 28 July 2026 (all times PT, PH's clock)

PH days run **12:01am → 11:59pm PT**. Engagement in the first hours sets the ranking trajectory. **Treat it as an all-day
event** (SKILL §PH "respond to every comment in real-time"). Coverage: Founder primary, Helper on monitoring/scheduling.

| Time (PT) | Action |
|---|---|
| **12:01am** | PH listing goes live. Post the **maker's first comment** immediately (§5). |
| **12:05am** | Post the **X launch thread**; pin it. Send the **launch email** to the full list. |
| **12:10am** | Personally ping the **warm list + seeded creators**: "we're live — would love your honest take" (ask for genuine engagement, never "upvote"; PH bans vote manipulation). |
| **6:00am** | Wake / check ranking & comments. Reply to **every** PH comment. Convert the first warm **Founder-license** buyers so the offer shows traction. |
| **6:00am–9:00am** | Peak US-morning traffic. Reply within minutes everywhere. Re-share the X thread with an early-traction update. |
| **9:00am** | First metrics pulse (see watch-list). Post a "we're #X on PH" update to X if ranking is strong. |
| **12:00pm** | Midday push: a fresh 15-sec JARVIS cutdown on X; thank early supporters by name; answer the hardest objections publicly (agent-trust, Mac-only). |
| **3:00pm** | EU is asleep, US afternoon active — keep replying. Drop the "you're paying twice for AI — the math" angle if conversation is slow. |
| **6:00pm** | Evening pulse; engage the late-day PH browsers and the EU-evening stragglers. |
| **9:00pm** | Final push before PT midnight if in contention for top spots. Last call on the Founder tier for the day. |
| **11:59pm** | Day closes. Screenshot final rank + stats. Draft thank-you list for tomorrow. |

**Hold for tomorrow (deliberate):** Show HN (Wed AM), r/macapps + r/ClaudeAI (Thu) — staggered so each spike gets full
attention and you don't burn the audience in one collision.

**First-24h engagement plan:**
- Reply to **100% of comments** on PH, then HN/Reddit as they go live — real answers, not canned lines.
- Direct every reply back to verba.run to **capture the email / start the trial** (ORB: convert rented attention to owned —
  SKILL §Rented).
- Surface a real testimonial or the /compare honesty matrix whenever someone doubts depth.
- Log every objection verbatim → it becomes FAQ + content (content-strategy §7 forum mining).

**Metrics to watch (live dashboard — GTM §9):**
- **Top-of-funnel:** PH rank/upvotes/comments, DMG downloads (GitHub Releases), site sessions, email captures.
- **Activation:** % downloads → first dictation, **time-to-first-dictation** (target <60s), **time-to-first-confirmed-action**.
- **Monetization:** paywall hits, 7-day trial starts, **Founder-license sales**, monthly/annual checkouts.
- **Loop:** referral links generated, leaderboard shares.
- **Guardrail:** error rate on first dictation + first JARVIS action (a broken first-run on launch day is the worst outcome —
  watch it like a hawk; L1 runtime truth).

---

## 7. Post-launch compounding (turn the spike into the engine)

The launch ends; the engines start (SKILL §Post-Launch; GTM §7 §8 Phase 2). Priorities, in order:
1. **Flip on the owned loops** (T+1 week): referral "Free Month" prompt after a delightful moment, shareable leaderboard,
   gamification milestones — already coded, just surface them (GTM §7). These are why a bootstrapped app compounds without ad spend.
2. **Onboarding email sequence** for every new install: zero-key Claude path → first great dictation → first JARVIS action →
   the privacy story. Reduces the BYOK first-run bounce (market-research §6 risk).
3. **Creator seeding wave matures** (T+3–5): the seeded reviews/demos go live — the TRMNL/Snazzy-Labs multiplier (one strong
   creator review can dwarf launch day). Convert borrowed attention to owned (email/trial).
4. **Comparison + use-case content compounds** (Engine A): the /compare matrix, the per-app JARVIS how-tos, the cost-math
   piece — bottom-funnel SEO that converts long after the spike.
5. **Expand-segment sequencing** (T+6–8, GTM §3): Privacy-first professionals → Voice-first operators, **messaging only** —
   the product already serves them; widen the message once developers are won. Hold multilingual/notes for later.
6. **Plan the next launch moment** (the second spike) — the SKILL's core philosophy: launch again and again.

---

## 8. Risks & contingencies

| Risk | Why it bites | Mitigation (grounded in the SSOT) |
|---|---|---|
| **Agent-trust fear** — "a voice agent in my Gmail/Slack? no thanks" | Legitimate fear reflex; the headline feature can scare more than it sells (market-research §6) | **Lead with control, not capability.** "It asks before it acts" is a headline, not a footnote (content-strategy §8). Every demo keeps the confirm step. Talking points: reads-only auto-run (capped), **every write confirm-gated**, plan generated **on your Mac by your own AI** (never a server key, d86685b), per-app disconnect in Settings. Publish the trust explainer [#13] in the window. |
| **Mac-only objection** | Forfeits Windows/Android/iOS demand (market-research §6) | **Own it honestly** (the /vs pages already do): "the best *native macOS* option today; if you need Windows/mobile now, Wispr Flow wins there — we say so." Reframe scarcity as focus. **Do NOT promise iOS or give a date** — iOS is scaffolded, not shipped; it is not a launch claim (content-strategy §8). |
| **A flat Product Hunt day** | PH is competitive; spikes are short-lived (SKILL §PH Cons) | PH is **one** channel, not the strategy. The Show HN + Reddit + X + creator waves are staggered across the week precisely so no single platform is the whole bet. If PH underperforms: double down on the HN/Reddit framing, lean on the building-in-public X thread (highest-trust channel for the beachhead, GTM §4 Engine B), and treat the seeded-creator wave (T+3–5) as the real multiplier. The owned loops compound regardless of launch-day rank. |
| **First-run breaks on launch day** | A leaky/broken activation on the highest-traffic day wastes the whole spike | The §3 gates are blocking for this reason; the launch slips before it ships broken (L1). Live error-rate watch on first dictation + first JARVIS action all day. |
| **"Why pay vs Apple Dictation / why not Wispr?"** | The two default objections in this category | Pre-loaded answers from `product-marketing.md` §Objections: Apple just transcribes (no restructuring/modes/intent); Wispr uploads your audio, costs $15, locks you into its markup, and only types — Verba is on-device, $9.99, BYO-Claude, and **acts**. |
| **Privacy claim challenged** | A competitor could call out "writes audio to disk" if overstated (market-research §6) | The pre-launch scrub (§3) removes any "nothing on disk" phrasing. The defensible claim — *"audio never leaves your Mac; local history with an off switch"* — is true and verified (`History.swift`). |
| **Vote-manipulation / community-rules misstep** | PH bans vote solicitation; Reddit/HN punish pitchy self-promo | Ask only for **genuine** engagement; lead with the demo and value, never "upvote me"; provide value in communities for 2 weeks *before* posting (T-2). HN gets the candid framing, never marketing copy. |

---

## 9. Definition of a successful launch (grade against this, not vibes — R-RUBRIC)

- **Funnel is clean** before T-0: the `api/try` copy gap closed, privacy claim accurate, first dictation <60s, first
  confirmed action works — all verified live. *(The launch is invalid if this isn't true.)*
- **Spike captured into owned channels:** measurable email captures + trial starts, not just upvotes (ORB discipline).
- **Founder-license proves the lever:** the lifetime tier converts the anti-subscription buyer and front-loads cash.
- **Reviews/proof manufactured:** the launch produces the first wave of public, attributed proof Verba lacked.
- **Loops turned on:** referral + leaderboard + gamification live in-app within T+1 week.
- **Trajectory toward GTM §8 Phase 1:** download→paid trending toward the 7–10% model; first paying subs toward the ~700
  (≈€5k/mo) milestone.

The launch is **ignition**, not the destination. Its job is to light the three compounding engines (SEO+GEO, community,
creators) and the coded growth loops — then get out of their way.

---

*Built on the Verba GTM package — does not contradict it. Every product claim traces to `.agents/product-marketing.md`,
`marketing/gtm-strategy.md`, `marketing/content-strategy.md`, or `marketing/market-research.md`. iOS not marketed. The agent
is JARVIS / connected apps.*

--- **Resume:** Stratégie de lancement écrite dans `marketing/launch-strategy.md` — narratif unique ("the Mac dictation app
that became a voice agent"), timeline semaine par semaine T-4 → T+8 avec lancement Product Hunt le mardi 28 juillet 2026,
runbook heure par heure (fuseau PT), play Show HN + Reddit + X, tier Lifetime "Founder" à 149 $ comme levier, démo JARVIS
comme actif héros, checklist pré-lancement (correctif copie `api/try`, activation <60s, confidentialité), risques &
contingences. Chaque claim tracé au SSOT ; iOS non promu ; aucun nom de fournisseur interne.
