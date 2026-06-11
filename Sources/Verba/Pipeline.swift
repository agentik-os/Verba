import Foundation
import NaturalLanguage

/// Thrown when a stage (transcription / reprompt) runs past its deadline so a hung
/// backend can't spin the overlay forever. Surfaced to the user as a clear error.
struct TimeoutError: LocalizedError {
    var errorDescription: String? { "Timed out — the backend took too long. Try again." }
}

/// Run `operation` but give up after `seconds`. The CALLER is guaranteed to resume at the
/// deadline (or on its own cancellation) even when the operation ignores cooperative
/// cancellation — a structured task group would AWAIT its children, so a hung
/// non-cancellable backend (e.g. a wedged Core ML local transcription) would spin past the
/// ceiling forever. Instead the operation races a deadline through a continuation:
/// whichever fires first resumes the caller exactly once, and the laggard is cancel()led
/// best-effort.
///
/// LEAK TRADEOFF (deliberate): a laggard that never honors cancellation is ABANDONED — it
/// keeps running detached and holds its resources (CPU, model memory) until it finishes or
/// the process exits. That bounded leak is the price of never wedging the overlay/session
/// past the timeout; the alternative (awaiting the hung child) wedges the whole pipeline.
/// One-shot, lock-guarded race state for `withTimeout`: exactly one of {operation, deadline,
/// caller cancellation} resumes the continuation; late arrivals are dropped. Also tolerates
/// the cancellation handler firing BEFORE the continuation is registered (the result is
/// parked in `pending` and delivered at registration).
private final class TimeoutRace<V: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<V, Error>?
    private var pending: Result<V, Error>?
    private var worker: Task<Void, Never>?
    private var timer: Task<Void, Never>?

    func register(_ c: CheckedContinuation<V, Error>) {
        lock.lock()
        if let r = pending { lock.unlock(); c.resume(with: r); return }
        continuation = c
        lock.unlock()
    }
    func setTasks(worker w: Task<Void, Never>, timer t: Task<Void, Never>) {
        lock.lock()
        let alreadyOver = pending != nil
        worker = w; timer = t
        lock.unlock()
        if alreadyOver { w.cancel(); t.cancel() }   // cancelled before the racers were stored
    }
    /// First result wins: resumes the caller (or parks the result) and cancels both racers.
    func finish(_ r: Result<V, Error>) {
        lock.lock()
        guard pending == nil else { lock.unlock(); return }
        pending = r
        let c = continuation; continuation = nil
        let w = worker; let t = timer
        lock.unlock()
        w?.cancel(); t?.cancel()
        c?.resume(with: r)
    }
}

func withTimeout<T: Sendable>(seconds: Double,
                              operation: @escaping @Sendable () async throws -> T) async throws -> T {
    let race = TimeoutRace<T>()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
            race.register(cont)
            let worker = Task {
                do { race.finish(.success(try await operation())) }
                catch { race.finish(.failure(error)) }
            }
            let timer = Task {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                race.finish(.failure(TimeoutError()))   // worker is cancelled best-effort; see leak note
            }
            race.setTasks(worker: worker, timer: timer)
        }
    } onCancel: {
        // The caller's Task was cancelled (Esc): resume it NOW with CancellationError instead
        // of making it wait out the deadline; both racers are torn down best-effort.
        race.finish(.failure(CancellationError()))
    }
}

struct PipelineResult {
    var original: String
    var reprompted: String
    var profileName: String
    var profileID: UUID? = nil         // the mode actually used (for "remember last used mode")
    var engine: String
    // Context mode + Labs "Agentic actions": when the spoken request is an actionable command
    // (create an event / reminder / draft an email), the vision model returns a structured action
    // instead of text. Non-nil here means the caller must CONFIRM and execute it rather than paste.
    var action: VerbaAction? = nil
    // Set when the dictation produced a SIDE-EFFECT (e.g. "add to dictionary" on a selection) rather
    // than text to deliver. Non-nil means: do NOT paste/replace the selection — just flash this
    // confirmation. `reprompted` is left as the original transcript and is not delivered.
    var notice: String? = nil
}

