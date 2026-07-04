import Foundation

// MARK: - Plan models

/// The server-side ACTION PLANNER's reply, returned by `/api/composio/agent`. The relay runs the
/// read→propose loop with `claude-opus-4-8` (auto-executing READ-only Composio tools to gather
/// context), then hands back this plan: a JARVIS summary, the conversational lines to show in the
/// feed, any WRITE actions the user must confirm, and an optional clarification when several
/// connected apps fit equally. The Mac stays a thin confirm-and-execute client.
struct VerbaPlan: Decodable {
    /// ≤14-word, localized line: what the planner understood + intends to do.
    let summary: String
    /// One of the VerbaAction classifications (reminder|calendar|email|… |composio_multistep|chat).
    let classification: String
    /// JARVIS conversational lines to render in the feed, in order (locale of the user).
    let messages: [String]
    /// The single line spoken in the feed after a write succeeds (locale). Optional.
    let announce: String?
    /// WRITE actions the user confirms before anything happens. Empty for a pure read / chat reply.
    let proposedActions: [PlannedAction]
    /// Present only when the planner needs the user to pick between equally-good candidates.
    let clarification: PlanClarification?
    /// Present when a connected-app WRITE needs values the user didn't give — the feed shows
    /// editable fields the user fills in, then the tool runs with those arguments.
    let inputRequest: PlanInputRequest?
    /// An optional next step to offer AFTER the action succeeds (e.g. "Invite people to the event?").
    let followup: PlanFollowup?

    private enum CodingKeys: String, CodingKey {
        case summary, classification, messages, announce
        case proposedActions, proposedWriteActions
        case clarification, inputRequest, followup
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary = (try? c.decode(String.self, forKey: .summary)) ?? ""
        classification = (try? c.decode(String.self, forKey: .classification)) ?? "chat"
        messages = (try? c.decode([String].self, forKey: .messages)) ?? []
        announce = try? c.decodeIfPresent(String.self, forKey: .announce)
        // The relay names the field `proposedWriteActions`; accept the shorter `proposedActions` too.
        let write = (try? c.decode([PlannedAction].self, forKey: .proposedWriteActions))
            ?? (try? c.decode([PlannedAction].self, forKey: .proposedActions))
            ?? []
        proposedActions = write
        clarification = try? c.decodeIfPresent(PlanClarification.self, forKey: .clarification)
        inputRequest = try? c.decodeIfPresent(PlanInputRequest.self, forKey: .inputRequest)
        followup = try? c.decodeIfPresent(PlanFollowup.self, forKey: .followup)
    }
}

/// A suggested next step shown after an action succeeds. Accepting re-plans `intent` as if the
/// user had spoken it (so it flows through the same confirm / fill-in / execute path).
struct PlanFollowup: Decodable {
    let question: String
    let intent: String
    private enum CodingKeys: String, CodingKey { case question, intent }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        question = (try? c.decode(String.self, forKey: .question)) ?? ""
        intent = (try? c.decode(String.self, forKey: .intent)) ?? ""
    }
}

/// A request to collect missing arguments for a connected-app tool via editable text fields.
struct PlanInputRequest: Decodable {
    /// The composio tool slug to run once the fields are filled.
    let tool: String
    /// Short action label for the feed + the submit button (localized).
    let label: String
    /// One line explaining what's needed (localized). May be empty.
    let prompt: String
    let fields: [PlanInputField]

    private enum CodingKeys: String, CodingKey { case tool, label, prompt, fields }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tool = (try? c.decode(String.self, forKey: .tool)) ?? ""
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        prompt = (try? c.decode(String.self, forKey: .prompt)) ?? ""
        fields = (try? c.decode([PlanInputField].self, forKey: .fields)) ?? []
    }
}

/// One editable field the user fills in (maps to a tool argument under `key`).
struct PlanInputField: Decodable, Identifiable {
    /// The tool's EXACT argument name (e.g. recipient_email).
    let key: String
    let label: String
    let placeholder: String
    let value: String        // prefilled by the planner, or empty
    let required: Bool
    let multiline: Bool
    var id: String { key }

