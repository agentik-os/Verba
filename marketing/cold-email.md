# Verba, Outbound / Relationship-Outreach Playbook

> Deliverable 7 of the Verba GTM package · Skill: `/omg-cold-email` (R-MARKETING: outbound acquisition)
> Reads: `.agents/product-marketing.md` (positioning + voice SSOT) · `marketing/gtm-strategy.md` (§4 Engine C creators) · `marketing/content-strategy.md`. Scope: **Verba only** (verba.run).
> Date: 2026-06-27 · Author: Oracle (OmegaOS)

---

## 0. Honest framing, read this before sending anything (L2)

The `/omg-cold-email` skill is built for **B2B prospecting**: SDRs emailing decision-makers to book demos and close seats. **Verba has none of that.** Verba is a **self-serve B2C / prosumer macOS app at $9.99/mo with no sales team, no procurement, no seats, no enterprise motion.** The buyer is one person clicking checkout. There is **no "cold-email-the-CISO" play** here, and pretending there is would burn the budget and the brand.

So this document deliberately **reframes "outbound" as relationship outreach**, the high-leverage, earned→paid motion from GTM Engine C. We are not prospecting buyers; we are reaching **multipliers**: people whose audience, distribution, or shelf can put Verba's two self-selling demos in front of thousands of the right Mac users at once. The five outreach types:

1. **Creators**, dev / Mac / productivity YouTubers, streamers, newsletter writers who already review dictation tools → **seed licenses**.
2. **Newsletter sponsorships**, paid placement in newsletters our beachhead reads.
3. **Partner / bundle**, Setapp + indie-Mac bundles → distribution + credibility.
4. **Podcast / founder-story**, the one-founder, agentic-builder, privacy-first, confirm-gated-agent narrative.
5. **Power-user / champion**, light, human outreach to people *publicly asking* for a "Wispr Flow alternative" or "Jarvis for Mac."

**The two assets that do the selling** (every sequence leans on one of them, never on a feature list):
- **Speak-vs-type**, a side-by-side clip: dramatically faster than typing (the dictation category's own "4× faster" claim, substantiate it with Verba's own benchmark before quoting a number), reuses your Claude Code sub, no markup.
- **The JARVIS clip**, *"I said it, it did it (after it asked)."* Dictate "create the Linear issue and email the team a summary," the agent shows both actions, you confirm, done. This one travels **beyond** the dictation niche into the much larger agent/productivity audience.

**Product truths only, no invented features.** macOS-only (iOS is *scaffolded, not shipped*, never pitch it). $9.99/mo. BYO-Claude with **no API key** (or Anthropic key / OpenRouter / local Ollama). **Private by default**, audio never leaves the Mac, never uploaded. **JARVIS**: confirm-gated voice agent across **1,000+ connected apps** + native Mac actions, **planned on-device by the user's own AI**. Plus Context (screen vision), hour-long Notes, live Translate. **Public vocabulary is "JARVIS" and "connected apps", never the underlying vendor name in any outreach.**

---

## 1. Voice & rules for every message (non-negotiable)

Brand voice (from `.agents/product-marketing.md`): **confident, candid, a little witty, pro-user, never salesy.** Radical honesty is the weapon, we literally publish where competitors beat us.

- **Write like a peer who noticed something**, not a vendor with a quota. Use contractions. Read it aloud; if it sounds like marketing copy, rewrite it.
- **Lead with their world.** "You/your" should dominate "I/we." Open on *their* video / post / newsletter / app, never on "My name is… and I work at…".
- **One ask, low-friction.** Offer a seed license or a 2-minute custom clip, never "hop on a 30-min call" in touch one.
- **The personalization must connect to the reason.** If you can delete the first line and the email still makes sense, the personalization is fake, don't send it.
- **Never demo an unconfirmed write.** The confirm step *is* the trust story. Keep it in every clip and every description.
- **No feature dumps.** One proof point beats ten features. The proof is the demo.
- **Never name the underlying connected-apps vendor.** Public names only: JARVIS, connected apps, on-device planning.

