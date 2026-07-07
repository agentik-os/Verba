# Verba, Partnerships & Distribution Strategy

> Deliverable 5 of the Verba GTM package · Builds on `.agents/product-marketing.md` (positioning SSOT),
> `marketing/gtm-strategy.md` (§4 channels, §6 pricing, §7 loops), `marketing/market-research.md` (§5 pricing, §6 risks),
> `marketing/content-strategy.md`. Scope: **Verba only** (verba.run).
> Date: 2026-06-27 · Author: Oracle (OmegaOS) · Method: Dynamic-Workflow fan-out research (5 parallel agents, web search/fetch).

**What this document is.** The GTM strategy named three earned engines, comparison SEO, community/launch, creator demos, and
flagged two structural pricing facts (zero inference COGS; no lifetime tier today). This deliverable turns those into a concrete
**partnership and distribution plan**: for each lever, Setapp, bundles/lifetime-deal marketplaces, Mac-ecosystem integrations,
creator/affiliate, and the Mac App Store question, a **pursue / later / avoid** verdict, the *why*, the tradeoffs, named first
targets, a 90-day sequence, and the metrics to watch. It never contradicts the substrate; it extends it.

**The one idea that governs every verdict.** Verba's economics are unusual: **BYO-AI means ~zero inference COGS** (the user brings
their own key or reuses a Claude Code subscription, `.agents/product-marketing.md` §Business model), so a direct $9.99/mo sub keeps
~$8.30 net after Stripe at ~95% margin. That fact cuts two ways across this document:
1. It gives Verba **real room to share revenue** with creators/affiliates and to offer a **lifetime tier** without a margin trap,
  levers that are dangerous for COGS-heavy SaaS are safe here.
2. It makes any channel that **converts a ~$8.30 direct subscriber into a few cents of pooled royalty** (Setapp membership) or
  **forces a 15-30% platform tax** (Apple IAP) actively *hostile* to the model. Protect the direct relationship; rent reach only
  where it is genuinely incremental.

---

## 0. Methodology & honesty note (L2 / R-CITE / R-VERIFY)

- Research was run as a Dynamic Workflow: five parallel agents (one per lever) did live web search/fetch (June 2026) and returned
 facts with source URLs, then a planned adversarial 2-of-3 verification pass.