    private enum CodingKeys: String, CodingKey { case key, label, placeholder, value, required, multiline }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? c.decode(String.self, forKey: .key)) ?? ""
        label = (try? c.decode(String.self, forKey: .label)) ?? key
        placeholder = (try? c.decode(String.self, forKey: .placeholder)) ?? ""
        value = (try? c.decode(String.self, forKey: .value)) ?? ""
        required = (try? c.decode(Bool.self, forKey: .required)) ?? true
        multiline = (try? c.decode(Bool.self, forKey: .multiline)) ?? false
    }
}

/// One proposed WRITE the planner wants to perform. `action` carries the raw `{"action":{…}}`
/// envelope verbatim, so it decodes through the EXISTING `Pipeline.parseAgenticAction` — no new
/// decode path. `label`/`rationale` are localized, human-readable lines for the feed card.
struct PlannedAction: Decodable, Identifiable {
    let id = UUID()
    /// The VerbaAction classification (reminder|calendar|email|message|composio|…).
    let kind: String
    /// Short localized label, e.g. "Reminder · eat cake · in 10 min".
    let label: String
    /// Why the planner chose this (one line, localized). May be empty.
    let rationale: String
    /// The resolved `VerbaAction`, decoded from the planner's `{"action":{…}}` shape.
    let action: VerbaAction?

    private enum CodingKeys: String, CodingKey { case kind, label, rationale, action }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? c.decode(String.self, forKey: .kind)) ?? ""
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        rationale = (try? c.decode(String.self, forKey: .rationale)) ?? ""

        // The planner emits exactly today's VerbaActionJSON under "action". Re-serialize that nested
        // object back to a JSON string and run it through the one true parser so the executor, the
        // confirm flow, and VerbaAction stay completely unchanged.
        if let nested = try? c.decode(AnyJSON.self, forKey: .action),
           let data = try? JSONSerialization.data(withJSONObject: ["action": nested.value]),
           let raw = String(data: data, encoding: .utf8) {
            action = Pipeline.parseAgenticAction(raw)
        } else {
            action = nil
        }
    }
}

/// A planner question shown inline in the feed when several connected apps fit equally (send via
/// Slack OR WhatsApp OR iMessage). Each option is one candidate; picking one re-plans with that
/// choice pinned.
struct PlanClarification: Decodable {
    let question: String
    let options: [PlanOption]
}

struct PlanOption: Decodable, Identifiable {
    let id: String
    let label: String

    private enum CodingKeys: String, CodingKey { case id, label }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        label = (try? c.decode(String.self, forKey: .label)) ?? id
    }
}

/// A minimal type-erased JSON box so we can decode the planner's free-form `action` object and
/// re-serialize it without modeling every tool's argument schema.
private struct AnyJSON: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { value = v }
        else if let v = try? c.decode(Int.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if let v = try? c.decode([String: AnyJSON].self) { value = v.mapValues { $0.value } }
        else if let v = try? c.decode([AnyJSON].self) { value = v.map { $0.value } }
        else if c.decodeNil() { value = NSNull() }
        else { value = NSNull() }
    }
}

// MARK: - Errors

enum ActionAgentError: LocalizedError {
    case http(Int, String)
    case badResponse
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case let .http(code, msg):
            return msg.isEmpty ? String(format: L("The action assistant couldn't be reached (HTTP %d)."), code) : msg
        case .badResponse:
            return L("The action assistant returned an unexpected response.")
        case .notSignedIn:
            return L("Sign in to Verba to use the action assistant.")
        }
    }
}

// MARK: - Client

/// The ON-DEVICE JARVIS planner. The relay only provides what must stay server-side — the
/// connected-toolkit context (`/agent-context`, no model call) and read-only tool execution
/// (`/agent-reads`, COMPOSIO_API_KEY) — while the PLANNING LLM runs here, on the user's own
/// engine: their Claude Code subscription, their local model, or their own key. The server never
/// spends Anthropic API credits for JARVIS.
final class ActionAgentClient {
    static let shared = ActionAgentClient()
    private init() {}