---

## 2. SEQUENCE A, Creators (dev / Mac / productivity)

**Goal:** a seed license accepted → an honest review / demo published. The leverage play of the whole GTM.

### Target profile (who to seed)
- Reviews Mac apps, dev tools, AI tools, or productivity/PKM workflows.
- Audience is **Mac power-users, developers (esp. Claude Code / Cursor), or "AI that does things" people.**
- Size sweet spot: **5k-150k** subs/followers (big enough to matter, small enough to reply and to genuinely try a tool). Micro-creators convert better than mega ones here.
- Has covered a competitor (Wispr Flow, Superwhisper, MacWhisper, Aqua) OR posts about Claude Code / agents / "Jarvis."
- **Disqualify:** pure Windows/Android channels, crypto-shill accounts, anyone who runs paid-only "reviews."

### Sourcing strings (build the list)
- **YouTube:** `Wispr Flow review`, `Superwhisper review`, `best Mac dictation app`, `Mac dictation 2026`, `voice to text Mac`, `Claude Code workflow`, `Cursor setup`, `AI tools for Mac`, `Jarvis for Mac`, `voice assistant Mac`. Filter "This year." Note channels that ranked a competitor.
- **X / Twitter:** `Wispr Flow alternative`, `"Superwhisper"`, `dictation Mac`, `"Jarvis for my Mac"`, `voice agent Mac`, `Claude Code` + `voice`, `from:` searches on known dev-tool reviewers. Sort Latest.
- **Newsletters / blogs:** `site:reddit.com/r/macapps dictation`, Google `"Mac dictation" newsletter`, `best Mac apps newsletter`, Indie Hackers, "macOS productivity" Substacks, Refind/TLDR-style dev digests.
- **Reddit/Lobsters scouts:** r/macapps, r/ClaudeAI, r/productivity power-posters who make content elsewhere.
- Capture: name, channel/handle, the specific video/post, contact (about-page email / X DM / newsletter reply), audience fit, last competitor covered.

### Seed-license offer mechanics (the deal)
1. **Free Verba Pro, no strings on the review.** Lifetime/Founder comp or 12-month Pro, give the tool free; honesty is required, a positive review is not. (Honesty *is* the brand, say so explicitly.)
2. **Affiliate % stacked on the built-in referral loop.** Verba already ships referral "Free Month" + `?ref` link capture → Stripe metadata (`gtm-strategy.md` §7). Give each creator a `?ref` link plus a **revenue share on conversions** so it pays beyond the one video.
3. **Done-for-them demo asset.** Offer a ready 60-sec speak-vs-type clip + the JARVIS clip they can drop in, removes the #1 reason a busy creator never gets to it.
4. **A real human follow-through:** a 15-min "show you JARVIS on your own apps" if they want it, never required.

### Subject lines (2-4 words, lowercase, internal-looking, `subject-lines.md`: 2-word = ~46% open, 60% more opens than 5-word; first names *lower* replies 12%)
- `your dictation video`, *contextual, references their content, looks like a viewer reply.*
- `verba for {{channel}}`, *specific, non-salesy, signals it's about their work not a blast.*
- `the jarvis clip`, *curiosity + concrete; works once you've name-dropped the demo.*

### First touch
```
Subject: your dictation video

Hey {{firstName}},

Watched {{their_video_or_post}}, your take on {{specific_detail}} was the
honest version nobody else gives.

I build Verba, a Mac dictation app, but the part I think your audience would
actually lose it over isn't the dictation, it's that it now *acts*. You say
"create the Linear issue for this bug and email the team a summary," it shows
you exactly what it'll do, you confirm, done. Across 1,000+ connected apps,
planned on-device by your own Claude Code sub. No key, $9.99, audio never
leaves the Mac.

Want a free Pro license to kick the tires? No ask for a review, if it's not
better than what you covered, say so on camera. I'll send a 30-sec "I said it,
it did it" clip so you can see it before you spend a minute.

, {{your_name}}
verba.run
```

