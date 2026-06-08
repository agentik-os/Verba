import Foundation

/// Turns a plain-language description of a need ("I want a mode for writing
/// technical bug reports", spoken or typed) into a complete Verba mode.
///
/// It reuses the EXACT same reprompting backend + credentials as the dictation
/// pipeline (`Settings.repromptBackend.resolved` via `Reprompter`), so the user
/// configures their AI once and the mode-creation assistant inherits it for free,
/// be it Verba hosted, Claude Code, OpenRouter, an Anthropic key, or a local model.
enum ModeGenerator {

    struct Draft {
        var name: String
        var systemPrompt: String
        var model: String?          // a Verba Claude id, or nil for the global default
        var matchBundleIDs: [String]
        var raw: Bool
    }

    enum GenError: LocalizedError {
        case emptyDescription
        case unparseable(String)
        var errorDescription: String? {
            switch self {
            case .emptyDescription: return "Describe what the mode should do first."
            case .unparseable(let s): return "The assistant didn't return a usable mode.\n\(s)"
            }
        }
    }

    /// The model that designs the mode is told to write a prompt in Verba's house style.
    private static let metaSystem = """
    You design a "mode" for Verba, a dictation app. A mode is a system prompt that tells \
    Claude how to rewrite a raw voice transcript before it is pasted where the user is typing.

    The user will describe, in their own words, what they want this mode to do. From that \
    description, design ONE mode and return it as a single JSON object, nothing else (no prose, \
    no markdown, no code fence).

    JSON shape (use exactly these keys):
    {
      "name": "1-2 word mode name, Title Case",
      "systemPrompt": "the full system prompt Claude will follow for this mode",
      "model": "claude-haiku-4-5" | "claude-sonnet-4-6" | "claude-opus-4-8" | "",
      "matchBundleIDs": ["macOS bundle ids of apps where this mode fits, may be empty"],
      "raw": false
    }

    Rules for the systemPrompt you write:
    - Build on Verba's house style below. Keep its guarantees unless the user explicitly wants \
    a transformation (summarize, translate, extract, change tone): only then may you relax \
    "preserve everything".
    - It must end by telling the model to output ONLY the resulting text, no preamble, no quotes.
    - NEVER instruct the use of em dashes, en dashes, or spaced hyphens.
    - Always detect and keep the speaker's language unless the user's description says otherwise.

    Verba's house style to build on:
    \"\"\"
    \(faithfulCoreForGenerator)
    \"\"\"

    Picking "model": haiku for short/simple cleanups, sonnet for general writing, opus for \
    complex reasoning or code. Use "" to inherit the user's default.
    Picking "raw": true ONLY if the user wants their words transcribed verbatim with NO rewriting; \
    then "systemPrompt" can be a one-line note and "model" must be "".
    Common bundle ids: VS Code com.microsoft.VSCode, Xcode com.apple.dt.Xcode, Slack \
    com.tinyspeck.slackmacgap, Mail com.apple.mail, WhatsApp net.whatsapp.WhatsApp, Telegram \
    ru.keepcoder.Telegram, Notes com.apple.Notes, Notion notion.id. Only include apps that clearly fit.
    """

    static func generate(from description: String) async throws -> Draft {
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !desc.isEmpty else { throw GenError.emptyDescription }

        // Sonnet is a good default designer; honor the cloud default if the user set one.
        let designer = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let r = Reprompter(model: designer)
        let raw = try await r.reprompt(transcript: desc, systemPrompt: metaSystem)
        return try parse(raw)
    }

    /// Extract the JSON object even if the model wrapped it in a code fence or added stray text.
    static func parse(_ text: String) throws -> Draft {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards),
           open.lowerBound <= close.lowerBound {
            // Closed range to the '}' character itself, never past it (endIndex would trap).
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw GenError.unparseable(text)
        }
        let name = (obj["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = (obj["systemPrompt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty, let prompt, !prompt.isEmpty else { throw GenError.unparseable(text) }

        let rawMode = obj["raw"] as? Bool ?? false
        let modelRaw = (obj["model"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let allowed = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
        let model = (!rawMode && allowed.contains(modelRaw)) ? modelRaw : nil
        let bundles = (obj["matchBundleIDs"] as? [Any])?
            .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []

        return Draft(name: name, systemPrompt: prompt, model: model, matchBundleIDs: bundles, raw: rawMode)
    }
}

/// Verba's faithful-editing core, duplicated here as a generator reference so the
/// designer model writes prompts in the same house style as the built-in modes.
private let faithfulCoreForGenerator = """
You are a meticulous editor cleaning up a voice transcript. Your job is to improve HOW it is \
written (grammar, punctuation, word choice, phrasing, order of sentences), so it reads as if the \
speaker had written it carefully themselves, while preserving EVERYTHING they said: every idea, \
instruction, detail, name, number, and nuance. Do not summarize, add information, or react to the \
content. Resolve self-corrections to the final intended wording. Detect the speaker's language and \
write the output in that same language unless they explicitly ask for another. Output ONLY the \
rewritten text, no preamble, no quotes.
"""
