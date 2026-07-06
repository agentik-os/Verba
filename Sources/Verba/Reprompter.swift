import Foundation

enum RepromptError: LocalizedError {
    case missingKey
    case http(Int, String)
    case empty
    var errorDescription: String? {
        switch self {
        case .missingKey: return "No API key set for the selected AI-rewriting backend. Add it in Verba ▸ Settings ▸ AI rewriting."
        case .http(let code, let body): return "AI rewriting failed (\(code)): \(body)"
        case .empty: return "The model returned no text."
        }
    }
}

/// Restructures a raw transcript into a clean prompt/message using the user's chosen backend (BYOK).
struct Reprompter {
    var model: String
    /// Forced backend for ONE attempt, set by the Automatic fallback loop. nil = use the user's
    /// configured backend (the normal path).
    var backendOverride: RepromptBackend? = nil
    /// Forces the "My API key" PROVIDER for ONE attempt, set by the Automatic fallback loop (which
    /// specifically wants the user's Anthropic key, never whatever provider they picked for the
    /// explicit "My API key" backend). nil = use Settings.shared.apiKeyProvider (the normal path).
    var apiKeyProviderOverride: ApiKeyProvider? = nil

    func reprompt(transcript: String, systemPrompt: String, fast: Bool = false) async throws -> String {
        let userText = "Here is the raw voice transcript to restructure:\n\n<transcript>\n\(transcript)\n</transcript>"
        // Automatic mode (Claude Code, else Verba) auto-recovers: it walks each available backend and
        // model until one succeeds, so a failed Claude CLI, an unavailable or rate-limited model never
        // dead-ends the dictation. An explicitly chosen backend keeps its single, predictable attempt.
        if backendOverride == nil, Settings.shared.repromptBackend == .auto {
            return try await autoFallback(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
        }
        return try await runOnce(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
    }

    /// Automatic mode: try every available (backend, model) pair until one returns text. Order: the
    /// user's Claude Code first (free, runs on their plan), then their Anthropic key, then Verba's
    /// hosted engine (always works, no key); within each, the mode's model first, then lighter models
    /// that are likelier to be available / within limits.
    private func autoFallback(transcript: String, systemPrompt: String, userText: String, fast: Bool) async throws -> String {
        var backends: [RepromptBackend] = []
        if ClaudeCode.isAvailable, !fast { backends.append(.claudeCode) }   // skip the slow CLI on the notes fast-path
        if let k = Keychain.anthropicKey, !k.isEmpty { backends.append(.apiKey) }
        backends.append(.verba)
        var seen = Set<String>(); backends = backends.filter { seen.insert($0.rawValue).inserted }

        var lastError: Error?
        for b in backends {
            for m in Reprompter.fallbackModels(preferred: model) {
                var attempt = self
                attempt.backendOverride = b
                attempt.model = m
                // Automatic mode's ".apiKey" entry above is gated on Keychain.anthropicKey
                // specifically — force that provider regardless of what the user picked for the
                // explicit "My API key" backend (could be OpenAI/OpenRouter).
                if b == .apiKey { attempt.apiKeyProviderOverride = .anthropic }
                do {
                    return try await attempt.runOnce(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
                } catch {
                    lastError = error
                    NSLog("Verba: Automatic reprompt attempt failed (\(b.rawValue) · \(m)): \(error.localizedDescription) — trying next")
                }
            }
        }
        throw lastError ?? RepromptError.empty
    }

    /// Model fallback order for Automatic mode: the chosen model first, then the balanced and lightest
    /// models. Deduped; only Claude models (every Automatic backend speaks them).
    static func fallbackModels(preferred: String) -> [String] {
        var list = preferred.hasPrefix("claude-") ? [preferred] : []
        for m in ["claude-sonnet-4-6", "claude-haiku-4-5"] where !list.contains(m) { list.append(m) }
        return list
    }

    /// A single reprompt attempt against one resolved backend + this instance's `model`.
    private func runOnce(transcript: String, systemPrompt: String, userText: String, fast: Bool) async throws -> String {
        var backend = backendOverride ?? Settings.shared.repromptBackend.resolved
        // The fast path below may force backend = .apiKey specifically because an ANTHROPIC key
        // exists (never the user's chosen apiKeyProvider) — track that override separately from
        // Settings so it doesn't accidentally route through OpenAI/OpenRouter instead.
        var provider = apiKeyProviderOverride ?? Settings.shared.apiKeyProvider
        // Notes fast path: spawning the Claude CLI costs ~6-8s of pure startup overhead per call,
        // which dwarfs the generation. For notes, never spawn it — swap to a direct HTTP model call
        // (API key if present, else the hosted proxy). Same model, no process spawn.
        if fast, backend == .claudeCode {
            if let key = Keychain.anthropicKey, !key.isEmpty { backend = .apiKey; provider = .anthropic }
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
            switch provider {
            case .openAI:     return try await openAIChat(systemPrompt: systemPrompt, userText: userText)
            case .openRouter: return try await openRouter(systemPrompt: systemPrompt, userText: userText)
            case .anthropic:  break   // falls through to the Anthropic path below
            }
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
    // Vision needs a multimodal model. We use whichever provider the "My API key"/OpenRouter
    // backend is set to, when its key is present. The CLI and local engines can't take images,
    // so we route around them with a clear message if no usable key/account is configured.
    func repromptVision(transcript: String, systemPrompt: String, imagePNG: Data) async throws -> String {
        let userText = "Here is what I said. Use the screenshot to do it:\n\n<request>\n\(transcript)\n</request>"
        let b64 = imagePNG.base64EncodedString()

        // Context mode must use the SAME engine as the user's other modes — never silently fall to a
        // stray key or a hosted call the user didn't choose. Route by the selected backend; only the
        // apiKey/openRouter backends use their own keys (the user's explicit choice). Backends that
        // can't see images at all (Claude Code's CLI, .verba) go through the user's SIGNED-IN ACCOUNT
        // (verbaHosted) — their own Claude subscription, the same one powering every other mode.
        // `.localLLM` (Fully local) NEVER falls back to verbaHosted just because the user also happens
        // to be signed in for other features (leaderboard etc.) — a local-only user gets a clear error,
        // not a silent hosted Claude call.
        let backend = Settings.shared.repromptBackend.resolved
        let hasAnthropic = !(Keychain.anthropicKey ?? "").isEmpty
        let hasOpenAI = !(Keychain.openAIKey ?? "").isEmpty
        let hasOpenRouter = !(Keychain.openRouterKey ?? "").isEmpty
        let signedIn = !Settings.shared.proEmail.trimmingCharacters(in: .whitespaces).isEmpty

        switch backend {
        case .apiKey:
            switch Settings.shared.apiKeyProvider {
            case .anthropic where hasAnthropic:
                return try await anthropicVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .openAI where hasOpenAI:
                return try await openAIVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .openRouter where hasOpenRouter:
                return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            default:
                // Chosen provider's key is missing: never borrow another provider's key or account.
                throw RepromptError.missingKey
            }
        case .openRouter:
            guard hasOpenRouter else { throw RepromptError.missingKey }
            return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
        case .verba, .claudeCode:
            guard signedIn else {
                throw RepromptError.http(401, "Sign in to Verba (Settings ▸ account) to use Context mode with this backend, or pick a vision-capable backend.")
            }
            return try await verbaHosted(transcript: transcript, systemPrompt: systemPrompt, imageBase64: b64)
        case .localLLM:
            // Local models here are text-only: never silently fall back to hosted Claude just
            // because the user is ALSO signed in for other features.
            throw RepromptError.http(400, "Context mode needs a vision-capable model; local models don't support screenshots yet. Pick another backend for Context mode.")
        case .auto:
            break   // unreachable, .resolved never returns .auto
        }
        throw RepromptError.missingKey
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

    private func openAIVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = Keychain.openAIKey, !key.isEmpty else { throw RepromptError.missingKey }
        let chosen = Settings.shared.openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        // Default to a vision-capable OpenAI model.
        let modelID = chosen.isEmpty ? "gpt-4o" : chosen

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
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

    // MARK: OpenAI, BYO key, chosen model — one of the three "My API key" providers.
    private func openAIChat(systemPrompt: String, userText: String) async throws -> String {
        guard let key = Keychain.openAIKey, !key.isEmpty else { throw RepromptError.missingKey }
        let chosen = Settings.shared.openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = chosen.isEmpty ? "gpt-4o" : chosen

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
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