/// record → transcribe → (Claude reprompt) → result. Output/side-effects handled by the caller.
enum Pipeline {
    static func run(audioURL: URL,
                    frontmostBundleID: String?,
                    forcedProfile: Profile?,
                    selection: String? = nil,
                    editLast: Bool = false,
                    actionMode: Bool = false,
                    status: @escaping (String) -> Void) async throws -> PipelineResult {
        let s = Settings.shared

        // 1. Transcribe with the selected engine.
        status(s.engine.isLocal ? "Transcribing locally…" : "Transcribing…")
        let lang = s.language.isEmpty ? nil : s.language
        let transcriber: Transcriber
        switch s.engine {
        case .openAI:   transcriber = OpenAITranscriber()
        case .whisper:  transcriber = LocalTranscriber.shared
        case .parakeet: transcriber = ParakeetTranscriber.shared
        }
        var original = try await transcriber.transcribe(fileURL: audioURL, language: lang,
                                                         hint: DictionaryStore.shared.hint())
        // Apply custom dictionary spellings to the raw transcript.
        original = DictionaryStore.shared.apply(to: original)
        // Voice commands ("new line", "comma", "scratch that", …) → real formatting.
        if s.voiceCommands { original = VoiceCommands.apply(original) }

        // 2. A dedicated-shortcut profile wins; else auto-detect / active profile.
        let profile = forcedProfile ?? s.profile(forBundleID: frontmostBundleID)
        var reprompted = original
        // Context mode + Labs "Agentic actions": set when the vision model resolves the spoken
        // request into a structured, confirmable action instead of plain screen-grounded text.
        var detectedAction: VerbaAction? = nil
        // True when an instruction-driven branch (verbal shortcut or selection instruction) produced
        // `reprompted`, so its result is an LLM rewrite that may legitimately be bilingual on request.
        // Edit-last is tracked separately via `editingLast`. The language-consistency guard below uses
        // both to skip normalization, which must only fix engine code-switching of plain dictation —
        // never undo a deliberately mixed-language result the user explicitly asked for.
        var wasInstruction = false
        let sel = selection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Edit-last is an EXPLICIT spoken instruction acting on the previous result, so it must
        // run the LLM in EVERY mode — including Flow/raw and when reprompting is globally off
        // (those gates exist to keep ordinary dictation untouched, not to kill an explicit edit).
        let editingLast = editLast && !sel.isEmpty
        // VER-15: the user picked an AI mode (NOT a raw/Flow mode) but "Rewriting with Claude" is
        // globally OFF — so the mode's whole purpose (rewrite / translate / context / selection
        // instruction) can't run and we'd otherwise silently paste the raw transcript, leaving the
        // user thinking the mode did nothing. Surface a clear notice telling them to turn rewriting
        // on, and DON'T deliver the unprocessed transcript (notice == no paste, see finish()).
        // Edit-last is exempt: it always reprompts regardless of the global toggle (see above), so
        // it never hits this branch.
        if !profile.raw && !s.repromptEnabled && !editingLast {
            return PipelineResult(
                original: original,
                reprompted: original,
                profileName: profile.name,
                profileID: profile.id,
                engine: engineLabel(s),
                notice: "AI rewriting is off — enable it in Settings to use “\(profile.name)”")
        }
        // Raw/Flow mode (or reprompting off) → return the transcript untouched, no Claude —
        // EXCEPT for an explicit edit-last instruction, which always reprompts (see above).
        if (s.repromptEnabled && !profile.raw) || editingLast {
            var sys = profile.effectiveSystemPrompt   // Translate mode injects its target language
            // Primary-language default: bias ambiguous output to the user's everyday language without
            // overriding a clearly-spoken other language. Never on Translate (it owns the target).
            if profile.targetLanguage == nil, let dir = s.languageDirective {
                sys += "\n\n\(dir)"
            }
            // Active STYLE layer: a tone/format nudge applied on top of the mode. The built-in
            // "Normal" style has an empty prompt, so it changes nothing (default behaviour).
            let style = s.activeStyle.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            if !style.isEmpty {
                sys += "\n\nADDITIONAL STYLE PREFERENCES (apply while staying faithful): \(style)"
            }
            sys += SnippetsStore.shared.promptContext()   // intent-based snippet insertion
            // Dictionary ↔ prompting link: tell Claude to PRESERVE the user's exact custom
            // spellings / branding (already fed to transcription via hint() + applied via apply()),
            // so the rewrite doesn't "correct" a brand like "Verba" or a specific capitalization.
            sys += DictionaryStore.shared.preservePromptContext()

            // #5 Tone match: feed a few of the user's recent messages in THIS app as style
            // examples, so the rewrite mimics how they actually write here.
            if s.toneMatch {
                let examples = ToneStore.examples(bundleID: frontmostBundleID)
                if !examples.isEmpty {
                    let block = examples.enumerated().map { "Example \($0.offset + 1):\n\($0.element)" }.joined(separator: "\n\n")
                    sys += "\n\nTONE MATCH: here are recent messages the user wrote in this app. Match their tone, vocabulary, formality and rhythm (NOT their content):\n\n\(block)"
                }
            }
            // If the result will be pasted as RICH text (Paste with formatting / render
            // Markdown is on for the target app), ask the model to PRODUCE Markdown structure
            // so headings/bold/lists exist to render. Skipped for Translate modes (self-contained
            // prompt) and when formatting is off, so plain mode stays a plain block.
            if profile.targetLanguage == nil, Output.willPasteRich(frontmostBundleID) {
                sys += markdownFormattingAddendum
            }

            let r = Reprompter(model: profile.model ?? s.claudeModel)   // per-mode model override

            // BRANCH PRECEDENCE (first match wins — ordered most-specific → general):
            //   1. edit-last        — explicit "Edit last by voice" action; the transcript is an
            //                          instruction acting on the PREVIOUS result. Must work in EVERY
            //                          mode (incl. Translate / Context-Vision), so it is checked FIRST
            //                          and uses its own channel — it is NOT gated by targetLanguage /
            //                          vision the way the selection branches below are.
            //   2. vision           — Context mode: screenshot + spoken request → vision model.
            //   3. verbal shortcut  — text selected + a short phrase matching a saved Transform.
            //   4. selection inst.  — text selected + a spoken instruction about it.
            //   5. normal reprompt  — plain dictation → mode's system prompt.
            // Vision is below edit-last (editing prior text shouldn't trigger a screenshot); the two
            // selection branches stay gated to non-Translate modes (Translate always translates the
            // spoken words), but edit-last is deliberately exempt from that gate.
            if editingLast {
                // Edit-last: the dictation is an INSTRUCTION applied to the last delivered result
                // (the text to edit arrives via `selection`). Works in ALL modes — Translate,
                // Context/Vision, and Flow/raw (or reprompting off) included — by routing through
                // its own dedicated prompt rather than the mode-gated selection-instruction channel.
                status("Editing your last result…")
                sys += """


                EDIT-LAST MODE, OVERRIDE: The user wants to EDIT the previous result shown below. \
                Treat the transcript as a spoken instruction to apply to that text \
                (rewrite/shorten/translate/transform it, or answer their request about it). \
                Output ONLY the resulting text that should REPLACE the previous result, no preamble, \
                no quotes, no commentary. Keep the user's language unless they ask otherwise.
                """
                let userText = "PREVIOUS RESULT:\n<<<\n\(sel)\n>>>\n\nSPOKEN INSTRUCTION:\n\(original)"
                reprompted = try await r.reprompt(transcript: userText, systemPrompt: sys)
            } else if profile.vision || actionMode {
                // Context mode (or the dedicated Action mode, Fn+X): the spoken request → an intent
                // model → clean text to insert, OR a structured action.
                //
                // The screenshot is CONDITIONAL. Context mode (the vision profile) is explicitly a
                // screen-grounded mode, so it always captures. The dedicated Action mode (Fn+X) is a
                // voice-command mode: most commands ("open Spotify", "create an event tomorrow 3pm",
                // "run my Morning Routine shortcut", "remind me to…") are self-contained and need NO
                // screen, so we only capture when the transcript is plausibly screen-grounded (mentions
                // "this"/"screen"/"selected"/"reply to this"/"what's on", etc — see commandNeedsScreen).
                // This means Action mode works WITHOUT Screen Recording for self-contained commands.
                let wantsScreen = profile.vision || commandNeedsScreen(original)
                // Only capture if we want the screen AND we can. In Action mode with the permission
                // off, we DON'T hard-fail every command: we fall back to a screenless intent pass so
                // self-contained commands keep working, and surface a prompt only if the command truly
                // needed the screen (handled below). Context mode keeps the hard requirement.
                var png: Data? = nil
                if wantsScreen {
                    if ScreenCapture.hasPermission() {
                        status("Looking at your screen…")
                        guard let shot = await ScreenCapture.capturePNG(), !shot.isEmpty else {
                            throw RepromptError.http(0, "Couldn't capture the screen. If Screen Recording was just enabled, quit and reopen Verba, then try again.")
                        }
                        png = shot
                    } else if profile.vision {
                        // Context mode is inherently screen-grounded — without the permission it can't run.
                        ScreenCapture.requestPermission()
                        ScreenCapture.openPrivacySettings()
                        throw RepromptError.http(0, "Context mode needs Screen Recording. Enable Verba in System Settings ▸ Privacy & Security ▸ Screen Recording, then try again.")
                    } else {
                        // Action mode + a screen-grounded command, but no Screen Recording: prompt the
                        // user to enable it rather than silently running blind on a request that needs
                        // the screen ("reply to this", "what's on screen").
                        ScreenCapture.requestPermission()
                        ScreenCapture.openPrivacySettings()
                        throw RepromptError.http(0, "That command needs to see your screen. Enable Verba in System Settings ▸ Privacy & Security ▸ Screen Recording, then try again — or phrase a self-contained command (e.g. “open Spotify”, “create an event tomorrow at 3pm”).")
                    }
                }
                status(Quips.current())
                // Labs "Agentic actions": ask the model to return EITHER a structured action OR
                // plain text. When a screenshot is attached (screen-grounded request) it goes to the
                // vision model (so "draft a reply to this email" can read the on-screen email); for a
                // self-contained command we run a screenless text intent pass instead. Parse robustly;
                // ANY parse failure falls back to treating the whole reply as text, so a result is
                // never lost. The agentic-action path runs when Labs "Agentic actions" is on OR in the
                // dedicated Action mode (Fn+X), which forces it regardless of the Labs toggle. The
                // model is given the user's actual Shortcuts so it can match a request to a real name.
                if s.agenticActions || actionMode {
                    let shortcuts = ActionExecutor().availableShortcuts()
                    let agenticSys = sys + agenticActionsAddendum(shortcuts: shortcuts, actionFirst: actionMode)
                    let raw: String
                    if let png {
                        raw = try await r.repromptVision(transcript: original, systemPrompt: agenticSys, imagePNG: png)
                    } else {
                        raw = try await r.reprompt(transcript: original, systemPrompt: agenticSys)
                    }
                    if let action = parseAgenticAction(raw), s.isActionEnabled(action.kind) {
                        detectedAction = action
                    } else {
                        reprompted = extractAgenticText(raw)
                    }
                } else if let png {
                    reprompted = try await r.repromptVision(transcript: original, systemPrompt: sys, imagePNG: png)
                } else {
                    // Non-agentic Context mode always captures (wantsScreen is true), so png is
                    // non-nil above. This arm is unreachable, but keeps the result defined.
                    reprompted = try await r.reprompt(transcript: original, systemPrompt: sys)
                }
            } else if !sel.isEmpty && profile.targetLanguage == nil,
                      let transform = TransformsStore.shared.match(transcript: original) {
                // Verbal Shortcut: the user selected text and spoke a short phrase that matches
                // a saved Transform (e.g. "fix grammar", "translate to English"). Auto-run that
                // transform's own prompt on the selection. Works in ALL modes. Longer/clearly
                // full instructions don't match (see TransformsStore.match) and fall through.
                if TransformsStore.isAddToDictionary(transform) {
                    // "Add to dictionary" shortcut: this is a SIDE-EFFECT, not a rewrite. Add the
                    // selected word(s) to the Dictionary preserving their exact written form (so
                    // their spelling/branding survives future transcription + reprompting) and
                    // surface a confirmation. Never replace the user's selection.
                    let added = await MainActor.run { DictionaryStore.shared.addUserTerm(sel) }
                    let short = sel.count > 40 ? String(sel.prefix(40)) + "…" : sel
                    return PipelineResult(
                        original: original,
                        reprompted: original,
                        profileName: profile.name,
                        profileID: profile.id,
                        engine: engineLabel(s),
                        notice: added ? "Added “\(short)” to Dictionary" : "Already in Dictionary")
                }
                status("Working on your selection…")
                wasInstruction = true
                reprompted = try await r.reprompt(
                    transcript: sel,
                    systemPrompt: TransformsStore.selectionSystemPrompt(for: transform))
            } else if !sel.isEmpty && profile.targetLanguage == nil {
                // Selection mode: the dictation is an INSTRUCTION acting on the selected text.
                // (Skipped for Translate modes — they always translate the spoken words.)
                status("Working on your selection…")
                sys += """


                SELECTION MODE, OVERRIDE: The user has TEXT SELECTED in their editor and \
                is giving you a spoken instruction about it. Treat the transcript as an \
                instruction to apply to the selected text (rewrite/translate/transform it, \
                or answer their question about it). Output ONLY the resulting text that \
                should REPLACE the selection, no preamble, no quotes, no commentary. \
                Keep the user's language unless they ask otherwise.
                """
                wasInstruction = true
                let userText = "SELECTED TEXT:\n<<<\n\(sel)\n>>>\n\nSPOKEN INSTRUCTION:\n\(original)"
                reprompted = try await r.reprompt(transcript: userText, systemPrompt: sys)
            } else {
                status(Quips.current())   // fun, ever-changing geek line instead of "Restructuring…"
                reprompted = try await r.reprompt(transcript: original, systemPrompt: sys)
            }
        }

        // Raw/Flow mode (no AI) → fall back to literal snippet expansion. In AI modes the
        // model already handled snippets by intent via the system prompt above. Skipped when
        // edit-last just ran the LLM (its output must not be snippet-mangled afterwards).
        if (!s.repromptEnabled || profile.raw) && !editingLast {
            reprompted = SnippetsStore.shared.apply(to: reprompted)
        }

        // Language-consistency guard: transcription engines code-switch (mix French + English
        // mid-sentence). Detect a mixed result and normalize it to its single dominant language.
        // Applies to EVERY mode, including Flow/raw (which otherwise ships the engine output as-is).
        // Skipped for Translate mode (its prompt already forces one target language), and for
        // instruction-driven results (edit-last / verbal-shortcut / selection-instruction): those are
        // LLM rewrites that may be deliberately bilingual on request (e.g. "translate the second
        // sentence to English", "add an English quote"), and normalizing would silently undo them.
        if s.languageGuard, detectedAction == nil, !editingLast, !wasInstruction,
           profile.targetLanguage == nil, isMixedLanguage(reprompted) {
            status("Cleaning up language…")
            if let fixed = try? await normalizeLanguage(reprompted, model: profile.model ?? s.claudeModel) {
                reprompted = fixed
            }
        }

        return PipelineResult(original: original,
                              reprompted: reprompted,
                              profileName: profile.name,
                              profileID: profile.id,
                              engine: engineLabel(s),
                              action: detectedAction)
    }

