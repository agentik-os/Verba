# /codeaudit — Forensic Report: gated `/atelier` internal docs feature

**Target:** commit `b9403db` (merged `44b4607`) — `website/` atelier feature
**Scope:** `website/lib/atelier.ts`, `website/app/atelier/**`, `website/middleware.ts`, `website/scripts/atelier-assets.mjs`, `website/app/robots.ts`, `website/package.json`
**Mode:** READ-ONLY (no project code edited — audit only)
**Date:** 2026-07-02
**Score:** **88 / 100 — Grade A (Solid)**
**Confidence:** high (auth + traversal verdicts backed by live prod runtime probes; static analysis of all 9 files)

---

## Executive verdict

A small, competently-built feature. The highest-stakes component — the Basic-Auth gate — is **correct and runtime-proven**: fail-closed, dotted-asset gotcha handled, CVE-2025-29927 patched, path normalization consistent. Path traversal has **no exploitable vector**. The only legitimate code defects are an XSS-escaping gap in the custom markdown renderer (real-world risk LOW because content is trusted/internal and the page is gated to the operator) and a dead build artifact. Nothing structural, nothing production-blocking.

### Load-bearing verdicts (the two the brief demanded explicitly)

| Vector | Verdict | Basis |
|---|---|---|
| **Auth bypass** | ✅ **PASS — no bypass found** | 8 live unauthenticated prod probes, all 401; CVE-2025-29927 tested and ineffective |
| **Path traversal** | ✅ **PASS — no exploitable vector** | Static read of every fs-touching path + slug constraint + no symlinks in `marketing/` |

---

## Runtime evidence (Popper falsification — live prod, unauthenticated)

All probes against `https://verba.run` with **no credentials** unless noted. Runtime is the only truth (L1).

```
GET /atelier                              -> 401   (fail-closed, no creds)
GET /atelier/fundraising                  -> 401
GET /atelier/  (trailing slash)           -> 308 -> Location: /atelier -> 401 (harmless normalize)
GET /Atelier   (case trick)               -> 404   (no content at capitalized path)
GET /atelier/_search.json                 -> 401   ← dotted asset gated
GET /atelier/foo.pdf                       -> 401   ← dotted asset gated
GET /atelier/foo.csv                       -> 401   ← dotted asset gated
GET /atelier/x.png                         -> 401   ← dotted asset gated
GET /atelier/03-visual-identity/*.svg      -> 401   ← nested dotted asset gated
curl -u verba:wrongpass  /atelier          -> 401   (wrong password rejected)
curl -u wronguser:x      /atelier          -> 401   (wrong user rejected)
Header check /atelier: www-authenticate: Basic realm="Verba Atelier", charset="UTF-8"
                       x-robots-tag: noindex, nofollow
robots.txt: "Disallow: /atelier" x2 (one per UA group — intended, not a bug)

# CVE-2025-29927 (Next.js middleware auth bypass, patched in 15.2.3; site runs 15.5.19)
x-middleware-subrequest: middleware                                  -> 401
x-middleware-subrequest: src/middleware                             -> 401
x-middleware-subrequest: middleware:middleware:middleware:...(x5)   -> 401
x-middleware-subrequest: pages/_middleware                          -> 401
   + confidential-content grep on bypass attempt: 0 atelier/investor/fundraising markers leaked

# Encoded-traversal normalization
GET /atelier/..%2faccount              -> 401 (stayed under /atelier for middleware)
GET /atelier/%2e%2e/account            -> 200  → serves /account (11x "account", 9x "clerk",
                                                 0 atelier markers) — normalizes OUT of atelier
                                                 to a PUBLIC route, NOT an atelier leak
GET /atelier/fundraising%2f..%2f..%2faccount -> 401
```

**Interpretation of the one `200`:** `%2e%2e` decodes to `..`, so `/atelier/%2e%2e/account` normalizes to `/account` — a normal public route. The response contains account/Clerk markup and **zero** atelier markers. Routing and middleware see the *same* normalized path (both resolved to `/account`), so there is no middleware-vs-routing divergence to exploit. This is correct behavior, not a leak.

---

## Findings (ranked by severity)

### 🟠 MEDIUM

