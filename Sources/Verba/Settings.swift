import Foundation
import Combine

enum RecordStyle: String, Codable, CaseIterable, Identifiable {
    case lock      // press to start, press again to send (Esc cancels)
    case direct    // hold ⌃⌥ to talk, release to send (push-to-talk)
    var id: String { rawValue }
    var label: String { self == .lock ? "Lock" : "Direct" }
    var help: String {
        self == .lock
            ? "Press a shortcut to start, press again to send. Esc cancels."
            : "Hold ⌃⌥ while you talk, release to send. Esc cancels."
    }
}

enum TranscriptionEngine: String, Codable, CaseIterable, Identifiable {
    case openAI                 // gpt-4o-transcribe (cloud, BYOK)
    case whisper = "local"      // WhisperKit (on-device); rawValue kept for migration
    case parakeet               // NVIDIA Parakeet TDT v3 (on-device, multilingual)
    var id: String { rawValue }
    var label: String {
        switch self {
        case .openAI:   return "OpenAI (cloud)"
        case .whisper:  return "Whisper (local)"
        case .parakeet: return "Parakeet (local · NVIDIA)"
        }
    }
    var isLocal: Bool { self != .openAI }
}

/// The humor style of the "loading" lines shown while Claude restructures.
/// `.off` shows a neutral word instead of a joke.
enum QuipTone: String, Codable, CaseIterable, Identifiable {
    case off
    case geek, dad, dry, absurdist, sarcastic, wholesome, corporate, noir
    case pirate, shakespeare, zen, scifi, gamer, chef, motivational, conspiracy, surreal
    var id: String { rawValue }
    var label: String {
        switch self {
        case .off: return "Off, just “Transmuting…”"
        case .geek: return "Geek / programmer"
        case .dad: return "Dad jokes"
        case .dry: return "Dry & deadpan"
        case .absurdist: return "Absurdist"
        case .sarcastic: return "Sarcastic"
        case .wholesome: return "Wholesome"
        case .corporate: return "Corporate buzzword"
        case .noir: return "Film-noir detective"
        case .pirate: return "Pirate"
        case .shakespeare: return "Shakespearean"
        case .zen: return "Zen koan"
        case .scifi: return "Sci-fi space crew"
        case .gamer: return "Gamer / RPG"
        case .chef: return "Cooking show"
        case .motivational: return "Over-the-top motivational"
        case .conspiracy: return "Conspiracy theorist"
        case .surreal: return "Surreal dream-logic"
        }
    }
    /// Instruction handed to Claude so the generated one-liners match the chosen humor.
    var styleInstruction: String {
        switch self {
        case .off: return ""
        case .geek: return "programmer / sci-fi / internet geek humor"
        case .dad: return "groan-worthy dad jokes and puns"
        case .dry: return "dry, deadpan, understated British wit"
        case .absurdist: return "absurdist, non-sequitur humor"
        case .sarcastic: return "sarcastic, lightly snarky humor (never mean)"
        case .wholesome: return "wholesome, warm, gently funny encouragement"
        case .corporate: return "satirical corporate buzzword-speak"
        case .noir: return "hard-boiled 1940s film-noir detective narration"
        case .pirate: return "swashbuckling pirate speak"
        case .shakespeare: return "mock-Shakespearean Elizabethan English"
        case .zen: return "calm zen koans, gently funny"
        case .scifi: return "dramatic sci-fi starship-crew chatter"
        case .gamer: return "RPG / video-game humor (loot, XP, quests)"
        case .chef: return "enthusiastic cooking-show narration"
        case .motivational: return "over-the-top motivational gym-coach hype"
        case .conspiracy: return "playful tinfoil-hat conspiracy humor"
        case .surreal: return "surreal dream-logic humor"
        }
    }
}

/// Look & position of the recording indicator.
enum OverlayStyle: String, Codable, CaseIterable, Identifiable {
    case floating   // glass pill, bottom-center (default)
    case island     // dark pill at the top of the screen, Dynamic-Island style
    case minimal    // tiny top bar, just the moving waveform, for power users
    var id: String { rawValue }
    var label: String {
        switch self {
        case .floating: return "Floating glass (bottom)"
        case .island:   return "Top island"
        case .minimal:  return "Minimal bar (top)"
        }
    }
}

/// Where the Claude reprompting runs: pay-per-token API key, or the user's
/// Claude Code subscription (Max/Pro plan) via the local `claude` CLI.
enum RepromptBackend: String, Codable, CaseIterable, Identifiable {
    case claudeCode, apiKey, openRouter
    var id: String { rawValue }
    var label: String {
        switch self {
        case .claudeCode: return "Claude Code (Max/Pro plan)"
        case .apiKey:     return "Anthropic API key"
        case .openRouter: return "OpenRouter (any model)"
        }
    }
}