    // MARK: - Agentic actions (Context mode, Labs)

    /// Current date/time + timezone, given to the model so it resolves "tomorrow at 3pm" /
    /// "this afternoon" to a concrete ISO8601 datetime. Mirrors TodoAgent.nowContext.
    private static func nowContext() -> String {
        let f = ISO8601DateFormatter(); f.timeZone = .current
        let tz = TimeZone.current
        return "CONTEXT — NOW is \(f.string(from: Date())) (timezone \(tz.identifier), " +
               "current UTC offset \(tz.secondsFromGMT() / 3600)h). Resolve \"tomorrow\", " +
               "\"this afternoon\", \"tonight\", \"next monday\", times like \"3pm\"/\"15h\" relative to this."
    }

    /// Appended to the Context system prompt when Labs "Agentic actions" is ON (or in the dedicated
    /// Action mode, Fn+X). Asks the model to return EITHER a structured action (when the request is an
    /// actionable command) OR plain text (a normal screen-grounded answer), as a single JSON object.
    ///
    /// `shortcuts` is the user's actual macOS Shortcuts (from ActionExecutor.availableShortcuts()), so
    /// the model can match a spoken request against the shortcuts they really have. `actionFirst` is set
    /// in the dedicated Action mode: it tells the model the user EXPECTS a command, so it should strongly
    /// prefer emitting an action (falling back to text only when the request truly isn't actionable).
    static func agenticActionsAddendum(shortcuts: [String] = [], actionFirst: Bool = false) -> String {
        let targets = Settings.shared.searchTargets
        let searchBlock = targets.isEmpty ? "(No search targets configured.)" :
            "The user's web search targets (for a 'search' action, set \"target\" to one of these EXACT names " +
            "and put the spoken query in \"query\"):\n" + targets.map { "  • \($0.name)" }.joined(separator: "\n")
        let disabled = Settings.shared.disabledActions.compactMap { ActionKind(rawValue: $0)?.label }
        let disabledBlock = disabled.isEmpty ? "" :
            "\n\nDISABLED actions (the user turned these OFF — NEVER emit them; fall back to text B instead): " +
            disabled.joined(separator: ", ")
        let shortcutsBlock: String
        if shortcuts.isEmpty {
            shortcutsBlock = "(The user has no saved Shortcuts, so do not emit a run_shortcut action.)"
        } else {
            let list = shortcuts.prefix(120).map { "  • \($0)" }.joined(separator: "\n")
            shortcutsBlock = "The user's macOS Shortcuts (match a spoken request to one of these EXACT names " +
                "for a run_shortcut action — never invent a name that isn't listed):\n\(list)"
        }
        let intro = actionFirst
            ? "ACTION MODE (OVERRIDE OF THE OUTPUT FORMAT ABOVE): The user is in a dedicated mode where " +
              "their speech CONTROLS THE MAC. They EXPECT their words to be a command. Resolve the spoken " +
              "request into the single best structured action below and emit it. Only fall back to text (B) " +
              "when the request genuinely isn't an actionable command."
            : "AGENTIC ACTIONS MODE (OVERRIDE OF THE OUTPUT FORMAT ABOVE): The user may dictate a COMMAND to " +
              "do something on their Mac. Decide:"
        return """


        \(intro)

        A) If the request is an actionable command, reply with a SINGLE JSON object \
        {"action":{...}} using ONE of these action types:

          calendar_event — create a Calendar event:
            {"action":{"type":"calendar_event","title":"...","start":"ISO8601","end":"ISO8601"(optional),"notes":"..."(optional)}}
          reminder — create a Reminder:
            {"action":{"type":"reminder","title":"...","due":"ISO8601"(optional),"notes":"..."(optional)}}
          email_draft — open a prefilled email draft:
            {"action":{"type":"email_draft","to":"..."(optional),"subject":"..."(optional),"body":"..."}}
          run_shortcut — run one of the user's macOS Shortcuts by EXACT name (see list below):
            {"action":{"type":"run_shortcut","name":"<exact shortcut name>","input":"..."(optional text to feed it)}}
          open_app — launch an application:
            {"action":{"type":"open_app","name":"Safari"}}
          play_music — play in Music.app (optional playlist/track/artist query):
            {"action":{"type":"play_music","query":"..."(optional)}}
          send_message — compose a Messages.app message (the user CONFIRMS before it sends):
            {"action":{"type":"send_message","to":"<name, phone, or email>","body":"..."}}
          search — run a web search or open a site in the browser:
            {"action":{"type":"search","target":"<one of the search targets below>","query":"<the spoken query>"}}
            or open a specific URL directly: {"action":{"type":"open_url","url":"https://..."}}
          apple_script — a last-resort escape hatch for an action none of the above cover:
            {"action":{"type":"apple_script","label":"<short human description>","script":"<AppleScript source>"}}

        B) Otherwise (a normal screen-grounded answer, a reply to insert, a rewrite, anything that \
        is text to type where the cursor is), reply with a SINGLE JSON object:
          {"text":"the exact text to insert"}

        Rules:
        - Reply with ONE JSON object and NOTHING else: no prose, no markdown, no code fence.
        - For "draft a reply to this email", READ the on-screen email and write the reply in "body" \
        (and "to"/"subject" if visible); type is "email_draft".
        - For run_shortcut, the "name" MUST be one of the user's exact Shortcut names listed below.
        - Prefer a built-in type (calendar/reminder/email/shortcut/open_app/play_music/send_message) \
        over apple_script; use apple_script ONLY when nothing else fits.
        - Resolve all relative dates/times to concrete ISO8601 WITH timezone offset using the \
        context below. Never invent a date the user didn't imply.
        - Use the user's language for titles, bodies and notes.

        \(shortcutsBlock)

        \(searchBlock)\(disabledBlock)

        \(nowContext())
        """
    }