### Follow-up 1, Day 3 (new value: hand them the asset)
```
Subject: the jarvis clip

{{firstName}}, the clip, in case it's easier to judge than my pitch:
{{demo_link}}

That's a real confirmed action on real tools, not a mockup. The "it asks
before it acts" pause is the whole point, that's the part people screenshot.

Pro license is yours whenever; takes 30 seconds, no card. Worth a look?
```

### Follow-up 2, Day 10 (social proof / momentum + the breakup)
```
Subject: last one on this

No worries if dictation-that-acts isn't your lane right now, {{firstName}}.

Quick context in case it changes the math: the category incumbent (Wispr Flow)
just raised at a $2B valuation, and it still only types and uploads your audio.
Verba runs on-device and *does* things. That gap is the story your audience
hasn't seen yet.

I'll leave it here. License + a `?ref` affiliate link are open if you ever want
them, replies pay you, not just clicks. Either way, genuinely good work on
{{their_video_or_post}}.
```

---

## 3. SEQUENCE B, Newsletter sponsorships

**Goal:** a paid (or comped-trial) placement in a newsletter our beachhead reads. Different from creators: this is a **media buy**, so the email is to the operator/ad-sales, and the value exchange is clear.

### Target profile
- Newsletters read by **Mac power-users, developers, Claude/AI builders, privacy-minded pros.** (dev digests, "best Mac apps," AI-tooling, indie-hacker, PKM/productivity.)
- 3k-100k subscribers; high open rate beats raw size for this niche.
- Runs sponsorships (has a "sponsor" / "advertise" page) **or** is small enough to do a one-off.

### Sourcing strings
- Google: `best Mac apps newsletter sponsor`, `developer newsletter advertise`, `AI tools newsletter sponsorship`, `Claude newsletter`, `macOS productivity Substack`. Check Sponsor/Media-Kit pages, Swapstack, Paved, beehiiv ad network.

### Subject lines
- `sponsor slot`, *internal, sounds like inbound interest, not a pitch.*
- `q3 sponsorship`, *concrete, businesslike, gets to ad-sales fast.*
- `{{newsletter_name}} fit`, *signals you read it and tailored this.*

### First touch
```
Subject: sponsor slot

Hi {{firstName}},

Your {{specific_issue_or_topic}} issue is exactly the reader I'm trying to
reach, Mac folks who'd rather talk than type and care where their data goes.

I run Verba (verba.run): on-device Mac dictation that reuses your Claude sub
with no API key, and a confirm-gated voice agent that can actually *do* things
across 1,000+ apps. $9.99, privacy-first, no audio ever uploaded.

Do you take sponsors? I'd want one slot with a short copy block + a 30-sec demo
GIF (the "say it → it does it" one, it tests well). Happy to start with a
single issue to see if your list converts before we talk about more.

What's your rate + next opening?

, {{your_name}}
```

### Follow-up 1, Day 4 (de-risk + offer the asset)
```
Subject: re: sponsor slot

{{firstName}}, two things to make this easy:

1. I'll write the copy in your newsletter's voice and hand you the demo GIF,
  zero production work on your end.
2. We can do a flat single-issue test, or a CPC/affiliate deal off a `?ref`
  link so you only win when readers convert. Your call.

Rate card and the nearest open slot when you have a sec?
```

### Follow-up 2, Day 12 (breakup, door open)
```
Subject: closing the loop

Totally understand if the calendar's full or it's not a fit, {{firstName}}.

If a slot opens later this quarter, I'd still love one test issue, the offer
(copy written for you + demo asset + affiliate option) stands. Either way I'm a
reader now. Thanks for {{newsletter_name}}.
```

---

## 4. SEQUENCE C, Partner / bundle (Setapp + indie-Mac bundles)

