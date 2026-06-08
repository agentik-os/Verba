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
}

/// record → transcribe → (Claude reprompt) → result. Output/side-effects handled by the caller.
enum Pipeline {
    static func run(audioURL: URL,
                    frontmostBundleID: String?,
                    forcedProfile: Profile?,
                    selection: String? = nil,
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
        // Raw/Flow mode (or reprompting off) → return the transcript untouched, no Claude.
        if s.repromptEnabled && !profile.raw {
            var sys = profile.effectiveSystemPrompt   // Translate mode injects its target language
            let style = s.styleText.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.styleEnabled && !style.isEmpty {
                sys += "\n\nADDITIONAL STYLE PREFERENCES (apply while staying faithful): \(style)"
            }
            sys += SnippetsStore.shared.promptContext()   // intent-based snippet insertion

            // #5 Tone match: feed a few of the user's recent messages in THIS app as style
            // examples, so the rewrite mimics how they actually write here.
            if s.toneMatch {
                let examples = ToneStore.examples(bundleID: frontmostBundleID)
                if !examples.isEmpty {
                    let block = examples.enumerated().map { "Example \($0.offset + 1):\n\($0.element)" }.joined(separator: "\n\n")
                    sys += "\n\nTONE MATCH: here are recent messages the user wrote in this app. Match their tone, vocabulary, formality and rhythm (NOT their content):\n\n\(block)"
                }
            }
            let r = Reprompter(model: profile.model ?? s.claudeModel)   // per-mode model override

            let sel = selection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if profile.vision {
                // Context mode: screenshot of the current screen + the spoken request →
                // a vision model → clean text to insert. Kept deliberately simple and robust.
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
                reprompted = try await r.repromptVision(transcript: original, systemPrompt: sys, imagePNG: png)
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
        if s.languageGuard, profile.targetLanguage == nil, isMixedLanguage(reprompted) {
            status("Cleaning up language…")
            if let fixed = try? await normalizeLanguage(reprompted, model: profile.model ?? s.claudeModel) {
                reprompted = fixed
            }
        }

        return PipelineResult(original: original,
                              reprompted: reprompted,
                              profileName: profile.name,
                              profileID: profile.id,
                              engine: engineLabel(s))
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
