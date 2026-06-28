# Verba — July 2026 Email Playbook (Sequences + Send Plan)

> **Deliverable 04** of the July 2026 content package · `marketing/content-juillet-2026/04-sequences-email.md`
> **Reuses verbatim:** `marketing/cold-email.md` (Sequences A–E, etiquette, tracking) · `marketing/launch-strategy.md` (§5 launch email, §4 timeline, §6 runbook).
> **Scope:** Verba only (verba.run). **Language:** all sending copy is English (the audience is English-speaking dev/Mac). Orchestration notes are flagged.
> **Date:** 2026-06-28 · Author: Oracle (OmegaOS)

This is the **operational email playbook for July**: the five outreach sequences (ready to send), a dated July send calendar mapping each sequence to the launch runway, the J-14 list teaser, the launch-day email, and the post-launch onboarding/lifecycle sequence — plus the anti-spam etiquette and the tracking table. Sequences A–E and the etiquette/tracking blocks are reproduced **verbatim** from `cold-email.md`; the launch email subject + hook are **verbatim** from `launch-strategy.md`. The teaser, the launch-email body assembly, and the onboarding sequence are authored **on top of** the strategy's verbatim narrative blocks — no new claims.

---

## ⚠️ Honesty guard-rails — read before sending anything (L2)

These bind every line in this document. They override convenience.

1. **The Lifetime "Founder's Edition" ($149) is NOT live in Stripe yet.** Only **monthly ($9.99/mo)** and **annual ($84/yr ≈ $7/mo)** SKUs exist today. The strategy *plans* the Founder tier as a launch lever, but it is a **build prerequisite**, in the T-4 checklist (`launch-strategy.md` §3). Anywhere this playbook quotes the Founder/lifetime offer, it carries the tag:
   > **[PRÉREQUIS : SKU Stripe à créer/tester — gate T-4, avant le 28 juil]**
   **Do not send any line offering the $149 lifetime until that SKU is live + test-purchased + entitlement honored in-app + `?ref` attribution intact.** If launch day arrives and the SKU is not green, cut every Founder/lifetime line and ship monthly/annual only.
2. **No invented features.** macOS only (**iOS is scaffolded, NOT shipped — never pitch it, never give a date**). The only product truths: on-device dictation; **private by default** (audio never leaves the Mac, never uploaded; the action *planner* runs on-device too); **bring-your-own-AI** (reuse the Claude Code sub with **no API key**, or Anthropic key / OpenRouter / local Ollama — zero markup); **JARVIS** = confirm-gated voice agent across **1,000+ connected apps** + native Mac actions; plus Context (screen vision), hour-long Notes, live Translate. Trial = **33 dictations, no card → then 7-day Pro**.
3. **Public vocabulary only.** The agent is **"JARVIS" / "connected apps" / "on-device planning"** — **never** name the underlying vendor in any outreach.
4. **Honesty is the brand.** A seed license never buys a positive review; the gift is real and the review is genuinely optional. We publish where competitors beat us.

---

## 0. The two assets that do the selling (every sequence leans on one — never a feature list)

*(verbatim — `cold-email.md` §0)*

- **Speak-vs-type** — a side-by-side clip: dramatically faster than typing (the dictation category's own "4× faster" claim — substantiate it with Verba's own benchmark before quoting a number), reuses your Claude Code sub, no markup.
- **The JARVIS clip** — *"I said it, it did it (after it asked)."* Dictate "create the Linear issue and email the team a summary," the agent shows both actions, you confirm, done. This one travels **beyond** the dictation niche into the much larger agent/productivity audience.

## Voice & rules for every message (non-negotiable)

*(verbatim — `cold-email.md` §1)*

- **Write like a peer who noticed something**, not a vendor with a quota. Use contractions. Read it aloud; if it sounds like marketing copy, rewrite it.
- **Lead with their world.** "You/your" should dominate "I/we." Open on *their* video / post / newsletter / app — never on "My name is… and I work at…".
- **One ask, low-friction.** Offer a seed license or a 2-minute custom clip — never "hop on a 30-min call" in touch one.
- **The personalization must connect to the reason.** If you can delete the first line and the email still makes sense, the personalization is fake — don't send it.
- **Never demo an unconfirmed write.** The confirm step *is* the trust story. Keep it in every clip and every description.
- **No feature dumps.** One proof point beats ten features. The proof is the demo.
- **Never name the underlying connected-apps vendor.** Public names only: JARVIS, connected apps, on-device planning.

---

# PART 1 — THE FIVE SEQUENCES (verbatim, ready to send)

---

## SEQUENCE A — Creators (dev / Mac / productivity)

**Goal:** a seed license accepted → an honest review / demo published. The leverage play of the whole GTM.

### Target profile (who to seed)
- Reviews Mac apps, dev tools, AI tools, or productivity/PKM workflows.
- Audience is **Mac power-users, developers (esp. Claude Code / Cursor), or "AI that does things" people.**
- Size sweet spot: **5k–150k** subs/followers (big enough to matter, small enough to reply and to genuinely try a tool). Micro-creators convert better than mega ones here.
- Has covered a competitor (Wispr Flow, Superwhisper, MacWhisper, Aqua) OR posts about Claude Code / agents / "Jarvis."
- **Disqualify:** pure Windows/Android channels, crypto-shill accounts, anyone who runs paid-only "reviews."

