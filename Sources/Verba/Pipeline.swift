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
            status("Restructuring with Claude…")
            var sys = profile.systemPrompt
            let style = s.styleText.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.styleEnabled && !style.isEmpty {
                sys += "\n\nADDITIONAL STYLE PREFERENCES (apply while staying faithful): \(style)"
            }
            let r = Reprompter(model: s.claudeModel)
            reprompted = try await r.reprompt(transcript: original, systemPrompt: sys)
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
