# SEO Audit: verba.run

Run: 2026-07-07. Method: live crawl (curl + WebFetch + WebSearch) against the production site, per `.claude/skills/seo-audit/SKILL.md`. No Google Search Console or Bing Webmaster Tools connection is configured in this environment, so any metric that requires it is explicitly labeled "requires Search Console" below rather than estimated.

**Score: 78/100**

- Technical: 24/25
- On-Page: 20/25
- Content: 24/25
- Search Presence: 10/25 (capped low: real ranking/index data needs Search Console, see section 4)

---

## 1. Technical SEO

| Check | Result | Evidence |
|---|---|---|
| HTTPS enforced | PASS | `curl -sI http://verba.run/` returns `308 Permanent Redirect` to `https://verba.run/` |
| HSTS header | PASS | `strict-transport-security: max-age=63072000` on the homepage response |
| robots.txt | PASS | `https://verba.run/robots.txt` returns 200, well-formed, references the sitemap |
| Sitemap.xml | PASS | `https://verba.run/sitemap.xml` returns 200, valid XML, 25 URLs, each with `lastmod`/`changefreq`/`priority` |
| Mobile viewport | PASS | `<meta name="viewport" content="width=device-width, initial-scale=1"/>` present |
| Canonical URLs | PASS | Self-referencing canonical confirmed on every page checked (/, /compare, /best-mac-dictation-app, /features, /docs, /changelog, /features/jarvis-voice-agent, /vs/wispr-flow, /contact, /privacy) |
| TTFB / edge caching | PASS | Homepage TTFB 0.22s, subpages 0.07 to 0.08s; `x-vercel-cache: HIT`, `x-nextjs-prerender: 1`, served from Vercel `fra1` edge |
| lang attribute | PASS | `<html lang="en">`, single-locale site, no hreflang needed (no hreflang tags present, consistent with English-only) |
| AI-crawler access | PASS (notable) | robots.txt explicitly names and allows GPTBot, OAI-SearchBot, ChatGPT-User, PerplexityBot, Perplexity-User, ClaudeBot, anthropic-ai, Claude-Web, Google-Extended, Applebot-Extended, CCBot, all with `Allow: /`. This is a deliberate, well-executed GEO (generative-engine-optimization) posture, ahead of most competitor sites. |
| robots.txt disallow rules | PASS | `/account`, `/app-auth`, `/api`, `/atelier` correctly blocked from crawl (private/app surfaces, not marketing pages) |

**Deduction (-1):** every URL in sitemap.xml carries the identical `lastmod` timestamp (`2026-07-07T14:57:18.959Z`), which is the sitemap's build time, not a real per-page last-modified date. This is low signal for crawlers trying to prioritize genuinely fresh content (e.g. `/changelog`, which really does change daily, looks no fresher than `/terms`, which almost never changes).

**No dedicated `/pricing` URL.** Pricing lives only at the `/#pricing` anchor on the homepage. Not a defect (it is linked and crawlable as part of the homepage), but it means "verba pricing" style queries have no page built specifically to win that intent.

---

## 2. On-Page SEO

### Title tags and meta descriptions (measured character counts)