### Sourcing strings (build the list)
- **YouTube:** `Wispr Flow review`, `Superwhisper review`, `best Mac dictation app`, `Mac dictation 2026`, `voice to text Mac`, `Claude Code workflow`, `Cursor setup`, `AI tools for Mac`, `Jarvis for Mac`, `voice assistant Mac`. Filter "This year." Note channels that ranked a competitor.
- **X / Twitter:** `Wispr Flow alternative`, `"Superwhisper"`, `dictation Mac`, `"Jarvis for my Mac"`, `voice agent Mac`, `Claude Code` + `voice`, `from:` searches on known dev-tool reviewers. Sort Latest.
- **Newsletters / blogs:** `site:reddit.com/r/macapps dictation`, Google `"Mac dictation" newsletter`, `best Mac apps newsletter`, Indie Hackers, "macOS productivity" Substacks, Refind/TLDR-style dev digests.
- **Reddit/Lobsters scouts:** r/macapps, r/ClaudeAI, r/productivity power-posters who make content elsewhere.
- Capture: name, channel/handle, the specific video/post, contact (about-page email / X DM / newsletter reply), audience fit, last competitor covered.

### Seed-license offer mechanics (the deal)
1. **Free Verba Pro, no strings on the review.** Lifetime/Founder comp **[PRÉREQUIS : SKU Stripe à créer/tester — gate T-4]** or 12-month Pro — give the tool free; honesty is required, a positive review is not. (Honesty *is* the brand — say so explicitly.)
2. **Affiliate % stacked on the built-in referral loop.** Verba already ships referral "Free Month" + `?ref` link capture → Stripe metadata (`gtm-strategy.md` §7). Give each creator a `?ref` link plus a **revenue share on conversions** so it pays beyond the one video.
3. **Done-for-them demo asset.** Offer a ready 60-sec speak-vs-type clip + the JARVIS clip they can drop in — removes the #1 reason a busy creator never gets to it.
4. **A real human follow-through:** a 15-min "show you JARVIS on your own apps" if they want it — never required.

### Subject lines (2–4 words, lowercase, internal-looking)
- `your dictation video` — *contextual, references their content, looks like a viewer reply.*
- `verba for {{channel}}` — *specific, non-salesy, signals it's about their work not a blast.*
- `the jarvis clip` — *curiosity + concrete; works once you've name-dropped the demo.*

### First touch
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

### Follow-up 1 — Day 3 (new value: hand them the asset)
```
Subject: the jarvis clip

{{firstName}} — the clip, in case it's easier to judge than my pitch:
{{demo_link}}

That's a real confirmed action on real tools, not a mockup. The "it asks
before it acts" pause is the whole point — that's the part people screenshot.

Pro license is yours whenever; takes 30 seconds, no card. Worth a look?
```

### Follow-up 2 — Day 10 (social proof / momentum + the breakup)
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

---

## SEQUENCE B — Newsletter sponsorships

**Goal:** a paid (or comped-trial) placement in a newsletter our beachhead reads. Different from creators: this is a **media buy**, so the email is to the operator/ad-sales, and the value exchange is clear.

### Target profile
- Newsletters read by **Mac power-users, developers, Claude/AI builders, privacy-minded pros.** (dev digests, "best Mac apps," AI-tooling, indie-hacker, PKM/productivity.)
- 3k–100k subscribers; high open rate beats raw size for this niche.
- Runs sponsorships (has a "sponsor" / "advertise" page) **or** is small enough to do a one-off.

### Sourcing strings
- Google: `best Mac apps newsletter sponsor`, `developer newsletter advertise`, `AI tools newsletter sponsorship`, `Claude newsletter`, `macOS productivity Substack`. Check Sponsor/Media-Kit pages, Swapstack, Paved, beehiiv ad network.

### Subject lines
- `sponsor slot` — *internal, sounds like inbound interest, not a pitch.*
- `q3 sponsorship` — *concrete, businesslike, gets to ad-sales fast.*
- `{{newsletter_name}} fit` — *signals you read it and tailored this.*

### First touch
```
Subject: sponsor slot

Hi {{firstName}},

Your {{specific_issue_or_topic}} issue is exactly the reader I'm trying to
reach — Mac folks who'd rather talk than type and care where their data goes.

I run Verba (verba.run): on-device Mac dictation that reuses your Claude sub
with no API key, and a confirm-gated voice agent that can actually *do* things
across 1,000+ apps. $9.99, privacy-first, no audio ever uploaded.

Do you take sponsors? I'd want one slot with a short copy block + a 30-sec demo
GIF (the "say it → it does it" one — it tests well). Happy to start with a
single issue to see if your list converts before we talk about more.

What's your rate + next opening?

— {{your_name}}
```