// Carbon modifier masks (avoid importing Carbon here): control|option = 4096|2048.
private let kCtrlOpt: UInt32 = 4096 | 2048

/// What a shortcut is being assigned to (for conflict resolution).
enum ShortcutTarget: Equatable { case primary; case profile(UUID) }

/// The shared editing contract for every profile: improve HOW it's written,
/// never change WHAT was said. This is the fix for "Claude interprets too much".
private let faithfulCore = """
You are a meticulous editor cleaning up a voice transcript. The speaker dictated \
this out loud, so it has filler words, false starts, repetitions, and self-corrections.

Your ONLY job is to improve how it is written, grammar, punctuation, word choice, \
phrasing, and the order of sentences, so it reads as if the speaker had written it \
carefully themselves.

ABSOLUTE RULES, follow them exactly:
- Preserve EVERYTHING the speaker said: every idea, instruction, detail, name, \
number, and nuance. Keep their voice and their level of detail.
- DO NOT summarize, shorten, condense, generalize, or omit anything.
- DO NOT add information, examples, or interpretation that the speaker did not say.
- DO NOT answer, execute, or react to the content, you are editing text, not \
responding to it. If they describe a task, you rewrite their description of the \
task; you do not do the task.
- Resolve self-corrections to the final intended wording ("no wait, actually X" → X).
- Keep the same language the speaker used.
- NEVER use an em dash, an en dash, or a spaced hyphen. Write like a human: use commas, \
periods, parentheses, or colons instead. This is mandatory.

Output ONLY the rewritten text. No preamble, no notes, no quotes around it.
"""

/// A reprompting profile: a Claude editing prompt + an optional dedicated hotkey
/// + app bundle IDs it auto-matches.
struct Profile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var systemPrompt: String
    var matchBundleIDs: [String] = []
    var builtin: Bool = false
    var hotkeyCode: UInt32? = nil       // dedicated shortcut (Carbon keycode)
    var hotkeyMods: UInt32? = nil       // Carbon modifier mask
    var raw: Bool = false               // true = pure dictation, no Claude reprompting
    var model: String? = nil            // per-mode Claude model override (nil = global default)
}

extension Profile {
    static let coding = Profile(
        name: "Coding",
        systemPrompt: faithfulCore + """


        CONTEXT: the output is a prompt for a coding agent (Claude Code, Cursor, etc.).
        The speaker dictated feedback or a request, often long and out of order. Turn it
        into a precise, well-engineered prompt that an agent can act on without guessing:

        - Open with a one-line statement of the goal / desired outcome.
        - Then give the needed context (what exists today, the problem, where it happens).
        - Then the concrete work: an ordered list of changes/steps, in a logical sequence.
        - Then constraints, acceptance criteria, edge cases, and any open questions, \
        each only if the speaker mentioned them.
        - Keep EVERY technical detail verbatim: file paths, function/variable names, \
        commands, error messages, library/version names, numbers. Never paraphrase these.
        - Group related points; resolve self-corrections to the final intent.
        - Be unambiguous and imperative ("Add…", "Change…", "Fix…"), but do NOT invent \
        requirements, scope, or solutions the speaker didn't state, and do not over-engineer.
        - Use clean markdown (short headers / bullet lists) when it aids clarity.
        """,
        matchBundleIDs: ["com.todesktop.230313mzl4w4u92", "com.microsoft.VSCode", "com.apple.dt.Xcode",
                         "com.googlecode.iterm2", "com.apple.Terminal", "dev.warp.Warp-Stable"],
        builtin: true, hotkeyCode: 18 /* 1 */, hotkeyMods: kCtrlOpt, model: "claude-opus-4-8")

    static let polish = Profile(
        name: "Polish",
        systemPrompt: faithfulCore + """


        CONTEXT: professional writing (work email, Slack to a colleague or client, a \
        document). Make it clear, well-structured, and courteous, confident and concise, \
        in the speaker's own voice, never stiff or corporate. Tighten loose sentences and \
        order the points logically, but keep every point the speaker made.
        """,
        matchBundleIDs: ["com.tinyspeck.slackmacgap", "com.apple.mail", "com.microsoft.Outlook",
                         "com.readdle.smartemail-Mac", "notion.id"],
        builtin: true, hotkeyCode: 19 /* 2 */, hotkeyMods: kCtrlOpt, model: "claude-haiku-4-5")

