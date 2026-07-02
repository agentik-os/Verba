# /uiuxaudit — verba.run/atelier (internal docs site) — Forensic UI/UX Report

**Date:** 2026-07-02 · **Skill:** `/uiuxaudit` v2 (Gestalt-Popper, audit-only — fix phases out of scope per dispatch: READ-ONLY on `website/`)
**User-need (verbatim):** *"This is an internal DOCS-READING tool consulted from a PHONE — grade documentation UX, not marketing conversion."*
**Hinge component:** the mobile docs-reading surface — sidebar tree drawer + rendered markdown pane at 375×812.
**Pages sampled (runtime, authenticated):** `/atelier`, `/atelier/fundraising/investors-research`, `/atelier/01-strategy/gtm-strategy`, `/atelier/content-juillet-2026/01-social-x-build-in-public`, `/atelier/fundraising`, `/atelier/00-context`, `/atelier/nonexistent-doc-xyz` (404 path) — at 375×812 **and** 1440×900, light **and** dark (`prefers-color-scheme`).
**Method:** static extraction of `website/app/atelier/*` + `website/lib/atelier.ts` (Pass A inductive), then Playwright-Chromium runtime capture against prod with `httpCredentials` (Pass B deductive), then adversarial re-verification of every contested finding (touch **and** mouse input). Raw data: `/tmp/atelier-audit-data.json`, `/tmp/atelier-verify-data.json`. Screenshots: `/tmp/atelier-*.png`.

---

## VERDICT

```
╔══════════════════════════════════════════════════════════╗
║  /uiuxaudit — verba.run/atelier                          ║
║  Score: 70/100 — Grade B                                 ║
║  "Good. Minor inconsistencies, strong foundation."       ║
╚══════════════════════════════════════════════════════════╝
```

### Mobile-usability verdict (explicit, per dispatch)

**USABLE on a phone today — B-tier reading comfort.** The fundamentals that usually break mobile docs sites are all correct here (verified at 375×812): **zero horizontal overflow on every sampled page** (`overflowX: 0` in all 14 page captures), **tables scroll horizontally inside their box instead of breaking the layout** (e.g. index status board: `scrollW 484 / clientW 343, scrollable: true, overflowsViewport: false`), **code blocks wrap** (`pre code` computed `white-space: pre-wrap`, `scrollW == clientW` on all 10 blocks of the X calendar), **0 console errors and 0 failed requests on every page**, and contrast passes WCAG AA in both schemes. What keeps it from A-tier on a phone is ergonomics, not rendering: a sticky topbar that can swallow **25.8% of the viewport**, a drawer that stays open covering the page after tapping a folder link, no table-of-contents on documents up to **~44 phone-screens tall**, and tap targets down to 19.7px.

### Phase scores (0–10, weighted /420 → normalized /100)

