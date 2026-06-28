# Verba — Partnerships & Outreach Plan — July 2026 (Days 1–30 Foundation)

> **Part 07 of the July 2026 content series.** Operationalizes `marketing/partnerships-distribution.md`
> §6 (priority table) + §7 (Days 1–30 foundation) onto the July launch runway. **Launch = Tue 28 Jul 2026**
> (Product Hunt, 12:01 PT). Email templates reused **verbatim** from **file `04` of this series — the
> cold-email / relationship-outreach playbook** (source: `marketing/cold-email.md`, Sequences **A / C / D**).
> Scope: **Verba only** (verba.run). All outreach copy in **English**; orchestration notes in French.

*Note d'orchestration (FR) : ce fichier ne réinvente rien — il prend la séquence « Days 1–30 — Foundation »
de la stratégie partenariats et la **date** sur les semaines de runway juillet (T-4 → semaine de lancement),
puis colle les **templates email verbatim** du fichier 04 pour chaque cible. Chaque cible porte : canal · angle ·
quand (date juillet) · statut initial.*

---

## ⚠️ Honesty guardrail — read before any partner/bundle conversation (L2)

The **$149 Founder's Edition (Lifetime)** SKU **does NOT exist in Stripe yet.** Only **monthly $9.99** and
**annual $84/yr (~$7/mo)** are live. The lifetime tier is a **launch lever the strategy plans** — it is on the
**T-4 build checklist** to **create + test before 28 Jul.**

- In **all** copy, reference it **only** as a prerequisite to build: **`[PREREQUISITE: Stripe SKU to create/test before 28 Jul]`**.
- **Never** write it as already available. **Do not** open any bundle/Setapp conversation that depends on it until the
  SKU is live and tested.
- The strategy quotes a **$149–199** range for the lifetime/Founder tier; the launch narrative anchors on **$149**.
  Either way: **prerequisite, not shipped.**
- **No other unshipped feature may be promised.** Product truths only: **macOS-only** (iOS is *scaffolded, not shipped* —
  never pitch it), **$9.99/mo · $84/yr**, **BYO-Claude with no API key**, **private by default** (audio never leaves the
  Mac), **JARVIS** = confirm-gated voice agent across **1,000+ connected apps**, **planned on-device by the user's own AI**.
- **Public vocabulary only:** "JARVIS", "connected apps", "on-device planning" — **never** the underlying connected-apps
  vendor name in any outreach (per `.agents/product-marketing.md` §Customer Language).

---

## The one rule that governs every partnership call

Verba's economics are unusual: **BYO-AI means ~zero inference COGS** (the user brings their own key or reuses a Claude Code
subscription), so a direct $9.99/mo sub keeps **~$8.30 net** at ~95% margin. That single fact makes the plan **asymmetric on purpose**:

- **PURSUE** distribution that is **earned** or **revenue-shared** — it's cheap, on-brand, and the margin can fund a
  **top-of-market 30% payout** without a margin trap.