| Page | Title | Title len | Meta description | Desc len |
|---|---|---|---|---|
| `/` | Verba, the Mac Voice Agent \| Private Dictation that Acts | 56 | Verba is the private Mac voice agent: dictate and it acts across 1,000+ apps. On-device voice-to-text, reuse your Claude Code plan with no key. $9.99/mo. | 153 |
| `/compare` | Verba vs Wispr Flow, superwhisper & more, Mac dictation | 55 | An honest, sourced comparison of Verba vs Wispr Flow, superwhisper, Aqua Voice, MacWhisper and 5 more, 24 dictation features, side by side. | 139 |
| `/best-mac-dictation-app` | Best Dictation App for Mac (2026), Ranked & Compared | 52 | An honest, sourced ranking of the best Mac dictation apps in 2026: Verba, Wispr Flow, superwhisper, MacWhisper and more, on-device, privacy, AI cleanup and voice agents compared. | **178 (too long)** |
| `/features` | Features, Verba AI Dictation for Mac | 36 | Everything Verba does: the JARVIS voice agent, AI dictation modes, voice notes, voice tasks, live translation, and screen-aware Context mode, all on your Mac. | 158 (borderline) |
| `/docs` | Documentation, Verba AI Dictation for Mac | 41 | Verba's technical documentation: install & permissions, dictation modes, AI engines and bring-your-own-AI setup, the JARVIS voice agent, Notes, Tasks, shortcuts, privacy and troubleshooting. | **190 (too long)** |
| `/changelog` | Changelog, Verba AI Dictation for Mac | 37 | Every Verba release since launch on June 5, 2026. Shipped in public, fast: 60+ releases in the first days, with dates and times. | 128 |
| `/features/jarvis-voice-agent` | JARVIS Voice Agent for Mac, Verba | 33 | JARVIS is a voice agent for Mac that acts across 1,000+ apps like Gmail, Slack, and Notion. It plans, shows the steps, and only acts after you confirm. | 151 |
| `/contact` | Contact, Verba | 14 | Get in touch with the Verba team at Agentik OS for support or questions. | 72 |
| `/privacy` | Privacy Policy, Verba | 21 | (not measured, legal page) |, |

**Finding:** 2 of 8 content pages checked (`/best-mac-dictation-app` at 178 chars, `/docs` at 190 chars) exceed Google's practical SERP truncation point (roughly 155 to 160 characters). Both will get cut off mid-sentence in search results, which weakens click-through. `/features` at 158 is right at the edge. Titles are all in good shape (33 to 56 chars, none truncated).

**H1 structure:** every page checked has exactly one H1. Good discipline, no duplicate or missing H1s found.

- Homepage H1: "Speak it. Send it clean.", a brand tagline, not a keyword-bearing H1. Reasonable as a hero headline for conversion, but it means the homepage's single most-weighted on-page element carries zero head-term signal ("Mac", "voice", "dictation", "AI"). The primary keywords only appear starting in the H1's supporting paragraph and in `<title>`/meta.
- Subpages carry the keyword correctly in H1: `/compare` → "Verba vs the rest, the Mac dictation that doesn't just type, it acts", `/best-mac-dictation-app` → "The Best Dictation App for Mac in 2026", `/features/jarvis-voice-agent` → "JARVIS: The Voice Agent for Mac That Acts on Your Apps". This is the right pattern; the homepage is the outlier.

**Image alt text:** 42 `<img>` tags found in the homepage source, all 42 carry a non-empty `alt` attribute (the app-integration logos: gmail, slack, notion, github, etc., each alt-tagged with the app name). No missing or empty alt attributes found on the homepage. Product screenshots elsewhere were not individually crawled in this pass; spot-check any new visual/screenshot pages before publishing.

**Structured data (JSON-LD):** present and valid on every page sampled.
- Site-wide: `SoftwareApplication`, `Offer`, `Person` (founder), `WebSite`, `Organization` (with `sameAs` to GitHub, Instagram, TikTok, YouTube, X, Reddit, Pinterest, Telegram).
- `/compare`, `/docs`, `/features/jarvis-voice-agent`: add `BreadcrumbList`.
- `/docs`, `/features/jarvis-voice-agent`: add `TechArticle`.
- `/best-mac-dictation-app`, `/features/jarvis-voice-agent`: add `FAQPage` (validated: 6 Q&A pairs on `/best-mac-dictation-app`, 5 on the JARVIS page).
- All blocks parsed as valid JSON with `python3 -m json` in this audit; no syntax errors found.

