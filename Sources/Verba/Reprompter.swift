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

    func reprompt(transcript: String, systemPrompt: String, fast: Bool = false) async throws -> String {
        let userText = "Here is the raw voice transcript to restructure:\n\n<transcript>\n\(transcript)\n</transcript>"
        var backend = Settings.shared.repromptBackend.resolved
        // Notes fast path: spawning the Claude CLI costs ~6-8s of pure startup overhead per call,
        // which dwarfs the generation. For notes, never spawn it — swap to a direct HTTP model call
        // (API key if present, else the hosted proxy). Same model, no process spawn.
        if fast, backend == .claudeCode {
            if let key = Keychain.anthropicKey, !key.isEmpty { backend = .apiKey }
            else if !Settings.shared.proEmail.trimmingCharacters(in: .whitespaces).isEmpty { backend = .verba }
        }
        switch backend {
        case .auto:   // unreachable (resolved never returns .auto), satisfy exhaustiveness
            return try await verbaHosted(transcript: transcript, systemPrompt: systemPrompt, imageBase64: nil)
        case .verba:
            return try await verbaHosted(transcript: transcript, systemPrompt: systemPrompt, imageBase64: nil)
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

    // MARK: Verba hosted backend — the included AI rewriting (no API key needed).
    // Calls verba.run/api/reprompt, gated by the signed-in account. Supports vision too.
    func verbaHosted(transcript: String, systemPrompt: String, imageBase64: String?) async throws -> String {
        let email = Settings.shared.proEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            throw RepromptError.http(401, "Sign in to Verba (Settings ▸ account) to use the included AI rewriting, or pick another backend.")
        }
        var req = URLRequest(url: URL(string: "https://verba.run/api/reprompt")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        AuthToken.bearer(&req)   // the route is 401-gated: prove the signed-in session, not just an email
        req.timeoutInterval = 180
        var payload: [String: Any] = ["email": email, "transcript": transcript, "system": systemPrompt, "model": model]
        if let imageBase64 { payload["image"] = imageBase64 }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw RepromptError.http(code, body ?? (String(data: data, encoding: .utf8) ?? ""))
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = (obj?["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty }
        return text
    }

    // MARK: Context mode (vision) — send a screenshot + the spoken request.
    // Vision needs a multimodal cloud model. We use the Anthropic API when a key exists,
    // otherwise OpenRouter. The CLI and local engines can't take images, so we route
    // around them with a clear message if no usable key is configured.
    func repromptVision(transcript: String, systemPrompt: String, imagePNG: Data) async throws -> String {
        let userText = "Here is what I said. Use the screenshot to do it:\n\n<request>\n\(transcript)\n</request>"
        let b64 = imagePNG.base64EncodedString()

        // Prefer the configured backend if it can do vision; else fall back to any key we have.
        let backend = Settings.shared.repromptBackend.resolved
        // The Verba hosted backend handles vision (no key). Claude Code's CLI can't take
        // images, so for vision we route Claude Code → Verba hosted as well.
        if backend == .verba || backend == .claudeCode {
            return try await verbaHosted(transcript: transcript, systemPrompt: systemPrompt, imageBase64: b64)
        }
        let hasAnthropic = !(Keychain.anthropicKey ?? "").isEmpty
        let hasOpenRouter = !(Keychain.openRouterKey ?? "").isEmpty

        if (backend == .openRouter && hasOpenRouter) || (!hasAnthropic && hasOpenRouter) {
            return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
        }
        guard hasAnthropic else { throw RepromptError.missingKey }
        return try await anthropicVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
    }

    private func anthropicVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = Keychain.anthropicKey, !key.isEmpty else { throw RepromptError.missingKey }
        // Context needs a vision-capable model; force one if the per-mode model isn't.
        let visionModel = model.hasPrefix("claude-") ? model : "claude-sonnet-4-6"

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 180

        let payload: [String: Any] = [
            "model": visionModel,
            "max_tokens": 8000,
            "system": systemPrompt,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image",
                     "source": ["type": "base64", "media_type": "image/png", "data": base64PNG]],
                    ["type": "text", "text": userText],
                ],
            ]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw RepromptError.http(code, String(data: data, encoding: .utf8) ?? "") }
        let parsed = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let text = parsed.content.compactMap { $0.type == "text" ? $0.text : nil }
            .joined().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty }
        return text
    }

    private func openRouterVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = Keychain.openRouterKey, !key.isEmpty else { throw RepromptError.missingKey }
        let chosen = Settings.shared.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        // Default to a vision-capable model on OpenRouter.
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
                ["role": "user", "content": [
                    ["type": "text", "text": userText],
                    ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(base64PNG)"]],
                ]],
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw RepromptError.http(code, String(data: data, encoding: .utf8) ?? "") }
        let parsed = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let text = (parsed.choices.first?.message.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty }
        return text
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
