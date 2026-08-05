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
    /// How many writes the PLANNER proposed, INCLUDING any entry this client couldn't turn into a
    /// usable action. When it exceeds the usable count something was dropped, and the feed must say
    /// so — silently presenting a proposed write as a chat reply is the invisible failure that made
    /// Action mode look like it had simply ignored the request.
    let proposedCount: Int

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
        // Decoded ELEMENT BY ELEMENT: one malformed entry used to fail the whole array decode and
        // wipe every proposed write with it.
        let write = (try? c.decode([FailableAction].self, forKey: .proposedWriteActions))
            ?? (try? c.decode([FailableAction].self, forKey: .proposedActions))
            ?? []
        proposedCount = write.count
        proposedActions = write.compactMap(\.value)
        clarification = try? c.decodeIfPresent(PlanClarification.self, forKey: .clarification)
        inputRequest = try? c.decodeIfPresent(PlanInputRequest.self, forKey: .inputRequest)
        followup = try? c.decodeIfPresent(PlanFollowup.self, forKey: .followup)
    }
}

/// One entry of `proposedWriteActions` that never fails the surrounding array decode.
private struct FailableAction: Decodable {
    let value: PlannedAction?
    init(from decoder: Decoder) throws { value = try? PlannedAction(from: decoder) }
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
        // confirm flow, and VerbaAction stay completely unchanged. The two Verba-task-manager shapes
        // (complete_task / set_task_reminder) live outside that parser's file, so they're resolved
        // here first; everything else falls through to Pipeline.parseAgenticAction untouched.
        if let nested = try? c.decode(AnyJSON.self, forKey: .action) {
            if let taskAction = Self.parseTaskAction(nested.value) {
                action = taskAction
            } else if let data = try? JSONSerialization.data(withJSONObject: ["action": nested.value]),
                      let raw = String(data: data, encoding: .utf8) {
                action = Pipeline.parseAgenticAction(raw)
            } else {
                action = nil
            }
        } else {
            action = nil
        }
    }

    /// Resolve the two Verba-task-manager action shapes the shared parser doesn't know about.
    /// Returns nil for any other type so decoding falls through to `Pipeline.parseAgenticAction`.
    private static func parseTaskAction(_ value: Any) -> VerbaAction? {
        guard let a = value as? [String: Any] else { return nil }
        let type = ((a["type"] as? String) ?? (a["kind"] as? String) ?? "")
            .lowercased().replacingOccurrences(of: "-", with: "_")
        let match = ((a["match"] as? String) ?? (a["task"] as? String) ?? (a["title"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case "complete_task", "completetask", "mark_done", "markdone", "finish_task", "complete":
            guard !match.isEmpty else { return nil }
            return .completeTask(match: match)
        case "set_task_reminder", "settaskreminder", "task_reminder", "remind_task", "remind_about_task":
            guard !match.isEmpty,
                  let dueStr = a["due"] as? String, let due = parseISO(dueStr) else { return nil }
            return .setTaskReminder(match: match, due: due)
        default:
            return nil
        }
    }

    /// Tolerant ISO8601 parse (with/without fractional seconds, or a bare full date).
    private static func parseISO(_ s: String) -> Date? {
        let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !str.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withFullDate]; f.timeZone = .current
        return f.date(from: str)
    }
}

/// A planner question shown inline in the feed when several connected apps fit equally (send via
/// Slack OR WhatsApp OR iMessage). Each option is one candidate; picking one re-plans with that
/// choice pinned.
struct PlanClarification: Decodable {
    let question: String
    let options: [PlanOption]