- **AVOID** distribution that is **bundle-pooled** (Setapp membership → a ~$8.30 subscriber becomes a few cents of pooled
  royalty *and* the referral loop can't run on it) or **platform-taxed** (Apple IAP → 15–30% tax + sandbox-incompatible).

**Protect the direct relationship; rent reach only where it is genuinely incremental and doesn't tax the margin or cheapen the brand.**

---

## 1. Priority table — pursue now / later / avoid (summary of partnerships §6)

| # | Lever | First targets (named) | Verdict |
|---|---|---|---|
| **1** | **Creator / affiliate** | Stand up **Dub** at 30%/12mo; seed **Ryan Shrott · jamesm.blog · afadingthought · This Week in AI Club** | **Pursue now** |
| **2** | **Community wedge** | **r/ClaudeAI · Anthropic Discord · Claude Code community · Cursor forum** — "reuse your Claude sub, no key" | **Pursue now** |
| **3** | **Raycast** | Ship a **Verba companion extension** (start/stop, insert transcript, snippets/styles); private/on-device vs Raycast's cloud dictation | **Pursue now (scope in July, ship Days 31–60)** |
| **4** | **Earned media (indie-Mac)** | **9to5Mac Indie App Spotlight · MacStories (Viticci/Voorhees) · Indie Dev Monday · Mac Power Users + MPU Talk · Indie Support Weeks** | **Pursue now** |
| **5** | **Bundles — self-run** | **Founder/Lifetime $149** capped cohort via Paddle/Gumroad, wired to the referral loop | **Pursue (BUILD FIRST — `[PREREQUISITE]`)** |
| **6** | **MCP server** | Ship **Verba as an MCP server** (registry listing) + "built with connected apps" showcase | **Pursue (technical)** |
| **7** | Creator — sponsored Tier-2 | **Theo/t3.gg · Keep Productive · Matthew Berman · Matt Wolfe**; newsletters **Ben's Bites · TLDR AI · Code With Andrea** | **Later (after Tier-1 proven)** |
| **8** | Bundles — curated | **One** indie/Black-Friday Mac bundle (**BundleHunt**-style), bounded window | **Later** |
| **9** | Alfred | Alfred Gallery workflow (mirror of the Raycast extension) | **Later** |
| **10** | Setapp | **Single-app 85/15 track** via setapp.com/developers (**never** the membership pool) | **Later (experiment only)** |
| **11** | Mac App Store | Reduced sandbox-safe discovery SKU (MacWhisper pattern) — only if useful | **Later / conditional** |
| **—** | AppSumo / StackSocial | Deep-discount LTD marketplaces (~70% cut, ~16–17% refunds, permanent cheap anchor) | **Avoid** |
| **—** | Setapp membership pool | All-you-can-eat pool (margin destruction + kills the referral loop) | **Avoid** |
| **—** | Mac App Store (flagship) | Porting the full app (sandbox-incompatible + IAP tax) | **Avoid** |
| **—** | MCP registry as consumer store | Treating registry/connected-apps infra as a consumer storefront | **Avoid** |

**July focus:** rows **1–6** (the "pursue now" block). Rows 7–11 stay parked; the "avoid" rows stay off the table.

---

## 2. July outreach calendar at a glance

Runway weeks (1 Jul = Wed; Mondays = 6, 13, 20, 27):

| Week | Dates | Theme | Partnership actions |
|---|---|---|---|
| **T-4** | Mon 29 Jun – Sun 5 Jul | Foundations + fix funnel | Build press kit · stand up **Dub** (account + Stripe wiring) · scope **Raycast** extension · build target lists (writers, earned-media, communities) · **`[PREREQUISITE]` start Founder's Edition Stripe SKU** |
| **T-3** | Mon 6 – Sun 12 Jul | Assets + proof | Finalize press kit + demo clips · **Dub live** (30%/12mo, first-paid-charge payout, ?ref links) · **seed the 4 named comparison-writers** (first touch) · **`[PREREQUISITE]` test Founder's Edition SKU** |
| **T-2** | Mon 13 – Sun 19 Jul | Warm-up communities + seed creators | **Community wedge** posts (r/ClaudeAI, Anthropic Discord, Cursor forum) · comparison-writer fu1 · broaden creator seeding · **pitch earned-media** (founder-story angle, timed to launch) |
| **T-1** | Mon 20 – Sun 26 Jul | Rehearsal + scheduling | Schedule launch-day affiliate activation · comparison-writer fu2 · earned-media follow-ups · confirm any launch-week coverage · press-kit public URL final |
| **Launch** | Mon 27 Jul – **Tue 28 Jul** – Sun 2 Aug | Launch week | **28 Jul PH 12:01 PT** · activate affiliates/creators to amplify · **Founder's Edition goes live** (lever; `[PREREQUISITE]` met) · **29 Jul Show HN** · **30 Jul Reddit** (r/macapps + r/ClaudeAI) |

*Reconciliation note (FR) : la stratégie place « seeding créateurs » en T-2. Les **4 comparison-writers nommés**
(qui rankent déjà sur la requête) sont l'exception : on les seed dès **T-3 (7 juil)** pour laisser le temps d'une
review/maj calée sur le lancement. Le seeding créateurs **large** monte en T-2. Pas de contradiction — priorité d'intention.*

---

## 3. The July actions — channel · angle · when · initial status

### 3.1 Creator affiliate program — stand up Dub (30%/12mo, wire Stripe)

**Why:** both closest competitors run public affiliate programs on **Dub** (Wispr Flow 25%/12mo; Superwhisper 30%/12mo).
BYO-AI = zero COGS lets Verba pay **top-of-market 30% recurring** and still keep a fat margin. Dub is the de-facto category
standard with best-in-class Stripe attribution (recurring, trials, refunds, expansion, churn).

**Program design (Tier 1 — Creator Affiliate, the new paid self-serve layer on top of the existing free referral loop):**
- **30% recurring for 12 months** (matches Superwhisper, beats Wispr), **30–90 day cookie**.
- **Payout fires on the referred customer's first paid charge** (abuse guard).
- Economics: on $9.99/mo ≈ $3/mo × 12 ≈ **$36/customer**; on $84/yr, 30% ≈ **$25**.
- **Auto-approve small creators.** Keep **Tier 0 (free referral "Free Month" loop + leaderboard)** running alongside.

| Step | Channel | Angle / what | When (July) | Initial status |
|---|---|---|---|---|
| Create Dub account, connect Stripe | dub.co · Stripe | Configure 30%/12mo, 30–90d cookie, first-paid-charge payout trigger, payouts via Stripe Express/PayPal | Mon 29 Jun – Fri 3 Jul (T-4) | `to-build` |
| Test attribution end-to-end | Dub + Stripe test mode | Verify recurring / trial / refund tracking on a test conversion; generate `?ref` links | Mon 6 – Wed 8 Jul (T-3) | `to-build` |
| Open self-serve auto-approve | verba.run/affiliates page + Dub | Publish the program page; small creators auto-approved | Mon 13 Jul (T-2) | `to-build` |
| Hand `?ref` links to seeded writers | email | Each comparison-writer gets a personal `?ref` link (stacks on the seed license) | with first touch, Mon 7 Jul (T-3) | `to-build` |
| Activate + monitor | Dub dashboard | Watch affiliate-attributed installs + paid conversions through launch week | Launch week (27 Jul+) | `not-started` |

> **Guardrail:** total affiliate payout must stay **< the margin headroom**. Gate cash behind the **first paid charge**;
> watch refund/chargeback rate on affiliate traffic (abuse signal).

---

### 3.2 Seed the named comparison-writers (highest-intent, seed first)

These four **already rank for the exact query** ("best Mac dictation apps 2026") — highest-intent, lowest-effort seeds.
**Offer = seed license (free Verba Pro / Founder comp) + affiliate `?ref` link + the done-for-them demo clip.** Honesty is
required; a positive review is **not** (honesty *is* the brand — say so). Use **Sequence A** (§4.1) verbatim.

| Target | Channel | Angle | When (July) | Initial status |
|---|---|---|---|---|
| **Ryan Shrott** (Medium — "Best Mac Dictation Apps in 2026", already lists Wispr Flow / Superwhisper / Apple Dictation) | Medium comment / about-page email | "Your roundup ranks the typers — Verba is the one that *acts*. On-device, reuses your Claude sub, no key. Want a license to add it?" | First touch **Mon 7 Jul** · fu1 **Thu 10 Jul** · fu2 **Thu 17 Jul** | `sourced` |
| **jamesm.blog** | blog contact / email | Same: position voice→action + private/on-device vs the dictation-only field he covered | First touch **Mon 7 Jul** · fu1 **Thu 10 Jul** · fu2 **Thu 17 Jul** | `sourced` |
| **afadingthought** (Substack) | Substack reply / email | BYO-key + privacy angle; offer the JARVIS clip for the post | First touch **Mon 7 Jul** · fu1 **Thu 10 Jul** · fu2 **Thu 17 Jul** | `sourced` |
| **This Week in AI Club** (Substack) | Substack reply / email | "Dictation that became a voice agent" — fits an AI-news cadence; seed + `?ref` | First touch **Mon 7 Jul** · fu1 **Thu 10 Jul** · fu2 **Thu 17 Jul** | `sourced` |

Source row (Ryan Shrott): https://medium.com/@ryanshrott/best-mac-dictation-apps-in-2026-dictaflow-wispr-flow-superwhisper-and-apple-dictation-compared-11911c671817

> **Cadence (file 04 §7):** Tue–Thu, 9–11am / 1–3pm local; **2–3 touches then stop.** ~55% of replies come from
> follow-ups — the **second** email matters, but each must add new value. **Personalize or don't send:** delete the first
> line; if the email still makes sense, the personalization is fake — rewrite it or skip the target.

---

### 3.3 Claude / Cursor community wedge — "reuse your Claude sub, no key"

**The one story no competitor (Wispr Flow, Superwhisper, Willow) can tell.** This is **community content, not email** —
**lead with the demo, never a pitch** (content-strategy §6). Public vocabulary only ("JARVIS", "connected apps").

| Channel | Angle | When (July) | Initial status |
|---|---|---|---|
| **r/ClaudeAI** | "Dictate into Claude Code and reuse your existing Claude subscription — no key, zero inference cost." Lead with the speak-vs-type + JARVIS clip. (This sub is also the **30 Jul** launch post.) | Warm-up **Mon 14 Jul** → sustained → **launch post Thu 30 Jul** | `not-started` |
| **Anthropic Discord** | Same wedge in the relevant channel; show the demo, answer questions, don't drop a store link cold | Warm-up week of **Mon 14 Jul** | `not-started` |
| **Claude Code community** | "Voice front-end for your Claude Code workflow" — the BYO-AI / no-key economics | Warm-up week of **Mon 14 Jul** | `not-started` |
| **Cursor forum / Discord** | "Talk to your editor — on-device planning, your own AI, confirm-gated actions" | Warm-up week of **Mon 14 Jul** | `not-started` |

> **Posting timing (calendar):** X (dev) **14:00–17:00 UTC** + **~21:00 UTC**; **stay in the comments the first 2 hours.**
> Track each community with a distinct UTM/promo so community-attributed installs are measurable.

---

### 3.4 Scope the Raycast companion extension

**Why it's a bullseye:** Raycast's audience is keyboard-driven, developer-heavy — Verba's exact ICP. **Publishing is free,
via GitHub PR** (`npm run publish` → Raycast review → auto-published, discoverable in-app + on the web Store).

**The catch (lead the differentiator):** Raycast ships its **own cloud dictation** (paid Pro), so Verba's
**private / on-device / BYO-key** model is the angle to lead with. Credentials must use the **preferences API** (not Keychain).
The extension can only be a **companion** (start/stop dictation · insert last transcript · manage snippets/styles · open Verba) —
it **can't** replace the native always-listening menu-bar app. **Treat it as a funnel + credibility surface, not the product.**

| Sub-task | Channel | Angle | When (July) | Initial status |
|---|---|---|---|---|
| Scope + spec the companion extension | internal / GitHub | Define the 4 commands (start/stop, insert transcript, snippets/styles, open Verba); preferences-API for creds | T-4 → T-3 (Mon 29 Jun – Fri 11 Jul) | `scoping` |
| **Ship** (GitHub-PR publish) | raycast.com/store | Position private/on-device/BYO vs Raycast's cloud dictation | **Days 31–60 (post-launch / August)** — *per strategy §7; July = scope only* | `deferred` |

---

### 3.5 Indie-Mac earned-media list (the native top-of-funnel for a DMG app)

For a notarized-DMG app (no App Store discovery), the indie-Mac editorial/podcast/newsletter network **is** the native
earned top-of-funnel. **Highest-fit, durable, credibility-compounding — but relationship-driven and slow.** Pitch **early**
in the runway with the **founder-story narrative (Sequence D, §4.3)** + the press kit; expect most coverage to land
**launch week → August**, not on demand.

| Target | Channel | Angle | When (July) | Initial status |
|---|---|---|---|---|
| **9to5Mac — "Indie App Spotlight"** (recurring series) | Submit per the series' contact / tip line | "The Mac dictation app that became a voice agent" — private-by-default, BYO-Claude, confirm-gated JARVIS demo | List by **Fri 11 Jul** · pitch **Mon 14 – Fri 18 Jul** · fu **week of 21 Jul** | `sourced` |
| **MacStories** (Federico Viticci / John Voorhees) | Email; review + automation / "App Defaults" angle | Cross-app automation + on-device privacy story; offer the JARVIS demo | List by **Fri 11 Jul** · pitch **Mon 14 – Fri 18 Jul** · fu **week of 21 Jul** | `sourced` |
| **Indie Dev Monday** (weekly indie-Apple-dev newsletter) | Submission form / email | Solo-founder, indie-Mac, agentic-builder story | List by **Fri 11 Jul** · submit **week of 14 Jul** | `sourced` |
| **Mac Power Users** (Relay FM; David Sparks / Stephen Hackett) + **MPU Talk** forum | MPU Talk forum thread + show contact | "Voice→action on the Mac you control" — power-user automation + privacy | List by **Fri 11 Jul** · thread **week of 14 Jul** | `sourced` |
| **Indie Support Weeks** (John Sundell) | GitHub repo / community wave | Join the next cross-promo wave across sites/podcasts/YouTube/newsletters | **Watch for the next wave** through July | `sourced` |

Source links — 9to5Mac: https://9to5mac.com/guides/indie-app-spotlight/ · MacStories: https://www.macstories.net/ ·
Indie Dev Monday: https://indiedevmonday.com/ · Indie Support Weeks: https://github.com/JohnSundell/IndieSupportWeeks

> *Caution (partnerships §3c):* the CleanShot X / CleanMyMac–class cross-promo network routes through **Setapp's bundle** —
> that's the §1 revenue-share/pricing conflict, **not** free cross-promo. Don't chase it as earned media.

---

### 3.6 Press kit checklist (feeds every channel above)

Build this **first** (T-4, by **Fri 11 Jul** finalized + public URL). It is the single asset every creator, journalist,
and partner conversation pulls from.

- [ ] **Launch one-liner / narrative:** *"The Mac dictation app that became a voice agent."*
- [ ] **The 3 pillars:** (1) **Private by default** — audio never leaves the Mac, even the planner is on-device · (2) **Bring-your-own-AI** — reuse your Claude Code sub with **no API key**, zero markup · (3) **Voice → action** — it doesn't just type, it **acts after your confirmation**, across **1,000+ connected apps**.
- [ ] **Product truths block:** macOS-only (iOS scaffolded, **not** shipped — never pitch it) · **$9.99/mo · $84/yr (~$7/mo)** · trial = **33 dictations, no card → then 7 days Pro** · BYO-Claude / Anthropic key / OpenRouter / local Ollama · private by default · JARVIS confirm-gated across 1,000+ connected apps, **planned on-device by the user's own AI**.
- [ ] **Demo asset 1 — Speak-vs-type clip:** side-by-side, dramatically faster than typing. ⚠️ **Substantiate the speed with Verba's own benchmark before quoting any number** (don't borrow the category's "4× faster" claim unverified).
- [ ] **Demo asset 2 — The JARVIS clip:** *"I said it, it did it (after it asked)."* Dictate "create the Linear issue and email the team a summary," the agent shows **both** actions, you **confirm**, done. **Keep the confirm step in every clip — the confirm step *is* the trust story.**
- [ ] **Screenshots:** app menu-bar UI · the confirm dialog · the referral leaderboard.
- [ ] **Founder bio + headshot:** solo founder, agentic-systems builder, privacy-first.
- [ ] **Logo / app-icon assets** (light + dark).
- [ ] **`/compare` honesty matrix link:** where rivals still win (radical honesty is the brand).
- [ ] **Pricing + trial mechanics** (as above) and **verba.run** links.
- [ ] **Press contact** + a short "facts at a glance" sheet.
- [ ] **`[PREREQUISITE: Stripe SKU to create/test before 28 Jul]` Founder's Edition (Lifetime $149):** include in the kit **only once the SKU is live and tested** — until then, omit or mark as the prerequisite.

---

## 4. Outreach email templates — use verbatim (from file `04` / `marketing/cold-email.md`)

> **Rules for every message (file 04 §1):** write like a peer who noticed something, not a vendor with a quota · lead with
> **their** world (you/your > I/we) · **one** low-friction ask (seed license or a 2-min clip — never a 30-min call in touch one) ·
> personalization must connect to the reason · **never demo an unconfirmed write** · one proof point, not a feature dump ·
> **never name the underlying connected-apps vendor.**

### 4.1 Sequence A — Creators / comparison-writers (§3.1–3.2)

**Subject options (2–4 words, lowercase, internal-looking):** `your dictation video` · `verba for {{channel}}` · `the jarvis clip`

**First touch**
```
Subject: your dictation video

Hey {{firstName}},

Watched {{their_video_or_post}} — your take on {{specific_detail}} was the
honest version nobody else gives.

I build Verba, a Mac dictation app, but the part I think your audience would
actually lose it over isn't the dictation — it's that it now *acts*. You say
"create the Linear issue for this bug and email the team a summary," it shows
you exactly what it'll do, you confirm, done. Across 1,000+ connected apps,
planned on-device by your own Claude Code sub. No key, $9.99, audio never
leaves the Mac.

Want a free Pro license to kick the tires? No ask for a review — if it's not
better than what you covered, say so on camera. I'll send a 30-sec "I said it,
it did it" clip so you can see it before you spend a minute.

— {{your_name}}
verba.run
```

**Follow-up 1 — Day 3 (hand them the asset)**
```
Subject: the jarvis clip

{{firstName}} — the clip, in case it's easier to judge than my pitch:
{{demo_link}}

That's a real confirmed action on real tools, not a mockup. The "it asks
before it acts" pause is the whole point — that's the part people screenshot.

Pro license is yours whenever; takes 30 seconds, no card. Worth a look?
```

**Follow-up 2 — Day 10 (momentum + breakup)**
```
Subject: last one on this

No worries if dictation-that-acts isn't your lane right now, {{firstName}}.

Quick context in case it changes the math: the category incumbent (Wispr Flow)
just raised at a $2B valuation — and it still only types and uploads your audio.
Verba runs on-device and *does* things. That gap is the story your audience
hasn't seen yet.

I'll leave it here. License + a `?ref` affiliate link are open if you ever want
them — replies pay you, not just clicks. Either way, genuinely good work on
{{their_video_or_post}}.
```

### 4.2 Sequence C — Partner / bundle (Setapp + indie-Mac bundles)

> **July status: PREP ONLY.** Bundle/Setapp outreach depends on the **Founder's Edition SKU `[PREREQUISITE]`** being live
> and tested. **Do not send §4.2 until the SKU exists.** Setapp = **single-app 85/15 track only, never the membership pool**,
> and it's a **Later** experiment (after direct conversion + the referral loop are healthy). Template kept here ready.

**Subject options:** `verba x setapp` · `catalog fit` · `bundle idea`

**First touch (Setapp / catalog)**
```
Subject: verba x setapp

Hi {{firstName}},

Setapp's AI/productivity shelf has the dictation base covered — but nobody on
it *acts* on what you say. That's the gap Verba fills.

Verba (verba.run) is a Mac voice app: on-device dictation that reuses the
user's own Claude sub (no markup), plus a confirm-gated voice agent that
creates the issue / sends the email / schedules the call across 1,000+ apps —
the user confirms every write. It's the "Jarvis for Mac" your subscribers keep
asking competitors for.

Is there a path to evaluate Verba for the catalog? I think it gives Setapp a
category-of-one feature against {{competitor_or_alternative}}, and gives us the
right Mac audience. Open to whatever evaluation/revenue-share structure you use.

— {{your_name}}
```

**First-touch variant (indie / lifetime bundle)**
```
Subject: bundle idea

Hey {{firstName}},

Saw {{their_bundle_or_post}} — your audience is dead-center for what I make.

Verba is a private-by-default Mac dictation app + confirm-gated voice agent
($9.99/mo normally). I'm spinning up a one-time Founder license, which makes it
a clean fit for a bundle. You'd be offering the only dictation tool that also
*does* things — a genuine headline SKU, not filler.

Want a free license to try it first, then talk terms (rev-share or flat)?
```

**Follow-up 1 — Day 5 (proof + lower the bar)**
```
Subject: re: {{prior_subject}}

{{firstName}} — to make the eval trivial, here's the 30-sec demo of the agent
running real confirmed actions: {{demo_link}}.

Quick differentiators for your catalog notes: on-device (audio never uploaded),
BYO-Claude (no key), 1,000+ connected apps, $9.99. The /compare matrix on our
site lists honestly where rivals still win — happy to share it so your team can
vet the claims.

What's the next step on your side?
```

**Follow-up 2 — Day 14 (breakup, keep the relationship)**
```
Subject: parking this

No problem if the timing or the model isn't right, {{firstName}}.

I'll check back when the Founder tier is live — that may make the bundle math
cleaner. Door's open on our end anytime; appreciate you taking a look.
```

### 4.3 Sequence D — Podcast / founder-story (also the angle for indie-Mac earned media, §3.5)

The narrative **is** the product to this audience: **one founder, agentic-systems builder, privacy-first, shipping a
confirm-gated agent** that runs on the user's own AI. Use this verbatim for podcasts **and** as the pitch backbone for
9to5Mac / MacStories / Indie Dev Monday / MPU.

**Subject options:** `pod guest?` · `founder story` · `confirm-gated agent`

**First touch**
```
Subject: founder story

Hi {{firstName}},

{{specific_episode}} stuck with me — {{specific_detail}}. Feels like your
listeners would dig the story I'm living right now.

I'm a solo founder who built Verba (verba.run): a Mac voice agent where the
*action planning runs on the user's own AI, on their own machine* — never my
server key — and every write is confirm-gated. Building a "Jarvis for Mac" that
you'd actually trust with your Gmail and Linear, as one person, with privacy as
the constraint, has some opinionated lessons (agentic reliability, why I refuse
autonomy, BYO-AI economics with zero inference cost).

Would that make a good episode? I can come with concrete stories and a live
"say it → it does it" demo, not just talking points. No pitch — happy to make
it 100% about the building.

— {{your_name}}
```

**Follow-up 1 — Day 5 (angles, make booking easy)**
```
Subject: re: founder story

{{firstName}}, a few angles in case one fits your format:

• "Why I built an AI agent that refuses to act without asking" (trust/safety)
• "Bring-your-own-AI: a SaaS with zero inference costs" (economics)
• "Privacy as a product constraint, not a feature" (the on-device bet)

I'll record around your schedule and send a 30-sec demo clip ahead so you can
judge the visual. Worth a slot?
```

**Follow-up 2 — Day 14 (breakup)**
```
Subject: last nudge

All good if it's not a fit for the lineup, {{firstName}}.

If you ever do an episode on agentic AI or solo-founder building, I'd love to
be in the running — and either way I'll keep listening. Thanks for the show.
```

---

## 5. Tracking sheet (reuse the file-04 §8 template)

One sheet. Status values: `sourced → first-touch → fu1 → fu2 → replied → in-progress → won → passed → dormant`
(build tasks: `to-build → scoping → live`). Seed it with the July targets:

| Target | Type | Channel | Hook (specific) | Touch | Last date | Status | Notes |
|---|---|---|---|---|---|---|---|
| Ryan Shrott | creator | Medium / email | "your 2026 dictation roundup — the one that *acts*" | — | 2026-07-07 | sourced | seed license + `?ref` + JARVIS clip |
| jamesm.blog | creator | blog / email | "voice→action vs the typers you covered" | — | 2026-07-07 | sourced | seed + `?ref` |
| afadingthought | creator | Substack | "BYO-key + private-by-default" | — | 2026-07-07 | sourced | seed + `?ref` |
| This Week in AI Club | creator | Substack | "dictation that became a voice agent" | — | 2026-07-07 | sourced | seed + `?ref` |
| 9to5Mac Indie Spotlight | earned-media | tip line | "Indie App Spotlight — voice agent for Mac" | — | 2026-07-14 | sourced | founder-story (Seq D) + press kit |
| MacStories (Viticci/Voorhees) | earned-media | email | "cross-app automation + on-device privacy" | — | 2026-07-14 | sourced | offer JARVIS demo |
| Indie Dev Monday | earned-media | form | "solo-founder agentic builder" | — | 2026-07-14 | sourced | submission |
| Mac Power Users + MPU Talk | earned-media | forum | "voice→action on the Mac you control" | — | 2026-07-14 | sourced | forum thread first |
| Indie Support Weeks | earned-media | GitHub/community | "join the next cross-promo wave" | — | 2026-07 | sourced | watch for wave |
| r/ClaudeAI | community | Reddit | "reuse your Claude sub, no key" | — | 2026-07-14 | not-started | lead with demo; launch post 30 Jul |
| Anthropic Discord | community | Discord | "no-key BYO-AI dictation" | — | 2026-07-14 | not-started | demo, not pitch |
| Cursor forum/Discord | community | forum | "talk to your editor, on-device" | — | 2026-07-14 | not-started | demo, not pitch |
| Dub affiliate | build | dub.co + Stripe | "30%/12mo, first-paid-charge" | — | 2026-06-29 | to-build | wire Stripe; live by T-3 |
| Raycast extension | build | GitHub PR | "private/on-device companion" | — | 2026-06-29 | scoping | ship Days 31–60 |
| Press kit | build | verba.run | "narrative + 2 demo clips + matrix" | — | 2026-06-29 | to-build | public by 11 Jul |
| Founder's Edition SKU | build | Stripe | `[PREREQUISITE]` $149 lifetime | — | 2026-06-29 | to-build | create+test before 28 Jul |

**Weekly ritual (file 04 §8):** re-run the searches, add 5–10 sourced targets, advance every contact one step or mark
dormant, and log which hook/demo earned replies — feed the winners back into the templates. Track creator-attributed
installs via the `?ref` links so you know which seeds actually moved revenue, not just published.

---

## 6. Metrics to watch (per lever — partnerships §8)

- **Creator / affiliate:** affiliate-attributed installs & paid conversions; **CAC per channel vs blended LTV**;
  recurring-commission payout as a % of affiliate-driven MRR (**guardrail: keep total payout < the margin headroom**);
  refund/chargeback rate on affiliate traffic (abuse signal).
- **Community wedge:** community-attributed installs (UTM/promo per community); reply/engagement quality (not vanity reach).
- **Mac integrations (Raycast):** extension installs → app downloads (funnel conversion) — *once shipped (Days 31–60)*.
- **Earned media:** placements landed and the referral traffic each drives.
- **Bundles / Lifetime:** Founder-tier units sold vs cap; **lifetime-buyer activation & referral rate** (do they feed the
  loop?); cannibalization check (% who'd otherwise have taken $84/yr) — *once the SKU is live*.
- **Guardrail (all levers):** gross margin stays very high (BYOK = zero inference COGS) — **never** let a partner deal
  introduce billed inference or a price anchor that drags the $84/yr plan.

North star to anchor against: **Weekly Active Dictators** + revenue, not vanity opens.

---

## 7. What stays LATER / AVOID in July (don't get distracted)

- **Later (do NOT start in July):** sponsored Tier-2 creator deals (Theo/t3.gg, Keep Productive, Matthew Berman, Matt Wolfe;
  newsletters Ben's Bites, TLDR AI, Code With Andrea) — only after Tier-1 CAC/LTV reads positive · one curated
  indie/Black-Friday bundle · Alfred Gallery workflow · **Setapp single-app 85/15** (experiment only, after direct
  conversion proven) · MAS reduced discovery SKU.
- **Avoid entirely:** AppSumo / StackSocial deep-discount LTDs (cut + refunds + permanent cheap anchor) · the **Setapp
  membership pool** (margin destruction + kills the referral loop) · **porting the flagship to the Mac App Store**
  (sandbox-incompatible + IAP tax) · treating the MCP registry / connected-apps infra as a **consumer storefront**.

---

**--- Resume :** Plan d'outreach partenariats Verba pour juillet (actions « Days 1–30 — Foundation » de
`partnerships-distribution.md`, datées sur le runway T-4 → semaine de lancement, lancement mardi 28 juil). Contient : la
table de priorités résumée (pursue now 1–6 / later / avoid), un calendrier semaine par semaine, puis les actions concrètes
avec **canal · angle · date juillet · statut initial** — affiliation **Dub** 30%/12mo câblée à Stripe, seeding des 4
comparison-writers nommés (Ryan Shrott, jamesm.blog, afadingthought, This Week in AI Club) avec licence+affiliate+démo, le
wedge communauté Claude/Cursor (« reuse your Claude sub, no key »), le scope de l'extension Raycast, la liste earned-media
indie-Mac (9to5Mac, MacStories, Indie Dev Monday, Mac Power Users, Indie Support Weeks) et la checklist press kit. Les
templates email **A / C / D** sont collés **verbatim** depuis le fichier 04. Garde-fou respecté : la Founder's Edition
Lifetime $149 est partout marquée `[PREREQUISITE : SKU Stripe à créer/tester avant le 28 juil]`, jamais comme disponible ;
aucune feature non livrée promise (macOS-only, iOS scaffolded-not-shipped).
