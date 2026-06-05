import Foundation
import Combine

enum TranscriptionEngine: String, Codable, CaseIterable, Identifiable {
    case openAI         // gpt-4o-transcribe (cloud, BYOK)
    case local          // WhisperKit large-v3-turbo (on-device)
    var id: String { rawValue }
    var label: String {
        switch self {
        case .openAI: return "OpenAI (cloud)"
        case .local:  return "Local (on-device)"
        }
    }
}

/// A reprompting profile: a system prompt for Claude + optional app bundle IDs it auto-matches.
struct Profile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var systemPrompt: String
    var matchBundleIDs: [String] = []   // frontmost-app bundle IDs that auto-select this profile
    var builtin: Bool = false
}

extension Profile {
    static let vibeCoding = Profile(
        name: "Vibe coding",
        systemPrompt: """
        You restructure a raw, stream-of-consciousness voice transcript into a clean, well-ordered \
        prompt for a coding agent (Claude Code, Cursor, etc.). The speaker jumps around, corrects \
        themselves, and thinks out loud. Your job:
        - Keep ALL of the speaker's intent and concrete details. Never invent requirements.
        - Reorder into: context, goal, concrete steps / changes, constraints, and any open questions.
        - Resolve self-corrections to the final intended meaning ("no wait, actually X" → just X).
        - Use clear markdown. Be concise but complete. Output ONLY the restructured prompt, no preamble.
        Write in the same language the speaker used.
        """,
        matchBundleIDs: ["com.todesktop.230313mzl4w4u92", "com.microsoft.VSCode", "com.apple.dt.Xcode",
                         "com.googlecode.iterm2", "com.apple.Terminal", "dev.warp.Warp-Stable"],
        builtin: true)

    static let message = Profile(
        name: "Message / comms",
        systemPrompt: """
        You turn a rambling voice transcript into a clear, concise written message (Slack, email, DM). \
        Keep the speaker's voice and intent; fix grammar, remove filler and false starts, order it \
        logically. Keep it natural, not corporate. Output ONLY the cleaned message, no preamble. \
        Write in the same language the speaker used.
        """,
        matchBundleIDs: ["com.tinyspeck.slackmacgap", "com.apple.mail", "com.hnc.Discord",
                         "ru.keepcoder.Telegram", "net.whatsapp.WhatsApp"],
        builtin: true)

    static let cleanup = Profile(
        name: "Clean transcript",
        systemPrompt: """
        You lightly clean a voice transcript: fix punctuation, capitalization, and obvious \
        transcription errors, remove filler words and false starts. Do NOT restructure or summarize — \
        preserve the speaker's wording and order. Output ONLY the cleaned text. Same language as input.
        """,
        builtin: true)

    static let defaults: [Profile] = [.vibeCoding, .message, .cleanup]
}

final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = UserDefaults.standard

    @Published var engine: TranscriptionEngine { didSet { d.set(engine.rawValue, forKey: "engine") } }
    @Published var localModel: String { didSet { d.set(localModel, forKey: "localModel") } }
    @Published var claudeModel: String { didSet { d.set(claudeModel, forKey: "claudeModel") } }
    @Published var language: String { didSet { d.set(language, forKey: "language") } }   // "" = auto-detect

    @Published var autoPaste: Bool { didSet { d.set(autoPaste, forKey: "autoPaste") } }
    @Published var copyToClipboard: Bool { didSet { d.set(copyToClipboard, forKey: "copyToClipboard") } }
    @Published var reviewBeforeSend: Bool { didSet { d.set(reviewBeforeSend, forKey: "reviewBeforeSend") } }
    @Published var autoDetectProfile: Bool { didSet { d.set(autoDetectProfile, forKey: "autoDetectProfile") } }
    @Published var repromptEnabled: Bool { didSet { d.set(repromptEnabled, forKey: "repromptEnabled") } }

    @Published var profiles: [Profile] { didSet { persistProfiles() } }
    @Published var activeProfileID: UUID { didSet { d.set(activeProfileID.uuidString, forKey: "activeProfileID") } }

    var activeProfile: Profile {
        profiles.first { $0.id == activeProfileID } ?? profiles.first ?? .cleanup
    }

    private init() {
        engine = TranscriptionEngine(rawValue: d.string(forKey: "engine") ?? "") ?? .openAI
        localModel = d.string(forKey: "localModel") ?? "large-v3-v20240930_turbo"
        claudeModel = d.string(forKey: "claudeModel") ?? "claude-sonnet-4-6"
        language = d.string(forKey: "language") ?? ""
        autoPaste = d.object(forKey: "autoPaste") as? Bool ?? true
        copyToClipboard = d.object(forKey: "copyToClipboard") as? Bool ?? true
        reviewBeforeSend = d.object(forKey: "reviewBeforeSend") as? Bool ?? false
        autoDetectProfile = d.object(forKey: "autoDetectProfile") as? Bool ?? true
        repromptEnabled = d.object(forKey: "repromptEnabled") as? Bool ?? true

        // Load profiles, seeding built-ins on first launch. Use a local so we never
        // read self.profiles before both stored properties are initialized.
        let loaded: [Profile]
        if let data = d.data(forKey: "profiles"),
           let saved = try? JSONDecoder().decode([Profile].self, from: data), !saved.isEmpty {
            loaded = saved
        } else {
            loaded = Profile.defaults
        }
        let savedActive = d.string(forKey: "activeProfileID").flatMap(UUID.init)
        activeProfileID = savedActive ?? loaded.first!.id
        profiles = loaded
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) { d.set(data, forKey: "profiles") }
    }

    /// Pick the profile that matches a frontmost app bundle id, if auto-detect is on.
    func profile(forBundleID bundleID: String?) -> Profile {
        if autoDetectProfile, let bid = bundleID,
           let match = profiles.first(where: { $0.matchBundleIDs.contains(bid) }) {
            return match
        }
        return activeProfile
    }
}
