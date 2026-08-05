import Foundation

enum RepromptError: LocalizedError {
    /// No API key stored for the named provider ("Anthropic", "OpenAI", "OpenRouter").
    case missingKey(String)
    /// Non-2xx from the named engine, with the response body (clipped for display).
    case http(String, Int, String)
    /// The named engine answered, but with no usable text.
    case empty(String)
    /// This step can't run at all, with an already-actionable reason (a missing permission, …).
    case unavailable(String)

    // Every message names WHICH engine failed: with five possible backends, "AI rewriting failed"
    // told the user nothing about which key, CLI or local server to go fix.
    var errorDescription: String? {
        switch self {
        case .missingKey(let provider):
            return "No \(provider) API key set. Add it in Verba ▸ Settings ▸ AI rewriting, or pick a different engine there."
        case .http(let engine, let code, let body):
            return "\(engine) failed (\(code)): \(Self.clip(body))"
        case .empty(let engine):
            return "\(engine) returned no text. Try again, or pick a different engine in Settings ▸ AI rewriting."
        case .unavailable(let reason):
            return reason
        }
    }

    /// Keep an error readable in a toast: an API error body can be a whole HTML error page.
    private static func clip(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > 300 else { return t }
        return String(t.prefix(300)) + "…"
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
            // A cancelled attempt (Esc, or the caller's deadline) is NOT an engine failure: recovering
            // from it would start a fresh local rewrite the user already asked to stop, and keep the
            // processing overlay spinning long past the cancel. Always surface it.
            if Self.isCancellation(error) { throw error }
            // SAFETY NET: an explicitly-chosen engine that is genuinely UNAVAILABLE (Claude Code CLI not
            // installed, no API key set, local server down) must not dead-end the dictation — fall back
            // to the fully-local model (which self-installs on demand). This recovers users the earlier
            // hosted-AI migration pinned to a single backend that later became unavailable. Transient/
            // content errors from a working engine still surface (we only catch unavailability).
            if backendOverride == nil, Self.isEngineUnavailable(error),
               Settings.shared.repromptBackend != .localLLM {
                let out = try await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel)
                return try Self.requireText(out, engine: "The local model")
            }
            throw error
        }
    }

    /// True for errors that mean "this engine can't run at all right now" (as opposed to a transient
    /// or content error from a working engine) — the cases where falling back to local is right.
    private static func isEngineUnavailable(_ error: Error) -> Bool {
        if case ClaudeCode.CCError.notInstalled = error { return true }
        if case RepromptError.missingKey(_) = error { return true }
        if case LocalLLM.LLMError.notRunning = error { return true }
        if case LocalLLM.LLMError.settingUp = error { return true }
        if case LocalLLM.LLMError.notDownloaded = error { return true }
        return false
    }

    /// True when the attempt was stopped rather than failed: the user pressed Esc, or the caller's
    /// deadline fired. Such an error must abort the WHOLE reprompt immediately instead of being
    /// retried on the next backend — otherwise one cancel is followed by every remaining engine
    /// being tried in turn, each with its own multi-minute ceiling.
    ///
    /// `URLError.cancelled` matters as much as `CancellationError`: URLSession reports a cancelled
    /// task that way, and `LocalLLM.chat` converts ANY URLSession failure into `.settingUp`, which
    /// `isEngineUnavailable` would otherwise read as "engine down, recover elsewhere".
    ///
    /// `TimeoutError` is deliberately NOT here. The caller's own deadline never arrives as one: the
    /// outer `withTimeout` cancels this Task, so it reaches us as `CancellationError`. A
    /// `TimeoutError` seen here can therefore only be a single ATTEMPT hitting its own ceiling (the
    /// Claude CLI budget in `runOnce`), and that is exactly the case that SHOULD fall through to the
    /// next engine — treating it as a cancel would let one wedged CLI dead-end the whole chain.
    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let u = error as? URLError, u.code == .cancelled { return true }
        return false
    }

    /// Normalize any engine's reply into the one shape every caller expects: trimmed, non-empty text,
    /// or a typed `.empty` naming the engine.
    ///
    /// This is load-bearing, not defensive dressing. `LocalLLM.chat` RETURNS "" on an empty
    /// completion instead of throwing, so an empty local rewrite used to travel back as a successful
    /// result and overwrite the user's dictation with nothing — the transcript was simply gone. It
    /// also let Automatic mode treat "" as a success and stop walking its fallback chain.
    private static func requireText(_ raw: String, engine: String) throws -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepromptError.empty(engine) }
        return text
    }

    /// Automatic mode: try every available (backend, model) pair until one returns text. Order: the
    /// user's Claude Code first (runs on their plan), then their Anthropic key, then the fully-local
    /// model (always works, no key, nothing leaves the device); within the Claude-speaking rungs, the
    /// mode's model first, then lighter models that are likelier to be available / within limits.
    private func autoFallback(transcript: String, systemPrompt: String, userText: String, fast: Bool) async throws -> String {
        // Each rung is a (backend, forced provider) pair. The provider is carried EXPLICITLY because
        // a rung earns its place by the key it has, which is not necessarily the provider the user
        // picked for the explicit "My API key" backend.
        var rungs: [(backend: RepromptBackend, provider: ApiKeyProvider?)] = []
        if ClaudeCode.isAvailable, !fast { rungs.append((backend: .claudeCode, provider: nil)) }   // skip the slow CLI on the notes fast-path
        // ANTHROPIC ONLY, deliberately. It is tempting to add a rung for every provider the user holds
        // a key for, but that breaks two promises. This setting is labelled "Automatic (Claude Code,
        // else local)", so a cloud call to a third party is not what the user agreed to; and
        // `Keychain.openAIKey` is the SAME slot the OpenAI *transcription* engine uses
        // (Transcriber.swift), so keying off mere presence would silently bill rewrites to a key
        // somebody stored only for cloud speech-to-text. A non-Anthropic key becomes a rewriting
        // engine only when the user explicitly picks it as their backend.
        if ApiKeyProvider.anthropic.hasKey { rungs.append((backend: .apiKey, provider: .anthropic)) }
        rungs.append((backend: .localLLM, provider: nil))   // final always-works fallback (on-device, no key)

        var lastError: Error?
        for rung in rungs {
            // Only the Claude-speaking rungs actually read `model`: OpenAI and OpenRouter take their
            // model from Settings and the local engine from `localLLMModel`, so walking the model list
            // there would just repeat a byte-identical request and double the failure latency.
            let usesModel = rung.backend == .claudeCode || (rung.backend == .apiKey && rung.provider == .anthropic)
            let models = usesModel ? Reprompter.fallbackModels(preferred: model) : [model]
            for m in models {
                // Stop the moment the user cancels: without this the chain keeps walking every
                // remaining backend and model after an Esc, each with its own multi-minute ceiling.
                try Task.checkCancellation()
                var attempt = self
                attempt.backendOverride = rung.backend
                attempt.model = m
                attempt.apiKeyProviderOverride = rung.provider
                do {
                    return try await attempt.runOnce(transcript: transcript, systemPrompt: systemPrompt, userText: userText, fast: fast)
                } catch {
                    // A cancel/deadline is the user stopping the work, not this engine failing:
                    // surface it instead of "recovering" onto the next one.
                    if Self.isCancellation(error) { throw error }
                    lastError = error
                    NSLog("Verba: Automatic reprompt attempt failed (\(rung.backend.rawValue) · \(m)): \(error.localizedDescription) — trying next")
                }
            }
        }
        // Every engine failed: surface the LAST real reason (an actionable, engine-named message)
        // rather than a generic one, so the user knows what to fix.
        throw lastError ?? RepromptError.empty("Automatic AI rewriting")
    }

    /// Model fallback order for Automatic mode: the chosen model first, then the balanced and lightest
    /// models. Deduped; only Claude models (every Automatic backend speaks them).
    static func fallbackModels(preferred: String) -> [String] {
        var list = preferred.hasPrefix("claude-") ? [preferred] : []
        for m in ["claude-sonnet-4-6", "claude-haiku-4-5"] where !list.contains(m) { list.append(m) }
        return list
    }

    /// Output-token budget for one rewrite, derived from the text being rewritten.
    ///
    /// A cleanup rewrite returns roughly as many tokens as it consumed, so a constant ceiling
    /// truncates exactly the users who dictate longest. 64000 is the current Sonnet/Opus output
    /// ceiling; the floor keeps short dictations on the same small, fast request as before.
    static func outputBudget(for text: String) -> Int {
        let inputTokens = text.count / 3          // conservative for accented text
        return min(max(4096, inputTokens * 3 / 2), 64000)
    }


    /// Request timeout for one rewrite. A 1-hour transcript genuinely takes minutes to regenerate,
    /// so a flat 180s aborted exactly the long dictations this pass is fixing. Short texts keep the
    /// old snappy ceiling so a failing backend still fails fast.
    static func requestTimeout(for text: String) -> TimeInterval {
        text.count > 6000 ? 900 : 180
    }

    /// A single reprompt attempt against one resolved backend + this instance's `model`.
    private func runOnce(transcript: String, systemPrompt: String, userText: String, fast: Bool) async throws -> String {
        var backend = backendOverride ?? Settings.shared.repromptBackend.resolved
        // The fast path below, and the Automatic chain, force `.apiKey` because a SPECIFIC provider's
        // key exists — which is not necessarily the one the user picked for the explicit "My API key"
        // backend. Track that choice separately from Settings so it can't route through the wrong one.
        var provider = apiKeyProviderOverride ?? Settings.shared.apiKeyProvider
        // Notes fast path: spawning the Claude CLI costs ~6-8s of pure startup overhead per call,
        // which dwarfs the generation. For notes, never spawn it — swap to a fast no-spawn call: a
        // direct HTTP call on a key the user holds if there is one, otherwise the fully-local model.
        // Never a hosted company call (there is no company AI backend anymore).
        if fast, backend == .claudeCode {
            // Anthropic only — same reasoning as the Automatic chain: never promote a key the user
            // stored for something else (Keychain.openAIKey is also the transcription key) into a
            // rewriting engine they did not choose.
            if ApiKeyProvider.anthropic.hasKey { backend = .apiKey; provider = .anthropic }
            else { backend = .localLLM }
        }
        switch backend {
        case .auto:   // unreachable (resolved never returns .auto), satisfy exhaustiveness
            return try Self.requireText(
                await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel),
                engine: "The local model")
        case .claudeCode:
            // No API key, uses the user's Claude subscription via the CLI.
            //
            // The CLI is the ONE engine with no deadline of its own: the HTTP engines carry a
            // `timeoutInterval`, but a wedged `claude` (stalled network, a prompt on stdin) blocks in
            // waitUntilExit forever, and every caller outside the main dictation path calls us with no
            // ceiling at all. Give it the same sized budget the HTTP engines get; the cancellation this
            // raises is what terminates the child process.
            let sys = systemPrompt, user = userText, chosen = model
            let out = try await withTimeout(seconds: Reprompter.requestTimeout(for: userText)) {
                try await ClaudeCode.reprompt(systemPrompt: sys, userText: user, model: chosen)
            }
            return try Self.requireText(out, engine: "Claude Code")
        case .openRouter:
            return try await openRouter(systemPrompt: systemPrompt, userText: userText)
        case .localLLM:
            return try Self.requireText(
                await LocalLLM.chat(system: systemPrompt, user: userText, model: Settings.shared.localLLMModel),
                engine: "The local model")
        case .apiKey:
            switch provider {
            case .openAI:     return try await openAIChat(systemPrompt: systemPrompt, userText: userText)
            case .openRouter: return try await openRouter(systemPrompt: systemPrompt, userText: userText)
            case .anthropic:  break   // falls through to the Anthropic path below
            }
        }
        guard let key = ApiKeyProvider.anthropic.storedKey else { throw RepromptError.missingKey("Anthropic") }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

        let payload: [String: Any] = [
            "model": model,
            // Sized from the transcript, not fixed. A cleanup rewrite is about as long as its
            // input, so a flat 16000 stopped mid-sentence on anything past roughly an hour of
            // speech: measured on a 21650-word transcript, the reply came back stop_reason
            // max_tokens with the last 27% of the content simply gone.
            "max_tokens": Reprompter.outputBudget(for: userText),
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userText]
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        return try Self.anthropicText(data, resp, engine: "Anthropic")
    }

    private struct ClaudeResponse: Decodable {
        struct Block: Decodable { let type: String; let text: String? }
        let content: [Block]
    }

    // MARK: Response normalization
    //
    // Every engine funnels through these two so that ANY reply becomes exactly one of: trimmed
    // non-empty text, or a typed error naming the engine and the real cause. Previously each call
    // site decoded straight into its response struct, so a body that didn't match the happy shape
    // surfaced as a bare `DecodingError` — "The data couldn't be read because it is missing" —
    // which names neither the engine nor what went wrong, and is not something a user can act on.

    /// The provider's own error text when a body carries one, in either shape they use:
    /// `{"error":{"message":…}}` or `{"error":"…"}`.
    ///
    /// This matters most on a 2xx: OpenRouter routinely answers **HTTP 200** with an error object
    /// and no `choices` (upstream provider refused, out of credit, model unavailable), so the
    /// status check alone lets a real failure through as an unreadable decode error.
    private static func providerErrorMessage(_ data: Data) -> String? {
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        if let e = obj["error"] as? [String: Any] {
            if let m = e["message"] as? String, !m.isEmpty { return m }
            return String(describing: e)
        }
        if let e = obj["error"] as? String, !e.isEmpty { return e }
        return nil
    }

    /// Non-2xx, or a 2xx body that is actually an error, as a typed engine-named error.
    private static func httpFailure(_ data: Data, _ resp: URLResponse, engine: String) -> RepromptError? {
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if !(200..<300).contains(code) {
            let body = providerErrorMessage(data) ?? String(data: data, encoding: .utf8) ?? ""
            return .http(engine, code, body)
        }
        if let msg = providerErrorMessage(data) { return .http(engine, code, msg) }
        return nil
    }

    /// Anthropic Messages reply → text, or an actionable error.
    private static func anthropicText(_ data: Data, _ resp: URLResponse, engine: String) throws -> String {
        if let failure = httpFailure(data, resp, engine: engine) { throw failure }
        guard let parsed = try? JSONDecoder().decode(ClaudeResponse.self, from: data) else {
            throw RepromptError.http(engine, (resp as? HTTPURLResponse)?.statusCode ?? 0,
                                     "unrecognized response: \(String(data: data, encoding: .utf8) ?? "")")
        }
        return try requireText(parsed.content.compactMap { $0.type == "text" ? $0.text : nil }.joined(),
                               engine: engine)
    }

    /// OpenAI-compatible reply (OpenAI, OpenRouter) → text, or an actionable error.
    private static func openAICompatibleText(_ data: Data, _ resp: URLResponse, engine: String) throws -> String {
        if let failure = httpFailure(data, resp, engine: engine) { throw failure }
        guard let parsed = try? JSONDecoder().decode(OpenAIResponse.self, from: data) else {
            throw RepromptError.http(engine, (resp as? HTTPURLResponse)?.statusCode ?? 0,
                                     "unrecognized response: \(String(data: data, encoding: .utf8) ?? "")")
        }
        return try requireText(parsed.choices?.first?.message.content ?? "", engine: engine)
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
        // Automatic is not a text-only engine: it is a CHAIN, and its cloud rung is whichever key
        // the user has. Reading the RESOLVED backend answered "no vision" for an Automatic user
        // with a perfectly good vision-capable key, purely because the Claude CLI happened to be
        // installed and won the resolve — see `visionProvider`.
        if Settings.shared.repromptBackend == .auto { return visionProvider != nil }
        switch Settings.shared.repromptBackend.resolved {
        case .apiKey:          return Settings.shared.apiKeyProvider.hasKey
        case .openRouter:      return ApiKeyProvider.openRouter.hasKey
        case .claudeCode, .localLLM, .auto: return false
        }
    }

    /// In Automatic mode, the provider a screenshot may go to: Anthropic, and ONLY Anthropic, because
    /// that is the single cloud rung Automatic already uses for text (`autoFallback`). Sending the
    /// user's screen to a provider Automatic never calls — least of all `Keychain.openAIKey`, which
    /// doubles as the transcription key — is not a decision this setting is allowed to make.
    /// nil = no Anthropic key, so Automatic degrades to a text-only reprompt as before.
    private static var visionProvider: ApiKeyProvider? {
        ApiKeyProvider.anthropic.hasKey ? .anthropic : nil
    }

    func repromptVision(transcript: String, systemPrompt: String, imagePNG: Data) async throws -> String {
        let userText = "Here is what I said. Use the screenshot to do it:\n\n<request>\n\(transcript)\n</request>"
        let b64 = imagePNG.base64EncodedString()

        // AUTOMATIC is a chain, not an engine: send the screenshot to whichever provider the user
        // actually has a key for. Resolving first sent Automatic users straight down the
        // `.claudeCode` arm whenever the CLI was installed, which THREW THE SCREENSHOT AWAY and
        // answered from text alone — while `autoFallback` was, in the same configuration, perfectly
        // willing to use that same key for text. Only with no key at all do we degrade.
        if Settings.shared.repromptBackend == .auto {
            switch Self.visionProvider {
            case .some(.anthropic):
                return try await anthropicVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .some(.openAI):
                return try await openAIVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .some(.openRouter):
                return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .none:
                // No vision-capable key at all: degrade to a text-only reprompt on the chain.
                return try await reprompt(transcript: transcript, systemPrompt: systemPrompt)
            }
        }

        // An EXPLICITLY chosen backend must use the SAME engine as the user's other modes — never
        // silently fall to a stray key, or to a hosted call, the user didn't choose. Backends that
        // can't see images at all (the Claude CLI, the local model) degrade to a TEXT-ONLY reprompt
        // on that SAME engine: the request is processed without seeing the screen, on the user's own
        // Claude plan / local model. There is no hosted company backend to fall back to, by design.
        switch Settings.shared.repromptBackend.resolved {
        case .apiKey:
            let provider = Settings.shared.apiKeyProvider
            guard provider.hasKey else {
                // Chosen provider's key is missing: never borrow another provider's key or account.
                throw RepromptError.missingKey(provider.label)
            }
            switch provider {
            case .anthropic:
                return try await anthropicVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .openAI:
                return try await openAIVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            case .openRouter:
                return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
            }
        case .openRouter:
            guard ApiKeyProvider.openRouter.hasKey else { throw RepromptError.missingKey("OpenRouter") }
            return try await openRouterVision(systemPrompt: systemPrompt, userText: userText, base64PNG: b64)
        case .claudeCode, .localLLM, .auto:
            // The Claude CLI and local models are text-only, but the user wants EVERY feature to work
            // on their chosen engine. Instead of a hard error, degrade to a text-only reprompt on the
            // SAME engine (it processes the spoken request without seeing the screen). NEVER a hosted
            // company call — there is no company AI backend anymore. (`.auto` is handled above and
            // never survives `.resolved`; degrading is the safe answer if it ever does.)
            return try await reprompt(transcript: transcript, systemPrompt: systemPrompt)
        }
    }

    private func anthropicVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = ApiKeyProvider.anthropic.storedKey else { throw RepromptError.missingKey("Anthropic") }
        // Context needs a vision-capable model; force one if the per-mode model isn't.
        let visionModel = model.hasPrefix("claude-") ? model : "claude-sonnet-4-6"

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

        let payload: [String: Any] = [
            "model": visionModel,
            "max_tokens": Reprompter.outputBudget(for: userText),
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
        return try Self.anthropicText(data, resp, engine: "Anthropic")
    }

    private func openAIVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = ApiKeyProvider.openAI.storedKey else { throw RepromptError.missingKey("OpenAI") }
        let chosen = Settings.shared.openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        // Default to a vision-capable OpenAI model.
        let modelID = chosen.isEmpty ? "gpt-4o" : chosen

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

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
        return try Self.openAICompatibleText(data, resp, engine: "OpenAI")
    }

    private func openRouterVision(systemPrompt: String, userText: String, base64PNG: String) async throws -> String {
        guard let key = ApiKeyProvider.openRouter.storedKey else { throw RepromptError.missingKey("OpenRouter") }
        let chosen = Settings.shared.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        // Default to a vision-capable model on OpenRouter.
        let modelID = chosen.isEmpty ? "anthropic/claude-3.7-sonnet" : chosen

        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("https://verba.run", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("Verba", forHTTPHeaderField: "X-Title")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

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
        return try Self.openAICompatibleText(data, resp, engine: "OpenRouter")
    }

    // MARK: OpenAI, BYO key, chosen model — one of the three "My API key" providers.
    private func openAIChat(systemPrompt: String, userText: String) async throws -> String {
        guard let key = ApiKeyProvider.openAI.storedKey else { throw RepromptError.missingKey("OpenAI") }
        let chosen = Settings.shared.openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = chosen.isEmpty ? "gpt-4o" : chosen

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

        let payload: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText],
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        return try Self.openAICompatibleText(data, resp, engine: "OpenAI")
    }

    // MARK: OpenRouter (OpenAI-compatible), BYO key, any model the user picks.
    private func openRouter(systemPrompt: String, userText: String) async throws -> String {
        guard let key = ApiKeyProvider.openRouter.storedKey else { throw RepromptError.missingKey("OpenRouter") }
        let chosen = Settings.shared.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = chosen.isEmpty ? "anthropic/claude-3.7-sonnet" : chosen

        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("https://verba.run", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("Verba", forHTTPHeaderField: "X-Title")
        req.timeoutInterval = Reprompter.requestTimeout(for: userText)

        let payload: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText],
            ],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        return try Self.openAICompatibleText(data, resp, engine: "OpenRouter")
    }

    private struct OpenAIResponse: Decodable {
        struct Choice: Decodable { struct Msg: Decodable { let content: String? }; let message: Msg }
        // OPTIONAL on purpose: OpenRouter answers HTTP 200 with `{"error":{…}}` and NO `choices`
        // when the upstream provider refuses. A non-optional array turned that into a raw
        // `DecodingError` and threw the provider's actual explanation away.
        let choices: [Choice]?
    }
}