**Goal:** distribution + credibility through a curated Mac catalog or a flash/lifetime bundle. **The value exchange must be explicit**, these are deals, not favors.

### Targets & the value exchange
- **Setapp** (MacPaw), the subscription Mac-app catalog. *Their* value: a category-of-one voice agent + private dictation rounds out their AI/productivity shelf and gives subscribers something Wispr-class without leaving Setapp. *Our* value: distribution to a paying Mac audience already past the "trust an indie app" hurdle, and credibility-by-association. **Caveat (L2):** Setapp is all-you-can-eat subscription revenue-share, model the economics before committing; it's a distribution + brand play, not necessarily margin-accretive. Note it, don't pretend it's free money.
- **Indie-Mac bundles** (e.g. seasonal "Mac power-user" bundles, lifetime-deal marketplaces). Pairs naturally with the **Lifetime/Founder tier** the strategy recommends (`gtm-strategy.md` §6), bundles want a one-time SKU, and COGS≈0 makes a lifetime license unusually safe to give.

### Subject lines
- `verba x setapp`, *names the partnership, peer-to-peer.*
- `catalog fit`, *internal, BD-sounding.*
- `bundle idea`, *low-pressure, collaborative.*

### First touch (Setapp / catalog)
```
Subject: verba x setapp

Hi {{firstName}},

Setapp's AI/productivity shelf has the dictation base covered, but nobody on
it *acts* on what you say. That's the gap Verba fills.

Verba (verba.run) is a Mac voice app: on-device dictation that reuses the
user's own Claude sub (no markup), plus a confirm-gated voice agent that
creates the issue / sends the email / schedules the call across 1,000+ apps,
the user confirms every write. It's the "Jarvis for Mac" your subscribers keep
asking competitors for.

Is there a path to evaluate Verba for the catalog? I think it gives Setapp a
category-of-one feature against {{competitor_or_alternative}}, and gives us the
right Mac audience. Open to whatever evaluation/revenue-share structure you use.

, {{your_name}}
```

### First touch variant (indie / lifetime bundle)
```
Subject: bundle idea

Hey {{firstName}},

Saw {{their_bundle_or_post}}, your audience is dead-center for what I make.

Verba is a private-by-default Mac dictation app + confirm-gated voice agent
($9.99/mo normally). I'm spinning up a one-time Founder license, which makes it
a clean fit for a bundle. You'd be offering the only dictation tool that also
*does* things, a genuine headline SKU, not filler.

Want a free license to try it first, then talk terms (rev-share or flat)?
```

### Follow-up 1, Day 5 (proof + lower the bar)
```
Subject: re: {{prior_subject}}

{{firstName}}, to make the eval trivial, here's the 30-sec demo of the agent
running real confirmed actions: {{demo_link}}.

Quick differentiators for your catalog notes: on-device (audio never uploaded),
BYO-Claude (no key), 1,000+ connected apps, $9.99. The /compare matrix on our
site lists honestly where rivals still win, happy to share it so your team can
vet the claims.

What's the next step on your side?
```

### Follow-up 2, Day 14 (breakup, keep the relationship)
```
Subject: parking this

No problem if the timing or the model isn't right, {{firstName}}.

I'll check back when the Founder tier is live, that may make the bundle math
cleaner. Door's open on our end anytime; appreciate you taking a look.
```

---

## 5. SEQUENCE D, Podcast / founder-story pitch

**Goal:** a guest spot or a founder-story feature. The narrative *is* the product to this audience: **one founder, agentic-systems builder, privacy-first, shipping a confirm-gated agent** that runs on the user's own AI.

### Target profile
- Indie-hacker / bootstrapper / dev-tool / "building in public" / AI-builder podcasts.
- Hosts who feature solo founders, agentic AI, or privacy-tech stories.

### Sourcing strings
- `indie hacker podcast`, `bootstrapped founder podcast`, `AI agent podcast`, `dev tools podcast`, `building in public podcast`, `Mac developer podcast`, `solo founder interview`. Plus guests-of-guests on shows you already know.