    /// Decide whether a dictated Action-mode command is plausibly SCREEN-GROUNDED — i.e. it can only
    /// be carried out by looking at what's currently on screen ("reply to this", "what's on my
    /// screen", "summarize the selected text"). Clearly self-contained commands ("open Spotify",
    /// "play my Focus playlist", "create an event tomorrow at 3pm", "run my Morning Routine shortcut",
    /// "remind me to call the bank") return false, so Action mode runs WITHOUT a screenshot and does
    /// not require Screen Recording. Conservative: only deictic / screen-referential phrasing flips it.
    static func commandNeedsScreen(_ transcript: String) -> Bool {
        let t = " " + transcript.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines) + " "
        guard t.count > 2 else { return false }

        // Phrases that clearly refer to on-screen content / a current selection. Word-ish boundaries
        // via surrounding spaces avoid matching inside unrelated words ("display" must not hit "this").
        let screenPhrases = [
            "this email", "this message", "this thread", "this conversation", "this text",
            "this page", "this article", "this code", "this error", "this tweet", "this post",
            "this document", "this paragraph", "this selection", "this window", "this tab",
            "reply to this", "respond to this", "answer this", "summarize this", "summarise this",
            "explain this", "translate this", "rewrite this", "fix this", "what does this",
            "what is this", "whats this", "what's this",
            "on screen", "on my screen", "on the screen", "what's on", "whats on", "what is on",
            "on this screen", "the screen", "my screen",
            "selected", "the selection", "highlighted", "what i selected", "what im looking at",
            "what i'm looking at", "currently showing", "showing now", "in front of me",
            "above this", "below this", "this here", "right here",
        ]
        for p in screenPhrases where t.contains(" \(p) ") || t.contains(" \(p)") { return true }

