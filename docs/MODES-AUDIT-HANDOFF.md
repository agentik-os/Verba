# Dictation modes audit, handoff for the serial pass

Scope of the worker that produced this: `Sources/Verba/ModesView.swift`,
`ModeGenerator.swift`, `TransformPicker.swift`, `FnTap.swift`. Everything below that lives in
another file was traced and verified read-only, never edited.

Every line reference was read directly, not inferred.

## 1. Why "Intent and the modes are broken even though the UI exists"

The chain, verified end to end:

1. `Settings.init` seeds the feature set exactly once. A brand-new install has no `onboarded` key,
   so `existingUser` is false and `enabledFeatures` is seeded to the **empty set**
   (`Settings.swift:872-879`). Nothing else in the tree ever writes `enabledFeatures` except the
   user tapping a toggle: the only writers are `setFeature` / `enableAllFeatures`
   (`Settings.swift:780-784`), called from `FeaturesView.swift:68,123,169,173`. `OnboardingView`
   finishes with `onboarded = true` only (`OnboardingView.swift:737-740`); no entitlement, sync or
   migration path turns a feature on.
2. `visibleProfiles` therefore drops every mode whose name is not in
   `level1ModeNames = {Raw, Polish, Translate, Prompt}` (`Settings.swift:789-794`, `:496`).
3. Every mode-switching gesture reads `visibleProfiles`: Fn+Tab cycling `AppDelegate.swift:1318`,
   Fn+digit `:1387`, the overlay picker `:1471` and `:1563`, the menu-bar mode list `:2308`, redo
   `:2356`, the Fn cheat sheet `:2512`, the Home strip `Sections.swift:94`.

Net effect on a fresh install: **Intent, Context and every user-created custom mode can never be
reached by any shortcut or picker.** They are still listed as ordinary modes in Settings > Modes,
which iterates `settings.profiles` (`ModesView.swift:76`), and onboarding actively advertises Intent
as the power mode (`OnboardingView.swift:604-605`).

Correction worth keeping: those modes are not dead, only un-gesture-able. Three surfaces bypass
`visibleProfiles` and will genuinely run a gated mode: the "Use this mode" chip
(`ModesView.swift:452-455`), app auto-match (`Settings.swift:1353-1358`, `autoDetectProfile`
defaults true at `:921`), and the AdaptPanel chips (`AdaptPanel.swift:24-25`).

**Fixed in scope:** `ModesView` now marks such a mode "Locked" and offers a one-tap
"Turn on Advanced modes" (`settings.setFeature(FeatureFlags.advancedModes, true)`, the same call
`FeaturesView` makes). The predicate mirrors both filters of `visibleProfiles`, including
`isModeEnabled`, so a mode the user hid himself is not offered a remedy that would do nothing.

**Not fixable in scope, for the serial pass to decide:** whether a fresh install should seed
`advancedModes` on, or whether onboarding should surface it, given that onboarding sells Intent.
That decision belongs in `Settings.swift:872-879` / `OnboardingView.swift`.

## 2. Built-in `Profile` statics mint a fresh id every launch

`Profile` declares `var id: UUID = UUID()` (`Settings.swift:256`) and none of the built-in statics
hard-codes an id (`Settings.swift:324, 356, 362, 385, 401, 426`). Their sibling types deliberately
do the opposite and say why: `Style.normal` (`Settings.swift:298-302`) and `NoteFormat.allBuiltIn`
(`NoteFormats.swift:22-24, 51`).

Consequence: `Profile.prompt.id` matches a persisted profile only during the one run that seeded the
defaults. The launch merge keeps the SAVED id (`Settings.swift:1097`, `u.id = S.id`), so it never
converges back. Assigning such an id to `activeProfileID` makes `activeProfile` fall through to
`profiles.first` with no signal (`Settings.swift:764-766`) and persists an id that resolves to
nothing (`didSet`, `Settings.swift:678`).

**Fixed in scope:** `ModesView.demoteIfActiveBlanked` no longer falls back to `Profile.prompt.id`,
and the enabled-state lookup no longer passes `Profile.prompt` as a placeholder. Those were the only
two references to a built-in static's identity outside `Settings.swift`; the third
(`ModesView.swift:619`) reads `Profile.custom.systemPrompt`, a value, and is fine.

