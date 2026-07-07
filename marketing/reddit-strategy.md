# Verba on Reddit: Maximum Reach, Zero Ban

**Account:** u/VerbaRun (brand, connected via publisher) · **Product:** verba.run, a paid macOS dictation + voice-agent app that types AND acts on what you say (on-device, private, bring-your-own-Claude) · **Beachhead:** Claude Code / Cursor developers on Mac, plus Mac power-users and privacy-conscious pros · **Date:** 2026-07-03

> **Method caveat (R-CITE honesty):** Reddit blocks automated fetching of its raw rules widget from datacenter IPs (403 on every route). Findings below come from live sub feeds read through a Redlib mirror in a real browser (safereddit.com, captured 2026-07-03), third-party rule databases, GummySearch member counts, and 2026 policy guides. Every claim carries a source URL. Where verbatim sidebar text was not retrievable it is flagged and the recommendation leans on observed operational reality (what mods pin, what posts survive). **Before the first post in any strict sub (r/programming, r/apple, r/macOS, r/cursor, r/LocalLLaMA), open its live `about/rules` from a logged-in browser to confirm.**

---

## 1. Subreddit intelligence table

| Subreddit | Members (2026) | Self-promo rule | Link posts? | Best post type for Verba | Safe cadence | Fit |
|---|---|---|---|---|---|---|
| **r/vibecoding** | ~301k | Most tolerant of the set. "I built X" show-and-tell with a download link is the native format; a paid on-device macOS app (Shacam) hit 130+ upvotes. Flairs loose. Still respect ~9:1. | Yes, outbound product links accepted + upvoted | Show-and-tell launch with demo | 1 show / 1-2 wks | **Best** |
| **r/ChatGPTCoding** | ~388k | Most promo-tolerant "serious" coding sub. "Project"-flaired posts with direct commercial links survive. Rules nominally point promo to a thread, but standalone Project posts succeed. | Yes | "Project" launch OR "Discussion" value post | 1 promo / ~2 wks | High |
| **r/SideProject** | ~180k | Self-promo encouraged, it is the sub's purpose. No 9:1 enforcement, but a bare link is spam: must tell the build story. | Yes, expected (link the live product) | [Launch] build-in-public journey | 1 / 3-4 wks | High |
| **r/ClaudeAI** | ~986k | Pinned "Built with Claude" Showcase Megathread + matching flair = the sanctioned promo channel. Heavy AI-driven moderation; no hard launch/link posts. | Yes, but text/self posts win | Value/workflow post + drop in Showcase Megathread | 1 promo touch / 2-3 wks | High reach |
| **r/macapps** | ~236k | Infrequent self-promo: **max once per dev / 30 days** (once per app/30d for flaired established devs). Must disclose. **10 karma** before promoting in comments. Trust & Transparency Initiative (updated 2026-06-17): unqualified devs limited to the monthly megathread. Dev flair required (Lifetime > Subscription > Free). | Yes, but download link must point to official source (verba.run or Mac App Store), no shorteners/affiliates/redirects | Flaired "I built" show-and-tell self-post | 1 / 30 days | High |
| **r/cursor** | ~144k | Cursor-team-run, ~11 posted rules. **Self-promo capped at 10% of activity** (explicit). No duplicate posts/surveys. **Misinformation rule**: mods remove inaccurate claims about pricing/performance/competitors, so never bash Cursor. Flair required. | Yes | Value/workflow post ("hands-free prompting in Cursor on Mac") | 1 value / few wks | Medium-high |
| **r/LocalLLaMA** | ~766k | Open-weights/local-first culture, hostile to closed paid cloud promo. Self-promo ~10%, direct non-clickbait links only. A "60-day cooldown / Share Your Startup megathread" claim circulating online is **fabricated**, do not rely on it. | Yes (open repo/model links are the norm) | Technical on-device/private post only, no paid launch | 1 / month IF genuine local hook | Weak |
| **r/Anthropic** | ~174k | No showcase thread; discussion/complaint-heavy. Low tolerance for hard product pushes. | Yes | Value/discussion tied to Claude usage | 1 / month | Low |
| **r/macOS** | ~1.1M | Promo-hostile, discussion-first. Pure "check out my app" link drops removed. *(Exact rule LOWER CONFIDENCE, confirm live.)* | Technically yes, but risky; text post safer | Value/discussion self-post, disclose you built it | 1 / 1-2 months | Value-only |
| **r/MacOSApps** | ~21k | Welcoming; purpose is sharing free/cheap/Lifetime macOS apps. Light moderation. Disclose + flair (Dev Tools / Productivity). | Yes | Show-and-tell self-post or flaired link | 1 / 30 days | Easy win |
| **r/nativemacapps** | ~1k | Tiny, discovery sub for 100% native apps (no Electron). Perfect ICP **if Verba is genuinely native (Swift/AppKit/SwiftUI)**. Low ban risk. *(Rule LOWER CONFIDENCE.)* | Yes (assumed) | Native-app showcase | Once, then on new versions | Niche-perfect |
| **r/apple** | ~3.2M+ | **Self-promotion Sundays only**, developers only, must be a **self/text post** (not a link), 10% rule, requires **5+ non-promo contributions in the past month** first. | No for promo (self-post only) | Sunday self-post with real substance | Rare reach play | Reach, strict |
| **r/programming** | ~6.9M | Strictest. Link-aggregator for substantive technical articles only; "I built X" and product posts removed/banned. 1:9 enforced. Banned all AI/LLM content in 2026. | Link submissions only, external technical articles | Genuine engineering deep-dive on your own blog, product incidental | 1 article / couple months, rare | High risk |
| **r/opensource** | ~358k | Limited self-promo allowed; project must be genuinely open-source. A paid closed app reads as spam. | Yes (repo link + context) | Only if you open-source a component | 1 / month tied to OSS release | Weak unless OSS |
| **r/productivity** | ~2.4M+ | Strict anti-spam; promo posts removed. App mentions live in **comments** with disclosure + alternatives. | No (discussion-first) | Comment-based contextual mentions + pure methodology posts | Comments over posts, mentions <10% | Comment-only |
| **r/RSI** | ~6k | Health/support, no promo thread. Product mention only inside a helpful answer. *(Rule characterized.)* | Yes (risky if link-only) | Value/story ("dev with RSI, my hands-free setup") | 1 value / 3-4 wks | Intent, gentle |
| **r/accessibility** | ~20k | Practitioner community, sharp on "accessibility-washing." Feedback-seeking framing beats promo. *(Rule characterized.)* | Yes, common | Discussion or "critique our voice-control a11y" post | 1 / month | Credibility |
| **r/dictation** | ~1-2k | Niche, lightly moderated, exact category = highest intent. | Yes | Show-and-tell / comparison; answer "what app should I use?" threads | 1 / few wks | Highest intent |
| **r/speechrecognition** | ~3k | Small technical ASR sub, plays to on-device angle. | Yes | Technical value post on on-device STT privacy/latency | 1 / few wks | Technical |
| **r/SaaS** | ~742k | "Promotion ok, but don't mention unless relevant/helpful." Feedback goes in the weekly pinned thread. Tightening toward once-per-60-days promo limit (Apr 2026). | Yes but link-drops discouraged | Story-led founder post + weekly feedback thread | Overt promo ~1 / 2 months | Founder reach |
| **r/Entrepreneur** | ~5.2M | Standalone promo/URL drops = permanent ban. **All promotion goes in the weekly "Thank You Thursday" thread.** | No (in-context support only) | Pure value/journey posts + Thursday thread for promo | Value ~weekly, promo Thursday only | Reach, strict |
| **r/artificial** | ~1.3M | Self-promo ~10%, be an active member first. Showcase allowed if framed as "here's what we built, feedback?" | Yes within 10% | Show-and-tell framed as feedback on the voice-agent angle | 1 showcase / 3-4 wks | AI reach |
| **r/webdev** | ~3.3M | "No self-promotion or advertising," including subtle comment promo. Showcases restricted to **Showoff Saturday** thread; flair required. | No standalone promo | Showoff Saturday + genuinely helpful answers | Saturday thread only | Reach, strict |
| **r/setups** | ~172k | Enthusiast audience; organic "my setup" posts, not promotion. | Yes (photo/story) | Organic "my hands-free dev setup" story | Occasional, organic | Soft |

