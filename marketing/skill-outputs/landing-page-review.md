Landing Page Review: https://verba.run
Method: WebFetch of the live site (2026-07-07) + raw curl of the live HTML + the Playwright snapshot at /home/vibe/.claude/jobs/425d3555/tmp/verba-site/index.html, cross-checked against each other. Every quote below is verbatim from one of these sources.

Conversion Score: 52/100

---

## Messaging: 20/30

- **Headline (7/10)**, "Speak it. Send it clean." (h1, hero). Tight and stylish, but it is a tagline, not a claim: it names no category and no outcome on its own. It only resolves into a real value prop once the reader also sees the "For macOS · Apple Silicon" eyebrow pill above it and the subhead below it. A cold visitor scanning the very first line alone does not yet know this is a voice-dictation app. Works as a brand line, underperforms as the thing that has to do the convincing in the first 3 seconds.

- **Value prop specificity (7/10)**, The subhead is genuinely specific and differentiated: "The private voice app for your Mac that doesn't just write what you say, it does it. Dictate clean text into any app, reuse the Claude Code subscription you already pay for (no API key), and let JARVIS act across 1,000+ apps. Every step is planned on-device, and nothing happens until you confirm." That is four concrete claims in one paragraph (private, acts not just transcribes, no extra AI bill if you already have Claude Code, 1,000+ app actions, on-device planning, confirm-before-act). Strong for a technical buyer. Two problems: (1) it front-loads a claim ("reuse the Claude Code subscription... no API key") that only lands for people who already know what Claude Code is, a large share of Verba's own stated audience (per this repo's product-marketing.md), but a claim that means nothing to a generalist Mac user hitting this page from an ad or a "best dictation app" search; (2) the 150 wpm vs 40 wpm speaking/typing stat lower on the page ("Speaking is roughly 3x faster than typing") is a real, sourced-sounding number but has no citation on the page itself, which slightly undercuts an otherwise numbers-forward page.

