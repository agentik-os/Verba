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

/// Sends a spoken Action-mode transcript to the server-side planner (`/api/composio/agent`) and
/// returns the resolved `VerbaPlan`. Authed by the signed-in app session
/// (`Authorization: Bearer <AuthToken.current>`) — the same pattern as `ComposioStore`. The relay
/// holds COMPOSIO_API_KEY + ANTHROPIC_API_KEY + the Composio entity (uid); the Mac never does.
final class ActionAgentClient {
    static let shared = ActionAgentClient()
    private init() {}

    private static let endpoint = "https://verba.run/api/composio/agent"

    /// NOW as a LOCAL ISO8601 with the device's UTC offset (e.g. 2026-06-11T23:01:46+02:00), so the
    /// planner reasons in the user's wall-clock time instead of converting from UTC.
    private static func localNowISO() -> String {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone.current
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }

    /// Plan an Action-mode command.
    /// - Parameters:
    ///   - transcript: the spoken command, verbatim.
    ///   - screenText: optional on-screen context (when the command is screen-grounded).
    ///   - resolveChoice: when re-planning after a clarification, the chosen option id.
    ///   - readResults: when the relay needs a second "resolve" pass, the read outputs to feed back.
    func plan(transcript: String,
              screenText: String? = nil,
              resolveChoice: String? = nil) async throws -> VerbaPlan {
        guard let token = AuthToken.current, !token.isEmpty else { throw ActionAgentError.notSignedIn }
        guard let url = URL(string: Self.endpoint) else { throw ActionAgentError.badResponse }

        var body: [String: Any] = [
            "transcript": transcript,
            "timezone": TimeZone.current.identifier,
            "locale": Locale.current.identifier,
            "nowISO": Self.localNowISO(),
            "shortcuts": ActionExecutor().availableShortcuts(),
            "searchTargets": Settings.shared.searchTargets.map(\.name),
            // The actions the user turned OFF in Settings ▸ Action mode — the planner must never
            // emit these (the relay forwards them into the prompt's DISABLED list).
            "disabled": Array(Settings.shared.disabledActions),
        ]
        if let screenText, !screenText.isEmpty { body["screenText"] = screenText }
        if let resolveChoice, !resolveChoice.isEmpty { body["resolveChoice"] = resolveChoice }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 75   // generous for a 2-phase read→plan; the feed watchdog backs it up
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let msg = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["error"] as? String
            throw ActionAgentError.http(code, msg ?? (String(data: data, encoding: .utf8) ?? ""))
        }
        do {
            return try JSONDecoder().decode(VerbaPlan.self, from: data)
        } catch {
            throw ActionAgentError.badResponse
        }
    }
}
