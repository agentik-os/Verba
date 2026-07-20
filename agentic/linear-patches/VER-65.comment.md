## Fix Verification Report (PROPOSED FIX, pending on-device verification)

**Ticket:** VER-65 - Pause key default (Control) collides with macOS Ctrl+Arrow desktop switching
**Mode:** FIX
**Status:** Proposed patch attached. NOT yet built or run on a device. This analysis was done statically on a Linux host with no Xcode and no Mac, so no build, screenshot, or on-device capture was possible. No "verified live" claim is made.

### What was requested
> par defaut j'ai l'impression que la touche qui est utilisee pour faire pause sur les prompts c'est controle sauf que sur un MacBook lorsqu'on utilise la touche controle avec des fleches c'est pour naviguer dans les bureaux. [...] on navigue vers un autre bureau pour avoir le contexte [...] et en fait ca met en pause l'enregistrement. Ce n'est pas du tout ce qu'on veut, en tout cas par defaut.

### Root cause
The pause/resume gesture is a plain Control tap (default), owned by the Fn HID event tap `FnTap` (Fn is the default primary trigger). The lone-Control detector in `FnTap.swift:130-146` only treats another MODIFIER (Option, Shift, Command) as a "companion" that disqualifies a Control press from being a pause tap: `let ctrlHasCompanion = opt || shift || cmd`. macOS binds Ctrl+Left / Ctrl+Right to desktop/Space switching, and arrow keys are ordinary key presses, not modifier flags, so they never set the combo latch. Result: pressing Ctrl+Arrow to switch desktop mid-dictation releases as a phantom lone-Control tap and pauses recording. The same gap exists in the `ChordMonitor` NSEvent fallback (`ChordMonitor.swift:72-88`).

### What I changed
- `Sources/Verba/FnTap.swift` (keyDown case, after line 182): while Control is held, any keyDown now latches the current Control press as a combo (`optSeenDuringCtrl = true`), so its release no longer fires pause. Ctrl+Arrow (and every Ctrl+key system shortcut) stops triggering pause; a genuine bare Control tap still pauses. Arrows are not consumed, so Space switching keeps working.
- `Sources/Verba/ChordMonitor.swift` (top of handleKey): the same latch for the fallback path (used only when the Fn tap is inactive). Note: global NSEvent monitors are best-effort and may not observe Ctrl+Arrow if the WindowServer consumes it first, so this mirror is a hardening, not a guarantee; the FnTap head-insert path is the reliable one and is the default.

### Why this is the right fix (challenging the ticket's premise, L2)
The ticket proposes changing the default key away from Control. The actual defect is narrower: the collision detector is incomplete. After this patch, no Ctrl+key combination fires pause anymore, only a bare Control tap does, and a bare Control tap collides with nothing in macOS. This resolves the reported pain without a subjective new-key choice.

### Open design decision for the operator
Whether to ALSO feature a different default pause key (for discoverability, not to fix the bug) is a product/UX call. It would touch onboarding copy (`OnboardingView.swift:500,517,534,620,627-628`) and add a non-Control default. Recommended only if desired; not required to close this bug.

### Verify (on a Mac, once built)
1. Start a dictation. 2. Press Ctrl+Left / Ctrl+Right to switch desktop. Expected AFTER fix: desktop switches, recording keeps running (no pause). 3. Tap Control alone: still pauses/resumes.

### Self-verification checklist
- [x] Root cause located at file:line with the exact incomplete condition
- [x] Surgical patch touches only the two root-cause files
- [ ] Built and run on device (NOT possible on this host; pending maintainer)
- [ ] BEFORE/AFTER capture (NOT possible on this host)