- **CTA strength (6/10)**, "Download for free" (hero, `btn-primary`, links straight to `https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg`) is action-oriented and visible above the fold, and it is reinforced by "Download free" and "no card, ever" language on the Free pricing card. But: the CTA sends a visitor straight to a raw `.dmg` binary hosted on GitHub Releases with zero intermediate reassurance (no "your download will start in a browser tab", no notarization/safety note, no App Store alternative). For a non-technical visitor arriving from a Reddit or TikTok ad, "click and a mystery file downloads from GitHub" is a real trust wobble at the exact moment of highest intent. The paid CTAs are worse: "Sign in to start trial" (Pro, $84/yr) and "Sign in for lifetime" (Founder's Edition, $149 one-time) both force account creation before the visitor sees a checkout or even confirms the price a second time, that's an extra gate competitors don't all have.

## Trust: 8/30

- **Social proof (0/10)**, There is no testimonial, review, star rating, customer quote, press mention, or user/download count anywhere on the page. Confirmed by direct text search of both the raw HTML (`grep -c testimonial` → 0 matches) and an independent WebFetch pass, which returned: "No customer testimonials, reviews, ratings, press logos, or user counts appear on the page." This is the single largest gap on the page. For comparison, I pulled the two competitor pages verba.run itself links to and names (`/vs/wispr-flow`, and Superwhisper which is the other Mac-dictation incumbent):
  - **Wispr Flow** (wisprflow.ai): nine named user testimonials on the homepage, including "This is the best AI product I've used since ChatGPT.", Rahul Vohra, CEO, plus 20+ recognizable company logos (Notion, Vercel, Nvidia, Amazon...).
  - **Superwhisper** (superwhisper.com): named testimonials from Andrej Karpathy, Guillermo Rauch (Vercel CEO), Pieter Levels, and Andrew Wilkinson, plus logos (Vercel, Shopify, Meta, OpenAI), plus the line "Hundreds of thousands rely on Superwhisper to save time."
  Verba is shipping into a category where both direct competitors lead with third-party credibility, and Verba currently shows none at all.

- **Credibility signals (5/10)**, What does exist: the page ships correct `SoftwareApplication` + `FAQPage` schema.org markup (good for rich snippets), the download links straight to a public GitHub Releases page (verifiable, dev-audience-friendly), and Clerk-based sign-in is a recognizable, credible auth provider even though it isn't named on-page. What's missing: no visible founder story or "built by" line on the page itself (the founder's name, Gareth Simono, exists only in the invisible JSON-LD, never in visible copy), no security/privacy badge, no App Store listing (Mac apps distributed only as a sideloaded DMG read as higher-risk to a mainstream buyer than an App Store listing), and the community links in the footer (Telegram, Reddit, X, TikTok, Instagram, YouTube, Pinterest) are all icon-only text links with no follower counts or activity signal, so they read as unproven rather than as proof of an active community.

- **Transparency (7/10)**, Pricing is fully transparent and shown with no "contact sales" gate: Free ($0), Pro ($84/yr ≈ $7/mo, "7-day trial, card required"), Founder's Edition ($149 one-time, "Sign in for lifetime"). Refund/trial terms exist ("Does Verba have a free trial or refund?" is a real FAQ entry) but they are buried inside a collapsed FAQ accordion rather than surfaced as a line directly under the Pro/Founder buy buttons, which is where a hesitating buyer is actually looking. One further transparency flag: the Founder's Edition card reads "Limited Founder's release" directly under a $149 lifetime price with no quantity, no deadline, and no counter, an unsubstantiated scarcity claim that a skeptical buyer (exactly the audience a developer-tooling product attracts) is likely to discount or actively distrust.

## UX: 13/20

- **Form/CTA friction (7/10)**, There is no lead-gen form on the page (this is a direct-download + sign-in-gated-purchase model, so classic form-field friction doesn't apply). The real friction is structural: both paid tiers require "Sign in" before the visitor can see a checkout screen or enter payment details, which is one extra forced step most competitor pricing pages don't insert before showing a card form.

- **Mobile (4/10)**, The primary nav ("Features", "Resources", "Pricing" including the `/#pricing` anchor link) lives inside `<div class="hidden items-center gap-7 ... md:flex">`, which is hidden below the `md` breakpoint. I searched the full rendered HTML (both the snapshot and a fresh curl of the live page) for any mobile menu trigger, `md:hidden`, `aria-label="Menu"`, a hamburger icon button, any mobile nav panel, and found none. On mobile, the sticky nav bar exposes only the logo and the "Download" button; "Features", "Resources", and the direct jump-to-"Pricing" link are not reachable from navigation at all on a phone. A mobile visitor can still scroll to reach pricing, but they lose wayfinding to the feature sub-pages (JARVIS, Modes, Voice Notes, Voice Tasks, Live Translation, Context mode) and to `/compare`, `/changelog`, and the community link entirely unless they scroll all the way to the footer.

- **Load speed (not measured, 2/10 placeholder, do not treat as a real score)**, No Lighthouse/WebPageTest run was performed as part of this review; I'm flagging this explicitly rather than inventing a number. Recommend running a real Core Web Vitals pass (there's a `cwv-audit` skill in this environment for that) before trusting any load-speed score here.

## Differentiation: 11/20

- **vs Wispr Flow (5/10)**, Verba already runs its own comparison page (`/vs/wispr-flow`, linked from the "Resources" dropdown as "Compare, Verba vs every Mac dictation app"), which is the right CRO move (capturing "X vs Y" search intent and pre-empting the comparison a prospect will make anyway). Verba's real differentiation vs Flow is the JARVIS action layer and the on-device/local-model privacy angle; Flow's is broader platform reach (Mac, Windows, iPhone, Android, vs Verba's Mac-only) and, per the point above, much heavier social proof and a funding-based trust signal ("$81M funding to build the Voice OS").

- **vs Superwhisper (6/10)**, Superwhisper's page leans on enterprise credibility (SOC 2 mention, a 30-day refund guarantee stated plainly on the pricing page, an Enterprise tier with "Contact us") stacked on top of the same named-testimonial wall described above. Verba's Founder's Edition ($149 lifetime) is a legitimately distinct pricing lever Superwhisper doesn't obviously mirror in the same way, but it needs the scarcity/urgency claim backed by a real number to land as a lever rather than a suspicion.

---

## Top 5 Changes (priority order)

1. **Add real social proof above the fold or directly below the hero.** This is the largest, single highest-leverage gap: 0 testimonials/logos/counts on Verba vs 9 testimonials + 20 logos on Wispr Flow and 4 named testimonials + 6 logos on Superwhisper. Verba has a live Telegram community (`t.me/verbarun`) and a Reddit presence (`u/VerbaRun`) already linked in the footer, pull 3 to 5 real quotes from those real users (with permission) rather than inventing any. Do not fabricate a quote or a user count; if no quotable testimonial exists yet, ship a smaller trust line instead ("Built in public. Every release, shipped and documented." linking to `/changelog`) until real quotes exist.

2. **Fix mobile navigation.** Add a hamburger/menu trigger that exposes Features, Resources (Docs, Compare, Best Mac dictation app, Changelog, Community), and Pricing on small screens, currently these are only reachable on desktop widths (`md:flex`), with zero fallback found in the rendered HTML.

3. **Surface trial/refund terms next to the buy button, not just in the FAQ.** Add a one-line trust reassurance directly under the Pro and Founder's Edition CTAs (e.g. the real terms already stated in the FAQ under "Does Verba have a free trial or refund?"), since that's the exact moment a hesitating buyer is looking for reassurance, not three FAQ items down.

4. **Either back the "Limited Founder's release" claim with a real number/deadline, or remove the word "Limited."** As written it's an unverifiable scarcity claim sitting next to a $149 one-time charge, aimed at a technically literate audience likely to discount it. State a real seat count or end date if one exists; otherwise drop to a neutral "Founder's Edition, pay once" framing.

5. **Add a one-line safety/trust note next to the primary "Download for free" CTA**, since it currently sends every visitor straight to a raw `.dmg` from GitHub Releases with no reassurance in view (e.g. confirm whether the build is Apple-notarized and, if so, say so in plain language, do not add this claim without first verifying it is true).

---

## Note on hard-rule compliance for any NEW copy (not a request to alter the live site without a decision)

The current homepage repeatedly names underlying tech in ways that would violate this project's marketing hard rules if reused in organic/paid copy: the meta description and hero subhead say "reuse your Claude Code plan/subscription... no API key," the FAQ explicitly names "Whisper," "Parakeet," "Anthropic," "OpenRouter," and "Ollama," and the hero product demo widget displays a live "Sonnet 4.6" model badge. That is very likely deliberate and fine *on the site itself*, where the primary stated audience (Claude Code-native developers) actively wants and trusts that specificity, removing it would cut a real acquisition hook for that ICP, and I want to flag that trade-off rather than silently recommend erasing it.

For any new social/ad copy that must follow the hard rules (never name underlying tech, never say "reuse your AI/bring your own/pay twice", never say "cloud," always keep "JARVIS," zero em/en dash), here is a compliant rewrite of the hero subhead that keeps the same four claims without the banned phrasing:

> Original (site, not compliant for social/ad use): "The private voice app for your Mac that doesn't just write what you say, it does it. Dictate clean text into any app, reuse the Claude Code subscription you already pay for (no API key), and let JARVIS act across 1,000+ apps. Every step is planned on-device, and nothing happens until you confirm."

> Compliant rewrite for social/ad copy: "The private voice app for your Mac that doesn't just write what you say, it acts on it. Dictate clean text into any app, then let JARVIS act across 1,000+ connected apps. Every step is planned on your Mac, and nothing happens until you confirm."

This drops the tech-naming clause entirely rather than trying to paraphrase it, since the rule bans the underlying concept ("reuse your AI subscription, no key"), not just specific words. Recommend keeping the fuller, tech-specific version on the site for the Claude Code-native audience, and using the generic version above for any social, ad, or email copy this review's rules apply to.
