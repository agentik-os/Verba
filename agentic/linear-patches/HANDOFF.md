# Linear feedback triage — handoff (2026-07-18)

Analyse multi-agents (workflow `verba-linear-triage`) des 7 tickets de vrai feedback Verba desktop.
**Aucun n'est vérifié runtime** (hôte Linux, pas de Xcode/Mac). Patches = diagnostic, à réconcilier + builder + tester sur Mac.
Patches bruts + commentaires Linear complets : `agentic/linear-patches/<TICKET>.patch` et `.comment.md`.

## VER-65  — verdict **sound**, confiance 0.8
**Fichiers:** Sources/Verba/FnTap.swift, Sources/Verba/ChordMonitor.swift
**Cause racine:** The pause/resume gesture defaults to a plain Control (Ctrl) tap, wired in AppDelegate.swift:154 (FnTap.shared.onControl = ... togglePause) and AppDelegate.swift:133 (ChordMonitor fallback). Fn is the primary trigger by default (Settings.swift:924, useFnAsPrimary defaults to true), so the load-bearing path is the FnTap HID event tap.

The real defect is in the lone-Control detector, not the choice of key. In FnTap.swift:130-146 (and the mirror in ChordMonitor.swift:72-88) a Control press is treated as a pause tap unless another MODIFIER was co-present during the press: `let ctrlHasCompanion = opt || shift || cmd`. Only Option/Shift/Command count as companions. macOS binds Ctrl+Left / Ctrl+Rig
**À arbitrer:** HARD CONSTRAINT honored: no build/run/screenshot was possible (Linux host, no Xcode, no Mac). The patch is a static proposal, not runtime-verified; the Linear comment is framed honestly as such with no false "verified live" claim, so it deliberately does not satisfy the protocol's 100/100 on-device gate.

code_fixable = true: the reported bug (Ctrl+Arrow firing pause) is a real, surgical code defe

## VER-44  — verdict **sound**, confiance 0.78
**Fichiers:** Sources/Verba/NotesView.swift
**Cause racine:** In the Notes tab there is no text-entry path: a note can only be created by voice. In `Sources/Verba/NotesView.swift`, the composition entry point (`detail`, lines 420-442) renders `intro + recorderCard` whenever `selectedID == nil && !hasComposed && !busy`. `recorderCard` (lines 488-507) exposes ONLY a microphone `RecordButton`, a timer, pause control, and format chips. It contains no text field, no editor, and no affordance to type or paste.

The always-editable body editor lives in `noteEditor` (lines 719-814), whose `MarkdownEditor` is an ordinary `MDTextView: NSTextView` (MarkdownEditor.swift:270-274) that natively supports typing and Cmd+V paste. But `noteEditor` is only rendered once 
**À arbitrer:** HARD CONSTRAINT respected: no build or runtime verification was possible (Linux host, no Xcode, no device), so this is a static root-cause plus a proposed patch, not a verified fix. The Linear comment is framed honestly as PROPOSED, with no fabricated screenshots, console diffs, or audit scores, and no "RESOLVED/live" claim — do not move the ticket to Done until a maintainer builds and exercises i

## VER-41  — verdict **sound**, confiance 0.6
**Fichiers:** Sources/Verba/Settings.swift, Sources/Verba/AppDelegate.swift, Sources/Verba/SettingsView.swift
**Cause racine:** Scope: VER-41's first half (validity rule + a clear onboarding confirmation state) already shipped in 0.9.68 per the 2026-07-09 comment; the only OPEN part is "add an option for double-tap Fn besides single tap and press & hold." Root cause of the missing feature: (1) the trigger model `TriggerStyle` enum (Sources/Verba/Settings.swift:25-35) defines exactly two cases, `toggle` and `hold`, so there is no third selectable option to render; the Settings picker at Sources/Verba/SettingsView.swift:1328 iterates `TriggerStyle.allCases`, so it can only ever show two chips. (2) The primary-trigger handler `fnDown()` (Sources/Verba/AppDelegate.swift:1224-1229) unconditionally calls `startRecording(..
**À arbitrer:** Honestly framed as a PROPOSED patch: this Linux host has no Xcode and no macOS device, so the code was NOT built or run — no runtime/on-device verification was possible (never claimed). The core double-tap-to-start is surgical and compiles by inspection (no exhaustive TriggerStyle switch exists elsewhere; the picker auto-renders the third case via allCases). Two items genuinely want operator/maint