### Subject lines
- `pod guest?`, *casual, peer, low-stakes.*
- `founder story`, *names the value you bring to their feed.*
- `confirm-gated agent`, *a hook that signals a real, specific topic, not a generic "I'd love to come on."*

### First touch
```
Subject: founder story

Hi {{firstName}},

{{specific_episode}} stuck with me, {{specific_detail}}. Feels like your
listeners would dig the story I'm living right now.

I'm a solo founder who built Verba (verba.run): a Mac voice agent where the
*action planning runs on the user's own AI, on their own machine*, never my
server key, and every write is confirm-gated. Building a "Jarvis for Mac" that
you'd actually trust with your Gmail and Linear, as one person, with privacy as
the constraint, has some opinionated lessons (agentic reliability, why I refuse
autonomy, BYO-AI economics with zero inference cost).

Would that make a good episode? I can come with concrete stories and a live
"say it → it does it" demo, not just talking points. No pitch, happy to make
it 100% about the building.

, {{your_name}}
```

### Follow-up 1, Day 5 (angles, make booking easy)
```
Subject: re: founder story

{{firstName}}, a few angles in case one fits your format:

• "Why I built an AI agent that refuses to act without asking" (trust/safety)
• "Bring-your-own-AI: a SaaS with zero inference costs" (economics)
• "Privacy as a product constraint, not a feature" (the on-device bet)

I'll record around your schedule and send a 30-sec demo clip ahead so you can
judge the visual. Worth a slot?
```

### Follow-up 2, Day 14 (breakup)
```
Subject: last nudge

All good if it's not a fit for the lineup, {{firstName}}.

If you ever do an episode on agentic AI or solo-founder building, I'd love to
be in the running, and either way I'll keep listening. Thanks for the show.
```

---

## 6. SEQUENCE E, Power-user / champion (light, reactive)

**Goal:** turn someone *publicly asking* for what we built into a delighted user (and often a public advocate). This is **reactive, one-to-one, and tiny-volume**, reply to a real post, never blast. Often a public reply > a DM, but a short DM/email works when they've shared contact.

### Where to find them (live searches, run weekly)
- X: `Wispr Flow alternative`, `"is there a Jarvis for Mac"`, `Superwhisper too expensive`, `dictation app that uploads`, `voice agent Mac`, `control my Mac by voice`.
- Reddit: r/macapps, r/ClaudeAI, r/productivity threads asking for recommendations; HN "Ask HN" + comments.

### Subject line (if email/DM)
- `you asked for this`, *direct, true, references their exact post.*
- `saw your post`, *human, honest, no pitch.*

### First touch (DM / reply tone)
```
Subject: you asked for this

{{firstName}}, saw your post asking for {{their_request}}. That's almost
exactly why Verba exists.

On-device Mac dictation, reuses your Claude sub (no key, no markup), and it can
actually *do* the thing you say, create the issue, send the email, after it
shows you and you confirm. $9.99, audio never leaves your Mac.

Here's a free Pro license, no strings: {{license_or_link}}. If it's not what you
wanted, tell me what's missing, I'm the founder and I read every reply.
```

### Follow-up (Day 5, only if they engaged but didn't redeem)
```
Subject: re: you asked for this

{{firstName}}, did the license land? If first-run tripped you up, the trick is:
have Claude Code installed → zero setup, no key. Or offline Parakeet for an
instant no-account start. Happy to walk you through JARVIS on your own apps if
useful, no pressure either way.
```
*(One follow-up max for champions. These are humans who already raised a hand; over-following-up sours goodwill. If silent, leave it.)*

---

## 7. Etiquette & anti-spam, why volume kills this niche

This is the most important section. **Volume-blasting doesn't just underperform here, it actively destroys the asset.**

