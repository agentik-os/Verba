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
        // Claude Code (Max plan) path — no API key, uses the user's subscription.
        if Settings.shared.repromptBackend == .claudeCode {
            return try await ClaudeCode.reprompt(systemPrompt: systemPrompt, userText: userText, model: model)
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
}