**M-1 — Custom `marked` renderer omits HTML-escaping of link `title` and external `href`** — `website/lib/atelier.ts:197`, `:200`
The overridden `link` renderer builds attributes with raw interpolation:
```ts
const titleAttr = token.title ? ` title="${token.title}"` : "";   // :197  token.title NOT escaped
return `<a href="${r.href}"${titleAttr} target="_blank" rel="noopener">${inner}</a>`; // :200  r.href raw for external
```
`marked`'s *default* renderer HTML-escapes both `title` and `href`; this override does not. A markdown link whose title contains a `"` (e.g. `[x](https://e.com "a" onmouseover="alert(1))`) or an external href containing `"` breaks out of the attribute → HTML/attribute injection.
- **Mitigating context (per brief):** source markdown is 100% operator-authored internal content, and the page is Basic-Auth-gated to a single operator user. Practical exploitability is effectively self-XSS. **Real-world risk: LOW.** Ranked MEDIUM as a code-correctness defect (a real regression from marked's safe default).
- **Note — one good side effect:** `javascript:` hrefs are *neutralized* — `resolveHref` (`:146`) classifies any non-http/mailto/tel/anchor scheme through path resolution, finds no match in `mdSet`/`assetSet`/`foldersBySlug`, and returns `{kind:"dead"}` → rendered as an inert `<span>` (`:207`), never an `<a>`. Verified by tracing `resolveHref` for `javascript:alert(1)`.
- **Fix:** escape `token.title` and `r.href` (e.g. reuse marked's `escape` helper or a small `.replace(/"/g,"&quot;")` on the attribute values). The heading renderer (`:187`) is already safe — `slugifyHeading` strips `[^\w\s-]`, so no quote can enter the `id`.

**M-2 — `dangerouslySetInnerHTML` renders unsanitized markdown HTML (no defense-in-depth)** — `website/app/atelier/[[...slug]]/page.tsx:35`, `:62`; renderer at `website/lib/atelier.ts:182`
`new Marked({ gfm: true })` runs with no sanitizer (marked v18 removed built-in `sanitize`), and both render paths inject the result via `dangerouslySetInnerHTML`. Any raw HTML in a source `.md` (`<script>`, `<img onerror=...>`, inline handlers) renders verbatim.
- **Mitigating context:** same trust boundary as M-1 (trusted internal authors, gated audience). **Real-world risk: LOW.** This is the same XSS surface as M-1 viewed from the sink side; listed separately because the remediation differs (a sanitizer pass such as `isomorphic-dompurify` on the rendered HTML would close both M-1 and M-2 as defense-in-depth).
- **Fix (optional, defense-in-depth):** sanitize `renderMarkdown` output before it reaches `dangerouslySetInnerHTML`.

### 🟡 LOW

**L-1 — `_search.json` build artifact is dead / redundant** — `website/scripts/atelier-assets.mjs:70`
The build script writes `public/atelier/_search.json`, but **nothing consumes it** — `grep -rn "_search" app/ lib/ components/` returns zero hits. The client search (`AtelierSearch.tsx`) is fed by `searchIndex()` (`lib/atelier.ts:263`) passed as a prop through `layout.tsx:25` → `AtelierShell` → `AtelierSearch`. So two independent search indexes are computed from the same source (R-KARPATHY simplicity violation) and the JSON is a served-but-unfetched artifact (runtime-confirmed: `/atelier/_search.json` → 401, i.e. it exists and is gated, but no code fetches it). Risk: silent drift between the two indexes; wasted build work. *Caveat:* could be intended for a future/external consumer — within the audited scope it is dead.
- **Fix:** either delete the `_search.json` emission, or make `AtelierSearch` fetch it (and drop the prop path) — pick one source of truth.

**L-2 — Non-constant-time credential comparison (timing side-channel)** — `website/middleware.ts:19`
`ok = user === "verba" && password === expected;` — JS `===` on strings can short-circuit on length/first-diff, a theoretical timing oracle on the shared secret. Over HTTPS with network jitter and a full-string compare this is practically infeasible, and the Clerk Edge runtime does not expose `crypto.timingSafeEqual`. Best-practice note only; **risk: LOW.**

**L-3 — Asset copy follows symlinks (build-time supply-chain / robustness)** — `website/scripts/atelier-assets.mjs:62`
`fs.copyFileSync(abs, dest)` follows symlinks. A symlink inside `marketing/` pointing outside the tree would copy an external file's content into the (gated) `public/atelier/` artifact; a symlink-to-directory would fall through to the asset branch and throw `EISDIR`, breaking the build. **Verified no symlinks currently exist** (`find marketing -type l` → empty), and `marketing/` is trusted operator content, so this is theoretical. Same applies to `walk` in `lib/atelier.ts:86` (uses `withFileTypes`, so a dir symlink is treated as a file/asset).

**L-4 — Folder-slug vs doc-slug collision silently shadows the doc** — `website/app/atelier/[[...slug]]/page.tsx:27` + `website/lib/atelier.ts:105`,`:111`
If a non-README doc's slug equals a folder slug (e.g. root `fundraising.md` → slug `"fundraising"` and folder `fundraising/` → slug `"fundraising"`), the page renders the *folder* (folder check precedes the doc check at `page.tsx:27`), and the doc becomes unreachable. `allSlugs()` (`:121`) dedupes via a `Set`, so there is no build error — the shadowing is silent. Low likelihood in the current tree; flagged as a latent correctness trap.

**L-5 — `linkReport` link regex is naive** — `website/lib/atelier.ts:281`
`/\]\(([^)]+)\)/g` misses reference-style links, breaks on URLs containing `)`, and matches inside fenced code blocks. It only affects the build-time "D2 proof" statistic, not rendering or link resolution, so impact is cosmetic — but the reported dead/total counts may be inaccurate.

### ⚪ INFO / nits

- **I-1** — `website/app/atelier/AtelierShell.tsx:43`: `<details open={isAncestor(...)}>` recomputes `open` from `pathname` every render, so a user's manual collapse can be re-opened on re-render. Minor UX.
- **I-2** — `website/lib/atelier.ts:264` + `:266`: `searchIndex` destructures `mdSet` from one `buildAtelier()` call, then calls `buildAtelier()` again for `model`. Harmless (module-level `cached` at `:74`), but redundant.
- **I-3** — `website/middleware.ts:13`: `header?.startsWith("Basic ")` is case-sensitive; RFC 7617 defines the auth scheme token as case-insensitive. No real browser sends `basic `, so cosmetic.
- **I-4** — `website/lib/atelier.ts:74` module-level `cached` is correct for build-time single-process use; the file header (`:1-4`) explicitly forbids runtime import, so no stale-cache risk in the intended usage. Documented constraint — noted for future readers.

---

## Phantom / dependency / config-drift checks (all clean)

- **Imports:** `marked@18.0.5` installed and version-matched (`package-lock.json`; `node_modules/marked` reports `18.0.5`); `next/navigation`, `next/link`, `node:fs`, `node:path`, `@/lib/atelier` all resolve. No phantom imports.
- **Env var:** `ATELIER_PASSWORD` (`middleware.ts:10`) is provisioned (runtime-confirmed — a 401 with a correct `WWW-Authenticate` challenge proves the gate is live and comparing). Not a phantom.
- **Build wiring:** `package.json:7` runs `node scripts/atelier-assets.mjs && next build` — asset copy precedes the Next build. Correct.
- **Gitignore:** `.gitignore:5` = `/public/atelier/` — the build artifact is correctly untracked (reproducible).
- **Marketing source present:** 147 `.md` + 11 non-md assets under `marketing/` (matches the commit message's "147 md" / "11 non-md assets").
- **`locateMarketingDir` fails loud** (`lib/atelier.ts:68`, `atelier-assets.mjs:18`) — throws rather than rendering an empty site. Good build robustness.
- **Next 15 correctness:** `params: Promise<…>` + `await params` (`page.tsx:22`), `force-static` + `dynamicParams = false` + `generateStaticParams` (`:5-11`) — idiomatic SSG; `dynamicParams=false` is what makes arbitrary slugs 404 (a key traversal defense). Server/client boundary is clean — `layout.tsx:13 toTree()` strips `relPath` before crossing to the client shell.

---

## Path-traversal verdict (detailed)

**No exploitable vector.** Every filesystem read is driven by build-time-discovered, membership-validated paths, never by raw request input:
- `resolveHref` (`lib/atelier.ts:146`) normalizes with `path.posix.normalize` (`:160`), rejects `..`/`../` escapes (`:164`), and then only returns a href if the target is a **member** of `mdSet`/`foldersBySlug`/`assetSet` (`:167-176`). It performs no fs read.
- `getDoc`/`getFolder` (`:221`,`:229`) read `path.join(marketingDir, doc.relPath)` where `relPath` originates from the `walk` of real files (`:99`), and the doc/folder is fetched by slug from maps keyed only on discovered content. With `dynamicParams=false` (`page.tsx:6`), any slug outside `generateStaticParams` 404s before a read.
- `atelier-assets.mjs` walks real `Dirent` entries; `entry.name` is a single path component, so `path.join(outDir, rel)` cannot escape `outDir`. Only residual is the symlink note (L-3), which is trusted build-time input with no symlinks present.

## Auth-bypass verdict (detailed)

**No bypass found**, confirmed by 12 live probes:
1. **Fail-closed** — no creds → 401; wrong password → 401; wrong user → 401 (`middleware.ts:19,24`). If `ATELIER_PASSWORD` is unset *or* empty string, `expected` is falsy → the `if (expected && …)` guard (`:13`) is skipped → `ok` stays false → 401. Verified logically + live.
2. **Matcher coverage** — the dedicated `/atelier/:path*` matcher entry (`:43`) catches dotted asset paths that the Clerk matcher (`:44`, excludes `.pdf/.csv/.json/...`) deliberately skips. All dotted-asset probes returned 401 — the documented "matcher gotcha" is genuinely closed.
3. **CVE-2025-29927** — the `x-middleware-subrequest` middleware-bypass (patched in Next 15.2.3; site runs 15.5.19) is ineffective: all header variants → 401, zero confidential markers leaked.
4. **Case trick** — `/Atelier` → 404 (no content served).
5. **Encoded traversal** — `%2e%2e` normalizes consistently for both routing and middleware; escapes resolve to public routes, never to atelier content.
6. **Header hygiene** — `X-Robots-Tag: noindex, nofollow` on both the 401 and the authenticated `NextResponse.next()` (`:29,34`); meta robots in `layout.tsx:9`; `robots.ts:6,15` disallows `/atelier` in both UA blocks.

Residual (LOW): timing-safe compare (L-2), case-sensitive scheme token (I-3).

---

## Score derivation

| Dimension | Assessment |
|---|---|
| Auth (highest stakes) | Correct, fail-closed, CVE-patched, runtime-proven — no deduction |
| Path traversal | No exploitable vector — no deduction |
| Contracts / data flow | Clean; slug/link resolution correct modulo L-4 shadow trap |
| XSS surface | M-1 + M-2 escaping/sanitization gap (trusted content → low real risk) — main deduction |
| Simplicity / dead code | L-1 redundant `_search.json` — deduction |
| Build robustness | Fails loud, wired correctly; L-3/L-5 minor |
| React/Next 15 | Idiomatic; I-1 minor |

**88/100 — Grade A.** Kept out of the 90s by the renderer escaping gap (M-1/M-2) and the dead/duplicated search index (L-1); everything security-critical is verified sound.

## Recommended fixes (priority order, for the operator — NOT applied, this is read-only)

1. **M-1** — escape `token.title` and external `r.href` in the `link` renderer (`lib/atelier.ts:197,200`). Smallest, highest-value fix.
2. **M-2** (optional) — add a DOMPurify pass on `renderMarkdown` output for defense-in-depth; closes M-1 too.
3. **L-1** — pick one search-index source of truth (delete `_search.json` or fetch it).
4. **L-4** — guard against folder/doc slug collisions (warn at build, or namespace).
5. L-2 / L-3 / L-5 / I-* — best-practice polish, non-urgent.

---

*Not covered by this audit:* an authenticated (valid-credential) render of every one of the 157 pages (no prod credentials in this session — probes were unauthenticated by design); a full `next build` run (no build executed here); the 147 source docs' actual markdown content for embedded raw HTML (the M-1/M-2 risk is structural, not enumerated per-doc). These are the honest bounds of the evidence above.