- **The verification pass did not complete**, every verifier hit a transient upstream rate-limit ("Server is temporarily limiting
 requests"), not a refutation. So the load-bearing facts below rest on **first-party source citations** (Setapp/MacPaw docs,
 Apple Developer guidelines, vendor pricing pages, competitors' own Dub partner pages) rather than on independent cross-checks.
- Where a figure is a **third-party estimate** (e.g. Setapp MAU/ARR, AppSumo's exact vendor split), it is marked **[estimate]**.
 First-party mechanics (revenue-split formulas, Apple guideline text, tool pricing) are marked **[first-party]**. Treat the
 estimates as directional and re-confirm before signing anything.
- No invented product features. Every Verba capability referenced traces to the product-marketing SSOT.

---

## 1. SETAPP, the Mac subscription bundle

**Verdict: LATER (and, if ever, via the single-app 85/15 track, not the membership pool).**

### What Setapp is
Setapp (by MacPaw, launched Jan 2017) is the largest Mac-app subscription *bundle*, a Spotify/Netflix model for Mac utilities.
End users pay a flat membership and get the whole curated library.

- End-user price: **Mac-only $9.99/mo, Mac+iOS $12.49/mo, 8-device $14.99/mo; annual saves up to ~40%.** [first-party], https://setapp.com/pricing
- Library: **260+ curated Mac/iOS/web apps** (mid-2025); reached 1M users by 2019. [first-party / Wikipedia], https://en.wikipedia.org/wiki/Setapp
- Reach: **110+ countries, 8 languages**, ~30,000 unique impressions for a new app in its first days, and Setapp claims to
 represent **~25% of worldwide Mac traffic**. [first-party], https://setapp.com/developers
- Scale: **~300,000+ monthly active users, 2M+ accounts, ~$40M ARR by 2024**, **[estimate]**, third-party (techlila), not
 MacPaw-published., https://www.techlila.com/setapp-subscriber-and-app-data-statistics/

### How developers are paid (the decisive part)
- **Membership pool:** Setapp distributes **70% of subscription revenue** across developers, split **by usage**, only apps a user
 actually *opened* in the billing period share that user's pool, weighted by a price-tier multiplier:
 `your share = 70% pool × (your tier multiplier / Σ tier multipliers of all apps the user used)`. [first-party],
 https://docs.setapp.com/docs/distributing-revenue
- **Partner referral bonus:** a developer who *brings* a user gets a guaranteed extra **20% of that user's fee**, so a Setapp
 Partner can earn **up to 90% of a referred user's fee**. [first-party], https://docs.setapp.com/docs/distributing-revenue
- **"Active" rule:** a single launch in the period counts the app as active and entitles it to a proportional share; payouts accrue
 daily, paid by the 7th of each month; membership tracks 24-month LTV. [first-party], https://docs.setapp.com/docs/application-statistics
- **New (2026): single-app purchases.** MacPaw added monthly/yearly/**lifetime** single-app options (no full membership required) at
 an **85/15 split** (developer keeps 85%), distinct from the 70% pool; 60+ apps participate. [first-party],
 https://www.prnewswire.com/news-releases/macpaw-launches-new-purchase-options-on-setapp-introducing-single-app-purchases-and-subscription-plans-302700175.html
- Apps may be sold on Setapp **and** elsewhere (own site / MAS) simultaneously; subscription apps' price tier is set by the **annual
 fee**. [first-party], https://docs.setapp.com/docs/faq

### Onboarding
Four steps: (1) reach out via setapp.com/developers, (2) submit for technical review, (3) integrate the Setapp SDK (Framework or
Vendor API, disabling your own licensing in that build), (4) earn. Setapp accepts mature, well-reputed native macOS + AI apps;
Electron is supported. Review cycle is fast (~24h). [first-party], https://setapp.com/developers

### Fit analysis for Verba
- **Reach (for):** exactly Verba's audience (Mac power-users who buy productivity utilities), zero CAC, built-in trust + billing +
 tax. The membership build can carry BYO-AI / Claude-Code-sub mode unchanged, **no inference COGS exposure to MacPaw**, and
 "private, on-device" is a selling point under review.
- **Economics (against):** membership pays a *usage-proportional slice of a 70% pool*, **not $0.70 of $9.99**. A user who opens 4-6
 apps splits that pool; a single-purpose dictation tool lands in a low price-tier with a small multiplier → realistic payout is a
 fraction of a dollar to ~$1-2/active-user/mo vs **~$8.30 net** Verba keeps on a direct sub. Setapp converts a ~95%-margin
 subscriber into a few-cents pooled royalty.
- **Cannibalization (against):** Verba's growth engine is the **referral "Free Month" loop + leaderboard** (GTM §7), which only runs
 on direct subscribers Verba controls (identity, billing, attribution). Setapp owns the customer, the loop **cannot run on Setapp
 users**, killing the primary viral lever for that cohort. Worse, a prospective direct buyer who already pays for Setapp will
 rationally drop the $9.99 direct sub and use Verba "free" inside the bundle, trading ~$8.30/mo for cents.
- **iOS angle is gone:** MacPaw sunset Setapp Mobile (EU iOS) on 2026-02-16, so there is no iOS-reach argument (Verba's iOS is
 scaffold-only anyway, `market-research.md` §6).

**Tradeoff summary.** Setapp is a *reach* channel that is economically *hostile* to a cheap, zero-COGS, referral-driven single
utility. The only Setapp path that preserves Verba's economics is the **2026 single-app 85/15 track** (~$8.49 of $9.99), but that
forgoes the bundle's "free to try" discovery advantage and still routes billing through MacPaw, weakening the referral loop.

**Recommendation: LATER.** Prove the direct GTM + referral loop first (GTM Phase 0-1). Revisit Setapp only as *incremental* top-of-
funnel once direct conversion is understood, and if entering, request the **single-app 85/15** track, not the membership pool. Apply
via setapp.com/developers; negotiate the tier off Verba's **$84/yr** annual fee; keep GitHub Releases + direct $9.99 as the primary
channel and the **only home of the referral/leaderboard loop.**

---

## 2. APP BUNDLES & LIFETIME-DEAL (LTD) MARKETPLACES

**Verdict: PURSUE a self-run capped Founder/Lifetime tier; LATER one curated indie/Black-Friday Mac bundle; AVOID AppSumo & deep-discount marketplaces.**

### The structural fact that gates everything
Every LTD marketplace (AppSumo, StackSocial, BundleHunt, MacHeist-style) sells **one-time redemption codes, not recurring
subscriptions**, so Verba's $9.99/mo plan is **not listable as-is**. A **~$149-199 Lifetime/Founder tier is the prerequisite**
that unlocks any of these (and is already recommended in GTM §6 and market-research §5). The classic LTD killer, "costs scale with
usage while revenue is permanently fixed", **does not apply to Verba**: a lifetime user costs ~$0 forever (they bring their own AI),
so a *capped* Founder LTD is a near-pure-margin acquisition + word-of-mouth play, not a margin trap., https://dodopayments.com/blogs/lifetime-deals-saas-pros-cons

### The marketplaces, with economics
- **AppSumo**, sells LTDs (one-time codes); free to list, revenue-share only on sales. Split is **negotiated case-by-case**;
 vendors widely report **~30% kept / ~70% to AppSumo** on buyers AppSumo brings (and ~95% on net-new buyers the vendor brings).
 [estimate, the exact rate card is undisclosed], https://appsumo.com/blog/appsumo-myths ·
 worked example ($30 code → $9 vendor gross): https://freemius.com/help/documentation/integrations/appsumo-lifetime-deals/ ·
 refund rates ~16-17%, deal-motivated non-ICP buyers, MRR cannibalization of warm leads, https://f3fundit.com/appsumo-lifetime-deals-worth-it-or-revenue-killer/
- **StackSocial / StackCommerce**, ~15-year-old LTD marketplace, software/courses/electronics at ~$9-$299 one-time; has paid
 $150M+ to publisher partners; vendor revenue-share % is **not public** (partner contact required); ~40% of LTD products don't
 survive 3 years. [estimate on terms], https://reseller.io/stacksocial-review/
- **BundleHunt**, buyers build a custom Mac-app bundle (apps from $1, up to ~95% off) sourced under **direct vendor contracts**
 with full licenses; runs affiliate/partner distribution. Genuinely Mac-native audience, tiny per-unit revenue. [first-party],
 https://bundlehunt.com/faq
- **MacHeist (historical caution)**, the famous 2006+ 10-app $49 bundle grossed ~$800k but devs got ~**$5,000 flat each (<3% of
 profit)** while MacHeist kept >70%; original incarnation offline after 2016. The cautionary tale on bundle economics.,
 https://en.wikipedia.org/wiki/MacHeist
- **Self-run LTD rails (best margin):** **Paddle** (~5% + $0.50, Merchant-of-Record, global tax, license keys),
 https://www.paddle.com/compare/gumroad · **Gumroad** (10% + $0.50, MoR, simplest), https://gumroad.com/pricing.
 Keep **~90-95%** of revenue, control the price anchor and the quantity cap, and feed the referral loop.

### Fit analysis & tradeoffs for Verba
- **Self-run Founder/Lifetime LTD ($149-199, on verba.run via Paddle/Gumroad):** best margin, full control of the anchor, caps
 scarcity, and crucially **keeps the customer + referral loop**. The downside is you supply your own traffic (no marketplace reach)
, but Verba's launch motion (Show HN, Product Hunt, creators, GTM §8) *is* the traffic, so the LTD becomes a **launch lever**
 exactly as GTM §6 intends. **Break-even** of a $179 lifetime vs $84/yr is ~2.1 years of an avoided annual sub, acceptable at
 near-zero marginal cost.
- **One curated indie / Black-Friday Mac bundle (LATER):** real Mac-native, privacy-conscious reach and direct vendor contracts, but
 $1-tier economics mean it's a **marketing/awareness spend, not a revenue line**, gate it to a limited window.
- **AVOID AppSumo & StackSocial deep-discount placement:** ~70% cut, ~16-17% refunds, deal-seeker churn, brand sitting next to
 clearance gadgets, and, most damaging, a **permanent cheap price anchor** that undercuts the $84/yr plan and the premium,
 privacy-first positioning. Worst fit for a high-margin recurring product.

**Recommendation:** **PURSUE** the capped self-run Founder/Lifetime tier (numbered cohort, e.g. first 500-1,000, routed through the
existing referral loop + leaderboard for viral lift). **LATER:** evaluate one curated indie/Black-Friday Mac bundle for a bounded
reach burst. **AVOID** AppSumo/StackSocial. The lifetime tier is the asset that makes bundles *possible*, build it first, then
decide whether any third-party bundle is worth the anchor risk.

---

## 3. MAC ECOSYSTEM INTEGRATION PARTNERSHIPS, which create *distribution*, not just features

The test here is strict: an integration earns a place only if it brings an **audience + a discovery surface**, not merely a feature.

### 3a. Raycast, **PURSUE (companion extension as a funnel)**
- **500,000+ active users** (2024), power users open it ~100×/day; **1,500+ extensions by 20,000+ developers**; $30M Series B.
 [estimate on user count; ecosystem figures third-party], https://www.techlila.com/raycast-company-growth-funding-and-market-share-statistics/ ·
 https://techcrunch.com/2024/09/25/raycast-raises-30m-to-bring-its-mac-productivity-app-to-windows-and-ios/
- **Publishing = free, via GitHub PR** (`npm run publish` → Raycast team reviews → auto-published to the Store), discoverable in-app
 and on the public web Store. [first-party], https://developers.raycast.com/basics/publish-an-extension · https://www.raycast.com/store
- **The catch:** Raycast ships its **own cloud dictation** (a paid Pro feature), so a Verba dictation extension overlaps Raycast's
 monetization, Verba's *private / on-device / BYO-key* model is the differentiator to lead with. Store guidelines don't explicitly
 forbid competing/wrapper extensions, but credentials must use the preferences API (not Keychain Access). [first-party],
 https://manual.raycast.com/ai/dictation · https://developers.raycast.com/basics/prepare-an-extension-for-store
- **Why it's a bullseye:** the audience is keyboard-driven, developer-heavy, Verba's exact ICP. An extension can only be a
 *companion* (start/stop dictation, insert last transcript, manage snippets/styles, open Verba), it can't replace the native
 always-listening menu-bar app, so treat it as **a funnel + credibility surface, not the product.**

### 3b. Alfred, **LATER**
Alfred Gallery is a curated one-click workflow source, but workflows are a **paid Powerpack-gated** feature with a smaller,
older power-user base, a marginal mirror of Raycast for similar build effort. Do it once Raycast is proven. [first-party],
https://alfred.app/frequently-asked-questions/ · https://www.alfredapp.com/powerpack/

### 3c. Indie-Mac earned-media / cross-promo network, **PURSUE (the real engine for a non-MAS DMG app)**
For an app distributed as a notarized DMG (no App Store discovery), the indie-Mac editorial/podcast/newsletter network *is* the
native top-of-funnel:
- **9to5Mac "Indie App Spotlight"** (recurring series), https://9to5mac.com/guides/indie-app-spotlight/
- **MacStories** (Federico Viticci / John Voorhees; review + automation/"App Defaults" angle), https://www.macstories.net/stories/the-world-of-indie-app-developers/
- **Indie Dev Monday** (weekly indie-Apple-dev newsletter), https://indiedevmonday.com/
- **Mac Power Users** (Relay FM; David Sparks / Stephen Hackett) podcast + MPU Talk forum
- **Indie Support Weeks** (John Sundell), a community cross-promo wave across sites/podcasts/YouTube/newsletters, https://github.com/JohnSundell/IndieSupportWeeks
Pro: highest-fit, durable, credibility-compounding earned media. Con: relationship-driven and slow, needs a genuine story + a
press kit (private-by-default, zero-COGS, reuse-your-Claude-sub, the JARVIS confirm-gated demo).
- *Note on the CleanShot X / CleanMyMac-class network:* those apps' primary cross-promo path **is Setapp's bundle** (CleanShot X is a
 Setapp app), i.e. the same revenue-share/pricing-conflict tradeoff as §1, not a free cross-promo., https://setapp.com/apps/cleanshot

### 3d. Claude Code / Anthropic / Cursor developer community + the connected-apps ecosystem, **PURSUE (the differentiated wedge)**
This is content/community distribution, not a store, but it maps 1:1 to Verba's category-of-one wedges and the beachhead:
- Lead with **"dictate into Claude Code and reuse your existing Claude subscription, no key, zero inference cost"** in r/ClaudeAI,
 the Anthropic Discord, the Claude Code community, and the Cursor forum/Discord. This is the one story no competitor (Wispr Flow,
 Superwhisper, Willow) can tell.
- The **connected-apps ecosystem** (the 1,000+ third-party apps JARVIS acts on) is a co-marketing surface: a "built with connected
 apps" showcase + the morning-by-voice demo travels into the much larger agent/productivity audience.
- **High-leverage technical move:** ship **Verba as an MCP server** so other agents can invoke Verba dictation, that flips Verba
 into the official MCP registry (registry.modelcontextprotocol.io, preview Sep 2025) as a real, discoverable server. The registry
 indexes *servers for AI clients*, not consumer apps, so it isn't a consumer storefront, but a Verba MCP server is a legitimate
 listing there and a developer-distribution wedge., https://registry.modelcontextprotocol.io/ · https://www.anthropic.com/news/model-context-protocol
- *Infra note (internal only):* the connected-apps layer is powered under the hood by Composio (integration infrastructure, a
 potential co-marketing/showcase partner, https://composio.dev/). **In all public copy this is "connected apps" / "JARVIS,"
 never the vendor name** (per `.agents/product-marketing.md` §Customer Language and content-strategy §8).
- **AVOID treating the MCP registry itself as a *consumer* distribution channel**, it's a feature + co-marketing relationship, not
 a place users find a dictation app.

**Section recommendation.** PURSUE Raycast (companion extension) + the indie-Mac earned-media network + the Claude/Cursor community
wedge, in parallel, now. LATER: Alfred. Sequence: Raycast extension + press kit first (fast, cheap, ICP-perfect), Claude-community
content in parallel, then Alfred as a follow-on once the first channel converts.

---

## 4. CREATOR / AFFILIATE DISTRIBUTION

**Verdict: PURSUE, the channel is proven for this exact category and Verba's margin can fund a top-of-market payout.**

### Why it's proven
Verba's two closest competitors **both run public affiliate programs on Dub**:
- **Wispr Flow:** 25% commission for 1 year, 30-day cookie (plus a referral program: referred friends get a 30-day Pro trial, the
 referrer a free month per successful referral). [first-party], https://partners.dub.co/flow
- **Superwhisper:** "Friends of Superwhisper" pays **30% on all payments in the first 12 months**. [first-party], https://partners.dub.co/superwhisper
- **Benchmark:** SaaS affiliate norm is ~20% recurring; **25-30% recurring is "strong"** and the 2026 market rate for mid-market
 tools, with sub-20% making recruitment hard., https://www.linkjolt.io/blog/recurring-commission-affiliate-programs

Because BYO-AI = zero inference COGS, Verba can pay a **top-of-market 30% recurring** and still keep a fat margin, a structural
advantage over COGS-heavy rivals.

### Tooling (Stripe-native, self-serve)
- **Dub Partners**, best-in-class Stripe attribution (recurring, trials, refunds, expansion, churn), payouts via Stripe
 Express/PayPal; **the de-facto category standard and what both direct competitors use.** [first-party], https://dub.co/help/article/dub-partners
- **Rewardful**, Stripe-only, simplest setup, fixed/%/recurring with configurable cookies; **$49-149+/mo, up to ~9% revenue fee at
 volume.** [first-party], https://www.rewardful.com/pricing
- **Tolt**, ~$49/mo, **0% transaction fee** (2% on automatic payouts), Stripe/Paddle/Chargebee, lowest-fee option. [first-party], https://tolt.com/pricing
- **FirstPromoter**, $99/mo, 0% fees, widest processor support. **PartnerStack**, a 131k-partner B2B network but **~$1,000/mo +
 3-15% of commissions**, overkill for a prosumer Mac app; only if an enterprise motion appears. [first-party],
 https://refgrow.com/compare-competitors/rewardful-vs-tolt-vs-firstpromoter · https://partnerstack.com/pricing
- **Distribution quirk that helps:** no App Store means **no Apple 15-30% cut to fight**, and every conversion flows
 link/promo-code → Stripe Checkout, giving clean **server-side attribution** that Dub/Rewardful handle cleanly.

### Program design, referral loop → 4-tier creator program
Verba already ships the bottom tier; the job is to layer a paid creator program on top (referral ≠ affiliate:
referral rewards customers for recommending people they know; affiliate pays third-party marketers, https://kickofflabs.com/blog/referral-program-vs-affiliate-program/):

- **Tier 0, Referral (exists; keep free, all users):** double-sided "Free Month" → referrer gets 1 free month per referred *paying*
 user, referee gets first month free/discount; leaderboard for status. The viral floor.
- **Tier 1, Creator Affiliate (new paid self-serve layer):** cash, **30% recurring for 12 months** (matches Superwhisper, beats
 Wispr), 30-90 day cookie, **payout fires on the referred customer's first paid charge** (abuse guard). On $9.99/mo ≈ $3/mo × 12 ≈
 **$36/customer**; on $84/yr, 30% ≈ **$25**. Auto-approve small creators.
- **Tier 2, Partner / Sponsored (hand-picked named creators):** flat sponsorship fee (mid-tier dev/AI creators command ~$3k-15k per
 integration; B2B-dev CPM ~$40-70 vs ~$15-35 consumer, https://kingy.ai/ai/the-ai-creator-sponsorship-index-2026/) **plus** a
 boosted commission (e.g. 40% recurring) **plus** a custom promo code that gives viewers an extended trial. Lead with the BYO-key /
 reuse-your-Claude-sub hook for dev creators, privacy-by-default for productivity creators.
- **Tier 3, Ambassador:** top leaderboard referrers **auto-graduate** from free-months into the cash affiliate tier (e.g. 10+
 active referred customers/quarter → a 5% bonus). Keeps power-referrers engaged.

### Named creator targets (the landscape)
- **Mac-dictation comparison writers already ranking for the exact query** (highest-intent, seed first): **Ryan Shrott** (Medium,
 "Best Mac Dictation Apps 2026"), https://medium.com/@ryanshrott/best-mac-dictation-apps-in-2026-dictaflow-wispr-flow-superwhisper-and-apple-dictation-compared-11911c671817 ·
 **jamesm.blog** · **afadingthought** (Substack) · **This Week in AI Club** (Substack).
- **Productivity reviewers:** **Keep Productive / Francesco D'Alessio** (YouTube), https://toolfinder.com/stacks/ali-abdaal ·
 **Ali Abdaal** · **Jeff Su** · **Tiago Forte / Building a Second Brain**.
- **Dev-tool creators (BYO-key / Claude Code angle):** **Theo / t3.gg** (already sponsored by Cursor/Warp/Convex) ·
 **Fireship / Jeff Delaney** · **ThePrimeagen**, https://clickstrike.com/blog/best-ai-youtube-channels/.
- **AI-tool reviewers:** **Matthew Berman** · **Matt Wolfe**.
- **Newsletters:** **Ben's Bites** (~120k) · **TLDR AI** (~1.1M) · **Code With Andrea** (Claude Code / agentic-dev).

**Tradeoffs.** Recurring % (category norm, aligns creators with retention) slows their payback vs a one-time bounty, but bounties
recruit poorly for a $9.99 product. Self-serve auto-approve risks coupon/incentivized-traffic abuse → gate cash behind the first
paid charge. Platform fee is the real cost (Tolt cheapest; Rewardful up to ~9%); Dub is the recommended default for competitor
parity + attribution quality.

**Recommendation: PURSUE now.** Phase 1 = keep the referral loop + stand up **Dub** self-serve at 30%/12mo, seeded by emailing the
dictation-comparison writers who already rank for the query. Phase 2 (later) = sponsored Tier-2 deals with named dev/AI YouTubers
once Tier-1 CAC/LTV is proven.

---

## 5. THE MAC APP STORE QUESTION

**Verdict: AVOID for the full app (now); LATER only as a deliberately-reduced discovery SKU.**

### Why the full app cannot pass MAS as built
Three of Verba's load-bearing capabilities are exactly what the **mandatory Mac App Store App Sandbox** forbids or makes
review-fragile (App Sandbox is mandatory for MAS, Guideline 2.4.5(i), https://developer.apple.com/app-store/review/guidelines/):
1. **Shelling out to the Claude Code CLI.** That binary is user-installed elsewhere on disk (npm/Homebrew), not bundled in
  Verba.app, and not signed to inherit Verba's sandbox. A sandboxed app may only spawn a child it **embeds** and that carries
  **exactly** `app-sandbox` + `inherit`, any other entitlement aborts the child. An arbitrary external CLI invocation is blocked.
  [first-party], https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html
2. **Driving local Ollama / Parakeet.** Ollama runs as a separate user-installed daemon, same external-process problem plus
  network/file entitlements the sandbox restricts. (In-bundle Parakeet *could* be sandbox-safe; the Ollama hand-off cannot.)
3. **Cross-app AppleScript / Shortcuts automation.** Sending Apple events to arbitrary apps needs scripting-targets entitlements or
  apple-events **temporary exceptions**; requesting those for Finder/System Events "will likely result in App Review rejection," and
  temporary exceptions are explicitly disfavored. [first-party], https://developer.apple.com/library/archive/qa/qa1888/_index.html ·
  https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html

### Plus: the billing tax destroys the margin thesis
**Guideline 3.1.1** requires **in-app purchase** to unlock features/subscriptions, own mechanisms (Stripe, license keys) are not
allowed for the digital unlock, handing Apple **15% (Small Business Program, <$1M) to 30%**. [first-party],
https://developer.apple.com/app-store/review/guidelines/ · https://developer.apple.com/app-store/small-business-program/.
That breaks the entire BYO-AI/zero-COGS economics, and the post-2025 US external-link entitlement permits *linking out* but does
**not** exempt a subscription-unlock app from 3.1.1, so it doesn't rescue Stripe on MAS. Auto-renewable subs must also be ≥7 days
and available across all the user's devices, https://developer.apple.com/app-store/subscriptions/.

### What DMG-only keeps vs loses
- **Keeps:** full capability (CLI shell-out, local-model subprocesses, cross-app automation), Stripe (~2-3% vs 15-30%), instant
 releases (no 5+ day review), the BYO/reuse-Claude-sub pitch, full referral/leaderboard control.
- **Loses:** MAS storefront discovery and the buyers who never leave the Store. (Context: **~66% of US Mac users download outside the
 MAS**; ~93.5% of MAS apps are sandboxed vs ~10.9% of third-party apps; >70% of dev-focused macOS apps ship via DMG. [estimate],
 https://www.techlila.com/mac-app-store-vs-direct-downloads-dmg/) Apple **requires notarization either way** and explicitly
 recommends direct distribution for "tools / power-user apps", https://developer.apple.com/macos/distribution/.

### Precedents
- **MacWhisper** ships a dual pattern: full **direct/Gumroad** build + a separate reduced **"Whisper Transcription" SKU on MAS**,
 https://macwhisper.helpscoutdocs.com/article/40-macwhisper-whisper-transcription-difference
- **Superwhisper** is on MAS **and** Homebrew cask, https://superwhisper.com/download
- **Wispr Flow** sells its subscription **directly via its website**, https://wisprflow.ai/comparison/superwhisper-alternative
- **AirBuddy** is cited as un-sandboxable / MAS-impossible, capability-heavy Mac apps go DMG-only, https://www.rambo.codes/posts/2021-01-08-distributing-mac-apps-outside-the-app-store

**Recommendation.** **Stay notarized-DMG-only** as the product's real home (as today). Treat MAS as a **LATER, optional discovery
SKU** *only if* a genuinely useful sandbox-safe subset exists, i.e. the MacWhisper pattern: a stripped MAS build doing only
**in-bundle on-device dictation (Parakeet), no CLI shell-out, no external Ollama, no arbitrary cross-app automation, IAP billing.**
Build that only if the crippled subset is useful as a funnel; otherwise MAS is pure cost. Do **not** port the flagship.

---

## 6. Prioritized partner target list (named first targets per lever)

| Priority | Lever | First targets (named) | Verdict |
|---|---|---|---|
| **1** | Creator/affiliate | Stand up **Dub** at 30%/12mo; seed **Ryan Shrott, jamesm.blog, afadingthought, This Week in AI Club** (rank for the query today) | **Pursue now** |
| **2** | Mac integrations, community wedge | **r/ClaudeAI, Anthropic Discord, Claude Code community, Cursor forum** ("reuse your Claude sub, no key") | **Pursue now** |
| **3** | Mac integrations, Raycast | Ship a **Verba companion extension** (start/stop, insert transcript, snippets/styles); position private/on-device vs Raycast's cloud dictation | **Pursue now** |
| **4** | Mac integrations, earned media | **9to5Mac Indie App Spotlight, MacStories (Viticci/Voorhees), Indie Dev Monday, Mac Power Users + MPU Talk, Indie Support Weeks** | **Pursue now** |
| **5** | Bundles, self-run | **Founder/Lifetime tier $149-199** (capped cohort) via **Paddle/Gumroad**, wired to the referral loop | **Pursue (build first)** |
| **6** | Mac integrations, MCP | Ship **Verba as an MCP server** (registry listing) + a "built with connected apps" showcase | **Pursue (technical)** |
| **7** | Creator/affiliate, sponsored | Tier-2 named YouTubers: **Theo/t3.gg, Keep Productive, Matthew Berman, Matt Wolfe**; newsletters **Ben's Bites, TLDR AI, Code With Andrea** | **Later (after Tier-1 proven)** |
| **8** | Bundles, curated | **One** indie/Black-Friday Mac bundle (**BundleHunt**-style), bounded window | **Later** |
| **9** | Mac integrations, Alfred | Alfred Gallery workflow (mirror of the Raycast extension) | **Later** |
| **10** | Setapp | **Single-app 85/15 track** via setapp.com/developers (never the membership pool) | **Later (experiment only)** |
| **11** | Mac App Store | Reduced sandbox-safe discovery SKU (MacWhisper pattern), only if useful | **Later / conditional** |
| **, ** | Bundles, AppSumo/StackSocial | Deep-discount LTD marketplaces | **Avoid** |
| **, ** | MCP registry as consumer store | Treating registry/connected-apps infra as a consumer storefront | **Avoid** |

---

## 7. 90-day partnerships action sequence

Mapped to GTM phases (Phase 0 weeks 0-4, Phase 1 months 1-4). Partnerships are **earned-first**; spend nothing on paid placement
until direct conversion is proven.

**Days 1-30, Foundation (cheap, ICP-perfect, owned).**
- Build the **press kit** (private-by-default, zero-COGS, reuse-your-Claude-sub, the confirm-gated JARVIS demo clip), it feeds every
 channel below.
- Stand up the **Dub** self-serve affiliate at **30%/12mo**, first-paid-charge payout trigger; wire it to Stripe.
- **Seed the comparison writers** who already rank: Ryan Shrott, jamesm.blog, afadingthought, This Week in AI Club, offer affiliate
 + a seeded license + the demo.
- Start the **Claude/Cursor community wedge**: post the demo + "reuse your Claude sub, no key" in r/ClaudeAI, Anthropic Discord,
 Cursor forum (lead with the demo, never a pitch, content-strategy §6).
- Scope the **Raycast companion extension** (start/stop dictation, insert last transcript, manage snippets/styles).

**Days 31-60, Surfaces live.**
- **Ship the Raycast extension** (GitHub-PR publish); position private/on-device/BYO vs Raycast's own cloud dictation.
- **Pitch the indie-Mac earned media**: 9to5Mac Indie App Spotlight, MacStories, Indie Dev Monday submission, an MPU Talk forum
 thread; watch for the next Indie Support Weeks wave.
- **Build & launch the Founder/Lifetime tier ($149-199, capped cohort)** on verba.run via Paddle/Gumroad, time it to the Show
 HN / building-in-public moment (GTM §8) so the launch *is* the traffic.
- Ship **Verba as an MCP server** + a "built with connected apps" showcase post.

**Days 61-90, Compound & graduate.**
- **Graduate top referrers** (Tier 0 → Tier 1 cash) and recruit the **first 2-3 Tier-2 sponsored creators** (Theo/t3.gg, Keep
 Productive, an AI-tools channel) once Tier-1 CAC/LTV reads positive.
- Decide on **one** curated indie/Black-Friday Mac bundle for a bounded reach burst (only if it won't anchor price below $84/yr).
- **Apply to Setapp's single-app 85/15 track** as a bounded experiment *only if* direct conversion + the referral loop are healthy.
- Defer Alfred and the MAS discovery SKU to the next quarter; revisit against the metrics below.

---

## 8. Metrics to track (per lever)

Anchor to the GTM north star (**Weekly Active Dictators**) and revenue, not vanity. Per-lever leading indicators:

- **Creator/affiliate:** affiliate-attributed installs & paid conversions; **CAC per channel vs blended LTV**; recurring-commission
 payout as a % of affiliate-driven MRR (guardrail: keep total payout < the margin headroom); Tier-1 → Tier-2 graduation rate;
 refund/chargeback rate on affiliate traffic (abuse signal).
- **Mac integrations:** Raycast extension installs → app downloads (funnel conversion); community-attributed installs (UTM/promo per
 community); earned-media placements landed and referral traffic each drives; MCP-server invocations (a dev-distribution signal).
- **Bundles / Lifetime:** Founder-tier units sold vs cap; **lifetime-buyer activation & referral rate** (do they feed the loop?);
 cannibalization check, % of lifetime buyers who would otherwise have taken $84/yr; bundle-window installs → trial → paid.
- **Setapp (if run):** Setapp-attributed activations; **realized payout per active user** (validate it's not pennies before scaling);
 measured cannibalization of direct subs.
- **App Store (if a SKU ships):** MAS installs → upgrade/cross-sell to the full DMG app; MAS-only churn; net of the 15-30% IAP tax.
- **Guardrail (all levers):** gross margin stays very high (BYOK = zero inference COGS), never let a partner deal introduce billed
 inference or a price anchor that drags the $84/yr plan.

---

## 9. Bottom line

Verba's zero-COGS, referral-driven, direct-DMG model rewards **earned and revenue-shared distribution** and punishes
**bundle-pooled and platform-taxed** distribution. So the plan is asymmetric on purpose:

- **Pursue now, cheap and on-brand:** a creator affiliate program (the channel both competitors already prove), the
 Claude/Cursor community wedge (the one story no rival can tell), a Raycast companion extension, and the indie-Mac earned-media
 network, plus a self-run capped **Founder/Lifetime tier** as the launch lever that the GTM strategy already called for.
- **Later / conditional:** Setapp (single-app 85/15 only), one curated Mac bundle, Alfred, an MCP-server listing, and a reduced
 MAS discovery SKU, each a bounded experiment, none a foundation.
- **Avoid:** AppSumo/StackSocial deep-discount LTDs (cut + refunds + a permanent cheap anchor), the Setapp *membership pool*
 (margin destruction + kills the referral loop), and porting the flagship to the Mac App Store (sandbox-incompatible + IAP tax).

Protect the direct relationship; rent reach only where it is genuinely incremental and doesn't tax the margin or cheapen the brand.

---

*Sources are cited inline as URLs. Load-bearing external facts rest on first-party documentation (Setapp/MacPaw, Apple Developer,
Dub partner pages, vendor pricing); figures marked [estimate] are third-party and should be re-confirmed before contracting. The
adversarial 2-of-3 verification pass did not complete (transient upstream rate-limiting, not refutation), see §0.*