**For the serial pass:** consider hard-coding the built-in `Profile` ids the way `Style` and
`NoteFormat` already do. That is a `Settings.swift` change and it would need a migration that maps
existing saved ids, so it was deliberately not attempted here.

## 3. Findings outside the four in-scope files, ranked by what bites first

1. **`AppDelegate.swift:154` + `:2131-2139`** - `onDigitOutOfRange` is wired to `flashInfo`, which
   unconditionally sets `overlay.model.recording = false` and `state = .idle`. Pressing Fn plus a
   digit with no mode at that index **while recording** drops the state machine to idle while the
   recorder and level timer keep running; the next Fn tap then calls `recorder.start()` on a busy
   recorder. The trigger is `FnTap.swift:240`, but FnTap cannot know the recording state, so the
   guard belongs in the handler.
2. **`AppDelegate.swift:1401-1405`** - `fnDigit` calls `startRecording(forced: p)` before writing
   `activeProfileID`, while `startRecording` checks the entitlement against the OLD active profile
   (`AppDelegate.swift:1534`). Fn+digit into an AI mode from Raw bypasses the free limit; Fn+digit
   into Raw from an AI mode paywalls a mode that is free forever.
3. **`ChordMonitor.escapeShouldCancel` is never assigned** (declared `ChordMonitor.swift:14`, read
   `:115`; the only assignment in the tree is the FnTap one at `AppDelegate.swift:165`). The branch
   returns early forever, so for a user who has not made Fn the primary trigger, Esc never cancels
   and the overlay's "Cancel (Esc)" help (`Overlay.swift:147`) is false.
4. **`changeMode()` has no call sites** (`AppDelegate.swift:1304`), so `overlay.model.menu` is never
   set true, so `FnTap.menuActive` is never true, so `FnTap.onArrow` and `FnTap.onEnter`
   (`FnTap.swift:248-252`) are dead, the numbered picker (`Overlay.swift:332`) never renders, and
   the SettingsView toggle at `:1356-1364` that promises "a numbered picker instead" is a dead
   switch.
5. **`Pipeline.swift:127` resolves the profile AFTER transcription** when `forcedProfile` is nil
   (the configurable global shortcut and the menu-bar toggle). A mode switch during the processing
   window, including the automatic sticky writeback of a different concurrent session
   (`AppDelegate.swift:1856-1860`), retroactively changes the mode of the in-flight dictation, and
   the session label computed at stop time (`AppDelegate.swift:1640-1641`) then disagrees with what
   ran.
6. **No empty-prompt guard in the pipeline.** `Pipeline.swift:162` sends
   `profile.effectiveSystemPrompt` verbatim. The only guards are the two in `ModesView`
   (`hasUsablePrompt` / the disabled "Use this mode" chip); every other activation path bypasses
   them, and `ConfigSync.swift:322` can materialise a profile with `systemPrompt: ""` from a remote
   row.
7. **Auto-match ignores both the enabled flag and the empty-prompt rule.**
   `Settings.swift:1353-1358` searches all `profiles`, not `visibleProfiles`, so a mode hidden with
   the eye toggle still drives dictation for its bundle ids, and two profiles claiming the same
   bundle id resolve by array order with no warning.
8. **`resetProfilesToDefaults()` (`Settings.swift:1318-1321`) leaves `disabledModeIDs` and
   `modeGroups` pointing at dead UUIDs.** A group activated after a restore disables every mode
   except Raw (`Settings.swift:805-812`).
9. **Per-mode hotkeys are stored, edited and cloud-synced but never registered.** Built-ins still
   carry `hotkeyCode`/`hotkeyMods` (`Settings.swift:354, 359, 388, 399, 423, 456`) and
   `Settings.holder(ofKey:mods:)` still treats them as holders (`Settings.swift:1283-1284`), while
   `applyTriggers` registers ids 1 and 3-14 only (`AppDelegate.swift:863-965`). `Sections.swift:91`
   still advertises "use Ctrl-Opt-1-6 for a specific mode".