| Phase | Score | Weighted | Key evidence |
|---|---|---|---|
| 1 Color system | 9/10 | 18/20 | Tokenized `--at-*` vars, zero rogue colors in `atelier.css`; AA everywhere (see P1) |
| 2 Typography | 7/10 | 17.5/25 | Clean scale; but 15.2px body on mobile, frontmatter-corrupted headings (F2) |
| 3 Spacing & rhythm | 7/10 | 14/20 | Consistent rem scale; 59px two-line folder rows (F6), 209px topbar (F1) |
| 4 Component anatomy | 6/10 | 18/30 | Solid tree/search/breadcrumb; drawer lacks close button + `aria-expanded` (F10) |
| 5 Cross-page coherence | 6/10 | 18/30 | Shell identical on all pages ✓; folder-vs-doc link drawer behavior split (F4), root vs nested tree ordering inverted (F5) |
| 6 Interaction & motion | 6/10 | 12/20 | Hover + chevron rotation + 0.2s drawer ✓; Escape doesn't close (F10) |
| 7 Responsive fidelity | 5/10 | 12.5/25 | 0 overflow ✓, tables/code ✓; topbar bloat (F1), 13.6px input → iOS zoom (F8), targets <44px (F9) |
| 8 Accessibility | 5/10 | 12.5/25 | `aria-label` on nav/search/menu ✓, semantic `details/summary` ✓; no skip link, no focus trap, no `aria-expanded` |
| 9 Design smells | 8/10 | 16/20 | No gradient/shadow abuse; consistent emoji iconography (📓📁📄) fits internal tool |
| 10 Visual hierarchy | 6/10 | 18/30 | Doc-page hierarchy good; frontmatter leak destroys the first screen of 17 docs (F2) |
| 11 Copy & microcopy | 7/10 | 14/20 | Coherent French UI copy ("Rechercher…", "Aucun résultat", dead-link tooltip); 404 is English default Next (F10) |
| 12 Performance as design | 9/10 | 18/20 | Static pages, ~1.0–1.7s networkidle, no image/CLS risk, 0 failed requests |
| 13 Dark mode | 9/10 | 18/20 | Complete auto dark (GitHub palette), AA (6.15–16.02:1); no manual toggle (LOW) |
| 14 System maturity | 7/10 | 17.5/25 | Single scoped token file, semantic vars, one writer; no docs/tests (fine for internal) |
| 15 Navigation architecture | 5/10 | 12.5/25 | Active highlight + ancestor auto-expand + breadcrumb + search ✓; no TOC (F3), 105 slug labels (F5), folder-link bug (F4) |
| 16 Onboarding/first-use | 8/10 | 16/20 | Index README is a real guided entry ("Read in this order") |
| 17 Data visualization | 8/10 | 16/20 | Tables: bordered, `th` bg, top-aligned, in-box scroll on mobile |
| 18 Error recovery | 4/10 | 10/25 | 404 = bare Next default, no shell, no way back (F10); 401 = plain text |
| 19 Brand expression | 7/10 | 14/20 | Quiet notebook identity (📓 Atelier); appropriate for a confidential internal tool |
| **TOTAL** | | **292.5/420** | **→ 70/100 (B)** |

---

## FINDINGS — ranked by severity

Every finding survived ≥2-of-3 adversarial lenses (L1 reproduce at runtime · L2 steelman the design · L3 cross-check against siblings/tokens). Killed candidates are listed at the end.

### F1 · HIGH — Sticky topbar swallows up to 25.8% of the phone viewport (breadcrumb never truncates)

- **Evidence (L1):** measured `.atelier-topbar` heights at 375×812 — index **57px**, gtm-strategy **107px**, investors-research **166px**, X calendar **209.4px = 25.8% of an 812px viewport**, `position: sticky` (verify-data `v5_topbar: {h: 209.375, pct: 25.8, sticky: "sticky"}`). Screenshot mid-scroll with a quarter of the screen dead: `file:///tmp/atelier-topbar-eats-viewport-m-light.png`; also `file:///tmp/atelier-investors-m-light.png`.
- **Cause:** `Breadcrumb` renders every ancestor's **full doc title** ("Verba — X/Twitter Content Calendar · July 2026 (Build-in-Public → Launch)") with `flex-wrap: wrap` and no truncation — `website/app/atelier/AtelierShell.tsx:70-100`, `website/app/atelier/atelier.css:127-136`. The wrapped 5-line breadcrumb also flows awkwardly around the ☰ button.
- **Why it matters for the user-need:** this is a phone reading tool; the deepest, longest docs (exactly the ones you read longest) permanently lose the most reading space.
- **Fix direction (not applied — read-only):** on `max-width: 767px` collapse the breadcrumb to `… / {last segment}` or a single-line `text-overflow: ellipsis; white-space: nowrap`, and/or un-stick the topbar on scroll-down (auto-hide).
- **Lenses:** L1 ✅ measured+screenshot · L2 ✅ no rationale for a 209px sticky header (desktop stays 55px — the design intent is clearly one line) · L3 ✅ 4 sibling pages show 57→209px variance driven only by title length.

### F2 · HIGH — YAML frontmatter renders as a garbled giant heading above the real H1 on 17 documents

