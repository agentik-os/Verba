import Foundation

struct PipelineResult {
    var original: String
    var reprompted: String
    var profileName: String
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

        // 2. A dedicated-shortcut profile wins; else auto-detect / active profile.
        let profile = forcedProfile ?? s.profile(forBundleID: frontmostBundleID)
        var reprompted = original
        // Raw/Flow mode (or reprompting off) → return the transcript untouched, no Claude.
        if s.repromptEnabled && !profile.raw {
            var sys = profile.systemPrompt
            let style = s.styleText.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.styleEnabled && !style.isEmpty {
                sys += "\n\nADDITIONAL STYLE PREFERENCES (apply while staying faithful): \(style)"
            }
            let r = Reprompter(model: s.claudeModel)

            let sel = selection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !sel.isEmpty {
                // Selection mode: the dictation is an INSTRUCTION acting on the selected text.
                status("Working on your selection…")
                sys += """


                SELECTION MODE — OVERRIDE: The user has TEXT SELECTED in their editor and \
                is giving you a spoken instruction about it. Treat the transcript as an \
                instruction to apply to the selected text (rewrite/translate/transform it, \
                or answer their question about it). Output ONLY the resulting text that \
                should REPLACE the selection — no preamble, no quotes, no commentary. \
                Keep the user's language unless they ask otherwise.
                """
                let userText = "SELECTED TEXT:\n<<<\n\(sel)\n>>>\n\nSPOKEN INSTRUCTION:\n\(original)"
                reprompted = try await r.reprompt(transcript: userText, systemPrompt: sys)
            } else {
                status("Restructuring with Claude…")
                reprompted = try await r.reprompt(transcript: original, systemPrompt: sys)
            }
        }

        // Expand snippets in the final text.
        reprompted = SnippetsStore.shared.apply(to: reprompted)

        return PipelineResult(original: original,
                              reprompted: reprompted,
                              profileName: profile.name,
                              engine: engineLabel(s))
    }

    private static func engineLabel(_ s: Settings) -> String {
        switch s.engine {
        case .openAI:   return "openai:gpt-4o-transcribe"
        case .whisper:  return "whisper:\(s.localModel)"
        case .parakeet: return "parakeet:v3"
        }
    }
}