**Spin-off multipliers for the vibecoding play:** r/VibeCodeDevs (~57k), r/AskVibecoders (~35k), r/vibecodingcommunity (~8k). Reuse the angle with a fresh title, never the identical crosspost.

**Sources:** r/macapps [reddifier](https://reddifier.com/free-subreddit-analysis-tool/r/macapps) · [gummysearch](https://gummysearch.com/r/macapps/) · [upvote.net](https://upvote.net/blog/macapps-reddit-analysis); r/apple [libreddit rules mirror](https://libredd.it/r/apple/wiki/rules/) · [painonsocial](https://painonsocial.com/companies/apple); r/macOS [mktclarity](https://mktclarity.com/blogs/news/list-subreddits-promotion); r/MacOSApps + r/nativemacapps [gummysearch](https://gummysearch.com/r/MacOSApps/), [gummysearch](https://gummysearch.com/r/nativemacapps/); r/ClaudeAI live feed via [safereddit](https://safereddit.com/r/ClaudeAI) + [gummysearch](https://gummysearch.com/r/ClaudeAI/) + [aibuilderclub](https://www.aibuilderclub.com/blog/best-reddit-communities-ai-builders-2026); r/cursor [foundationinc](https://foundationinc.co/lab/cursor-branded-subreddit/) + [gummysearch](https://gummysearch.com/r/cursor/) + [syften](https://syften.com/blog/startup-subreddits/); r/ChatGPTCoding [safereddit](https://safereddit.com/r/ChatGPTCoding) + [Tereza Tizkova](https://tereza-tizkova.medium.com/best-subreddits-for-sharing-your-project-517c433442f9); r/LocalLLaMA [safereddit](https://safereddit.com/r/LocalLLaMA) + [gummysearch](https://gummysearch.com/r/LocalLLaMA/); r/vibecoding [safereddit](https://safereddit.com/r/vibecoding) + [saascity](https://saascity.io/blog/best-subreddits-promote-startup-2026); r/SideProject [mediafa.st](https://www.mediafa.st/marketing-on-rsideproject) + [shipwithai](https://shipwithai.substack.com/p/4-steps-to-promote-your-side-project); r/programming [Tom's Hardware AI ban](https://www.tomshardware.com/tech-industry/artificial-intelligence/the-largest-programming-community-on-reddit-just-banned-all-content-related-to-ai-llms-r-programming-is-prioritizing-only-high-quality-discussions-about-ai) + [replyagent](https://www.replyagent.ai/blog/reddit-self-promotion-rules-naturally-mention-product); r/opensource [Tereza Tizkova](https://tereza-tizkova.medium.com/best-subreddits-for-sharing-your-project-517c433442f9) + [thehiveindex](https://thehiveindex.com/communities/r-opensource/); r/productivity [hashmeta case study](https://hashmeta.com/insights/case-study-reddit-seo-traffic-growth) + [wisp.blog](https://www.wisp.blog/blog/how-to-plug-your-productservices-with-comments-on-reddit-without-breaking-self-promotion-rules); r/RSI + r/accessibility + r/dictation + r/speechrecognition [gummysearch](https://gummysearch.com/r/RSI/), [gummysearch](https://gummysearch.com/r/accessibility/), [conbersa](https://www.conbersa.ai/learn/reddit-self-promotion-rules); r/SaaS [soar.sh mod enforcement](https://soar.sh/blog/r-saas-rules-decoded-mod-enforcement) + [redditmaster](https://redditmaster.com/subreddit-rules/saas); r/Entrepreneur [redditagency](https://redditagency.com/subreddits/r/entrepreneur); r/artificial [linkeddit](https://linkeddit.com/blog/best-subreddits-for-ai-marketing-2026); r/webdev [redditmaster](https://redditmaster.com/subreddit-rules/webdev) + [teract.ai](https://www.teract.ai/resources/reddit-subreddit-marketing-2026); r/setups [gummysearch](https://gummysearch.com/r/setups/).

---

## 2. Anti-ban doctrine (the non-negotiables)

1. **Warm up u/VerbaRun before any promo.** Reddit's AutoModerator pre-filters on account age and karma. Target: **30+ days old, 100+ comment karma** platform-wide, and **10+ karma inside r/macapps specifically** (its hard gate) before the first promo post there. Spend weeks 1-2 commenting genuinely, zero links. Sources: [conbersa](https://www.conbersa.ai/learn/reddit-self-promotion-rules), [karmaguy](https://karmaguy.io/en/blog/reddit-self-promotion-rules).
2. **The 9:1 (90/10) rule is the real filter.** Reddit retired the rigid wording but mods enforce it by scanning your history. Keep self-referential activity **under 10%** of everything u/VerbaRun does. Nine genuine helpful comments per one promotional link. A history that is all-Verba is the #1 removal trigger. Source: [teract.ai](https://www.teract.ai/resources/reddit-subreddit-marketing-2026).
3. **Comment-first presence.** Value lives in comments, not posts. Answer "what dictation app / how do I go hands-free / RSI setup / voice-drive Claude Code" threads with a genuinely useful answer, disclose you built Verba, and **list alternatives** so it does not read as a pitch. This alone drove a comparable productivity app ~47k monthly visits over 9 months. Source: [hashmeta](https://hashmeta.com/insights/case-study-reddit-seo-traffic-growth).
4. **Spacing and rate limits.** Never two promo posts in one week across the whole account. Per sub, respect the tightest documented cadence (r/macapps: once/30 days). Space community posts 2-4 days apart. Post value in the Tue-Thu 8-11am ET window on the maker subs.
5. **No identical crossposts.** Duplicate posts and near-identical link blasts trip spam detection and are explicitly bannable in r/cursor. Rewrite the title and lead for every sub; rotate subs rather than blast one launch to six at once the same day.
6. **Vary titles and angles.** Same product, different door: workflow tip for r/ClaudeAI, "I built this" for r/vibecoding, RSI story for r/RSI, on-device engineering for r/LocalLLaMA.
7. **One account only.** u/VerbaRun. Sockpuppet upvoting or a second "happy customer" account is vote manipulation and a fast sitewide ban. Founders post as themselves and disclose.
8. **Link placement by sub.** Where a sub bans or punishes promo links: put the link in a **comment** (r/ClaudeAI, r/cursor, r/LocalLLaMA, r/SaaS), in a **self-post body** as text not URL (r/apple, r/macOS), in the **designated thread** (r/Entrepreneur Thursday, r/webdev Saturday, r/ClaudeAI Showcase), or **only on the profile** (r/productivity, r/programming where a product link never belongs). Where promo posts are welcome (r/vibecoding, r/ChatGPTCoding, r/SideProject, r/macapps, r/MacOSApps), the link can go in the post, always pointing to verba.run or the Mac App Store, never a shortener/affiliate/redirect (auto-removed on r/macapps).
9. **Detect shadowbans early.** Log out and open `reddit.com/user/VerbaRun`, if your posts are invisible logged-out you are shadowbanned. Check `reddit.com/r/ShadowBan` tooling monthly. Watch for posts stuck at "1 upvote, 0 comments, no impressions" (removed-by-filter signal). If a post vanishes, it is likely AutoMod, not a ban: message the mods politely, do not repost.

---

## 3. The engine: AUTO vs HUMAN

### AUTO (safe to automate daily via the publisher)

**The honest boundary (L2):** no community subreddit safely permits fully automated, scheduled self-promotion. Every "welcoming" sub still wants a human story and scans post history. So automation is confined to the one surface that breaks no sub rule: **the u/VerbaRun profile.** Self-posts on your own profile need no subreddit, trip no ratio rule, and are visible to your profile followers and via search.

**Profile cadence (automate this):**
- **5 posts / week**, one per weekday, themed:
  - **Mon: Tip** (a macOS/dictation/voice-agent micro-tip, no link, or link on profile)
  - **Tue: Thread of the week** (repost/expand your best community comment of the week as a standalone note)
  - **Wed: Demo clip** (10-20s screen recording of voice-driving Claude Code/Cursor)
  - **Thu: Build log** (what shipped, honest build-in-public metric)
  - **Fri: Roundup / question** (a poll or an open question to followers)
- Never more than 1 profile post/day. This is the always-on drumbeat that makes the account look human and active between community posts, and it is 100% publisher-schedulable.
- The profile also hosts the canonical link so that in strict subs you can say "setup is on my profile" instead of dropping a URL.

**Designated promo threads are borderline-auto but scheduled by hand.** r/Entrepreneur "Thank You Thursday," r/webdev "Showoff Saturday," and the r/ClaudeAI "Built with Claude" Showcase Megathread are recurring slots. You can schedule a reminder, but the comment itself should be written fresh each time. Treat as HUMAN-lite.

### HUMAN (hand-done, value-first, founder voice)

Every community-sub post is human. The founder writes it, discloses authorship, leads with value, and makes **exactly one soft ask.** The 90-day map below assigns each strict/community sub to a specific JALON (milestone) week so no sub is touched more often than its rule allows. Priority order by reach-vs-risk:

1. **Beachhead first (weeks 3-5):** r/vibecoding, r/ChatGPTCoding, r/SideProject, r/ClaudeAI. Highest tolerance + exact ICP.
2. **Core Mac + dev tools (weeks 6-8):** r/macapps (the once/30-day flagship), r/cursor, r/speechrecognition, r/RSI, r/accessibility, r/artificial.
3. **Reach plays with strict gates (weeks 9-12):** r/apple (Sunday), r/Entrepreneur (Thursday), r/SaaS, r/macOS, r/nativemacapps, r/setups, r/webdev (Saturday), r/productivity (comments).
4. **Second cycle + weakest fit last (week 13+):** r/LocalLLaMA (only with a real local hook), r/macapps round 2 (30 days elapsed), repeat the winners.

---

## 4. Content templates (title + body outline + link placement)

**T1. "I built" show-and-tell (r/vibecoding, r/MacOSApps, r/nativemacapps)**
- Title: `I built a Mac voice agent that types AND runs what you say, fully on-device`
- Body: the itch (typing prompts all day gave my wrists hell) → what it does (dictation + it acts: opens apps, runs commands, drives Claude Code) → the honest differentiators (on-device/private, bring-your-own-Claude so no extra token bill) → 15s demo GIF → pricing stated plainly → "I'm the dev, happy to answer anything."
- One soft ask: *"What is the first thing you would voice-control?"*
- Link: **in post** (verba.run).

**T2. Workflow value post (r/ClaudeAI)**
- Title: `I dictate to Claude Code instead of typing. Here is my on-device setup + CLAUDE.md`
- Body: the workflow, the exact CLAUDE.md snippet and hooks, why on-device matters for code you cannot send to the cloud, Verba named as the tool that drives it. Teaches even if they never buy.
- One soft ask: *"Happy to share the full hooks config if useful."*
- Link: **in a comment** (or "on my profile"); also drop the tool into the Built with Claude Showcase Megathread separately.

**T3. Cursor-on-Mac workflow (r/cursor)**
- Title: `Hands-free prompting in Cursor on Mac: an on-device dictation layer`
- Body: how you voice-drive Cursor, latency numbers, privacy note, flair as Resources & Tips. **Never** compare against Cursor pricing or bash it (misinformation rule).
- One soft ask: *"Anyone else voice-driving Cursor? Curious what breaks for you."*
- Link: **in a comment**.

**T4. Cross-tool discussion bait (r/ChatGPTCoding, r/artificial)**
- Title: `Where do AI coding tools still drop you back to the keyboard?`
- Body: name the real workflow gap (you can prompt an agent but you still type it), invite answers, then mention Verba in-thread as how you closed it for yourself.
- One soft ask: *"What is the step where your flow still breaks?"*
- Link: **in a comment**, in-thread.

**T5. Build-in-public launch journey (r/SideProject, r/SaaS)**
- Title: `[Launch] Verba: on-device dictation + voice agent for devs. 6 months of building solo`
- Body: milestone (users/revenue if real), 2 hard technical challenges, one lesson, the ask. Story first, product third.
- One soft ask: *"Feedback on the voice-agent mode especially welcome."*
- Link: **in post** (r/SideProject) / **weekly feedback thread** (r/SaaS).

**T6. RSI / hands-free story (r/RSI, r/accessibility)**
- Title: `Dev with RSI: the hands-free setup that let me keep coding`
- Body: the injury, what you tried (Dragon, macOS Voice Control), where they fell short, the setup that worked, Verba disclosed as the tool you built out of your own need. Substance first, no pitch.
- One soft ask (r/RSI): *"What is helping your wrists right now?"* / (r/accessibility): *"Would love an a11y expert critique of the voice-control UX."*
- Link: **in a comment**.

**T7. On-device engineering post (r/LocalLLaMA, r/speechrecognition)**
- Title: `Running low-latency on-device speech-to-text on Apple Silicon: what I learned`
- Body: real engineering, latency/accuracy numbers, why the audio never leaves the Mac, local model choices, Verba as the concrete example. Must stand as a technical read.
- One soft ask: *none, or "curious how others handle local STT latency."*
- Link: **in a comment** (r/LocalLLaMA is hostile to a link-forward paid post).

**T8. Flaired Mac app show-and-tell (r/macapps)**
- Title: `I built Verba: fast on-device dictation + a voice agent, for developers on Mac`
- Body: problem-first (system dictation is slow and cloud-bound), what makes it native/on-device, disclose you are the dev, official verba.run link only. Set the correct paid flair (Subscription or Lifetime). Requires 10+ sub karma first.
- One soft ask: *"Feedback on the voice-agent mode?"*
- Link: **in post**, official source only.

**T9. Pure value / methodology post (r/productivity, r/macOS)**
- Title: `How voice dictation cut my context-switching while coding`
- Body: the method and results, Verba absent or disclosed only if someone asks. On r/macOS frame as a macOS setup guide.
- One soft ask: *none (methodology stands alone).*
- Link: **profile only / none** (mention in replies if asked).

**T10. Designated-thread promo (r/Entrepreneur Thursday, r/webdev Saturday, r/apple Sunday)**
- Title/body: fit the thread's format. r/apple Sunday must be a **self/text post** with real substance (only after 5+ non-promo contributions that month). r/Entrepreneur and r/webdev go in the pinned weekly thread as a comment.
- One soft ask: *"Open to feedback."*
- Link: **in the thread comment** (r/Entrepreneur, r/webdev) / **in the self-post body as text** (r/apple).

---

## 5. Cadence summary

- **AUTO profile:** 5 self-posts/week, every week, publisher-scheduled.
- **HUMAN community:** 2-3 posts/week max across the whole account, each in a different sub, each respecting that sub's tightest cadence. Comments are unlimited and are the main event.
- **Per-sub ceilings honored:** r/macapps once/30d, r/ClaudeAI + r/cursor once/2-3wk, r/SaaS + r/Entrepreneur promo once/~2mo, r/programming article once/couple months (and only if you actually publish a real engineering post, otherwise skip it entirely).
- **Warmup weeks 1-2:** zero promo, comments only, build karma.

---

## 6. The 90-day Reddit calendar

Weeks 1-2 are warmup (comments, no promo). Weeks 3-13 are JALON weeks, each landing one or two strict/community subs at its allowed cadence, with the always-on AUTO profile drumbeat underneath. Every HUMAN entry carries exactly one soft ask and an explicit link placement.

```json
[
  {"week":1,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Pin an intro post: what Verba is, on-device dictation + voice agent, bring-your-own-Claude","ask":"Follow for build-in-public updates","linkPlacement":"profile"},
  {"week":1,"day":"Tue","mode":"human","target":"r/ClaudeAI","type":"value","angle":"Warmup: answer 3-5 Claude Code workflow threads, genuinely helpful, no link","ask":"none","linkPlacement":"none"},
  {"week":1,"day":"Wed","mode":"auto","target":"profile","type":"show","angle":"Demo clip: voice-driving Claude Code hands-free (15s)","ask":"none","linkPlacement":"post"},
  {"week":1,"day":"Thu","mode":"human","target":"r/cursor","type":"value","angle":"Warmup: help on Cursor-on-Mac threads, no link, learn the flairs","ask":"none","linkPlacement":"none"},
  {"week":1,"day":"Fri","mode":"human","target":"r/dictation","type":"question","angle":"Warmup: answer 'what dictation app should I use' threads, disclose, list alternatives","ask":"none","linkPlacement":"none"},
  {"week":2,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip: 3 macOS dictation shortcuts most devs miss","ask":"none","linkPlacement":"profile"},
  {"week":2,"day":"Tue","mode":"human","target":"r/vibecoding","type":"value","angle":"Warmup: comment on 'I built' threads, build rapport, no link","ask":"none","linkPlacement":"none"},
  {"week":2,"day":"Wed","mode":"auto","target":"profile","type":"show","angle":"Before/after clip: typing a prompt vs speaking it","ask":"none","linkPlacement":"post"},
  {"week":2,"day":"Thu","mode":"human","target":"r/RSI","type":"value","angle":"Warmup: helpful answers under 'Question' posts, no product push yet","ask":"What is helping your wrists right now?","linkPlacement":"none"},
  {"week":2,"day":"Sat","mode":"human","target":"r/MacOSApps","type":"show","angle":"First soft show-and-tell in the friendliest small sub, flair Dev Tools, disclose dev","ask":"Feedback on the on-device approach?","linkPlacement":"post"},
  {"week":3,"day":"Tue","mode":"auto","target":"profile","type":"build","angle":"Build log: what shipped this week","ask":"none","linkPlacement":"profile"},
  {"week":3,"day":"Wed","mode":"human","target":"r/vibecoding","type":"show","angle":"JALON: 'I built a Mac voice agent that types AND runs what you say, on-device' with demo (T1)","ask":"What would you voice-control first?","linkPlacement":"post"},
  {"week":3,"day":"Sat","mode":"human","target":"r/SideProject","type":"show","angle":"[Launch] build-in-public journey, story first (T5)","ask":"Feedback on the voice-agent mode welcome","linkPlacement":"post"},
  {"week":4,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip of the week","ask":"none","linkPlacement":"profile"},
  {"week":4,"day":"Wed","mode":"human","target":"r/ChatGPTCoding","type":"show","angle":"JALON: 'Project' post, dictation layer to voice-drive AI coding on Mac (T1/T4)","ask":"Do you type or speak your prompts?","linkPlacement":"post"},
  {"week":4,"day":"Fri","mode":"human","target":"r/dictation","type":"show","angle":"Verba vs Dragon vs macOS Voice Control, honest on-device comparison","ask":"What do you use today?","linkPlacement":"post"},
  {"week":5,"day":"Tue","mode":"auto","target":"profile","type":"show","angle":"Demo clip of a new voice-agent action","ask":"none","linkPlacement":"post"},
  {"week":5,"day":"Wed","mode":"human","target":"r/ClaudeAI","type":"value","angle":"JALON: 'I dictate to Claude Code instead of typing, here is my CLAUDE.md + hooks' (T2)","ask":"Happy to share the full hooks config","linkPlacement":"comment"},
  {"week":5,"day":"Thu","mode":"human","target":"r/ClaudeAI","type":"promo","angle":"Drop Verba into the pinned 'Built with Claude' Showcase Megathread","ask":"none","linkPlacement":"comment"},
  {"week":6,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip: hands-free git workflow","ask":"none","linkPlacement":"profile"},
  {"week":6,"day":"Wed","mode":"human","target":"r/macapps","type":"show","angle":"JALON flagship: flaired 'I built Verba' self-post, official link only, 10+ sub karma earned (T8)","ask":"Feedback on the voice-agent mode?","linkPlacement":"post"},
  {"week":6,"day":"Fri","mode":"human","target":"r/speechrecognition","type":"value","angle":"On-device STT latency and privacy vs cloud, Verba as example (T7)","ask":"How do others handle local STT latency?","linkPlacement":"comment"},
  {"week":7,"day":"Tue","mode":"auto","target":"profile","type":"build","angle":"Build log: metric update","ask":"none","linkPlacement":"profile"},
  {"week":7,"day":"Wed","mode":"human","target":"r/cursor","type":"value","angle":"JALON: 'Hands-free prompting in Cursor on Mac', flair Resources & Tips, never bash Cursor (T3)","ask":"Anyone else voice-driving Cursor?","linkPlacement":"comment"},
  {"week":7,"day":"Fri","mode":"human","target":"r/RSI","type":"value","angle":"'Dev with RSI: the hands-free setup that let me keep coding' (T6)","ask":"What is helping your wrists right now?","linkPlacement":"comment"},
  {"week":8,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip of the week","ask":"none","linkPlacement":"profile"},
  {"week":8,"day":"Wed","mode":"human","target":"r/accessibility","type":"question","angle":"JALON: feedback-seeking, 'a11y expert critique of our voice-control UX for motor impairment' (T6)","ask":"Would love an expert critique","linkPlacement":"post"},
  {"week":8,"day":"Fri","mode":"human","target":"r/artificial","type":"show","angle":"'Built a macOS voice agent that acts on speech, not just transcribes', feedback framing (T4)","ask":"Feedback on the voice-agent concept?","linkPlacement":"post"},
  {"week":9,"day":"Tue","mode":"auto","target":"profile","type":"show","angle":"Demo clip","ask":"none","linkPlacement":"post"},
  {"week":9,"day":"Thu","mode":"human","target":"r/Entrepreneur","type":"value","angle":"JALON: journey post 'acquiring first paying users for a niche Mac tool', zero pitch","ask":"none","linkPlacement":"none"},
  {"week":9,"day":"Thu","mode":"human","target":"r/Entrepreneur","type":"promo","angle":"Share Verba in the weekly 'Thank You Thursday' pinned thread (T10)","ask":"Open to feedback","linkPlacement":"comment"},
  {"week":9,"day":"Sun","mode":"human","target":"r/apple","type":"show","angle":"JALON: Self-promotion Sunday self/text post, real substance, after 5+ non-promo contributions logged (T10)","ask":"none","linkPlacement":"post"},
  {"week":10,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip of the week","ask":"none","linkPlacement":"profile"},
  {"week":10,"day":"Wed","mode":"human","target":"r/vibecoding","type":"show","angle":"JALON round 2: 'update, shipped new voice-agent actions', fresh title (T1)","ask":"What should I build next?","linkPlacement":"post"},
  {"week":10,"day":"Fri","mode":"human","target":"r/SaaS","type":"value","angle":"Story-led founder post + drop Verba in the weekly feedback thread (T5)","ask":"none","linkPlacement":"comment"},
  {"week":11,"day":"Tue","mode":"auto","target":"profile","type":"build","angle":"Build log","ask":"none","linkPlacement":"profile"},
  {"week":11,"day":"Wed","mode":"human","target":"r/macOS","type":"value","angle":"JALON: 'How I set up fast on-device dictation for coding on macOS', disclose, value-only (T9)","ask":"none","linkPlacement":"comment"},
  {"week":11,"day":"Thu","mode":"human","target":"r/nativemacapps","type":"show","angle":"Native macOS dictation + voice agent showcase (only if genuinely native)","ask":"none","linkPlacement":"post"},
  {"week":11,"day":"Sat","mode":"human","target":"r/setups","type":"value","angle":"Organic 'my hands-free dev setup' photo/story, no pitch","ask":"none","linkPlacement":"none"},
  {"week":12,"day":"Mon","mode":"auto","target":"profile","type":"value","angle":"Tip of the week","ask":"none","linkPlacement":"profile"},
  {"week":12,"day":"Wed","mode":"human","target":"r/ChatGPTCoding","type":"question","angle":"JALON: 'Where do AI coding tools still drop you back to the keyboard?', mention Verba in-thread (T4)","ask":"Where does your flow break?","linkPlacement":"comment"},
  {"week":12,"day":"Fri","mode":"human","target":"r/productivity","type":"value","angle":"Comment-only: answer dictation/voice tool asks, disclose + list alternatives (T9)","ask":"none","linkPlacement":"none"},
  {"week":12,"day":"Sat","mode":"human","target":"r/webdev","type":"show","angle":"Showoff Saturday pinned thread: voice-driven dev tool (T10)","ask":"Open to feedback","linkPlacement":"comment"},
  {"week":13,"day":"Tue","mode":"auto","target":"profile","type":"show","angle":"Demo clip","ask":"none","linkPlacement":"post"},
  {"week":13,"day":"Wed","mode":"human","target":"r/LocalLLaMA","type":"value","angle":"JALON weakest-fit: technical on-device local STT post, 'nothing leaves the Mac', only with a real local hook, no launch tone (T7)","ask":"none","linkPlacement":"comment"},
  {"week":13,"day":"Fri","mode":"human","target":"r/macapps","type":"show","angle":"Round 2 (30+ days since week 6): feature-update show-and-tell, official link only (T8)","ask":"Feedback on the new feature?","linkPlacement":"post"},
  {"week":13,"day":"Sat","mode":"human","target":"r/ChatGPTCoding","type":"show","angle":"'Project' update post, fresh angle, direct link (T1)","ask":"Feedback welcome","linkPlacement":"post"}
]
```

---

### Delivery notes for the caller

- **Deliverable is this markdown message** (per the explicit instruction, "Return a clean markdown report... This is the whole deliverable"). No file written, no artifact published, nothing committed.
- **Two honest boundaries flagged (L2):** (1) No community subreddit safely permits automated scheduled self-promo, so AUTO is confined to the u/VerbaRun profile plus hand-written entries in designated recurring threads; everything else is HUMAN. (2) Reddit's raw rules widget is IP-blocked from this environment; every rule claim is sourced from live-feed mirrors, rule databases, and 2026 policy guides, and the strict subs (r/programming, r/apple, r/macOS, r/cursor, r/LocalLLaMA) should have their live sidebar confirmed from a logged-in browser before the first post.
- **Two conditional dependencies to verify:** r/nativemacapps only works if Verba is genuinely native (no Electron); r/opensource and r/programming are only viable if you publish a real technical article or open-source a component, so they were left off the core calendar as opportunistic rather than scheduled.
- Zero em/en dashes anywhere in the copy (R-NODASH).