- **Evidence (L1):** on `/atelier/01-strategy/gtm-strategy` at 375px the entire first screen is `project: Verba layer: strategy produced_by: marketing-strategist (/omg-marketing-strategist) status: filled reconciles_with: ../gtm-strategy.md # doc racine riche (18 Ko)…` rendered at H2 size **above** "GTM Strategy — Verba" — screenshot `file:///tmp/atelier-gtm-frontmatter-m-light.png` (desktop: `file:///tmp/atelier-gtm-d-light-sidebar.png`). Runtime heading census: `headings[0] = "H2:project: Verba\nlayer: strategy…"`; first article element is the stray `<hr>` (verify-data `v4`).
- **Cause:** `lib/atelier.ts:180-213` (`makeMarked`) pipes raw markdown to `marked` with no frontmatter stripping; `--- yaml ---` becomes HR + setext-H2. **17 files** start with `---` (grep of `marketing/**`: gtm-strategy.md, content-strategy.md, launch-strategy.md, all of 05-calendar, 04-publishing/zernio.md, 03-visual-identity/DA.md, all of 02-copy, all of 00-context…), i.e. the entire strategy/copy/context layer.
- **Fix direction:** strip `^---\n[\s\S]*?\n---\n` before `m.parse()` in `renderMarkdown` (one regex), or render it as a small muted metadata chip.
- **Lenses:** L1 ✅ screenshot both viewports · L2 ✅ no designer intends metadata soup as the opening heading · L3 ✅ 17 files affected → systemic, and `firstHeadingOrName` already skips it for titles, proving the intent was to hide it.

### F3 · HIGH — No table of contents / no back-to-top on documents up to ~44 phone-screens tall

- **Evidence (L1):** `/atelier/content-juillet-2026/01-social-x-build-in-public` measures **35,923px** of document height at 375px (≈44 viewport-heights); index 5,624px; investors 5,075px (audit-data `docHeight`). The renderer already generates heading ids (`lib/atelier.ts:185-193`) and `:target { scroll-margin-top: 4rem }` exists (`atelier.css:287`) — but no UI ever exposes them: no "on this page" list, no prev/next doc links, no back-to-top.
- **Why it matters:** finding "E17" in the July calendar from a phone means blind scrolling through ~40 screens; the anchors are built and wasted.
- **Fix direction:** auto-generate a collapsed "Sommaire" `<details>` at the top of docs with >N h2s (data already in the HTML), + a floating ↑ button past 2 viewports.
- **Lenses:** L1 ✅ measured heights · L2 ✅ no steelman — ids are generated, so linking within docs was intended · L3 ✅ all long siblings share the gap (system-level, not one page).

### F4 · HIGH — Tapping a folder link navigates but leaves the drawer covering the new page (inconsistent with doc links)

- **Evidence (L1, reproduced with touch AND mouse):** touch: tap "00-context" folder link → URL becomes `/atelier/00-context` but `sidebar.open: true, backdrop: true` (audit-data `t3_folderLinkNav`); mouse re-verification identical (verify-data `v2_mouseFolderLink: {url: "/atelier/00-context", open: true}`); screenshots `file:///tmp/atelier-after-folderlink-m-light.png`, `file:///tmp/atelier-v2-folderlink-drawer-m-light.png`. Doc links behave correctly: tap → navigate → drawer closes (`t4_docLinkNav: open: false`).
- **Cause:** the folder `<Link>` inside `<summary>` calls `e.stopPropagation()` (`AtelierShell.tsx:48`), which blocks the `<aside onClick={() => setMenuOpen(false)}>` close handler (`AtelierShell.tsx:118`).
- **Why it matters:** on the phone the user taps a folder, the page changes underneath, and the drawer still fills the screen — "did my tap work?" Then a second gesture (backdrop tap) is needed. Same UI pattern, two behaviors = the #1 coherence sin (skill Law 1).
- **Fix direction:** in the folder link's onClick, also `setMenuOpen(false)` (pass a callback down), keeping `stopPropagation` for the details-toggle concern.
- **Lenses:** L1 ✅ ×2 input methods + screenshots · L2 ✅ steelman ("keep browsing the tree") fails — navigation already happened and the target page is hidden; doc links prove the intended pattern is close-on-navigate · L3 ✅ doc-link sibling behavior differs → inconsistency confirmed.