- **Our audience is the hardest possible crowd to spam.** Developers, privacy professionals, and Mac power-users can smell a mail-merge from the subject line, and they have megaphones. A creator who feels mass-blasted can post the screenshot to 50k people. One careless blast can do more brand damage than 100 good emails do good.
- **Reputation is the product.** Verba's brand *is* radical honesty (we publish where competitors beat us). Spammy outreach contradicts the entire positioning. Every email must be congruent with "pro-user, never salesy."
- **The math favors quality, not quantity.** This is relationship outreach: 30 genuinely personalized emails to well-fit creators beat 3,000 templated ones. One creator who actually loves it is worth more than a thousand opens.
- **Personalize or don't send, the real test:** delete your first line. If the email still makes sense, the personalization is fake; rewrite it or skip the target. Every send must reference a *specific* video / post / issue / app / request.
- **Honor the breakup.** Two to three touches, then stop. No "just bumping this," no re-adding silent contacts to a new sequence. Loss-aversion works once; nagging poisons the well.
- **Lead with value, not the ask.** A free license, a done-for-them clip, a useful comparison, give before you ask. The seed-license model only works if the gift is real and the review is genuinely optional.
- **Cadence & timing** (from `follow-up-sequences.md`): Tue-Thu, 9-11am / 1-3pm local; increasing gaps between touches; ~55% of replies come from follow-ups, so the *second* email matters, but each must add new value.
- **Never fake it.** No `Re:`/`Fwd:` trick subjects, no false urgency, no invented social proof. We're early-stage with no testimonials yet, our proof is product depth + category momentum, and we say exactly that.
- **Channel-match the contact:** creators via their stated contact (about page / X DM / newsletter reply); never scrape personal addresses. Respect "no sponsors / no PR" pages.

---

## 8. Tracking table template

Keep one simple sheet. Columns: target, type, channel, the specific hook used, touch #, last-touch date, status, owner, notes. Status values: `sourced → first-touch → fu1 → fu2 → replied → in-progress → won → passed → dormant`.

| Target | Type | Channel | Hook (specific) | Touch | Last date | Status | Notes |
|---|---|---|---|---|---|---|---|
| {{name}} | creator | YouTube / email | "your Wispr Flow review" | fu1 | 2026-06-27 | first-touch | seeded license, sent JARVIS clip |
| {{newsletter}} | newsletter | email | "best-Mac-apps issue" |, |, | sourced | check sponsor page for rate |
| Setapp BD | partner | email | "catalog fit, voice-agent gap" | first-touch | 2026-06-27 | first-touch | model rev-share before terms |
| {{podcast}} | podcast | email | "confirm-gated agent story" | fu1 | 2026-06-27 | replied | offered 3 angles + demo |
| {{handle}} | champion | X DM | "asked for Jarvis for Mac" | first-touch | 2026-06-27 | won | redeemed license, posted publicly |

**Weekly ritual:** re-run the champion searches (§6), add 5-10 new sourced creators, advance every contact one step or mark dormant, and log which hook/demo earned replies, feed the winners back into the templates. Track creator-attributed installs via the `?ref` links so you know which seeds actually moved revenue, not just published.

---

## 9. Quality check before any send

- Does it sound like a human peer wrote it? (Read it aloud.)
- Would *you* reply to this?
- Is the first line specific to *this* target and connected to the reason you're writing?
- Is there exactly one low-friction ask (seed license / demo / slot), no 30-min call?
- One proof point (a demo), not a feature dump?
- Zero invented features, no iOS pitch, no underlying-vendor name, no salesy/urgency words?

If all six are yes, send. If any is no, fix it or don't send, in this niche, not sending is always safer than spamming.

---

**--- Resume :** Playbook d'outreach relationnel pour Verba, cadrage B2C honnête (pas de prospection B2B), 5 séquences prêtes à envoyer (créateurs, newsletters, partenaires/bundles, podcasts, power-users) avec objets + premier contact + 2 relances, chaînes de sourcing, mécanique de licence-seed + affiliation, et une section anti-spam : personnaliser ou ne pas envoyer.