    private static let base = "https://verba.run/api/composio"

    /// NOW as a LOCAL ISO8601 with the device's UTC offset (e.g. 2026-06-11T23:01:46+02:00), so the
    /// planner reasons in the user's wall-clock time instead of converting from UTC.
    private static func localNowISO() -> String {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone.current
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }

    /// Plan an Action-mode command: fetch the planner context from the relay, run the planning
    /// model ON-DEVICE, let the relay execute any read-only steps, resolve, then validate/repair
    /// the proposed arguments against the real schemas.
    func plan(transcript: String,
              screenText: String? = nil,
              resolveChoice: String? = nil) async throws -> VerbaPlan {
        guard let token = AuthToken.current, !token.isEmpty else { throw ActionAgentError.notSignedIn }

        // 1 — context (prompts + schemas), built server-side from the user's connected toolkits.
        var ctxBody: [String: Any] = [
            "transcript": transcript,
            "timezone": TimeZone.current.identifier,
            "locale": Locale.current.identifier,
            "nowISO": Self.localNowISO(),
            "shortcuts": ActionExecutor().availableShortcuts(),
            "searchTargets": Settings.shared.searchTargets.map(\.name),
            "disabled": Array(Settings.shared.disabledActions),
        ]
        if let resolveChoice, !resolveChoice.isEmpty { ctxBody["resolveChoice"] = resolveChoice }
        let ctx = try await Self.post("/agent-context", token: token, body: ctxBody)
        guard let sysPlan = ctx["systemPlan"] as? String,
              let sysResolve = ctx["systemResolve"] as? String else { throw ActionAgentError.badResponse }
        let schemas = ctx["schemas"] as? [String: Any] ?? [:]

        var userMsg = "The user said:\n\n<command>\n\(transcript)\n</command>"
        if let screenText, !screenText.isEmpty { userMsg += "\n\nON-SCREEN CONTEXT:\n\(screenText.prefix(4000))" }
        if let resolveChoice, !resolveChoice.isEmpty {
            userMsg += "\n\nThe user answered your clarification: they chose \"\(resolveChoice)\". Re-plan with that choice pinned."
        }

        // 2 — PLAN, on the user's own engine.
        var planObj = try Self.firstJSON(await Self.runLLM(system: sysPlan, user: userMsg))

        // 3 — read-only steps via the relay, then RESOLVE locally with the results.
        if let needs = planObj["needReads"] as? [[String: Any]], !needs.isEmpty {
            let readsResp = try await Self.post("/agent-reads", token: token, body: ["steps": needs])
            let block = readsResp["block"] as? String ?? ""
            let resolveMsg = userMsg
                + "\n\nREAD RESULTS (you requested these; use them to produce concrete proposedWriteActions, needReads MUST be []):\n"
                + block
            planObj = try Self.firstJSON(await Self.runLLM(system: sysResolve, user: resolveMsg))
        }

        // 4 — self-correct the plan SHAPE (weaker models flatten it), then validate the proposed
        // composio arguments against the real schemas and repair once.
        Self.normalizePlan(&planObj)
        await Self.repairInvalidActions(&planObj, schemas: schemas)

        // 5 — decode into the app's plan model (same JSON contract as before).
        let data = try JSONSerialization.data(withJSONObject: planObj)
        guard let plan = try? JSONDecoder().decode(VerbaPlan.self, from: data) else {
            throw ActionAgentError.badResponse
        }
        return plan
    }

    // MARK: On-device planning engine

