## Fix Verification Report

**Ticket:** VER-44 — Section: Mode notes (cannot create a note without voice dictation)
**Mode:** FIX
**Status:** PROPOSED FIX, pending on-device verification (static root-cause + patch; not yet built or run)

> Honest scope note: this analysis and patch were produced on a Linux host with no Xcode and no Mac device, so the fix has NOT been compiled or exercised on a build. No before/after screenshots, console diff, or audit run are claimed. Everything below is static (source-level) evidence per file:line. A maintainer must build and verify on-device before this moves to Done.

### What was requested
> Section: Mode notes
> Issue: Cannot create a note without using voice dictation
> Expected: Ability to create a note by writing or copying and pasting directly

### Root cause
The Notes tab has no text-entry path; voice is the only way in. In `Sources/Verba/NotesView.swift` the compose screen (`detail`, lines 420-442) shows `recorderCard` (lines 488-507) whenever `selectedID == nil && !hasComposed && !busy`. That card exposes only the mic record button, a timer, pause, and format chips: no text field, no editor.

The editable body editor lives in `noteEditor` (lines 719-814); its `MarkdownEditor` is a plain `NSTextView` subclass (`MDTextView`, MarkdownEditor.swift:270-274) that already supports typing and Cmd+V paste. But `noteEditor` renders only when `hasComposed == true` or a saved note is selected. `hasComposed` is latched solely by `markComposedIfNeeded()` (lines 947-955), which reacts to `editorText` / `noteTitle` / `noteTags` edits, and those fields exist only inside `noteEditor`. The one code path that fills `editorText` from the compose screen is transcription (`transcribe` -> line 1169 -> `applyFormat` -> line 1203). So without a recording the user can never reach the editor: text and paste creation are impossible.

### What I changed
- `NotesView.swift` recorderCard (after line 500) — added a "Write it instead" button, shown while not recording.
- `NotesView.swift` (new `writeInsteadButton`, ~line 509) — a keyboard-icon capsule button that calls `startTypedNote()`.
- `NotesView.swift` (new `startTypedNote()`) — starts a fresh empty draft via `newNote()`, then sets `hasComposed = true` to reveal the editable editor, and best-effort focuses the body so the user can type or paste at once.

The editor and the existing debounced autosave (`autosaveCommit`, line 1020, which persists any non-empty `editorText`) are reused verbatim, so a typed or pasted note saves through the same path as a dictated one. No changes to `NotesStore` or the save model. The voice-first default is unchanged; the new button is an additional path, reachable from every "New note" entry point since they all route through `recorderCard`.

### Before / After (static, source-level)
| | Before | After |
|---|---|---|
| Compose screen | recorderCard renders mic button + format chips only (lines 488-507); no text field or editor reachable | recorderCard additionally renders "Write it instead"; tapping it sets `hasComposed = true` so `detail` renders `noteEditor` with the editable `MarkdownEditor` (typing + paste) |
| Text/paste note creation | impossible (only `transcribe` writes `editorText`) | possible: type or paste into the editor -> `scheduleAutosave` -> `autosaveCommit` -> `store.add` |

### Verify (on device — required before Done)
Build the app (`./bundle.sh`), open the Notes tab, then:
1. On the compose screen, click "Write it instead": the editor should appear on an empty draft.
2. Type a note, and separately paste text with Cmd+V: both should appear in the body.
3. Confirm the note autosaves and shows in the left sidebar list (as an untitled or titled note).
4. Confirm voice recording still works unchanged, and "New note" from the sidebar / editor returns to the card that now shows the button.
Device from the report: macOS 26.3, app 0.9.68.

### Self-verification checklist
- [x] Root cause identified and cited to file:line
- [x] Patch is surgical: one file, additive, reuses the existing editor + autosave
- [x] Patch verified to apply cleanly to the current source (git apply --check)
- [ ] Built on macOS (NOT possible on this host — pending maintainer)
- [ ] Exercised on-device: type + paste create and save a note (pending)