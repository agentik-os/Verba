## Fix Verification Report

**Ticket:** VER-41 — Custom shortcut selection during onboarding (double-tap Fn)
**Mode:** FIX (remaining scope only)
**Status:** PROPOSED FIX — pending on-device verification (NOT verified live)

> Honesty note: this analysis ran on a Linux host with no Xcode and no macOS device, so the app was NOT built or run. There are no before/after screenshots or console logs because a native menu-bar app has no browser surface and no device was available to capture. Everything below is a static root-cause plus a surgical proposed patch for a maintainer to apply and verify on a Mac.

### Scope
The 0.9.68 comment already shipped half of this ticket: the picker now states the validity rule (a Cmd/Opt/Ctrl modifier is required) and shows a clear onboarding confirmation state. The only OPEN part is the requested "double-tap Fn" option. This patch addresses ONLY that.

### What was requested
> Expected: Clear workflow and confirmation for choosing a shortcut, adding an option for double tap Fn besides single tap and press & hold.

### Root cause
`TriggerStyle` (Settings.swift:25-35) defines exactly two cases, `toggle` and `hold`. The Settings picker iterates `TriggerStyle.allCases` (SettingsView.swift:1328), so it can only ever render two chips. And `fnDown()` (AppDelegate.swift:1224-1229) unconditionally starts recording on the FIRST bare Fn press, so no double-tap path exists.

The prior deferral cited a "~250ms window that regresses instant single-tap and collides with Fn gestures." That tradeoff only exists if double-tap must coexist with single-tap inside ONE mode. Modelling it as a distinct, mutually-exclusive `TriggerStyle.doubleTap` removes the ambiguity: toggle/hold keep instant single-tap start (no regression), and in double-tap mode recording starts on the SECOND keydown with no timer and no added latency. Held-Fn chords are on FnTap's independent keyDown path, so they are untouched.

### What I changed (proposed)
- Settings.swift:25 — add `TriggerStyle.doubleTap`; convert `label`/`help` from a two-way ternary to a switch (a third case would otherwise silently mislabel); add a `chordHint` subtitle.
- AppDelegate.swift:~18 — add `fnDoubleTapArmed` / `fnDoubleTapWindow` (0.35s) state.
- AppDelegate.swift:1224 — in `fnDown()`, when style is `.doubleTap` and idle, the first tap arms a short window and returns; only a second tap within it starts recording. Timestamp-compare, no `Timer`, matching the existing `lastControlFire`/`lastOptionFire` pattern.
- AppDelegate.swift:2444 + SettingsView.swift:1331 — make the two-way "hold vs tap" subtitles three-way so the new option reads correctly.

`TriggerStyle.allCases` means the Settings picker gains the third chip with no extra UI plumbing. No exhaustive `switch` over `TriggerStyle` exists elsewhere, so nothing else breaks at compile time.

### Verify (on a Mac, once built)
1. Settings ▸ Dictation ▸ "When you press Fn" now shows three chips: Tap to toggle / Hold to talk / Double-tap. Pick Double-tap.
2. Idle: a single Fn tap does nothing; two quick Fn taps (< ~0.35s apart) start recording; a single Fn tap then stops & sends.
3. Regression check: switch back to Tap to toggle and Hold to talk — instant single-tap start still works, unchanged.
4. Interaction matrix to confirm on-device: Fn+digit / Fn+Tab / ⌥+Fn / Fn+T/Z/X while in Double-tap mode still behave; tune the 0.35s window for feel; consider adding an onboarding coach row describing double-tap.

### Self-verification checklist
- [x] Scoped to the exact OPEN part (double-tap only; 0.9.68 half untouched)
- [x] Root cause cited at file:line
- [x] Surgical: 3 files, every changed line traces to the request
- [ ] Built / run — NOT possible on this Linux host (no Xcode/device); needs a Mac
- [ ] On-device behaviour verified — pending maintainer