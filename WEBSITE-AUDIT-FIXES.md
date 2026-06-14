# Website audit fixes — ready-to-apply patch (handoff)

These files are part of the **other session's uncommitted WIP** (all of `website/app`, `website/lib`,
`website/components`), so this patch is NOT applied automatically — apply it once that WIP is committed,
or cherry-pick the hunks. Every item below is from the verified multi-agent audit (2026-06-14).

---

## 🔴 HIGH-1/2 — `/compare` cells truncated mid-word (live on prod)

`website/lib/compare-matrix.ts` cell strings were clipped to a fixed width at generation and render
verbatim on `/compare` (a key conversion page). **Real fix: regenerate the matrix with full strings +
add a build-time assert that no cell ends mid-word.** Until then:

**Verba's own cells — suggested full text (verify against intended copy):**
| line | current (truncated) | suggested full |
|---|---|---|
| 105 | `yes:6 built-in dictation m` | `yes:6 built-in dictation modes` |
| 150 | `yes:API key or OpenRouter` | `yes:API key or OpenRouter (BYOK)` |
| 180 | `yes:fully offline, can aut` | `yes:fully offline, auto-installs a local model` |
| 195 | `yes:speak an intent, serve` | `yes:speak an intent, served by the right model` |
| 210 | `989 in catalog (site mar` | `~1,000 in catalog` *(see app-count below)* |
| 225 | `yes:to-dos with deadline r` | `yes:to-dos with deadline reminders` |
| 240 | `yes:10 note formats (Clean` | `yes:10 note formats` |
| 255 | `yes:modes auto-select when` | `yes:modes auto-select per app` |
| 270 | `yes:persisted DictTerm lis` | `yes:persisted dictionary list` |
| 285 | `yes:native Swift, Apple Si` | `yes:native Swift, Apple Silicon` |
| 375 | `yes:on-device (Parakeet/Wh` | `yes:on-device (Parakeet/Whisper)` |

**Competitor cells (52,65,127,165,187,211,219,290,292,382,390-399, price row 388-400): DO NOT GUESS** —
restore from the generator source. Fabricating a competitor's capability/price is worse than the bug.
The price row also duplicates the clean `COMPARE.prices` map (29-40) → drop the truncated price row.

---

## 🟠 MEDIUM/LOW — exact, unambiguous code fixes

**`website/app/compare/page.tsx`**
```diff
- if (v === "partial") return <span className="text-[12px]" style={{ color: "var(--fg-50)" }}>~ partial</span>;
+ if (v === "partial") return <span className="text-[12px]" style={{ color: "var(--fg-dim)" }}>~ partial</span>;   // --fg-50 is undefined in globals.css
- if (v === "?") return <span className="muted">, </span>;
+ if (v === "?") return <span className="muted">–</span>;   // committed source renders a stray comma; prod already shows an en-dash
```
Also: `/compare` + `/vs/*` headers drop the primary CTA — use the shared `SiteNav` (or add the
`Download` button + `Sign in`) so the CTA isn't only at the page bottom.

**`website/app/layout.tsx:52`** — stale structured-data version:
```diff
- softwareVersion: "0.9.16",
+ softwareVersion: "0.9.25",   // match the latest changelog entry (ideally import it so it can't drift)
```

**App-count contradiction** — pick ONE figure everywhere (`compare-matrix.ts:210` says `989`, the rest
says `1,000+`). On a "nothing inflated" page, use `~1,000` / `989+` consistently across
`layout.tsx`, `app/page.tsx`, `app/compare/page.tsx`, `app/vs/[slug]/page.tsx`, `app/llms.txt/route.ts`.

**`website/app/vs/[slug]/page.tsx:145`** — the "If you need mobile or Windows today, those tools win…"
caveat is unconditional; it shows on macOS-only competitors (VoiceInk, MacWhisper, Apple Dictation).
Gate it: only render when `c.platforms` actually contains Windows/mobile.

**`website/components/LiveDemo.tsx:166`** — caption says "Haiku to polish" but Polish routes to Sonnet 4.6.
Drop/correct the Haiku claim to match real routing.

**`website/components/TryIt.tsx:158`** — "7 free tries" sits next to the hero's "33 dictations" with no
distinction. Label it "7 free browser demos" so it can't read as contradicting the 33-dictation in-app trial.

**`website/app/page.tsx`** — ~10 section components are defined but never rendered (dead code):
`Nav, Bento, ContextMode, NotesTab, LanguageDetection, VoiceTodos, TranslateMode, ModesModels,
FeatureBlurbs, Footer` (+ `BentoStat`, used only by the dead `Bento`). Delete them (incl. the duplicate
`Nav`/`Footer` that compete with the live `SiteNav`/`SiteFooter`) or wire the wanted ones into `Home()`.

---

## Mac (also the other session's WIP — `Pipeline.swift`, `ActionExecutor.swift`)
- `Pipeline.swift:815` — `isMixedLanguage` trips at 0.2 (2 off-language sentences in 10); raise toward
  ~0.35 to match the "real share, not a lone outlier" intent. Also `Pipeline.swift:739-749`: the
  code-switch doc comment is mis-attached to `stripLeadingPreamble` — move it above `isMixedLanguage` (783).
- `ActionExecutor.swift:446` — `mailto` recipient is set raw (unencoded) while subject/body are encoded;
  percent-encode/validate the recipient (display names with spaces/angle brackets break the URL).

## Convex — deferred (invasive, needs its own change + migration)
- Same-millisecond `(uid, ts)` collision merges distinct rows: sync the existing client UUID as a real
  `id` column and dedup on it (ts stays a sort field). Touches schema + all 8 push handlers + clients.
- Tombstones: de-dup inserts in `wipe`/`prune`/`account.wipe`; add retention/compaction + a since-cursor
  `tombstones` query; add composite `by_uid_ts` indexes and `.order().take(N)` instead of full `.collect()`.