    /// Run one planning completion on the user's engine. `.verba`/unusable choices fall through to
    /// Claude Code (their subscription) or the local model — NEVER the server's Anthropic key.
    private static func runLLM(system: String, user: String) async throws -> String {
        let backend = Settings.shared.repromptBackend.resolved
        switch backend {
        case .claudeCode:
            return try await ClaudeCode.reprompt(systemPrompt: system, userText: user, model: "claude-sonnet-4-6")
        case .localLLM:
            return try await LocalLLM.chat(system: system, user: user, model: Settings.shared.localLLMModel)
        case .apiKey:
            if let key = Keychain.anthropicKey, !key.isEmpty {
                return try await anthropicDirect(key: key, system: system, user: user)
            }
        case .openRouter:
            if let key = Keychain.openRouterKey, !key.isEmpty {
                return try await openRouterDirect(key: key, system: system, user: user)
            }
        case .verba, .auto:
            break
        }
        // Fallback chain for hosted/auto or a chosen-but-missing key.
        if ClaudeCode.isAvailable {
            return try await ClaudeCode.reprompt(systemPrompt: system, userText: user, model: "claude-sonnet-4-6")
        }
        return try await LocalLLM.chat(system: system, user: user, model: Settings.shared.localLLMModel)
    }

    /// Direct Anthropic call on the USER'S OWN key (their explicit backend choice).
    private static func anthropicDirect(key: String, system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 120
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "claude-sonnet-4-6", "max_tokens": 8000, "system": system,
            "messages": [["role": "user", "content": user]],
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw ActionAgentError.http(code, "") }
        let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let parts = (obj?["content"] as? [[String: Any]]) ?? []
        return parts.compactMap { ($0["type"] as? String) == "text" ? $0["text"] as? String : nil }.joined()
    }

    /// Direct OpenRouter call on the user's own key.
    private static func openRouterDirect(key: String, system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 120
        let chosen = Settings.shared.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": chosen.isEmpty ? "anthropic/claude-sonnet-4.5" : chosen,
            "messages": [["role": "system", "content": system], ["role": "user", "content": user]],
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw ActionAgentError.http(code, "") }
        let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let choices = (obj?["choices"] as? [[String: Any]]) ?? []
        let msg = choices.first?["message"] as? [String: Any]
        return msg?["content"] as? String ?? ""
    }

    // MARK: Plumbing

    /// Authed JSON POST to the relay.
    private static func post(_ path: String, token: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: base + path) else { throw ActionAgentError.badResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 75
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let msg = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["error"] as? String
            throw ActionAgentError.http(code, msg ?? "")
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ActionAgentError.badResponse
        }
        return obj
    }

    /// First balanced {...} in a model reply (tolerates prose / code fences).
    private static func firstJSON(_ raw: String) throws -> [String: Any] {
        guard let open = raw.firstIndex(of: "{"), let close = raw.lastIndex(of: "}"), open < close,
              let data = String(raw[open...close]).data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ActionAgentError.badResponse
        }
        return obj
    }

    // MARK: Validation + one-shot repair (against the real tool schemas)

    /// Shallow-but-strict schema check: required fields present, arrays are arrays, objects are
    /// objects, scalars typed right. Returns human-readable problems ([] = valid).
    private static func validate(_ args: [String: Any], ip: [String: Any]) -> [String] {
        guard let props = ip["properties"] as? [String: Any] else { return [] }
        var errs: [String] = []
        for r in (ip["required"] as? [String]) ?? [] {
            let v = args[r]
            if v == nil || (v as? String)?.isEmpty == true { errs.append("missing required field \"\(r)\"") }
        }
        for (k, v) in args {
            guard let spec = props[k] as? [String: Any] else { errs.append("unknown field \"\(k)\""); continue }
            switch spec["type"] as? String {
            case "array" where !(v is [Any]):                errs.append("\"\(k)\" must be an ARRAY")
            case "object" where !(v is [String: Any]):       errs.append("\"\(k)\" must be an OBJECT")
            case "string" where !(v is String):              errs.append("\"\(k)\" must be a string")
            case "number" where !(v is NSNumber), "integer" where !(v is NSNumber):
                errs.append("\"\(k)\" must be a number")
            case "boolean" where !(v is Bool || v is NSNumber): errs.append("\"\(k)\" must be a boolean")
            default: break
            }
        }
        return errs
    }

    /// Validate every proposed composio action; on errors, one focused ON-DEVICE repair call.
    /// Self-correct the plan's SHAPE before decode. Small local models routinely flatten the contract
    /// (put type/tool/arguments directly on the action item instead of nesting under "action", use
    /// type:"write" instead of "composio", or drop kind/label). Rather than error, we reshape those
    /// common variants into the exact `{kind,label,action:{type:"composio",tool,arguments}}` the app
    /// decodes — so a weaker engine still executes instead of failing.
    private static func normalizePlan(_ plan: inout [String: Any]) {
        if plan["proposedWriteActions"] == nil, let alt = plan["proposedActions"] {
            plan["proposedWriteActions"] = alt
        }
        guard var items = plan["proposedWriteActions"] as? [[String: Any]] else { return }
        // Fields that belong to the inner VerbaAction (never the wrapper).
        let actionKeys = ["type", "tool", "arguments", "title", "start", "end", "due", "notes",
                          "to", "subject", "body", "query", "name", "url", "script", "target", "input"]
        for i in items.indices {
            var it = items[i]
            // 1 — lift a flattened action into `action` if the wrapper is missing one.
            if it["action"] == nil {
                var action: [String: Any] = [:]
                for k in actionKeys where it[k] != nil { action[k] = it[k] }
                if action["tool"] != nil || action["type"] != nil { it["action"] = action }
            }
            // 2 — any item carrying a composio `tool` IS a composio action, whatever type it claimed.
            if var action = it["action"] as? [String: Any] {
                let t = (action["type"] as? String)?.lowercased() ?? ""
                if action["tool"] != nil, t != "composio" { action["type"] = "composio" }
                it["action"] = action
            }
            // 3 — fill the wrapper fields the decoder requires.
            if (it["kind"] as? String) == nil { it["kind"] = "composio" }
            if (it["label"] as? String) == nil {
                it["label"] = ((it["action"] as? [String: Any])?["tool"] as? String) ?? "Action"
            }
            items[i] = it
        }
        plan["proposedWriteActions"] = items
    }

    private static func repairInvalidActions(_ plan: inout [String: Any], schemas: [String: Any]) async {
        guard var proposed = plan["proposedWriteActions"] as? [[String: Any]] else { return }
        for (i, p) in proposed.enumerated() {
            guard var action = p["action"] as? [String: Any],
                  (action["type"] as? String)?.lowercased() == "composio",
                  let slug = action["tool"] as? String,
                  let ip = schemas[slug] as? [String: Any] else { continue }
            let args = action["arguments"] as? [String: Any] ?? [:]
            let errs = validate(args, ip: ip)
            guard !errs.isEmpty,
                  let ipJSON = try? JSONSerialization.data(withJSONObject: ip),
                  let argsJSON = try? JSONSerialization.data(withJSONObject: args) else { continue }
            let prompt = "Tool: \(slug)\nJSON schema of its input:\n\(String(data: ipJSON, encoding: .utf8) ?? "")"
                + "\n\nCurrent (INVALID) arguments:\n\(String(data: argsJSON, encoding: .utf8) ?? "")"
                + "\n\nValidation errors:\n- \(errs.joined(separator: "\n- "))"
                + "\n\nReturn ONLY the corrected arguments JSON object. Keep the user's values; fix shapes/types; drop unknown fields."
            guard let out = try? await runLLM(
                system: "You repair tool-call arguments. Reply with ONLY a JSON object — the corrected arguments — no prose, no fence.",
                user: prompt
            ), let fixed = try? firstJSON(out) else { continue }
            if validate(fixed, ip: ip).count < errs.count {
                action["arguments"] = fixed
                var item = p; item["action"] = action
                proposed[i] = item
            }
        }
        plan["proposedWriteActions"] = proposed
    }
}