### Follow-up 1 — Day 4 (de-risk + offer the asset)
```
Subject: re: sponsor slot

{{firstName}}, two things to make this easy:

1. I'll write the copy in your newsletter's voice and hand you the demo GIF —
   zero production work on your end.
2. We can do a flat single-issue test, or a CPC/affiliate deal off a `?ref`
   link so you only win when readers convert. Your call.

Rate card and the nearest open slot when you have a sec?
```

### Follow-up 2 — Day 12 (breakup, door open)
```
Subject: closing the loop

Totally understand if the calendar's full or it's not a fit, {{firstName}}.

If a slot opens later this quarter, I'd still love one test issue — the offer
(copy written for you + demo asset + affiliate option) stands. Either way I'm a
reader now. Thanks for {{newsletter_name}}.
```

---

## SEQUENCE C — Partner / bundle (Setapp + indie-Mac bundles)

**Goal:** distribution + credibility through a curated Mac catalog or a flash/lifetime bundle. **The value exchange must be explicit** — these are deals, not favors.

> **[PRÉREQUIS : SKU Stripe à créer/tester — gate T-4]** — the indie/lifetime-bundle variant below references a one-time **Founder license**. That SKU does **not** exist in Stripe yet. You can *open the conversation* (it's a slow BD cycle) honestly framing the Founder tier as "spinning up," but do not commit a bundle on the lifetime SKU until it's live + tested.

### Targets & the value exchange
- **Setapp** (MacPaw) — the subscription Mac-app catalog. *Their* value: a category-of-one voice agent + private dictation rounds out their AI/productivity shelf and gives subscribers something Wispr-class without leaving Setapp. *Our* value: distribution to a paying Mac audience already past the "trust an indie app" hurdle, and credibility-by-association. **Caveat (L2):** Setapp is all-you-can-eat subscription revenue-share — model the economics before committing; it's a distribution + brand play, not necessarily margin-accretive. Note it, don't pretend it's free money.
- **Indie-Mac bundles** (e.g. seasonal "Mac power-user" bundles, lifetime-deal marketplaces). Pairs naturally with the **Lifetime/Founder tier** the strategy recommends — bundles want a one-time SKU, and COGS≈0 makes a lifetime license unusually safe to give.

### Subject lines
- `verba x setapp` — *names the partnership, peer-to-peer.*
- `catalog fit` — *internal, BD-sounding.*
- `bundle idea` — *low-pressure, collaborative.*

### First touch (Setapp / catalog)
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

### First touch variant (indie / lifetime bundle)
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
> **[PRÉREQUIS]** "spinning up a one-time Founder license" is honest only while the SKU is genuinely in build (T-4). Don't quote a price or a live link until it's tested.

### Follow-up 1 — Day 5 (proof + lower the bar)
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

### Follow-up 2 — Day 14 (breakup, keep the relationship)
```
Subject: parking this

No problem if the timing or the model isn't right, {{firstName}}.

I'll check back when the Founder tier is live — that may make the bundle math
cleaner. Door's open on our end anytime; appreciate you taking a look.
```

---

## SEQUENCE D — Podcast / founder-story pitch

**Goal:** a guest spot or a founder-story feature. The narrative *is* the product to this audience: **one founder, agentic-systems builder, privacy-first, shipping a confirm-gated agent** that runs on the user's own AI.

### Target profile
- Indie-hacker / bootstrapper / dev-tool / "building in public" / AI-builder podcasts.
- Hosts who feature solo founders, agentic AI, or privacy-tech stories.

### Sourcing strings
- `indie hacker podcast`, `bootstrapped founder podcast`, `AI agent podcast`, `dev tools podcast`, `building in public podcast`, `Mac developer podcast`, `solo founder interview`. Plus guests-of-guests on shows you already know.

### Subject lines
- `pod guest?` — *casual, peer, low-stakes.*
- `founder story` — *names the value you bring to their feed.*
- `confirm-gated agent` — *a hook that signals a real, specific topic, not a generic "I'd love to come on."*

### First touch
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

### Follow-up 1 — Day 5 (angles, make booking easy)
```
Subject: re: founder story

{{firstName}}, a few angles in case one fits your format:

• "Why I built an AI agent that refuses to act without asking" (trust/safety)
• "Bring-your-own-AI: a SaaS with zero inference costs" (economics)
• "Privacy as a product constraint, not a feature" (the on-device bet)

I'll record around your schedule and send a 30-sec demo clip ahead so you can
judge the visual. Worth a slot?
```

### Follow-up 2 — Day 14 (breakup)
```
Subject: last nudge

All good if it's not a fit for the lineup, {{firstName}}.

If you ever do an episode on agentic AI or solo-founder building, I'd love to
be in the running — and either way I'll keep listening. Thanks for the show.
```

---

## SEQUENCE E — Power-user / champion (light, reactive)

**Goal:** turn someone *publicly asking* for what we built into a delighted user (and often a public advocate). This is **reactive, one-to-one, and tiny-volume** — reply to a real post, never blast. Often a public reply > a DM, but a short DM/email works when they've shared contact.

### Where to find them (live searches, run weekly)
- X: `Wispr Flow alternative`, `"is there a Jarvis for Mac"`, `Superwhisper too expensive`, `dictation app that uploads`, `voice agent Mac`, `control my Mac by voice`.
- Reddit: r/macapps, r/ClaudeAI, r/productivity threads asking for recommendations; HN "Ask HN" + comments.

### Subject line (if email/DM)
- `you asked for this` — *direct, true, references their exact post.*
- `saw your post` — *human, honest, no pitch.*

### First touch (DM / reply tone)
```
Subject: you asked for this

{{firstName}} — saw your post asking for {{their_request}}. That's almost
exactly why Verba exists.

On-device Mac dictation, reuses your Claude sub (no key, no markup), and it can
actually *do* the thing you say — create the issue, send the email — after it
shows you and you confirm. $9.99, audio never leaves your Mac.

Here's a free Pro license, no strings: {{license_or_link}}. If it's not what you
wanted, tell me what's missing — I'm the founder and I read every reply.
```

### Follow-up (Day 5, only if they engaged but didn't redeem)
```
Subject: re: you asked for this

{{firstName}}, did the license land? If first-run tripped you up, the trick is:
have Claude Code installed → zero setup, no key. Or offline Parakeet for an
instant no-account start. Happy to walk you through JARVIS on your own apps if
useful — no pressure either way.
```
*(One follow-up max for champions. These are humans who already raised a hand; over-following-up sours goodwill. If silent, leave it.)*

---

# PART 2 — JULY SEND PLAN (which sequence, to whom, WHEN)

> **Note d'orchestration (FR) :** le calendrier ci-dessous est aligné sur le runway de `launch-strategy.md` §4 et sur les ancres exactes de juillet (lancement = mardi 28 juil). Chaque vague a une *raison de timing* (lead-time du canal), pas un placement arbitraire.

## 2.1 Why each sequence lands in its phase (the timing logic)

| Seq | Audience | Phase (first touch) | Why this phase — the lead-time logic |
|---|---|---|---|
| **B — Newsletters** | ad-sales / operators of dev & Mac newsletters | **T-4** (29 Jun–5 Jul) | A media buy must **run during launch week**. Newsletter inventory books 3–4 weeks out → you have to reach out *now* to land an issue on/just before Tue 28 Jul. Earliest because the slot date is fixed and external. |
| **D — Podcasts** | indie/dev/AI-builder podcast hosts | **T-3** (6–12 Jul) | Longest production lead (book → record → edit → publish). Seed in T-3 so episodes **record T-1/launch week and air T+1 onward**, extending the spike (the TRMNL-style multiplier). |
| **C — Partner/bundle** | Setapp BD + indie-bundle curators | **T-3** (6–12 Jul) | Slow BD cycle; **not launch-gated**. Start early, expect it to mature post-launch. Lifetime-bundle variant references the Founder SKU **[PRÉREQUIS]** — honest only while it's genuinely in build. |
| **A — Creators** | dev/Mac/productivity creators (5k–150k) | **T-2** (13–19 Jul) | Creators need a license + the demo clip + ~2 weeks to actually try it and maybe film around launch. Matches `launch-strategy.md` T-2: "seed 10–20 creators." |
| **E — Champions** | people *publicly asking* for "Jarvis for Mac" / a Wispr alt | **Always-on weekly** (T-4 → T+2) | Reactive 1:1, tiny volume. **Peaks launch week** when launch posts generate "is there an X for Mac?" reactions to reply to. |

## 2.2 Per-sequence concrete schedule (follow-up offsets preserved)

All touches land **Tue–Thu, 9–11am / 1–3pm recipient-local** (`cold-email.md` §7 cadence). Day-offsets are the source's own (A: 3/10 · B: 4/12 · C: 5/14 · D: 5/14 · E: 5, one max), nudged to the Tue–Thu window with increasing gaps.

| Seq | First touch | Follow-up 1 | Follow-up 2 | Afterlife |
|---|---|---|---|---|
| **B — Newsletters** | **Wed 1 Jul** | **Tue 7 Jul** (Day ~4) | **Wed 15 Jul** (Day ~12) | Booked slot **runs launch week (27 Jul–2 Aug)** — push for an issue on/just before Tue 28 Jul |
| **D — Podcasts** | **Tue 7 Jul** | **Tue 14 Jul** (Day ~5) | **Tue 21 Jul** (Day ~14) | Record T-1 / launch wk → **episodes air from early Aug** |
| **C — Partner/bundle** | **Wed 8 Jul** | **Wed 15 Jul** (Day ~5) | **Tue 22 Jul** (Day ~14) | Setapp eval continues for weeks; re-open bundle "when Founder tier is live" |
| **A — Creators** | **Tue 14 Jul** | **Thu 17 Jul** (Day 3) | **Thu 24 Jul** (Day 10) | T+1 (from 3 Aug): convert seeded creators who haven't posted into reviews/clips |
| **E — Champions** | **rolling, weekly** (run searches each Tue) | **+5 days, one max** | — | **Peak Tue 28–Fri 31 Jul** on launch reactions |

## 2.3 List emails (owned channel) — the dated moments

| Email | Date / time | List | Source |
|---|---|---|---|
| **J-14 teaser** ("something big in 2 weeks") | **Tue 14 Jul** | existing/early list | `launch-strategy.md` T-2 — *full copy in Part 3* |
| **Launch email** ("Verba can now do what you say…") | **Tue 28 Jul, 12:05am PT** | full list | `launch-strategy.md` §5 + §6 runbook — *verbatim subject + assembled body in Part 4* |
| **"We launched" recap** | **Fri 31 Jul** | full list | `launch-strategy.md` §4 launch week — *copy in Part 4* |
| **Onboarding / lifecycle** (behavior-triggered) | **flips ON from Mon 3 Aug** | every new install | `launch-strategy.md` §7.2 — *full sequence in Part 5* |

## 2.4 Month-at-a-glance

| Week (phase) | Outbound outreach | Owned list |
|---|---|---|
| **T-4** · Mon 29 Jun–Sun 5 Jul | **B first touch** (Wed 1) · build A/C/D lists · **E** rolling | — |
| **T-3** · Mon 6–Sun 12 Jul | **D first touch** (Tue 7) · **B FU1** (Tue 7) · **C first touch** (Wed 8) · **E** rolling | — |
| **T-2** · Mon 13–Sun 19 Jul | **A first touch** (Tue 14) · **D FU1** (Tue 14) · **A FU1** (Thu 17) · **C FU1** (Wed 15) · **B FU2** (Wed 15) · **E** rolling | **Teaser J-14 (Tue 14)** |
| **T-1** · Mon 20–Sun 26 Jul | **D FU2** (Tue 21) · **C FU2** (Tue 22) · **A FU2** (Thu 24) · confirm warm list + creators for launch · **E** rolling | *(launch email scheduled)* |
| **Launch wk** · Mon 27 Jul–Sun 2 Aug | **E PEAK** (28–31) · warm-list + seeded-creator launch ping (Tue 28, 12:10am PT) | **Launch email (Tue 28)** · **"We launched" recap (Fri 31)** |
| **T+1–2** · Mon 3–Sun 16 Aug | **A afterlife** (convert non-posters) · **C** continues · **D** episodes air | **Onboarding/lifecycle ON** (all new installs) |

> **Go/No-Go (Fri 24 Jul):** if the Founder/lifetime SKU **[PRÉREQUIS]** is not live + tested, strip every Founder line from the launch email and PH/X copy and launch monthly/annual only. The launch is still valid; the lever just isn't loaded.

---

# PART 3 — J-14 LIST TEASER (Tue 14 Jul)

> **Authored on strategy** (`launch-strategy.md` T-2: *"Email any existing list: 'something big from Verba in 2 weeks' teaser → capture replies/interest."*). No new claims; built from the verbatim narrative line + the three messages. Send to the existing/early list only (opted-in).

**Goal:** warm the owned list two weeks out, plant the narrative, and capture replies/interest (loss-aversion + a real reason to watch). One soft CTA: reply.

```
Subject: something big from Verba in 2 weeks

Hey {{firstName}},

Quick heads-up because you've followed Verba early.

In two weeks I'm shipping the thing I've been quietly building: Verba started as
a Mac dictation app — talk, get clean text where your cursor is, on-device,
reusing the Claude sub you already pay for (no key, no markup).

Now it does more than type. Say "create the Linear issue for this bug and email
the team a summary" — Verba plans it on your Mac, shows you exactly what it'll
do, and does it only after you confirm. Across 1,000+ connected apps. Your audio
never leaves your machine.

The Mac dictation app that became a voice agent. Launching Tue 28 July.

I'll have a launch-day offer for this list before anyone else. Want the early
heads-up the morning it goes live? Just reply "in" and I'll make sure you're first.

— {{your_name}}
verba.run
```

*Reply-handling: tag every "in" reply as **warm list** in the tracker — these are the people you ping at 12:10am PT on launch day, and the first warm Founder-license conversions once that SKU is live.*

---

# PART 4 — LAUNCH EMAILS

## 4.1 Launch email — Tue 28 Jul, 12:05am PT (full list)

> **Subject is VERBATIM** from `launch-strategy.md` §5. The **hook spec** is verbatim: *"the narrative line + the demo GIF + 'we're on Product Hunt today' + the Founder lifetime offer."* The body below is **assembled from the strategy's verbatim narrative blocks** (the §1 narrative line, the §1 three messages, the §5 PH/X Founder-offer line) — no new claims.
> **[PRÉREQUIS : SKU Stripe à créer/tester]** — the Founder line is bracketed. **If the $149 SKU isn't live + tested by Fri 24 Jul, delete that line entirely** and keep the monthly/annual close.

**Subject:** `Verba can now do what you say (not just type it)`

```
Subject: Verba can now do what you say (not just type it)
Preview: The Mac dictation app that became a voice agent. We're live today.

Hey {{firstName}},

The Mac dictation app that became a voice agent.

Here's the one-take demo: I dictate "create the Linear issue for this bug and
email the team a summary." Verba plans it, shows me both actions, I hit confirm
— done. Nothing edited out, confirm step included.

[ ▶ demo GIF / video — {{demo_link}} ]

Three things I care about more than anything:

1. Private by default — your voice never leaves your Mac, never uploaded. Even
   the action planning runs on-device, with your own AI.
2. Bring your own AI — reuse your Claude Code subscription with no API key (or
   Anthropic / OpenRouter / local Ollama). No markup, ever.
3. It doesn't just type — it does. JARVIS plans, asks when unsure, shows you
   the action, and executes only on your confirm — across 1,000+ connected apps
   + native Mac actions.

We're live on Product Hunt today. If you've got 30 seconds, an honest comment
means everything to a bootstrapped, one-person launch:
👉 {{product_hunt_link}}

Start free — 33 dictations, no card. $9.99/mo or $84/yr after.

[ LAUNCH-DAY OFFER — only send if the SKU is live:
  And for today only: a one-time $149 Founder's Edition (first 200) — lifetime
  Verba, no subscription, ever. {{founder_link}}
  → [PRÉREQUIS : SKU Stripe à créer/tester — gate T-4]. If not live, DELETE these lines. ]

Tell me what you'd want to do by voice — I read every reply.

— {{your_name}}
verba.run

Mac-only today. Your audio stays on your Mac (local history, with an off switch).
{{unsubscribe}} · {{postal_address}}
```

*Send mechanics (`launch-strategy.md` §6): fire at **12:05am PT** alongside pinning the X launch thread; at **12:10am PT** personally ping the warm list + seeded creators ("we're live — would love your honest take" — ask for genuine engagement, never "upvote"; PH bans vote manipulation).*

## 4.2 "We launched" recap email — Fri 31 Jul (full list)

> **Authored on strategy** (`launch-strategy.md` §4 launch week: *"send the 'we launched' email to the full list; convert warm Founder-license interest."*). Building-in-public, real numbers, transparency — the audience rewards it.

```
Subject: we launched — here's what actually happened

Hey {{firstName}},

We did it. Verba went live on Product Hunt Tuesday, hit Show HN Wednesday, and
the dev/Mac crowd showed up. A few honest numbers:

• {{installs}} downloads
• {{reviews}} reviews / comments — including the hard questions, which I love
• Best part: dozens of "wait, it actually does the thing after I confirm?" moments

If you were one of the people who tried it, commented, or just cheered — thank
you. This is a one-person, bootstrapped build, and that support is the whole
engine.

If you haven't yet: the demo is still the fastest way to get it —
{{demo_link}}. Start free, 33 dictations, no card.

[ Only if the SKU is live: The $149 Founder's Edition (lifetime, no subscription)
  has a few of the first-200 slots left → {{founder_link}}
  → [PRÉREQUIS : SKU Stripe à créer/tester]. If not live, DELETE these lines. ]

What would you want to run by voice next? Reply and tell me — it's how the
roadmap gets built.

— {{your_name}}
verba.run

{{unsubscribe}} · {{postal_address}}
```

---

# PART 5 — ONBOARDING / LIFECYCLE SEQUENCE (post-launch, flips ON from Mon 3 Aug)

> **Authored on strategy** (`launch-strategy.md` §7.2: *"Onboarding email sequence for every new install: zero-key Claude path → first great dictation → first JARVIS action → the privacy story. Reduces the BYOK first-run bounce."* + GTM §7 owned loops). **Behavior-triggered**, not a fixed drip — the trigger beats the day. Every email maps to one **activation moment**.

**The activation spine (the only goals these emails serve):**
1. **First dictation < 60s** — the zero-key Claude Code path is the hero; offline Parakeet is the instant no-account fallback.
2. **First confirmed JARVIS action** — connect one app → dictate → see the plan → confirm → done. The confirm step *is* the trust story.
3. **Trial → paid** — 33 free dictations (no card) → 7-day Pro → $9.99/mo or $84/yr.
4. **Turn on the owned loops** — referral "Free Month," shareable leaderboard (GTM §7).

| # | Trigger | Activation goal | Subject |
|---|---|---|---|
| O0 | install / account created (t=0) | first dictation <60s | `you're 60 seconds from your first dictation` |
| O1 | +24h, **no first dictation** | activation rescue | `stuck on first run? the zero-key trick` |
| O2 | **after first dictation** | first confirmed action | `now make it act (your first JARVIS action)` |
| O3 | +3 days active | the privacy story | `where your voice actually goes` |
| O4 | delightful moment / ~10th use | referral + leaderboard loop | `give a free month, get a free month` |
| O5 | trial value-cliff (≈30/33 dictations or day 6 of Pro) | trial → paid | `your Pro trial is almost up` |
| O6 | +14 days, **dormant / never activated** | win-back | `still want a Jarvis for your Mac?` |

### O0 — Welcome (t=0)
```
Subject: you're 60 seconds from your first dictation

Welcome to Verba, {{firstName}}.

Fastest path to "whoa": press your hotkey, talk, watch clean text land where
your cursor is.

→ Already have Claude Code installed? You're ready — no key, no setup. Verba
  reuses the subscription you already pay for.
→ No Claude Code? Pick offline Parakeet in setup — instant, no account, runs
  entirely on your Mac.

That's it. Go say one sentence into any text field, then come back — the next
email is the fun part: making Verba *act* on what you say.

— The Verba team
{{unsubscribe}} · {{postal_address}}
```

### O1 — Activation rescue (+24h, no first dictation)
```
Subject: stuck on first run? the zero-key trick

{{firstName}}, noticed you haven't run your first dictation yet — usually
that's one small first-run snag, not you.

The 10-second fix: if you have Claude Code installed, Verba uses it directly —
no API key, nothing to paste. If you don't, switch the engine to offline
Parakeet (Settings ▸ Engine) and you're transcribing instantly, no account.

Press the hotkey, say "this is my first Verba dictation," done. Reply if it
fights you — a real human (the founder) reads these.
```

### O2 — First confirmed action (after first dictation)
```
Subject: now make it act (your first JARVIS action)

Nice — you've got dictation working, {{firstName}}. Here's the part most people
don't realize Verba can do:

1. Settings ▸ Connected apps → connect one (Linear, Gmail, Slack, Calendar…).
2. Dictate something like "create a Linear issue: fix the login bug."
3. Verba shows you the exact action it's about to take.
4. You hit confirm. It does it.

It plans everything on your Mac with your own AI, and it never writes anything
without showing you first. That confirm step is the whole point — you stay in
control. Try one and tell me what you'd want to automate next.
```

### O3 — The privacy story (+3 days active)
```
Subject: where your voice actually goes

Quick one, {{firstName}}, because it's the reason Verba exists:

Your audio never leaves your Mac. It's not uploaded — ever. It lives in local
history (with an off switch and auto-prune if you want neither).

Even the agent's *planning* — figuring out the steps for "send the email and
file the note" — runs on-device, on your own AI. Not my server. Most voice
tools ship your audio to the cloud to do far less. Verba doesn't.

Private by default isn't a setting here. It's the architecture.
```

### O4 — Referral + leaderboard loop (delightful moment / ~10th use)
```
Subject: give a free month, get a free month

{{firstName}}, you've clearly found your groove with Verba — so here's the
neighborly part:

Share your referral link → a friend gets Verba, and you both get a free month.
{{referral_link}}

And if you're curious how much typing you've actually skipped, your leaderboard
card is shareable: {{leaderboard_link}}. ("I saved {{hours}} hours with Verba"
is a fun flex.)

No pressure — just the fastest way to get the people you'd recommend it to anyway.
```

### O5 — Trial → paid (value-cliff: ≈30/33 dictations or day 6 of Pro)
```
Subject: your Pro trial is almost up

Heads-up, {{firstName}} — you're near the end of your free run (your 33
dictations / 7-day Pro window).

If Verba's earned a spot in your day, keeping Pro is $9.99/mo, or $84/yr
(~$7/mo) if you'd rather not think about it again. You keep all 6 modes, JARVIS
actions across 1,000+ apps, Context, Notes, and Translate.

Still on the fence? Reply and tell me what's missing — I'd rather fix it than
lose you. {{upgrade_link}}
```
> **[PRÉREQUIS]** Do **not** add a lifetime/Founder line to onboarding emails until that SKU is live + tested. Until then, O5 closes on monthly/annual only.

### O6 — Win-back (+14 days, dormant / never activated)
```
Subject: still want a Jarvis for your Mac?

{{firstName}}, Verba's been quiet on your Mac — no hard feelings, first-run AI
setup trips a lot of people.

The no-friction restart: switch the engine to offline Parakeet (no account, no
key, runs locally) and you're dictating in seconds. Then connect one app and
try a single confirmed action — that's the moment it clicks.

If it's just not for you, tell me why in one line — that feedback genuinely
shapes what I build next. Either way, thanks for giving it a look.

— {{your_name}}, founder
{{unsubscribe}} · {{postal_address}}
```

---

# PART 6 — ANTI-SPAM ETIQUETTE (why volume kills this niche)

*(verbatim — `cold-email.md` §7. This is the most important section.)* **Volume-blasting doesn't just underperform here — it actively destroys the asset.**

- **Our audience is the hardest possible crowd to spam.** Developers, privacy professionals, and Mac power-users can smell a mail-merge from the subject line — and they have megaphones. A creator who feels mass-blasted can post the screenshot to 50k people. One careless blast can do more brand damage than 100 good emails do good.
- **Reputation is the product.** Verba's brand *is* radical honesty (we publish where competitors beat us). Spammy outreach contradicts the entire positioning. Every email must be congruent with "pro-user, never salesy."
- **The math favors quality, not quantity.** This is relationship outreach: 30 genuinely personalized emails to well-fit creators beat 3,000 templated ones. One creator who actually loves it is worth more than a thousand opens.
- **Personalize or don't send — the real test:** delete your first line. If the email still makes sense, the personalization is fake; rewrite it or skip the target. Every send must reference a *specific* video / post / issue / app / request.
- **Honor the breakup.** Two to three touches, then stop. No "just bumping this," no re-adding silent contacts to a new sequence. Loss-aversion works once; nagging poisons the well.
- **Lead with value, not the ask.** A free license, a done-for-them clip, a useful comparison — give before you ask. The seed-license model only works if the gift is real and the review is genuinely optional.
- **Cadence & timing:** Tue–Thu, 9–11am / 1–3pm local; increasing gaps between touches; ~55% of replies come from follow-ups, so the *second* email matters — but each must add new value.
- **Never fake it.** No `Re:`/`Fwd:` trick subjects, no false urgency, no invented social proof. We're early-stage with no testimonials yet — our proof is product depth + category momentum, and we say exactly that.
- **Channel-match the contact:** creators via their stated contact (about page / X DM / newsletter reply); never scrape personal addresses. Respect "no sponsors / no PR" pages.

### List-email compliance (applies to the J-14 teaser, launch emails, and onboarding only)
The 1:1 outreach above is person-to-person and not bulk. The **list emails** (Parts 3–5) are bulk and must obey list law: **opted-in recipients only**, a working **unsubscribe** link in every send, a real **postal address** in the footer, an honest subject/preview, and honor unsubscribes immediately. Onboarding/lifecycle = transactional-adjacent but still give an opt-out of marketing emails. Never import the outreach contacts (Parts 1) into a bulk list.

---

# PART 7 — TRACKING TABLE + WEEKLY RITUAL

*(verbatim — `cold-email.md` §8)*

Keep one simple sheet. Columns: target, type, channel, the specific hook used, touch #, last-touch date, status, owner, notes. Status values: `sourced → first-touch → fu1 → fu2 → replied → in-progress → won → passed → dormant`.

| Target | Type | Channel | Hook (specific) | Touch | Last date | Status | Notes |
|---|---|---|---|---|---|---|---|
| {{name}} | creator | YouTube / email | "your Wispr Flow review" | fu1 | 2026-07-17 | first-touch | seeded license, sent JARVIS clip |
| {{newsletter}} | newsletter | email | "best-Mac-apps issue" | — | 2026-07-01 | sourced | check sponsor page for rate; needs to RUN launch wk |
| Setapp BD | partner | email | "catalog fit, voice-agent gap" | first-touch | 2026-07-08 | first-touch | model rev-share before terms |
| {{podcast}} | podcast | email | "confirm-gated agent story" | fu1 | 2026-07-14 | replied | offered 3 angles + demo |
| {{handle}} | champion | X DM | "asked for Jarvis for Mac" | first-touch | 2026-07-28 | won | redeemed license, posted publicly |

**Weekly ritual:** re-run the champion searches (Sequence E), add 5–10 new sourced creators, advance every contact one step or mark dormant, and log which hook/demo earned replies — feed the winners back into the templates. Track creator-attributed installs via the `?ref` links so you know which seeds actually moved revenue, not just published.

---

# PART 8 — QUALITY CHECK BEFORE ANY SEND

*(verbatim — `cold-email.md` §9)*

- Does it sound like a human peer wrote it? (Read it aloud.)
- Would *you* reply to this?
- Is the first line specific to *this* target and connected to the reason you're writing?
- Is there exactly one low-friction ask (seed license / demo / slot) — no 30-min call?
- One proof point (a demo), not a feature dump?
- Zero invented features, no iOS pitch, no underlying-vendor name, no salesy/urgency words?
- **+ Founder/lifetime guard-rail:** if the copy offers the $149 lifetime, is the Stripe SKU actually live + tested? If not, the line is deleted. **[PRÉREQUIS]**

If all are yes, send. If any is no, fix it or don't send — in this niche, not sending is always safer than spamming.

---

*Built on the Verba GTM package — does not contradict it. Sequences A–E, the etiquette, and the tracking table are verbatim from `marketing/cold-email.md`; the launch-email subject + hook are verbatim from `marketing/launch-strategy.md` §5. The July send plan, the J-14 teaser, the launch-email body assembly, and the onboarding sequence are authored on top of the strategy's verbatim narrative blocks — no invented features. iOS not marketed. The agent is JARVIS / connected apps. The Founder/lifetime SKU is a build prerequisite, flagged everywhere it appears.*

--- **Resume :** Playbook email de juillet écrit dans `marketing/content-juillet-2026/04-sequences-email.md` — les 5 séquences A–E reproduites VERBATIM (objets + premier contact + 2 relances + mécaniques) depuis `cold-email.md`, plus un PLANNING D'ENVOI daté aligné sur le runway (B newsletters en T-4 pour le lead-time, D podcasts + C partenaires en T-3, A créateurs en T-2 le 14 juil, E champions réactif en continu avec pic semaine de lancement), le teaser liste J-14 (mar 14 juil), l'EMAIL DE LANCEMENT (mar 28 juil, objet verbatim "Verba can now do what you say (not just type it)") + email recap "we launched" (ven 31 juil), une séquence ONBOARDING/lifecycle déclenchée par comportement (1ère dictée <60s zéro-clé Claude Code, 1ère action JARVIS confirmée, story privacy, boucle referral, trial→payant), l'étiquette anti-spam + conformité bulk, le tableau de tracking et le quality-check. Garde-fou Lifetime/Founder $149 = PRÉREQUIS Stripe balisé partout ; aucune feature inventée ; iOS non promu ; nom du fournisseur jamais cité.*
