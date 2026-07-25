# Verba website, OmegaOS audit synthesis

Run: 2026-07-26 · Target: https://verba.run · Power level: Standard · Scope: seo, perf, a11y, sec, copy, uiux

## The finding that matters most: the tools were lying

The first pass reported **0 findings across every severity on every audit**. That was false.
`lighthouse-seo.json`, `lighthouse-a11y.json`, `lighthouse-perf.json` and `pa11y.json` were all
**3 bytes**: Lighthouse and pa11y never started (`CHROME_PATH must be set` / `Could not find Chrome`),
and `axe.json` was corrupt (the axe CLI wrote its human-readable banner into the JSON stream).
`npm-audit.json` was 0 bytes.

A blocked surface scored as green is an ABORT, not a PASS (L5). Every number below comes from a
re-run against the Playwright chromium at
`~/.cache/ms-playwright/chromium-1228/chrome-linux64/chrome`.

**Action for the machine, not just this site:** `~/.omega/lib/audit-gather/*.sh` needs to export
`CHROME_PATH`/`PUPPETEER_EXECUTABLE_PATH` and to fail loudly when a tool writes an empty artifact,
otherwise every future audit on this box silently returns a perfect score.

## Scores (Lighthouse desktop, after fixes)

| Page | Perf | A11y | Best practices | SEO |
|---|---|---|---|---|
| `/` | 89 | **100** | 100 | 100 |
| `/blog` | 100 | **100** | 100 | 100 |
| `/blog/zoom-meeting-transcript` | 96 | **100** | 96 | 100 |

Accessibility before the fixes: 94 / 96 / 93.

## Fixed

| Sev | Finding | Evidence | Fix |
|---|---|---|---|
| **CRITICAL** | `@clerk/nextjs` 6.12.0 in range of GHSA-vqx2-fgx2-5wq9, CVSS **9.1** middleware route-protection **bypass** | `npm audit`: 1 critical + 7 high | upgraded to 6.39.6 (+ React 19.2.3 peer). Now 0 critical, 5 high |
| HIGH | Clerk authorization bypass on org/billing/reverification (8.1), `@clerk/backend` data-authenticity (7.5) | same | same upgrade |
| MED | `.mono-meta` / `.mono-index` at 3.30:1 and 3.24:1, below the 4.5:1 WCAG AA floor for 0.72rem text | Lighthouse `color-contrast`, fg `#636366` on `#0a0a0d` | new `--faint-data` token at the passing alpha |
| MED | Record button is icon-only, announced as "button" | Lighthouse `button-name`, `components/TryIt.tsx:113` | state-dependent `aria-label` |
| MED | Outrank video iframes carry no title | Lighthouse `frame-title` | labelled at render + `youtube-nocookie` |
| MED | 20 em dashes in live copy, a hard R-NODASH breach | 19 in `app/changelog/page.tsx`, 1 in `app/privacy/page.tsx` | rewritten; 30 live pages rescanned, zero left |
| MED | Blog article cards flush against the footer | operator report, measured 0px | grid bottom margin, now 99px |
| MED | Footer links painted over the next column | 50 page/viewport combos, overlapping pairs found | content-sized flex columns; re-tested 50 combos, 0 overlaps |
| LOW | Sitemap frozen at build time, new articles would never enter it | live `lastmod` was the 07-21 build date | `revalidate = 300`; proven live, `lastmod` moved with no deploy |
| LOW | `llms.txt` listed no blog at all (GEO) | fetched body | generated blog section, revalidated |

## Crawl, 30 URLs from the sitemap

All 200. Zero missing canonicals, zero canonical mismatches, exactly one `h1` per page, zero heading
level skips, zero images without `alt`, zero accidental `noindex`. robots.txt already grants GPTBot,
ClaudeBot, PerplexityBot and friends explicitly.

## Open, needing an operator decision

1. **5 high npm vulnerabilities remain**, all transitive: `next` (App Router Server Actions DoS,
   needs a Next 16 major), `ws` via `convex`, `postcss` (build-time only), `sharp`/libvips. Each
   needs a deliberate upgrade, not a drive-by.
2. **The secret-tech rule is broken on the money pages.** `/best-mac-dictation-app` and `/compare`
   name Parakeet, WhisperKit, Claude, Anthropic, OpenAI and OpenRouter in visible copy, which the
   standing rule says to never do in public. But on a comparison page the BYO-AI story is arguably
   the differentiator being sold. Rewriting the positioning copy on the two highest-intent SEO pages
   is not a call to make unilaterally, so it is reported, not changed.
3. `/blog/…` best-practices sits at 96 because the YouTube embed sets a third-party cookie even on
   `youtube-nocookie`. The only complete fix is a click-to-load facade, which changes how Outrank's
   article bodies render.
4. Meta descriptions outside the 110-165 SERP window: `/privacy` (262), `/docs` (190),
   `/best-mac-dictation-app` (178) get truncated; `/acknowledgements` (59) and `/contact` (72) are thin.
5. Home CLS 0.041 and LCP 1.9s: both inside Google's "good" thresholds, so no defect, but it is why
   perf reads 89 rather than 100.

## Not run

`uiuxaudit` and `copyaudit` were covered by their concrete findings above (footer overlap, spacing,
banned dashes, tech-naming) rather than as full standalone protocols.
