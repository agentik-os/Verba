import Foundation

enum RepromptError: LocalizedError {
    case missingKey
    case http(Int, String)
    case empty
    var errorDescription: String? {
        switch self {
        case .missingKey: return "No Anthropic API key set. Add it in Verba ▸ Settings."
        case .http(let code, let body): return "Claude reprompting failed (\(code)): \(body)"
        case .empty: return "Claude returned no text."
        }
    }
}

/// Restructures a raw transcript into a clean prompt/message using Claude (BYOK).
struct Reprompter {
    var model: String

    func reprompt(transcript: String, systemPrompt: String) async throws -> String {
        let userText = "Here is the raw voice transcript to restructure:\n\n<transcript>\n\(transcript)\n</transcript>"
        switch Settings.shared.repromptBackend {
        case .claudeCode:
            // No API key, uses the user's Claude subscription via the CLI.
            return try await ClaudeCode.reprompt(systemPrompt: systemPrompt, userText: userText, model: model)
        case .openRouter:
            return try await openRouter(systemPrompt: systemPrompt, userText: userText)
        case .localLLM:
            return try await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel)
        case .apiKey:
            break   // falls through to the Anthropic path below
        }
        guard let key = Keychain.anthropicKey, !key.isEmpty else { throw RepromptError.missingKey }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 180

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userText]
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw RepromptError.http(code, String(data: data, encoding: .utf8) ?? "")
        }
        let parsed = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let text = parsed.content.compactMap { $0.type == "text" ? $0.text : nil }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty }
        return text
    }

    private struct ClaudeResponse: Decodable {
        struct Block: Decodable { let type: String; let text: String? }
        let content: [Block]
    }

    // MARK: OpenRouter (OpenAI-compatible), BYO key, any model the user picks.
    private func openRouter(systemPrompt: String, userText: String) async throws -> String {
        guard let key = Keychain.openRouterKey, !key.isEmpty else { throw RepromptError.missingKey }
        let chosen = Settings.shared.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = chosen.isEmpty ? "anthropic/claude-3.7-sonnet" : chosen

        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("https://verba.run", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("Verba", forHTTPHeaderField: "X-Title")
        req.timeoutInterval = 180

        let payload: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText],
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw RepromptError.http(code, String(data: data, encoding: .utf8) ?? "")
        }
        let parsed = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let text = (parsed.choices.first?.message.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty }
        return text
    }

    private struct OpenAIResponse: Decodable {
        struct Choice: Decodable { struct Msg: Decodable { let content: String? }; let message: Msg }
        let choices: [Choice]
    }
}