### F5 · MEDIUM — 105 of 156 sidebar labels are raw machine slugs, and root ordering buries the numbered scaffold

- **Evidence (L1):** DOM census of the expanded tree: **156 links, 105 with labels matching `^\d{2,3}-[a-z-]+$`** — "00-context", "01-strategy", "02-copy", "026-speedinvest"… (verify-data `v3_sidebar`); drawer screenshot `file:///tmp/atelier-drawer-open-m-light.png`; expanded-tree screenshot `file:///tmp/atelier-sidebar-investors-m-light.png`. The ~100 `fundraising/emails/NNN-firm.md` files flood both the tree and search (first search hit for "invest" is the slug-titled `026-speedinvest` — screenshot `file:///tmp/atelier-search-m-light.png`).
- **Ordering split (L3):** at the root the shell renders loose docs **before** folders (`AtelierShell.tsx:122-132`), so nine "Verba — …" summary docs push the numbered scaffold (00→05) below the drawer fold; inside `FolderNode` the order is folders-**then**-docs (`AtelierShell.tsx:53-63`) — the two levels contradict each other, and folder index pages ("Dans ce dossier") use folders-first too.
- **Cause:** folders show `readmeTitle || name` (`AtelierShell.tsx:40`) and most folders have no README title; email docs have no `# H1` so `firstHeadingOrName` falls back to the filename (`lib/atelier.ts:54-58`).
- **Fix direction:** humanize fallback labels (strip `NN-`, title-case), order root like nested levels, and either collapse `fundraising/emails` by default or label it "Emails investisseurs (100)".
- **Lenses:** L1 ✅ DOM census + screenshots · L2 ◐ partial steelman — the `00-`…`05-` numbering intentionally encodes reading order (keep the numbers), but "026-speedinvest" as a *search result title* has no defense · L3 ✅ folders WITH READMEs ("Calendrier prévisionnel — Verba") get proper titles → the system already wants titles. Verdict: survives (2/3) at MEDIUM.

### F6 · MEDIUM — Folder chevron renders on its own line → every folder row is a 59px two-line block

- **Evidence (L1):** all sampled `summary` heights = **59.2px** (two lines) even for "02-copy" (audit-data `tapTargets.summaries`); visible on mobile drawer AND desktop screenshots (`file:///tmp/atelier-drawer-open-m-light.png`, `file:///tmp/atelier-index-d-dark.png` — the ▸ sits alone above each folder name).
- **Cause:** `.atelier-tree a` is `display: block` (`atelier.css:95-104`), so the folder `<Link>` inside `<summary>` wraps below the inline-block `summary::before` chevron (`atelier.css:110-116`).
- **Why it matters:** folder rows look broken (misaligned glyph, double height), the tree eats twice the vertical space in a drawer that is the primary phone navigation, and the chevron's isolated ~16px line is the only pure "expand" affordance.
- **Fix direction:** `summary { display: flex; align-items: center; }` + `summary > a { display: inline; flex: 1; }` — one-line rows, chevron aligned.
- **Lenses:** L1 ✅ measured + 2 screenshots · L2 ✅ no design intent for a floating chevron line · L3 ✅ doc rows are 29.6px single-line → folders are the outlier.

### F7 · MEDIUM — Search matches titles/slugs only; content queries silently fail; no keyboard support