    // Tolerant like every other plan model here: a clarification that arrives without a question,
    // or with one malformed option, used to fail the whole decode and vanish — taking the user's
    // only way forward with it.
    private enum CodingKeys: String, CodingKey { case question, options, choices }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        question = (try? c.decode(String.self, forKey: .question)) ?? ""
        options = (try? c.decode([PlanOption].self, forKey: .options))
            ?? (try? c.decode([PlanOption].self, forKey: .choices))
            ?? []
    }
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

    /// A compact list of the user's OPEN (not-done) Verba tasks + sub-tasks, for the planner to match
    /// against when the user asks to complete or set a reminder on an EXISTING task. Capped at ~40
    /// items so the prompt stays small. Empty string when there are no open tasks.
    @MainActor
    private static func openTasksBlock() -> String {
        let df = DateFormatter(); df.locale = .current; df.dateStyle = .short; df.timeStyle = .short
        var lines: [String] = []
        outer: for project in TodoStore.shared.projects {
            for task in project.tasks {
                if !task.isComplete {
                    let due = task.deadline.map { ", due \(df.string(from: $0))" } ?? ""
                    lines.append("- \(task.title) (\(project.name)\(due))")
                    if lines.count >= 40 { break outer }
                }
                for sub in task.subtasks where !sub.done {
                    let due = sub.deadline.map { ", due \(df.string(from: $0))" } ?? ""
                    lines.append("- \(sub.title) (\(project.name) › \(task.title)\(due))")
                    if lines.count >= 40 { break outer }
                }
            }
        }
        guard !lines.isEmpty else { return "" }
        return "\n\nYOUR CURRENT OPEN TASKS (match these for complete_task / set_task_reminder):\n"
            + lines.joined(separator: "\n")
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
        // Hand the schemas to the executor's client: the action model flattens every argument to a
        // String on its way to the confirm card, and only the schema can tell which ones must be
        // turned back into arrays, objects, numbers or booleans before the tool runs.
        await MainActor.run { ComposioStore.shared.cacheToolSchemas(schemas) }

        var userMsg = "The user said:\n\n<command>\n\(transcript)\n</command>"
        // Inject the user's own OPEN Verba to-dos so the planner can match complete_task /
        // set_task_reminder against them (the relay has no access to these local tasks).
        let tasksBlock = await Self.openTasksBlock()
        if !tasksBlock.isEmpty { userMsg += tasksBlock }
        if let screenText, !screenText.isEmpty { userMsg += "\n\nON-SCREEN CONTEXT:\n\(screenText.prefix(4000))" }
        if let resolveChoice, !resolveChoice.isEmpty {
            userMsg += "\n\nThe user answered your clarification: they chose \"\(resolveChoice)\". Re-plan with that choice pinned."
        }

        // 2 — PLAN, on the user's own engine.
        var planObj = try Self.firstJSON(await Self.runLLM(system: sysPlan, user: userMsg))

        // 3 — read-only steps via the relay, then RESOLVE locally with the results.
        //
        // The relay runs these WITHOUT any confirmation, which is only acceptable while every step
        // is genuinely a read. Its own gate is a verb heuristic, and a slug like TWITTER_FOLLOW_LIST
        // passes it while actually changing the user's account. So we refuse write-shaped slugs HERE
        // too, before they leave the Mac, and hand the refusal to the resolve phase so the model
        // re-proposes them as confirmable writes instead of losing them.
        if let needs = planObj["needReads"] as? [[String: Any]], !needs.isEmpty {
            let safe = needs.filter { Self.isReadShaped(($0["tool"] as? String) ?? "") }
            let refused = needs.compactMap { $0["tool"] as? String }.filter { !Self.isReadShaped($0) }

            var block = ""
            if !safe.isEmpty {
                let readsResp = try await Self.post("/agent-reads", token: token, body: ["steps": safe], timeout: 180)
                block = readsResp["block"] as? String ?? ""
            }
            if !refused.isEmpty {
                block += "\n• REFUSED (never auto-run, they can change data): \(refused.joined(separator: ", "))"
                    + "\n  If the user asked for one of these, put it in proposedWriteActions so they can confirm it."
            }
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

    /// Tool-slug verbs that can CHANGE something. A slug carrying any of them is never eligible for
    /// the auto-executed read phase, whatever the planner claims — the confirmation gate is the
    /// whole product promise, and a step that runs without one has already broken it.
    private static let mutatingVerbs: Set<String> = [
        "CREATE", "ADD", "SEND", "POST", "UPDATE", "EDIT", "MODIFY", "PATCH", "PUT", "UPSERT",
        "DELETE", "REMOVE", "DESTROY", "TRASH", "ARCHIVE", "CLEAR", "EMPTY", "RESTORE",
        "MOVE", "RENAME", "SET", "WRITE", "UPLOAD", "INSERT", "APPEND", "REPLACE", "MERGE",
        "REPLY", "FORWARD", "SHARE", "INVITE", "ASSIGN", "TRANSFER", "GRANT", "REVOKE",
        "FOLLOW", "UNFOLLOW", "SUBSCRIBE", "UNSUBSCRIBE", "WATCH", "JOIN", "LEAVE",
        "LIKE", "UNLIKE", "VOTE", "PIN", "UNPIN", "MUTE", "BLOCK", "SNOOZE",
        "APPROVE", "REJECT", "SUBMIT", "PUBLISH", "CANCEL", "CLOSE", "REOPEN",
        "RUN", "EXECUTE", "TRIGGER", "START", "STOP", "ENABLE", "DISABLE", "OPERATION",
        "BOOK", "PAY", "CHARGE", "REFUND", "IMPORT", "SYNC", "DUPLICATE",
    ]

    /// Verbs that mean a tool only LOOKS things up. A slug must carry one of these to be eligible
    /// for the auto-executed read phase.
    private static let readingVerbs: Set<String> = [
        "GET", "LIST", "FETCH", "SEARCH", "READ", "FIND", "QUERY", "RETRIEVE", "LOOKUP",
        "VIEW", "SHOW", "COUNT", "DESCRIBE", "DETAILS", "DETAIL", "INFO", "STATUS", "STATS",
    ]

    /// True when a tool slug is safe to auto-run without confirmation.
    ///
    /// An ALLOW-list (it must name a reading verb) AND a DENY-list (it must name no mutating verb).
    /// The allow-list is the load-bearing half: a deny-list alone fails OPEN on every verb nobody
    /// thought of — GITHUB_STAR_A_REPOSITORY, HACKERNEWS_UPVOTE_ITEM — and auto-running one of those
    /// is exactly the confirmation bypass this gate exists to prevent. Refusing a genuine read costs
    /// only one confirmation (the refusal is handed back to the resolve phase, which re-proposes it
    /// as a confirmable write), so the conservative direction is the cheap one.
    static func isReadShaped(_ slug: String) -> Bool {
        // The first token is the toolkit (GMAIL_…), never the verb.
        let tokens = slug.split(separator: "_").dropFirst().map { $0.uppercased() }
        guard !tokens.isEmpty else { return false }
        guard tokens.contains(where: { readingVerbs.contains($0) }) else { return false }
        return !tokens.contains { mutatingVerbs.contains($0) }
    }

    // MARK: On-device planning engine

    /// Run one planning completion on the user's engine. `.auto`/unusable choices fall through to
    /// Claude Code (their subscription) or the local model — there is no hosted company backend.
    private static func runLLM(system: String, user: String) async throws -> String {
        let backend = Settings.shared.repromptBackend.resolved
        switch backend {
        case .claudeCode:
            return try await ClaudeCode.reprompt(systemPrompt: system, userText: user, model: "claude-sonnet-4-6")
        case .localLLM:
            return try await LocalLLM.chat(system: system, user: user, model: Settings.shared.localLLMModel)
        case .apiKey:
            // Honor the CHOSEN provider (Anthropic/OpenAI/OpenRouter), never assume Anthropic.
            switch Settings.shared.apiKeyProvider {
            case .anthropic:
                if let key = Keychain.anthropicKey, !key.isEmpty {
                    return try await anthropicDirect(key: key, system: system, user: user)
                }
            case .openAI:
                if let key = Keychain.openAIKey, !key.isEmpty {
                    return try await openAIDirect(key: key, system: system, user: user)
                }
            case .openRouter:
                if let key = Keychain.openRouterKey, !key.isEmpty {
                    return try await openRouterDirect(key: key, system: system, user: user)
                }
            }
        case .openRouter:
            if let key = Keychain.openRouterKey, !key.isEmpty {
                return try await openRouterDirect(key: key, system: system, user: user)
            }
        case .auto:
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

    /// Direct OpenAI call on the user's own key.
    private static func openAIDirect(key: String, system: String, user: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 120
        let chosen = Settings.shared.openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": chosen.isEmpty ? "gpt-4o" : chosen,
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

    /// Authed JSON POST to the relay. `timeout` matches what the route can actually take: the read
    /// executor runs real third-party calls and declares `maxDuration = 300` server-side, so the old
    /// flat 75s client timeout cut off reads the relay was still legitimately running.
    private static func post(_ path: String, token: String, body: [String: Any],
                             timeout: TimeInterval = 75) async throws -> [String: Any] {
        guard let url = URL(string: base + path) else { throw ActionAgentError.badResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = timeout
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            if code == 401 { throw ActionAgentError.notSignedIn }
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
                          "to", "subject", "body", "query", "name", "url", "script", "target", "input", "match"]
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
        var unfillable: [Int] = []   // indices turned into an input request instead of a doomed call
        for (i, p) in proposed.enumerated() {
            guard var action = p["action"] as? [String: Any],
                  (action["type"] as? String)?.lowercased() == "composio",
                  let slug = action["tool"] as? String,
                  let ip = schemas[slug] as? [String: Any] else { continue }
            var args = action["arguments"] as? [String: Any] ?? [:]
            let errs = validate(args, ip: ip)
            if !errs.isEmpty,
               let ipJSON = try? JSONSerialization.data(withJSONObject: ip),
               let argsJSON = try? JSONSerialization.data(withJSONObject: args) {
                let prompt = "Tool: \(slug)\nJSON schema of its input:\n\(String(data: ipJSON, encoding: .utf8) ?? "")"
                    + "\n\nCurrent (INVALID) arguments:\n\(String(data: argsJSON, encoding: .utf8) ?? "")"
                    + "\n\nValidation errors:\n- \(errs.joined(separator: "\n- "))"
                    + "\n\nReturn ONLY the corrected arguments JSON object. Keep the user's values; fix shapes/types; drop unknown fields."
                if let out = try? await runLLM(
                    system: "You repair tool-call arguments. Reply with ONLY a JSON object — the corrected arguments — no prose, no fence.",
                    user: prompt
                ), let fixed = try? firstJSON(out), validate(fixed, ip: ip).count < errs.count {
                    args = fixed
                    action["arguments"] = fixed
                    var item = p; item["action"] = action
                    proposed[i] = item
                }
            }
            // Still missing REQUIRED values? Executing would just bounce off the tool's schema with
            // an error the user can do nothing about. Ask them instead: the plan already has a
            // first-class shape for that (inputRequest → editable fields in the feed → same tool).
            // ONLY for a single-step plan: the feed renders an inputRequest INSTEAD of the proposed
            // writes, so converting one step of a batch would silently swallow the others.
            let missing = missingRequired(args, ip: ip)
            if !missing.isEmpty, proposed.count == 1, plan["inputRequest"] == nil {
                let label = (p["label"] as? String) ?? slug
                plan["inputRequest"] = inputRequest(tool: slug, label: label, args: args, ip: ip, missing: missing)
                unfillable.append(i)
            }
        }
        for i in unfillable.reversed() { proposed.remove(at: i) }
        plan["proposedWriteActions"] = proposed
    }

    /// Required schema keys with no usable value in `args`.
    private static func missingRequired(_ args: [String: Any], ip: [String: Any]) -> [String] {
        guard ip["properties"] is [String: Any] else { return [] }
        return ((ip["required"] as? [String]) ?? []).filter { key in
            guard let v = args[key] else { return true }
            if let s = v as? String { return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if let a = v as? [Any] { return a.isEmpty }
            return v is NSNull
        }
    }

    /// Build the `inputRequest` the feed renders as editable fields. Every required key becomes a
    /// field, PREFILLED with whatever the planner already resolved, so submitting can't lose the
    /// values it did get right (the feed rebuilds the call from these fields alone).
    private static func inputRequest(tool: String, label: String, args: [String: Any],
                                     ip: [String: Any], missing: [String]) -> [String: Any] {
        let props = (ip["properties"] as? [String: Any]) ?? [:]
        let required = (ip["required"] as? [String]) ?? []
        // Required keys first (they're what's blocking), then anything already filled in.
        var keys = required
        for k in args.keys.sorted() where !keys.contains(k) && props[k] != nil { keys.append(k) }
        let fields: [[String: Any]] = keys.prefix(8).map { key in
            let spec = props[key] as? [String: Any] ?? [:]
            let title = (spec["title"] as? String) ?? key.replacingOccurrences(of: "_", with: " ").capitalized
            let hint = (spec["description"] as? String) ?? ""
            let long = ["body", "message", "text", "content", "description", "comment"]
                .contains { key.lowercased().contains($0) }
            return [
                "key": key,
                "label": title,
                "placeholder": String(hint.prefix(80)),
                "value": stringValue(args[key]),
                "required": required.contains(key),
                "multiline": long,
            ]
        }
        let names = missing.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", ")
        return [
            "tool": tool,
            "label": label,
            "prompt": String(format: L("I still need: %@"), names),
            "fields": fields,
        ]
    }

    /// Render an existing argument as editable text (containers keep their JSON form; the executor
    /// re-types them on the way out — see ComposioStore.retyped).
    private static func stringValue(_ value: Any?) -> String {
        guard let value, !(value is NSNull) else { return "" }
        if let s = value as? String { return s }
        if let n = value as? NSNumber {
            return CFGetTypeID(n) == CFBooleanGetTypeID() ? (n.boolValue ? "true" : "false") : n.stringValue
        }
        if let d = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
           let s = String(data: d, encoding: .utf8) { return s }
        return ""
    }
}