    static let casual = Profile(
        name: "Casual",
        systemPrompt: faithfulCore + """


        CONTEXT: a casual personal message or note (text to a friend, a reminder, a quick \
        message). Keep it warm, natural, and relaxed, the speaker's everyday voice and \
        slang. Just clean it up and order it lightly; keep all the content and the casual tone.
        """,
        matchBundleIDs: ["net.whatsapp.WhatsApp", "ru.keepcoder.Telegram", "com.hnc.Discord",
                         "com.apple.MobileSMS", "com.apple.Notes"],
        builtin: true, hotkeyCode: 20 /* 3 */, hotkeyMods: kCtrlOpt, model: "claude-haiku-4-5")

    static let intent = Profile(
        name: "Intent",
        systemPrompt: """
        You receive a raw voice transcript with a SPECIAL TWO-PART STRUCTURE:
        1. INTENT, at the very start, the speaker states how they want the rest handled \
        (e.g. "turn what follows into a bug report", "rewrite the next part as an email to \
        my client", "give me the key decisions as bullet points", "just clean this up and \
        keep everything"). This is an instruction to YOU.
        2. CONTENT, everything after the intent: the material to transform.

        Your job:
        - Detect where the intent ends and the content begins.
        - Apply the intent FAITHFULLY to the content, and output only the result.
        - DO NOT include or restate the intent itself, it is a directive, not content.
        - The intent OVERRIDES defaults: if it asks you to summarize, extract, reformat, \
        change tone, translate, or filter, do exactly that. If the intent is vague or \
        absent, fall back to: improve wording and reorder systematically WITHOUT losing \
        any information.
        - Never add facts the speaker didn't provide. Resolve self-corrections to the \
        final intended meaning.
        - Keep the speaker's language unless the intent says otherwise.

        NEVER use an em dash, en dash, or a spaced hyphen; use commas, \
        periods, parentheses, or colons instead.

        Output ONLY the final result. No preamble, no echo of the intent, no commentary.
        """,
        builtin: true, hotkeyCode: 21 /* 4 */, hotkeyMods: kCtrlOpt, model: "claude-sonnet-4-6")

    static let flow = Profile(
        name: "Flow",
        systemPrompt: "(Free-flow dictation, your words are transcribed exactly, with no AI reprompting or reordering.)",
        builtin: true, hotkeyCode: 22 /* 6 */, hotkeyMods: kCtrlOpt, raw: true)

    static let custom = Profile(
        name: "Custom",
        systemPrompt: faithfulCore + """


        CONTEXT: (your own, edit this prompt in Settings to define exactly how Verba \
        should reorder and improve your dictation.)
        """,
        builtin: true, hotkeyCode: 23 /* 5 */, hotkeyMods: kCtrlOpt)

    static let defaults: [Profile] = [.flow, .intent, .polish, .coding, .casual, .custom]
}