- **Evidence (L1):** query "SPF DKIM" (a real phrase inside `marketing/fundraising` docs) → "Aucun résultat" (audit-data `t7b_contentSearch`); the index only carries `{slug, title, folder}` (`AtelierShell.tsx:20-24`, `lib/atelier.ts:263-275`); matcher checks `title`/`slug` only (`AtelierSearch.tsx:29`). No arrow-key navigation of results, no `/` or ⌘K shortcut, no `role="listbox"`.
- **Steelman (L2):** diacritic-insensitive matching is genuinely good (`AtelierSearch.tsx:13-18`), title search is cheap and honest for 147 docs — a deliberate scope choice. But for a *docs-reading* tool the user asks "where did we write about X?", which titles cannot answer, and nothing tells the user search is title-only ("Aucun résultat" reads as "we don't have this").
- **Fix direction:** minimum: placeholder "Rechercher un titre…" (honest scope); better: build-time excerpt index (first ~200 words per doc) — the model is already fully static.
- **Lenses:** L1 ✅ reproduced · L2 ◐ partial · L3 ✅ every doc affected. Survives (2/3), MEDIUM.

### F8 · MEDIUM — Search input font is 13.6px → iOS Safari auto-zooms the page on focus

- **Evidence (L1):** computed `font-size: 13.6px` on `.atelier-search input` at 375px (audit-data `fonts.searchInput`, `t7_search.inputFontPx`); source `atelier.css:152` (`font-size: 0.85rem`). iOS Safari zooms any focused input <16px — on a phone-first tool this makes every search interaction jarring (documented WebKit behavior; not reproducible in Chromium, flagged from the measured value).
- **Fix direction:** `@media (max-width: 767px) { .atelier-search input { font-size: 16px; } }`.
- **Lenses:** L1 ✅ computed value cited (mechanism is platform-documented) · L2 ✅ no intent — desktop uses the same size, it's just untuned · L3 ✅ body text (15.2px) is also <16px but non-focusable, so only the input triggers zoom. Survives, MEDIUM.

### F9 · MEDIUM — Tap targets below guidelines: breadcrumb links 19.7px, sidebar links 29.6px, ☰ 37.2px

- **Evidence (L1):** measured rects at 375×812 — breadcrumb links **19.7px** tall (fails even WCAG 2.5.8 minimum 24px), sidebar doc links **29.6px**, menu button **37.2×37.2px**, search input 35.2px (all < Apple HIG 44px; audit-data `tapTargets`, all pages). Search result items are 65–91px ✓ — proof the codebase can do it right.
- **Fix direction:** mobile media query: tree links `padding: 0.55rem 0.5rem`, menu button `min-width/height: 44px`, breadcrumb `padding-block: 0.35rem`.
- **Lenses:** L1 ✅ measured · L2 ✅ density is desirable in a tree, but 29.6px with 0.05rem gaps is beyond "dense" for touch · L3 ✅ consistent across pages (token-level, one fix).

### F10 · MEDIUM — Error/edge states: bare 404, Escape doesn't close the drawer, no close affordance inside it, no `aria-expanded`

- **Evidence (L1):**
  - 404 (authed) = default Next page, **no atelier shell, no link back** — body is exactly "404 — This page could not be found." (audit-data `notFound: {status: 404, hasAtelierShell: false}`; screenshot `file:///tmp/atelier-404-m-light.png`). A typo'd/stale URL strands the reader; also the only English-default screen in a French UI.
  - Escape with drawer open → still `open: true` (audit-data `t5_escape`). Backdrop tap works (`t6_backdrop: open: false`) — but the open drawer covers the ☰ button (`z-index 40` sidebar vs topbar 20, `atelier.css:204-218`), so the **only** close affordance is the ~67px backdrop strip; there is no ✕ inside the drawer.
  - Menu button: static `aria-label="Ouvrir le menu"`, no `aria-expanded`, no focus trap in the drawer (`AtelierShell.tsx:137-143`).
