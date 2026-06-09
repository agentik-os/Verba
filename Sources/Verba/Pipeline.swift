import Foundation
import NaturalLanguage

/// Thrown when a stage (transcription / reprompt) runs past its deadline so a hung
/// backend can't spin the overlay forever. Surfaced to the user as a clear error.
struct TimeoutError: LocalizedError {
    var errorDescription: String? { "Timed out — the backend took too long. Try again." }
}

/// Run `operation` but give up after `seconds`. Whichever finishes first wins; the
/// loser is cancelled. Guarantees the caller's Task always completes (and can reset
/// to idle) even when the underlying call ignores cooperative cancellation.
func withTimeout<T: Sendable>(seconds: Double,
                              operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else { throw TimeoutError() }
        return result
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
        // Raw/Flow mode (or reprompting off) → return the transcript untouched, no Claude.
        if s.repromptEnabled && !profile.raw {
            var sys = profile.effectiveSystemPrompt   // Translate mode injects its target language
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

            let sel = selection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
            if editLast && !sel.isEmpty {
                // Edit-last: the dictation is an INSTRUCTION applied to the last delivered result
                // (the text to edit arrives via `selection`). Works in ALL modes — Translate and
                // Context/Vision included — by routing through its own dedicated prompt rather than
                // the mode-gated selection-instruction channel.
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
                // Context mode (or the dedicated Action mode, Fn+X): screenshot of the current screen
                // + the spoken request → a vision model → clean text to insert, OR a structured action.
                // Kept deliberately simple and robust.
                guard ScreenCapture.hasPermission() else {
                    ScreenCapture.requestPermission()
                    ScreenCapture.openPrivacySettings()
                    throw RepromptError.http(0, "Context mode needs Screen Recording. Enable Verba in System Settings ▸ Privacy & Security ▸ Screen Recording, then try again.")
                }
                status("Looking at your screen…")
                guard let png = ScreenCapture.capturePNG(), !png.isEmpty else {
                    throw RepromptError.http(0, "Couldn't capture the screen. If Screen Recording was just enabled, quit and reopen Verba, then try again.")
                }
                status(Quips.current())
                // Labs "Agentic actions": ask the model to return EITHER a structured action OR
                // plain text. The screenshot still goes to the vision model (so "draft a reply to
                // this email" can read the on-screen email). Parse robustly; ANY parse failure falls
                // back to treating the whole reply as text, so a result is never lost.
                // The agentic-action path runs when Labs "Agentic actions" is on OR in the dedicated
                // Action mode (Fn+X), which forces it regardless of the Labs toggle. The model is given
                // the user's actual Shortcuts so it can match a spoken request to a real shortcut name.
                if s.agenticActions || actionMode {
                    let shortcuts = ActionExecutor().availableShortcuts()
                    let raw = try await r.repromptVision(
                        transcript: original,
                        systemPrompt: sys + agenticActionsAddendum(shortcuts: shortcuts, actionFirst: actionMode),
                        imagePNG: png)
                    if let action = parseAgenticAction(raw) {
                        detectedAction = action
                    } else {
                        reprompted = extractAgenticText(raw)
                    }
                } else {
                    reprompted = try await r.repromptVision(transcript: original, systemPrompt: sys, imagePNG: png)
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
                reprompted = try await r.reprompt(
                    transcript: sel,
                    systemPrompt: transform.prompt + "\nOutput ONLY the transformed text.")
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
                let userText = "SELECTED TEXT:\n<<<\n\(sel)\n>>>\n\nSPOKEN INSTRUCTION:\n\(original)"
                reprompted = try await r.reprompt(transcript: userText, systemPrompt: sys)
            } else {
                status(Quips.current())   // fun, ever-changing geek line instead of "Restructuring…"
                reprompted = try await r.reprompt(transcript: original, systemPrompt: sys)
            }
        }

        // Raw/Flow mode (no AI) → fall back to literal snippet expansion. In AI modes the
        // model already handled snippets by intent via the system prompt above.
        if !s.repromptEnabled || profile.raw {
            reprompted = SnippetsStore.shared.apply(to: reprompted)
        }

        // Language-consistency guard: transcription engines code-switch (mix French + English
        // mid-sentence). Detect a mixed result and normalize it to its single dominant language.
        // Applies to EVERY mode, including Flow/raw (which otherwise ships the engine output as-is).
        // Skipped for Translate mode (its prompt already forces one target language).
        if s.languageGuard, detectedAction == nil, profile.targetLanguage == nil, isMixedLanguage(reprompted) {
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

        \(nowContext())
        """
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
        // Mixed if at least one full sentence is a confidently different language AND it isn't
        // a lone outlier in a long monologue (≥ ~20% off-language sentences, or any in short text).
        return other >= 1 && (languages.count <= 4 || Double(other) / Double(languages.count) >= 0.2)
    }

    /// Cheap LLM cleanup pass: rewrite the text entirely in its single dominant language,
    /// translating any code-switched fragments, changing nothing else. Uses the configured
    /// backend via Reprompter (fast path) so it routes to the user's chosen model.
    static func normalizeLanguage(_ text: String, model: String) async throws -> String {
        let sys = """
        You are a language-consistency fixer for voice-dictation output. The transcription \
        engine sometimes code-switches, dropping fragments of one language into text that is \
        mostly another language (e.g. English words inside French speech, or the reverse).

        Detect the ONE dominant language of the text and rewrite it ENTIRELY in that single \
        language, translating every code-switched fragment into it so the result is 100% \
        monolingual.

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
