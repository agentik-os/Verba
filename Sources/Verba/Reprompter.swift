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
        // Automatic mode (Claude Code, else fully-local) auto-recovers: it walks each available backend
        // and model until one succeeds, so a failed Claude CLI, an unavailable or rate-limited model
        // never dead-ends the dictation. An explicitly chosen backend keeps its single, predictable attempt.
        if backendOverride == nil, Settings.shared.repromptBackend == .auto {
            return try await autoFallback(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
        }
        do {
            return try await runOnce(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
        } catch {
            // SAFETY NET: an explicitly-chosen engine that is genuinely UNAVAILABLE (Claude Code CLI not
            // installed, no API key set, local server down) must not dead-end the dictation — fall back
            // to the fully-local model (which self-installs on demand). This recovers users the earlier
            // hosted-AI migration pinned to a single backend that later became unavailable. Transient/
            // content errors from a working engine still surface (we only catch unavailability).
            if backendOverride == nil, Self.isEngineUnavailable(error),
               Settings.shared.repromptBackend != .localLLM {
                return try await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel)
            }
            throw error
        }
    }

    /// True for errors that mean "this engine can't run at all right now" (as opposed to a transient
    /// or content error from a working engine) — the cases where falling back to local is right.
    private static func isEngineUnavailable(_ error: Error) -> Bool {
        if case ClaudeCode.CCError.notInstalled = error { return true }
        if case RepromptError.missingKey = error { return true }
        if case LocalLLM.LLMError.notRunning = error { return true }
        if case LocalLLM.LLMError.settingUp = error { return true }
        if case LocalLLM.LLMError.notDownloaded = error { return true }
        return false
    }

    /// Automatic mode: try every available (backend, model) pair until one returns text. Order: the
    /// user's Claude Code first (runs on their plan), then their Anthropic key, then the fully-local
    /// model (always works, no key, nothing leaves the device); within each, the mode's model first,
    /// then lighter models that are likelier to be available / within limits.
    private func autoFallback(transcript: String, systemPrompt: String, userText: String, fast: Bool) async throws -> String {
        var backends: [RepromptBackend] = []
        if ClaudeCode.isAvailable, !fast { backends.append(.claudeCode) }   // skip the slow CLI on the notes fast-path
        if let k = Keychain.anthropicKey, !k.isEmpty { backends.append(.apiKey) }
        backends.append(.localLLM)   // final always-works fallback (on-device, no key)
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
        // which dwarfs the generation. For notes, never spawn it — swap to a fast no-spawn call: the
        // user's Anthropic key (direct HTTP) if present, otherwise the fully-local model. Never a
        // hosted company call (there is no company AI backend anymore).
        if fast, backend == .claudeCode {
            if let key = Keychain.anthropicKey, !key.isEmpty { backend = .apiKey; provider = .anthropic }
            else { backend = .localLLM }
        }
        switch backend {
        case .auto:   // unreachable (resolved never returns .auto), satisfy exhaustiveness
            return try await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel)
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

    // MARK: Context mode (vision) — send a screenshot + the spoken request.
    // Vision needs a multimodal model. We use whichever provider the "My API key"/OpenRouter
    // backend is set to, when its key is present. The Claude CLI and local engines can't take
    // images, so vision degrades to a text-only reprompt on those (never a hosted company call).
    /// True when the CURRENTLY-selected backend can actually see a screenshot. The Claude Code CLI
    /// and local text models can't, so they report false and callers send a screenshot-free, text-only
    /// reprompt instead — a feature that offers screenshots still works on every backend, on the user's
    /// OWN engine, never a hosted company call. An apiKey/openRouter backend needs its key present.
    static var backendSupportsVision: Bool {
        switch Settings.shared.repromptBackend.resolved {
        case .apiKey:
            switch Settings.shared.apiKeyProvider {
            case .anthropic:  return !(Keychain.anthropicKey ?? "").isEmpty
            case .openAI:     return !(Keychain.openAIKey ?? "").isEmpty
            case .openRouter: return !(Keychain.openRouterKey ?? "").isEmpty
            }
        case .openRouter:      return !(Keychain.openRouterKey ?? "").isEmpty
        case .claudeCode, .localLLM, .auto: return false
        }
    }

    func repromptVision(transcript: String, systemPrompt: String, imagePNG: Data) async throws -> String {
        let userText = "Here is what I said. Use the screenshot to do it:\n\n<request>\n\(transcript)\n</request>"
        let b64 = imagePNG.base64EncodedString()

        // Context mode must use the SAME engine as the user's other modes — never silently fall to a
        // stray key or a hosted call the user didn't choose. Route by the selected backend; only the
        // apiKey/openRouter backends use their own keys (the user's explicit choice). Backends that
        // can't see images at all (Claude Code's CLI, the local model) degrade to a TEXT-ONLY reprompt
        // on that SAME engine — the request is processed without seeing the screen, on the user's own
        // Claude plan / local model. There is no hosted company backend to fall back to, by design.
        let backend = Settings.shared.repromptBackend.resolved
        let hasAnthropic = !(Keychain.anthropicKey ?? "").isEmpty
        let hasOpenAI = !(Keychain.openAIKey ?? "").isEmpty
        let hasOpenRouter = !(Keychain.openRouterKey ?? "").isEmpty

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
        case .claudeCode, .localLLM:
            // The Claude CLI and local models are text-only, but the user wants EVERY feature to work
            // on their chosen engine. Instead of a hard error, degrade to a text-only reprompt on the
            // SAME engine (it processes the spoken request without seeing the screen). NEVER a hosted
            // company call — there is no company AI backend anymore.
            return try await reprompt(transcript: transcript, systemPrompt: systemPrompt)
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