- **Fix direction:** `app/atelier/not-found.tsx` inside the shell with a "← Retour à l'Atelier" link; `keydown Escape → setMenuOpen(false)`; add ✕ in the drawer header; `aria-expanded={menuOpen}`.
- **Lenses:** all three items L1-reproduced ✅; L2 ✅ no intent (Next default 404 is what you get when you don't override); L3 ✅ consistent across pages.

### F11 · LOW — Desktop reading column pinned left; ~450px dead zone on 1440px

- **Evidence:** `.atelier-content { max-width: 900px; }` without `margin-inline: auto` (`atelier.css:66-70`); screenshot `file:///tmp/atelier-gtm-d-light-sidebar.png` (large empty right band). Phone-first tool, so LOW — but `margin: 0 auto` is free.
- **Lenses:** L1 ✅ screenshot · L2 ◐ left-anchored docs exist (MDN) · L3 ✅ all pages. Survives at LOW.

### F12 · LOW — Minor a11y/system gaps

- No skip-to-content link (`skipLink: false` on all pages); no `prefers-reduced-motion` guard on the drawer/chevron transitions (0.15–0.2s, low impact); no manual dark-mode toggle (system-only — fine for internal, noted for completeness); body prose 15.2px at 375px is slightly under the 16px comfort floor for long-form phone reading (`fonts.proseP`, `atelier.css:230`).

---

## What is VERIFIED GOOD (falsification attempted, passed)

| Claim | Falsification test run | Result |
|---|---|---|
| Auth gate correct | `curl -o /dev/null -w "%{http_code}"` without / with `-u verba:***` on `/atelier`; bogus path with auth | **401 / 200 / 404** — fail-closed confirmed (`website/middleware.ts:7-36`), `X-Robots-Tag: noindex` + `robots` metadata (`layout.tsx:7-10`) |
| No horizontal overflow at 375px | `scrollWidth - innerWidth` on 7 distinct pages × light/dark | **0 on every capture** |
| Tables scroll, don't overflow | per-table `scrollW/clientW` + bounding-box vs viewport, 5 tables | wide tables `scrollable: true, overflowsViewport: false` (`atelier.css:265-272` `display:block; overflow-x:auto`) |
| Code blocks wrap on 375px | computed `white-space` + `scrollW` on 10 `pre` blocks | all `pre-wrap`, no scroll (`atelier.css:262`) |
| Dead-link affordance | computed style of `.dead-link` on index | muted `#6b7280`, dotted underline, `cursor: not-allowed`, tooltip "document interne non publié" (`lib/atelier.ts:207`, `atelier.css:281-286`) — exemplary |
| Active page highlight + ancestor auto-expand | DOM `a.active` href vs URL on 4 deep pages; `details[open]` count; active item in viewport | exact match on all; ancestors expanded; active visible (`t9_active`) |
| Contrast AA (light+dark) | relative-luminance ratios on measured computed colors | light: muted 4.83, accent 5.17, fg 17.4 · dark: muted 6.15, accent 7.49, fg 16.02 — **all pass AA** |
| Console/network clean | console-error + requestfailed + ≥400 listeners on every page load | **0 errors, 0 failed requests** on all 14 captures |
| Drawer basics | open via ☰, chevron-expand keeps drawer open (touch + mouse), backdrop closes, doc-link closes | all pass (`t1`, `t2`/`v1`, `t6`, `t4`) |
| Search dropdown fits mobile | result-box bounding rect vs viewport | `offLeft: false, offRight: false`; items 65–91px tall |
| Load speed | networkidle timing ×14 | 1.0–1.7s, static output (`force-static`, `page.tsx:5`) |

## Candidate findings KILLED by adversarial verification

- ~~"Sidebar `onClick` closes the drawer when expanding a folder"~~ (static Pass-A hypothesis from `AtelierShell.tsx:118`) — **refuted at runtime twice**: chevron tap (touch `t2`) and mouse click (`v1`) both expand the folder with the drawer staying open. Runtime wins over code reading (L1). Only the *folder-link* path misbehaves (F4).
- ~~"Emoji icons = AI-generic smell"~~ — L2 steelman holds: 📓/📁/📄/☰ used consistently, zero icon-library weight, fits a confidential internal notebook. 1/3 lenses → killed.
- ~~"`details open` prop desync after manual toggle"~~ — not reproduced in navigation flows; ancestor expansion behaved correctly on every sampled navigation. Not scored.

---

## Fix plan (NOT executed — dispatch is read-only on `website/`; priority order per Phase 21)

| # | Finding | File | Effort |
|---|---|---|---|
| 1 | F2 strip frontmatter | `website/lib/atelier.ts` (`renderMarkdown`) | ~3 lines |
| 2 | F1 truncate mobile breadcrumb | `atelier.css` + `AtelierShell.tsx` (Breadcrumb) | ~10 lines |
| 3 | F4 close drawer on folder-link nav | `AtelierShell.tsx:45-51` | ~5 lines |
| 4 | F6 flex summary row | `atelier.css:95-116` | ~4 lines |
| 5 | F8+F9 mobile font/tap-target block | `atelier.css` media query | ~10 lines |
| 6 | F3 auto-TOC for long docs | `lib/atelier.ts` (headings already parsed) | ~30 lines |
| 7 | F10 shell 404 + Escape + ✕ + aria-expanded | `app/atelier/not-found.tsx`, `AtelierShell.tsx` | ~25 lines |
| 8 | F5 humanize labels / root order / collapse emails | `AtelierShell.tsx`, `lib/atelier.ts` | ~15 lines |

Estimated post-fix score if 1–5 land: **~85/100 (A)**.

---

## v2 meta-protocol result block

```json
{
  "score": 70,
  "confidence": "high",
  "skill_used": "uiuxaudit",
  "ticket": "atelier-uiux-2026-07-02",
  "user_need_match": {
    "quote": "internal DOCS-READING tool consulted from a PHONE — grade documentation UX, not marketing conversion",
    "addressed": true,
    "evidence": "Every dispatch dimension graded with runtime proof: sidebar tree+collapsibility (F4,F5,F6 + t2/v1 pass), active highlight (t9_active pass), breadcrumb (F1), client search (F7,F8 + t7 pass), markdown readability incl. tables-scroll-not-overflow at 375px (pass), code wrapping (pass), link+dead-link affordance (pass), mobile nav toggle ergonomics (F4,F10), contrast/dark-mode (pass, ratios cited), tap targets (F9). Both required viewports (375x812, 1440x900) and both color schemes captured.",
    "edge_cases_covered": ["404 with auth", "401 without auth", "36k-px document", "8-column table at 375px", "diacritic search", "content-phrase search", "touch vs mouse input"]
  },
  "falsifiable_tests_count": 11,
  "falsifiable_tests_ref": "table 'What is VERIFIED GOOD' above — each row = hypothesis + command + actual output; raw JSON at /tmp/atelier-audit-data.json and /tmp/atelier-verify-data.json",
  "hinge_findings": [
    { "location": "website/app/atelier/AtelierShell.tsx:48", "concern": "folder-link tap leaves drawer over navigated page", "verified_safe_by": "NOT safe — reproduced touch+mouse (t3, v2)" },
    { "location": "website/app/atelier/atelier.css:127-136", "concern": "sticky topbar up to 25.8% of mobile viewport", "verified_safe_by": "NOT safe — measured 209.4px (v5)" },
    { "location": "website/lib/atelier.ts:180-213", "concern": "frontmatter rendered as heading on 17 docs", "verified_safe_by": "NOT safe — screenshot + heading census (v4)" }
  ],
  "issues_found_and_fixed": [],
  "confidence_basis": "Every scored claim carries a runtime artifact (computed style, DOM census, screenshot, or HTTP probe) captured against production with real Basic-Auth; contested findings were re-verified with an independent input method; three static hypotheses were killed by runtime evidence rather than reported. Not covered: real iOS Safari (F8 inferred from measured font-size + documented WebKit behavior), screen-reader runtime (VoiceOver), and the 100 unsampled email docs beyond their sidebar/search footprint.",
  "finished_at": "2026-07-02T00:00:00Z"
}
```

**Scope statement:** this audit proves the state of 7 sampled routes × 2 viewports × 2 color schemes on production as of 2026-07-02, plus static analysis of the full `app/atelier` implementation. It did **not** exercise: real iOS Safari, screen readers, offline behavior, or all 147 documents individually. Fix phases (21–23) intentionally not run — dispatch is read-only on `website/`.