## VER-64  — verdict **sound**, confiance 0.6
**Fichiers:** Sources/Verba/AppDelegate.swift
**Cause racine:** The ticket has two distinct problems. Problem 1 (the "transcription failed" message itself) is a runtime FluidAudio/Parakeet failure whose exact cause is NOT statically determinable (model download interrupted, corrupt on-device cache, or a decode error); it is already logged server-side via ErrorReporter.report (Sources/Verba/AppDelegate.swift:1684) and VerbaLog (1683), so the real error for user ark2042/qkj2oa1c should be pulled from telemetry. Problem 2 is the "grosse friction" the user reports (voice lost, nothing in history) and IS a definite code bug: on a transcription failure, runSession's catch block calls self.purgeAudio(ctx.audioURL) at AppDelegate.swift:1690, which deletes the te
**À arbitrer:** code_fixable=true for the concrete data-loss bug (audio purged on failure), but two items need an operator/on-device decision. (1) The exact Parakeet "transcription failed" cause is a runtime FluidAudio error not determinable statically; pull the real error from ErrorReporter/VerbaLog telemetry for user ark2042/qkj2oa1c (it is already logged at AppDelegate.swift:1683-1684). (2) The user literally 

## VER-69  — verdict **sound**, confiance 0.6
**Fichiers:** Sources/Verba/Paste.swift, Sources/Verba/SettingsView.swift
**Cause racine:** The feature in the screenshot is the toggle "Deliver each dictation where you started it" (Settings.routeResultToOrigin, default ON: Settings.swift:546,894; UI at SettingsView.swift:1177). It is reachable (deliveryMode==.paste maps to autoPaste==true, SettingsView.swift:1154-1163) and the AppDelegate routing branch is wired (AppDelegate.swift:1825-1831 canRouteToOrigin, used at 1921-1933). The actual delivery goes through Output.paste(_:rich:target:) in Paste.swift.

The defect is in that paste routine's "origin not frontmost" branch (Paste.swift:273-281). It calls app.activate() then, on a FIXED 0.15s timer, restores focus and synthesizes Cmd-V, WITHOUT ever confirming the origin app actual
**À arbitrer:** Cannot build or run on this Linux host (native Swift/macOS app, no Xcode/device), so this is a static root-cause + surgical patch, NOT a runtime-verified fix. The patch is verified only in that `git apply --check` passes cleanly on both hunks against HEAD.

Confidence 0.6: the em-dash removal is certain; the feature root cause (fixed 0.15s activation delay with no frontmost confirmation before syn

## VER-67  — verdict **weak**, confiance 0.72
**Fichiers:** Sources/Verba/FeedbackView.swift
**Cause racine:** The feedback text field is a plain SwiftUI `TextEditor(text: $draft)` at Sources/Verba/FeedbackView.swift:124. A `TextEditor` is backed by an AppKit `NSTextView`, which is itself a registered drag destination for file/image types and by default inserts the dropped file's PATH as text. The Feedback panel already has the correct drop handler at FeedbackView.swift:291-294 (`.onDrop(of: [.fileURL, .image]) { handleDrop($0) }`), and handleDrop/attach (lines 584-669) already attach the real image BYTES (the VER-14 work). But because the `NSTextView` is a descendant view sitting on top of that panel-level `.onDrop`, AppKit's drag-destination hit test delivers any drop over the text area to the `NST
**À arbitrer:** Code-fixable, no operator decision needed. HARD CONSTRAINT respected: static-only, no build/run possible on this Linux host, so this is a proposed patch pending on-device verification, not a runtime-verified fix. The patch was validated with `git apply --check` (applies cleanly) but was NOT compiled or executed. Scope: VER-41 was only partial (commit 232bac9) and VER-6/VER-14 added drop-anywhere +

## VER-68  — verdict **weak**, confiance 0.7
**Fichiers:** Sources/Verba/FeedbackView.swift
**Cause racine:** The user's AI-rewriting backend resolves to the on-device local model qwen3:8b ("Qwen") because a Parakeet + Automatic user has no Claude Code CLI and no API key (Settings.swift:147-150, Settings.swift:885). "Improve with AI" in the feedback panel hard-depends on that local model: improveWithAI -> Reprompter.reprompt -> .localLLM -> LocalLLM.chat (FeedbackView.swift:486-572, Reprompter.swift:125-126). The ~5GB Ollama model is almost certainly NOT installed on this Mac (consistent with the user never seeing a download bar): the visible progress bar only appears in the "Fully local" onboarding card (OnboardingView:300) and in Settings, never in the feedback surface, and the silent launch-time 
**À arbitrer:** DIAGNOSIS is high-confidence from a clean static trace. The proposed patch is surgical (one file, FeedbackView.swift) and defensible, but it does NOT by itself make "Improve with AI" succeed: the ~5GB on-device qwen3:8b model must finish downloading first, which is an environmental condition this host cannot verify (Linux, no Xcode, no device, cannot build or run the macOS app). OPERATOR DECISIONS