**Flag, not a ranking defect but a brand-guardrail conflict:** the site-wide `SoftwareApplication` JSON-LD `featureList` and the `/privacy` meta description name the underlying engines directly: `"On-device voice-to-text (WhisperKit, NVIDIA Parakeet)"`, `"Bring your own AI (Claude, OpenRouter, local Ollama)"`, and `/privacy`'s description says `"our included AI (OpenRouter/Anthropic)"`. The project's standing content rule for this repo is to never name Verba's underlying tech (Whisper, Parakeet, Claude, Anthropic, GPT, OpenAI) in marketing copy. Structured data is technically read by crawlers and AI answer engines, not just humans, so this is real public-facing content, not internal documentation. Recommend the operator decide whether this is an intentional, accepted exception (legal/privacy disclosure has a legitimate reason to name real subprocessors) or something to reword. Not scored against On-Page since the schema itself is accurate and well-formed; flagging separately because it is the one place on the crawled surface that breaks the house copy rule.

---

## 3. Content Structure

**Word count:** every page checked clears the 300-word minimum by a wide margin. Rough raw word counts (tags stripped, includes nav/footer boilerplate, so treat as an upper bound):

- `/`: ~5,255 words
- `/compare`: ~3,268 words
- `/best-mac-dictation-app`: ~4,043 words
- `/features`: ~1,344 words
- `/docs`: ~4,653 words
- `/changelog`: ~28,510 words (60+ dated release entries, `changefreq: daily`)
- `/features/jarvis-voice-agent`: ~3,388 words
- `/vs/wispr-flow`: ~1,806 words

**Header hierarchy:** clean H1 → H2 → H3 nesting confirmed on the homepage (H2s: "The case for talking," "Who it's for," "Speak it. JARVIS does it.," "Why Verba," "The full kit," "Start free. Go Pro when you're hooked.," "Questions, answered," etc.; H3s nested correctly under each, e.g. "Engineers/Founders/Writers" under "Who it's for"). No skipped levels (no H3 without a parent H2) found in the sampled pages.

**Internal linking:** strong hub-and-spoke pattern.
- Homepage nav links to all 6 `/features/*` subpages, `/docs`, `/compare`, `/best-mac-dictation-app`, `/changelog`, one `/vs/*` page.
- `/compare` links out to all 9 `/vs/*` comparison pages (`wispr-flow`, `talktastic`, `superwhisper`, `macwhisper`, `aqua-voice`, `willow-voice`, `voiceink`, `apple-dictation`, `otter-ai`), so nothing is orphaned; they are simply two clicks deep from the homepage rather than one.
- No broken internal links found among the pages checked (every internal href resolved to a 200).

**Content cannibalization risk (real finding):** `/compare` and `/best-mac-dictation-app` both target overlapping intent ("Verba vs Wispr Flow / superwhisper / MacWhisper," "best Mac dictation app") with separate URLs, separate titles, and meaningfully different word counts (3,268 vs 4,043 words). This is a legitimate content strategy (a feature-matrix comparison page vs. an editorial ranking page) but the two pages currently reference the same competitor set and could compete against each other for the same query cluster in Google's ranking rather than reinforcing one page. Worth an explicit internal-linking pass (each should link to the other with clear differentiated anchor text: "see the full feature comparison" vs "see the full 2026 ranking") to signal to Google they are complementary, not duplicate.

**No blog / evergreen content hub found.** The crawlable surface is entirely product pages (features, docs, compare, changelog) plus legal. There is no `/blog` in the sitemap or nav. This isn't a defect against the current 25 URLs, but it is the single biggest content-side lever left unpulled: there is no long-tail, editorial content path to rank for adjacent queries beyond direct product/competitor terms.

---

## 4. Search Presence

**What could be checked live (no Search Console needed):**