        // Bare deictic "this"/"that"/"it"/"here" as a standalone word, with no concrete object given,
        // is ambiguous enough to be screen-grounded ("reply to this", "what's that", "do it here").
        // Only treat a lone "this"/"that" referent as screen-grounded — "this morning"/"this week"
        // are time words and are NOT screen references, so guard against those.
        let ambiguousDeictic = [" this ", " that ", " these ", " those ", " it here ", " right here "]
        let timeWordsAfterDeictic = ["this morning", "this afternoon", "this evening", "this week",
                                     "this weekend", "this month", "this year", "this tuesday",
                                     "this monday", "this wednesday", "this thursday", "this friday",
                                     "this saturday", "this sunday", "this time"]
        if ambiguousDeictic.contains(where: { t.contains($0) }),
           !timeWordsAfterDeictic.contains(where: { t.contains($0) }) {
            return true
        }
        return false
    }

    /// Parse the model's reply into a VerbaAction when it returned `{"action":{…}}`. Robust: extracts
    /// the first `{` to the last `}` (TodoAgent style), tolerates a missing wrapper, and resolves
    /// ISO8601 dates. Returns nil for `{"text":…}` or any unparseable / non-action reply, so the
    /// caller falls back to treating the reply as text — a result is never lost.
    static func parseAgenticAction(_ raw: String) -> VerbaAction? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards),
           open.lowerBound <= close.lowerBound {
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        // An explicit {"text":…} reply, or no "action" key → not an action.
        guard let a = obj["action"] as? [String: Any] else { return nil }
        let type = ((a["type"] as? String) ?? (a["kind"] as? String) ?? "")
            .lowercased().replacingOccurrences(of: "-", with: "_")
        let title = (a["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = (a["notes"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = (a["start"] as? String).flatMap(parseISO)
        let end = (a["end"] as? String).flatMap(parseISO)
        let due = (a["due"] as? String).flatMap(parseISO)

        switch type {
        case "calendar_event", "calendarevent", "event":
            guard let title, !title.isEmpty, let start else { return nil }
            return .calendarEvent(title: title, start: start, end: end,
                                  notes: (notes?.isEmpty == false) ? notes : nil)
        case "reminder":
            guard let title, !title.isEmpty else { return nil }
            return .reminder(title: title, due: due, notes: (notes?.isEmpty == false) ? notes : nil)
        case "email_draft", "emaildraft", "email":
            let body = ((a["body"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let to = (a["to"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let subject = (a["subject"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            // Need at least a body or a subject to be a meaningful draft.
            guard !body.isEmpty || (subject?.isEmpty == false) else { return nil }
            return .emailDraft(to: (to?.isEmpty == false) ? to : nil,
                               subject: (subject?.isEmpty == false) ? subject : nil,
                               body: body)
        case "run_shortcut", "runshortcut", "shortcut":
            let name = ((a["name"] as? String) ?? (a["title"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let input = (a["input"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .runShortcut(name: name, input: (input?.isEmpty == false) ? input : nil)
        case "open_app", "openapp", "launch_app", "app":
            let name = ((a["name"] as? String) ?? (a["app"] as? String) ?? (a["title"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return .openApp(name: name)
        case "play_music", "playmusic", "music":
            let query = ((a["query"] as? String) ?? (a["title"] as? String))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .playMusic(query: (query?.isEmpty == false) ? query : nil)
        case "send_message", "sendmessage", "message", "imessage", "text_message":
            let to = ((a["to"] as? String) ?? (a["recipient"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let body = ((a["body"] as? String) ?? (a["message"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !to.isEmpty, !body.isEmpty else { return nil }
            return .sendMessage(to: to, body: body)
        case "apple_script", "applescript", "script":
            let script = ((a["script"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !script.isEmpty else { return nil }
            let label = ((a["label"] as? String) ?? (a["title"] as? String) ?? "Action")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .appleScript(label: label.isEmpty ? "Action" : label, script: script)
        case "search", "web_search", "websearch", "open_url", "openurl", "url":
            // A direct URL the model produced ("open github.com").
            if let urlStr = (a["url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !urlStr.isEmpty, let url = URL(string: urlStr.contains("://") ? urlStr : "https://\(urlStr)") {
                let label = (a["target"] as? String) ?? url.host ?? "link"
                return .openURL(label: label, url: url)
            }
            // Otherwise resolve one of the user's configured search targets by name + fill the query.
            let query = ((a["query"] as? String) ?? (a["q"] as? String) ?? (a["title"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let targetName = ((a["target"] as? String) ?? (a["engine"] as? String) ?? (a["name"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let targets = Settings.shared.searchTargets
            let match = targets.first { $0.name.caseInsensitiveCompare(targetName) == .orderedSame } ?? targets.first
            guard let target = match, !query.isEmpty, let url = target.url(for: query) else { return nil }
            return .openURL(label: "\(target.name): \(query)", url: url)
        default:
            return nil
        }
    }

    /// Pull the text to insert from the model's reply when it isn't an action. Honors a
    /// `{"text":…}` envelope; if the reply isn't that shape, returns the raw reply unchanged
    /// (so a model that ignored the JSON contract still produces a usable result).
    static func extractAgenticText(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards),
           open.lowerBound <= close.lowerBound {
            let json = String(s[open.lowerBound...close.lowerBound])
            if let data = json.data(using: .utf8),
               let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
               let text = obj["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // Not a recognizable envelope: use the reply verbatim so nothing is lost.
        return s.isEmpty ? raw : s
    }

    /// Parse an ISO8601 date string (with or without fractional seconds, or date-only).
    private static func parseISO(_ s: String) -> Date? {
        let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !str.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withFullDate]; f.timeZone = .current
        return f.date(from: str)
    }

    /// Heuristic, offline detector for code-switched (mixed-language) text. Uses Apple's
    /// NaturalLanguage recognizer per-sentence: if a meaningful share of the sentences are
    /// confidently a DIFFERENT language than the document's dominant one, the text is mixed.
    /// Deliberately conservative — short or clearly-monolingual text returns false so we don't
    /// pay for an unneeded LLM pass or risk mangling clean output.
    static func isMixedLanguage(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Need enough words for per-sentence detection to be meaningful.
        guard trimmed.split(whereSeparator: { $0 == " " || $0 == "\n" }).count >= 6 else { return false }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let dominant = recognizer.dominantLanguage else { return false }

        // Split into sentence-ish units and tag each one's language.
        var languages: [NLLanguage] = []
        let st = NLTokenizer(unit: .sentence)
        st.string = trimmed
        st.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { range, _ in
            let sentence = String(trimmed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            // Only consider sentences long enough to language-detect with any confidence.
            guard sentence.split(whereSeparator: { $0 == " " }).count >= 3 else { return true }
            let r = NLLanguageRecognizer()
            r.processString(sentence)
            if let lang = r.dominantLanguage,
               let conf = r.languageHypotheses(withMaximum: 1)[lang], conf >= 0.80 {
                languages.append(lang)
            }
            return true
        }

        guard languages.count >= 2 else { return false }
        let other = languages.filter { $0 != dominant }.count
        // Only treat as MIXED when off-language sentences are a real share of the text, not a
        // lone outlier — a French-dominant utterance with one English brand/loan word must NOT
        // trip the rewrite. Require ≥2 off-language sentences, OR a single one only when it's
        // at least ~33% of a very short (2-3 sentence) text where it's genuinely half the content.
        if other >= 2 { return Double(other) / Double(languages.count) >= 0.2 }
        return languages.count <= 3 && Double(other) / Double(languages.count) >= 0.33
    }

    /// Human-readable name for an NL language code, used to PIN the rewrite target so the LLM
    /// can never promote a minority language to the whole output. Falls back to the raw code.
    static func languageDisplayName(_ lang: NLLanguage) -> String {
        Locale(identifier: "en_US").localizedString(forLanguageCode: lang.rawValue) ?? lang.rawValue
    }

    /// Cheap LLM cleanup pass for code-switched dictation. We FIRST detect the document's
    /// dominant language offline with Apple's NaturalLanguage recognizer, then instruct the
    /// model to keep THAT language as the output language — it may never flip the whole text
    /// to a minority language just because a few foreign tokens appear. Embedded foreign
    /// brand / product / technical / loan words are preserved verbatim, never translated.
    /// Uses the configured backend via Reprompter (fast path).
    static func normalizeLanguage(_ text: String, model: String) async throws -> String {
        // Pin the target language offline so the LLM can't mis-pick a minority one.
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let targetClause: String
        if let dominant = recognizer.dominantLanguage {
            targetClause = """
            The DOMINANT language of this text is \(languageDisplayName(dominant)). Keep the \
            ENTIRE output in \(languageDisplayName(dominant)). Do NOT switch the output to any \
            other language, even if some words or a short phrase appear in another language.
            """
        } else {
            targetClause = """
            Keep the ENTIRE output in the single dominant language of the text. Do NOT switch \
            the output to a minority language that only appears in a few words.
            """
        }

        let sys = """
        You are a language-consistency fixer for voice-dictation output. The transcription \
        engine sometimes code-switches, dropping a few fragments of one language into text that \
        is mostly another language (e.g. a stray English fragment inside French speech).

        \(targetClause)

        Rewrite ONLY the fragments that are accidentally in the WRONG language back into the \
        dominant output language, so the prose reads naturally and monolingually.

        CRITICAL — PRESERVE these verbatim, never translate them: brand names, product names, \
        company names, proper nouns, technical terms, acronyms, and established loanwords that a \
        native speaker would normally keep in the foreign form (e.g. words like "weekend", \
        "email", "software", "deadline", "feedback", "meeting", "le wifi", "un bug"). A French \
        sentence that mentions an English brand or borrowed word must STAY French with that word \
        left exactly as spoken.

        Change NOTHING else: keep all content, meaning, tone, numbers, names, code, punctuation \
        and formatting exactly as they are. Do not summarize, add, remove, reorder, or explain.
        NEVER use an em dash, en dash, or a spaced hyphen.

        Output ONLY the corrected text. No preamble, no quotes, no commentary.
        """
        let r = Reprompter(model: model)
        let out = try await r.reprompt(transcript: text, systemPrompt: sys, fast: true)
        let cleaned = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }

    private static func engineLabel(_ s: Settings) -> String {
        switch s.engine {
        case .openAI:   return "openai:gpt-4o-transcribe"
        case .whisper:  return "whisper:\(s.localModel)"
        case .parakeet: return "parakeet:v3"
        }
    }
}