final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = UserDefaults.standard

    // Bump when the built-in profiles change so users get the new prompts/shortcuts.
    static let profilesVersion = 11  // bumped: corrected no-dash wording in prompts

    @Published var engine: TranscriptionEngine { didSet { d.set(engine.rawValue, forKey: "engine") } }
    @Published var localModel: String { didSet { d.set(localModel, forKey: "localModel") } }
    @Published var claudeModel: String { didSet { d.set(claudeModel, forKey: "claudeModel") } }
    @Published var repromptBackend: RepromptBackend { didSet { d.set(repromptBackend.rawValue, forKey: "repromptBackend") } }
    @Published var openRouterModel: String { didSet { d.set(openRouterModel, forKey: "openRouterModel") } }
    @Published var overlayStyle: OverlayStyle { didSet { d.set(overlayStyle.rawValue, forKey: "overlayStyle") } }
    @Published var quipTone: QuipTone { didSet { d.set(quipTone.rawValue, forKey: "quipTone"); Quips.onToneChanged() } }
    @Published var language: String { didSet { d.set(language, forKey: "language") } }   // "" = auto-detect

    @Published var autoPaste: Bool { didSet { d.set(autoPaste, forKey: "autoPaste") } }
    @Published var copyToClipboard: Bool { didSet { d.set(copyToClipboard, forKey: "copyToClipboard") } }
    @Published var richTextPaste: Bool { didSet { d.set(richTextPaste, forKey: "richTextPaste") } }
    @Published var reviewBeforeSend: Bool { didSet { d.set(reviewBeforeSend, forKey: "reviewBeforeSend") } }
    @Published var autoDetectProfile: Bool { didSet { d.set(autoDetectProfile, forKey: "autoDetectProfile") } }
    @Published var useSelectionContext: Bool { didSet { d.set(useSelectionContext, forKey: "useSelectionContext") } }
    @Published var voiceCommands: Bool { didSet { d.set(voiceCommands, forKey: "voiceCommands") } }
    @Published var repromptEnabled: Bool { didSet { d.set(repromptEnabled, forKey: "repromptEnabled") } }
    @Published var recordStyle: RecordStyle { didSet { d.set(recordStyle.rawValue, forKey: "recordStyle") } }
    @Published var useFnAsPrimary: Bool { didSet { d.set(useFnAsPrimary, forKey: "useFnAsPrimary") } }
    @Published var onboarded: Bool { didSet { d.set(onboarded, forKey: "onboarded") } }
    @Published var showInDock: Bool { didSet { d.set(showInDock, forKey: "showInDock") } }

    // Global Style, extra instructions appended to every (non-raw) reprompt.
    @Published var styleEnabled: Bool { didSet { d.set(styleEnabled, forKey: "styleEnabled") } }
    @Published var styleText: String { didSet { d.set(styleText, forKey: "styleText") } }

    // Primary trigger shortcut (active/auto-detected mode). Default ⌃⌥Space.
    @Published var primaryKeyCode: UInt32 { didSet { d.set(Int(primaryKeyCode), forKey: "primaryKeyCode") } }
    @Published var primaryMods: UInt32 { didSet { d.set(Int(primaryMods), forKey: "primaryMods") } }

    @Published var profiles: [Profile] { didSet { persistProfiles() } }
    @Published var activeProfileID: UUID { didSet { d.set(activeProfileID.uuidString, forKey: "activeProfileID") } }

    // Pro entitlement (editing system prompts / custom modes is Pro-only).
    @Published var isPro: Bool { didSet { d.set(isPro, forKey: "verba.pro") } }
    @Published var proEmail: String { didSet { d.set(proEmail, forKey: "verba.email") } }
    @Published var referralCode: String { didSet { d.set(referralCode, forKey: "verba.referral") } }
    var referralLink: String { "https://verba.run/?ref=\(referralCode)" }
    @Published var username: String { didSet { d.set(username, forKey: "verba.username") } }
    /// The single account identity used everywhere (leaderboard, history, wishlist).
    var uid: String { referralCode.isEmpty ? "anon-" + (proEmail.isEmpty ? "local" : proEmail) : referralCode }

    var activeProfile: Profile {
        profiles.first { $0.id == activeProfileID } ?? profiles.first ?? .coding
    }

    /// Verify the subscription by email against verba.run and update `isPro`.
    @MainActor
    func verifyPro() async -> Bool {
        let ok = await Entitlement.verify(email: proEmail.trimmingCharacters(in: .whitespacesAndNewlines))
        isPro = ok
        return ok
    }

    private init() {
        engine = TranscriptionEngine(rawValue: d.string(forKey: "engine") ?? "") ?? .openAI
        localModel = d.string(forKey: "localModel") ?? "large-v3-v20240930_turbo"
        claudeModel = d.string(forKey: "claudeModel") ?? "claude-sonnet-4-6"
        repromptBackend = RepromptBackend(rawValue: d.string(forKey: "repromptBackend") ?? "") ?? .claudeCode
        openRouterModel = d.string(forKey: "openRouterModel") ?? "anthropic/claude-3.7-sonnet"
        overlayStyle = OverlayStyle(rawValue: d.string(forKey: "overlayStyle") ?? "") ?? .floating
        quipTone = QuipTone(rawValue: d.string(forKey: "quipTone") ?? "") ?? .geek
        language = d.string(forKey: "language") ?? ""
        autoPaste = d.object(forKey: "autoPaste") as? Bool ?? true
        copyToClipboard = d.object(forKey: "copyToClipboard") as? Bool ?? true
        richTextPaste = d.object(forKey: "richTextPaste") as? Bool ?? true
        reviewBeforeSend = d.object(forKey: "reviewBeforeSend") as? Bool ?? false
        autoDetectProfile = d.object(forKey: "autoDetectProfile") as? Bool ?? true
        useSelectionContext = d.object(forKey: "useSelectionContext") as? Bool ?? true
        voiceCommands = d.object(forKey: "voiceCommands") as? Bool ?? true
        repromptEnabled = d.object(forKey: "repromptEnabled") as? Bool ?? true
        recordStyle = RecordStyle(rawValue: d.string(forKey: "recordStyle") ?? "") ?? .lock
        useFnAsPrimary = d.object(forKey: "useFnAsPrimary") as? Bool ?? false
        onboarded = d.object(forKey: "onboarded") as? Bool ?? false
        showInDock = d.object(forKey: "showInDock") as? Bool ?? true
        styleEnabled = d.object(forKey: "styleEnabled") as? Bool ?? false
        styleText = d.string(forKey: "styleText") ?? "Write in a clear, natural voice. Keep it concise."
        primaryKeyCode = UInt32(d.object(forKey: "primaryKeyCode") as? Int ?? 49 /* Space */)
        primaryMods = UInt32(d.object(forKey: "primaryMods") as? Int ?? Int(kCtrlOpt))
        isPro = (ProcessInfo.processInfo.environment["VERBA_PRO"] != nil) || d.bool(forKey: "verba.pro")
        proEmail = d.string(forKey: "verba.email") ?? ""
        // Public alias for the leaderboard (never the email). Fun default if unset.
        if let u = d.string(forKey: "verba.username"), !u.isEmpty {
            username = u
        } else {
            let adjectives = ["Swift", "Clever", "Bold", "Lucid", "Rapid", "Sharp", "Calm", "Witty", "Zen", "Turbo"]
            let nouns = ["Falcon", "Otter", "Comet", "Vox", "Scribe", "Quill", "Echo", "Nova", "Pilot", "Sage"]
            let name = "\(adjectives.randomElement()!)\(nouns.randomElement()!)\(Int.random(in: 10...99))"
            username = name
            d.set(name, forKey: "verba.username")
        }
        if let saved = d.string(forKey: "verba.referral"), !saved.isEmpty {
            referralCode = saved
        } else {
            let code = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).lowercased()
            referralCode = code
            d.set(code, forKey: "verba.referral")
        }

        // Re-seed built-ins when the profiles version bumps (new prompts/shortcuts).
        let upToDate = d.integer(forKey: "profilesVersion") >= Self.profilesVersion
        let loaded: [Profile]
        if upToDate, let data = d.data(forKey: "profiles"),
           let saved = try? JSONDecoder().decode([Profile].self, from: data), !saved.isEmpty {
            loaded = saved
        } else {
            loaded = Profile.defaults
        }
        let savedActive = (upToDate ? d.string(forKey: "activeProfileID").flatMap(UUID.init) : nil)
        // Fresh installs default to Polish (a good general writing mode), not Flow (raw).
        activeProfileID = savedActive ?? loaded.first(where: { $0.name == "Polish" })?.id ?? loaded.first!.id
        profiles = loaded
        if !upToDate {
            d.set(Self.profilesVersion, forKey: "profilesVersion")
            if let data = try? JSONEncoder().encode(loaded) { d.set(data, forKey: "profiles") }
        }
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) { d.set(data, forKey: "profiles") }
    }

    // MARK: Shortcut assignment with conflict swap

    /// Assign a shortcut, swapping it away from whoever currently holds it.
    func assignShortcut(keyCode: UInt32, modifiers: UInt32, to target: ShortcutTarget) {
        if let holder = holder(ofKey: keyCode, mods: modifiers), holder != target {
            setCombo(combo(of: target), on: holder)   // previous holder inherits target's old combo
        }
        setCombo((keyCode, modifiers), on: target)
    }

    func clearShortcut(_ target: ShortcutTarget) { setCombo(nil, on: target) }

    var primaryHasShortcut: Bool { primaryMods != 0 }

    private func combo(of t: ShortcutTarget) -> (UInt32, UInt32)? {
        switch t {
        case .primary: return primaryMods == 0 ? nil : (primaryKeyCode, primaryMods)
        case .profile(let id):
            guard let p = profiles.first(where: { $0.id == id }), let c = p.hotkeyCode, let m = p.hotkeyMods else { return nil }
            return (c, m)
        }
    }
    private func setCombo(_ combo: (UInt32, UInt32)?, on t: ShortcutTarget) {
        switch t {
        case .primary:
            primaryKeyCode = combo?.0 ?? 0
            primaryMods = combo?.1 ?? 0
        case .profile(let id):
            if let i = profiles.firstIndex(where: { $0.id == id }) {
                profiles[i].hotkeyCode = combo?.0
                profiles[i].hotkeyMods = combo?.1
            }
        }
    }
    private func holder(ofKey k: UInt32, mods m: UInt32) -> ShortcutTarget? {
        if let p = profiles.first(where: { $0.hotkeyCode == k && $0.hotkeyMods == m }) { return .profile(p.id) }
        if primaryMods != 0, primaryKeyCode == k, primaryMods == m { return .primary }
        return nil
    }

    /// Restore the built-in profiles (used after prompt changes ship in an update).
    func resetProfilesToDefaults() {
        profiles = Profile.defaults
        activeProfileID = profiles.first!.id
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