- `WebSearch site:verba.run` surfaced exactly **one** indexed result: the homepage (`https://verba.run/`). None of the other 24 sitemap URLs (`/compare`, `/best-mac-dictation-app`, `/features/*`, `/vs/*`, `/docs`, `/changelog`) appeared in this query. This is a real, if approximate, signal: search-index tooling available to this audit could not find those subpages indexed at all. It is consistent with a young domain that has not yet been fully crawled/indexed, or with genuinely thin indexation of the deeper pages.
- Brand query ("Verba Mac voice agent dictation") does return the Verba homepage and surfaces accurate product facts (JARVIS, tone matching, on-device Whisper/Parakeet, pricing), so the brand itself is discoverable and the content is accurately represented when it is surfaces.
- A generic competitive query ("Verba Mac dictation vs Wispr Flow superwhisper") returned **zero** mentions of Verba. The results were dominated by competitor and third-party comparison content (spokenly.app, medium.com, getvoibe.com, wisprflow.ai's own comparison page, jamesm.blog), and the search tool's own summary stated "I didn't find any product called Verba... in these results." This means that for the exact competitive intent the `/compare` and `/best-mac-dictation-app` pages are built to win, Verba is not currently surfacing against third-party aggregator content.

**Requires Search Console connection (not faked, not estimated here):**
- Actual indexed-page count and per-page indexing status (Coverage report)
- Real impressions, clicks, average position, and CTR per query
- Which queries currently drive any organic traffic
- Whether Google has crawled and processed the sitemap, and any crawl errors
- Mobile usability report and Core Web Vitals field data (CrUX, real user data rather than this audit's synthetic TTFB numbers)

**Requires Bing Webmaster Tools connection (not faked, not estimated here):**
- Bing indexing/crawl stats, Bing query and keyword data, backlink counts

---

## Top 3 Actions

1. **Fix the two over-length meta descriptions** (`/best-mac-dictation-app` at 178 chars, `/docs` at 190 chars) and trim `/features` from 158 to under 155. These are the exact pages built to win competitive dictation-app search intent; a truncated, mid-sentence snippet in the SERP directly costs click-through on the highest-intent pages on the site.
2. **Connect Google Search Console** (and ideally Bing Webmaster Tools) before drawing further conclusions on indexing and rankings. The one clean signal available without it, `site:verba.run` returning only the homepage plus zero visibility on a head-term competitive query, is concerning enough that it should be confirmed with real Coverage and Performance data rather than acted on from search-engine approximations alone.
3. **Cross-link `/compare` and `/best-mac-dictation-app` explicitly**, and consider a real `/pricing` URL instead of only the `/#pricing` anchor, to remove ambiguity between the two overlapping comparison pages and to give "verba pricing" queries a dedicated landing page.

---

## Appendix: raw evidence

**robots.txt** (`curl -s https://verba.run/robots.txt`):
```
User-Agent: *
Allow: /
Disallow: /account
Disallow: /app-auth
Disallow: /api
Disallow: /atelier

User-Agent: GPTBot
User-Agent: OAI-SearchBot
User-Agent: ChatGPT-User
User-Agent: ClaudeBot
User-Agent: anthropic-ai
User-Agent: Claude-Web
User-Agent: PerplexityBot
User-Agent: Perplexity-User
User-Agent: Google-Extended
User-Agent: Applebot-Extended
User-Agent: CCBot
Allow: /
Disallow: /account
Disallow: /app-auth
Disallow: /api
Disallow: /atelier

Sitemap: https://verba.run/sitemap.xml
```

**Sitemap URL list** (25 total, `curl -s https://verba.run/sitemap.xml`):
`/`, `/best-mac-dictation-app`, `/compare`, `/features`, `/docs`, `/changelog`, `/acknowledgements`, `/privacy`, `/terms`, `/contact`, `/features/jarvis-voice-agent`, `/features/dictation-modes`, `/features/voice-notes`, `/features/voice-tasks`, `/features/live-translation`, `/features/context-mode`, `/vs/wispr-flow`, `/vs/talktastic`, `/vs/superwhisper`, `/vs/macwhisper`, `/vs/aqua-voice`, `/vs/willow-voice`, `/vs/voiceink`, `/vs/apple-dictation`, `/vs/otter-ai`

**Homepage response headers** (`curl -sI https://verba.run/`):
```
HTTP/2 200
strict-transport-security: max-age=63072000
server: Vercel
x-nextjs-prerender: 1
x-vercel-cache: HIT
content-length: 142797
```