10. **The transform picker has no reliable Esc during `.working`.**
    `FnTap.escapeShouldCancel` (`AppDelegate.swift:165-176`) lists the todo glance and the action
    feed but not `TransformPickerController.shared.isShowing` or `transformInFlight`, and `state`
    stays `.idle` during a transform (`AppDelegate.swift:1222-1225`). So the predicate is false, Esc
    is not consumed, and the picker is left with only its own local monitor, which the code itself
    documents as unreliable when the panel cannot take key focus (`AppDelegate.swift:1132-1135`).
    The picker's own Esc also hides the panel without cancelling `transformTask`, so the transform
    still pastes over the selection afterwards (`TransformPicker.swift:196` vs
    `AppDelegate.swift:1118`).
11. **Empty transform prompts are unguarded on the Opt-X and Services paths.**
    `TransformsStore.selectionSystemPrompt` (`Stores.swift:614-616`) turns an empty prompt into a
    bare "Output ONLY the transformed text", and the result is pasted over the user's selection
    (`AppDelegate.swift:1118`). The voice path is protected only by accident: `match` filters on the
    empty NAME (`Stores.swift:594`), not the prompt.

## 4. NoteFormats dependency surface

Requested explicitly for the serial pass. Verified by repo-wide grep for `NoteFormat`,
`NoteModesStore` and `noteModes`.

**None of the four in-scope files depends on NoteFormats.swift.** `ModesView.swift`,
`ModeGenerator.swift`, `TransformPicker.swift` and `FnTap.swift` have zero references, and so does
the whole transform execution path (`AppDelegate.showTransformPicker` / `runTransformOnSelection`
-> `TransformsStore.runOnSelectionSync` -> `Reprompter.reprompt`).

Outbound: only `NotesView.swift` and `NoteModesView.swift` consume it.

Inbound, and this is the one that matters for whoever owns `Settings.swift`:
`NoteFormat.fromProfile(_:)` (`NoteFormats.swift:88-96`) reads a dictation `Profile` and its
`effectiveSystemPrompt` (`Settings.swift:272-285`). Changing the shape of `Profile` or the semantics
of `effectiveSystemPrompt` changes note formats too. `NotesView.quickActionModes`
(`NotesView.swift:956-962`) merges note modes with bridged non-builtin dictation modes and drops a
dictation mode whose NAME collides with a note mode, silently.

Two independent things are both called "Intent" and they are not the same object:
`Profile.intent` (`Settings.swift:324-354`), whose intent is spoken at the head of the transcript
and which has no special-casing anywhere in `Pipeline.swift`, and `NoteFormat.intent`
(`NoteFormats.swift:50-63`), which has a real stored `intent: Bool` and takes a typed instruction
through `effectiveSystemPrompt(instruction:)` (`NoteFormats.swift:69-78`), consumed at
`NotesView.swift:1226-1234`. There is no typed-intent classification step in the dictation pipeline
at all; `Profile.intent` is a system prompt and nothing more.

Note modes are also the only one of the three prompt-bearing entities that is not cloud-synced:
`ConfigSync` carries modes, styles, snippets, transforms, dictionary and tasks
(`ConfigSync.swift:4`), never `noteModes`.

## 5. Verification status

`swift build -c debug` **could not be run**: this worktree is on Linux
(`Linux 6.8.0-124-generic x86_64`) and the package targets `.macOS(.v14)` with WhisperKit, FluidAudio
and Sparkle. `command -v swift` and `command -v swiftc` both return nothing; `swiftlint`,
`swift-format`, `sourcekit-lsp` and `xcrun` are all absent as well. The exact unavailable command is
`swift build -c debug` (`/bin/bash: line 9: swift: command not found`).

What was run instead: a per-file delimiter balance check against `HEAD` (braces, parens and quotes
all balanced in both edited files), a grep proof that every symbol the new code calls exists
(`Settings.isFeatureEnabled` `:779`, `Settings.setFeature` `:780`, `Settings.level1ModeNames` `:496`,
`FeatureFlags.advancedModes` `:478`, `glassButton` / `glassCard` in `Glass.swift:192` / `:156`), a
grep proof that the removed `showWorking` had no callers, and a grep proof that no reference to a
built-in `Profile` static's `.id` remains anywhere in `Sources/`.

**A macOS compile is still required before this is considered green.**
