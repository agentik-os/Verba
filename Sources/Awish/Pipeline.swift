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
                    status: @escaping (String) -> Void) async throws -> PipelineResult {
        let s = Settings.shared

        // 1. Transcribe with the selected engine.
        status(s.engine == .local ? "Transcribing locally…" : "Transcribing…")
        let lang = s.language.isEmpty ? nil : s.language
        let transcriber: Transcriber = (s.engine == .local)
            ? LocalTranscriber.shared
            : OpenAITranscriber()
        let original = try await transcriber.transcribe(fileURL: audioURL, language: lang)

        // 2. Pick a profile (auto by frontmost app, or the active one) and reprompt.
        let profile = s.profile(forBundleID: frontmostBundleID)
        var reprompted = original
        if s.repromptEnabled {
            status("Restructuring with Claude…")
            let r = Reprompter(model: s.claudeModel)
            reprompted = try await r.reprompt(transcript: original, systemPrompt: profile.systemPrompt)
        }

        return PipelineResult(original: original,
                              reprompted: reprompted,
                              profileName: profile.name,
                              engine: s.engine == .local ? "local:\(s.localModel)" : "openai:gpt-4o-transcribe")
    }
}
