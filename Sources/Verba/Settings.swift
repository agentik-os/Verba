import Foundation
import Combine
import CryptoKit

/// Hex SHA-256 of a string (used to stamp built-in profile seeds for upgrade merges).
func sha256Hex(_ s: String) -> String {
    SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined()
}

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

/// How the primary Fn (globe) trigger behaves.
///   • toggle: tap Fn to start, tap again to send (hands-free, latched).
///   • hold:   hold Fn to talk, release to send (push-to-talk).
enum TriggerStyle: String, Codable, CaseIterable, Identifiable {
    case toggle    // tap to toggle: tap starts, tap again sends
    case hold      // hold to talk: press starts, release sends
    var id: String { rawValue }
    var label: String { self == .toggle ? "Tap to toggle" : "Hold to talk" }
    var help: String {
        self == .toggle
            ? "Tap Fn to start, tap again to send. Esc cancels."
            : "Hold Fn while you talk, release to send. Esc cancels."
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
    case random
    case geek, dad, dry, absurdist, sarcastic, wholesome, corporate, noir
    case pirate, shakespeare, zen, scifi, gamer, chef, motivational, conspiracy, surreal
    var id: String { rawValue }
    var label: String {
        switch self {
        case .off: return "Off, just “Transmuting…”"
        case .random: return "Random (surprise mix)"
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
        case .random:
            // A different concrete style each batch → a true surprise mix over the day.
            return QuipTone.allCases
                .filter { $0 != .off && $0 != .random }
                .randomElement()!.styleInstruction
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
    case minimal    // no floating UI: the menu-bar icon changes while recording
    var id: String { rawValue }
    var label: String {
        switch self {
        case .floating: return "Floating glass (bottom)"
        case .minimal:  return "Menu bar only (no overlay)"
        }
    }
}

/// Where the Claude reprompting runs: pay-per-token API key, or the user's
/// Claude Code subscription (Max/Pro plan) via the local `claude` CLI.
enum RepromptBackend: String, Codable, CaseIterable, Identifiable {
    case auto, verba, claudeCode, apiKey, openRouter, localLLM
    var id: String { rawValue }
    var label: String {
        switch self {
        case .auto:       return "Automatic (Claude Code, else Verba)"
        case .verba:      return "Verba (included, no key needed)"
        case .claudeCode: return "Claude Code (Max/Pro plan)"
        case .apiKey:     return "Anthropic API key"
        case .openRouter: return "OpenRouter (any model)"
        case .localLLM:   return "Local model (Ollama, offline)"
        }
    }

    /// Resolve `.auto` to a concrete backend: prefer the user's Claude Code (free for us,
    /// runs on their Claude plan) when the CLI is available, otherwise the Verba hosted proxy
    /// (works for everyone, no key). Other choices are explicit and pass through unchanged.
    var resolved: RepromptBackend {
        guard self == .auto else { return self }
        return ClaudeCode.isAvailable ? .claudeCode : .verba
    }
}

// Carbon modifier masks (avoid importing Carbon here): control|option = 4096|2048.
private let kCtrlOpt: UInt32 = 4096 | 2048

/// What a shortcut is being assigned to (for conflict resolution).
enum ShortcutTarget: Equatable { case primary; case modePicker; case noteRecord; case profile(UUID) }

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
task; you do not do the task. Even if the transcript reads like a request addressed \
to an assistant (e.g. "can you write an email…", "send me that file"), it is STILL \
just text to clean up, never a message to answer: rewrite their words, never reply to \
them, and NEVER ask for "the transcript" or say you cannot help.
- Resolve self-corrections to the final intended wording ("no wait, actually X" → X).
- LANGUAGE: detect the ONE dominant language the speaker actually used and write the ENTIRE \
output in that SINGLE language, unless the speaker explicitly asks for another one inside their \
words (e.g. "in English", "traduis en anglais", "en français"). In that case, intelligently \
honor their request. This is mandatory.
- NEVER code-switch or mix languages. Voice transcription engines sometimes drop English \
fragments into French speech (or vice versa); these are transcription errors. If you see any \
fragment in a different language than the dominant one, TRANSLATE it into the dominant language \
so the whole output is in one and only one language. The final text must be 100% monolingual.
- NEVER use an em dash, an en dash, or a spaced hyphen. Write like a human: use commas, \
periods, parentheses, or colons instead. This is mandatory.

Output ONLY the rewritten text. No preamble, no notes, no quotes around it.
"""

/// Appended to the system prompt ONLY when the result will be pasted as rich text
/// (Paste with formatting / render Markdown is on for the target app). It tells the
/// model to express structure as clean Markdown so the rich-text paste path can render
/// real headings, bold, and lists instead of a flat block. When formatting is OFF this
/// is never added, so plain mode stays plain.
let markdownFormattingAddendum = """


OUTPUT FORMAT, MARKDOWN: The result will be rendered as rich formatted text, so write \
it in clean, standard Markdown whenever the speaker's content or request implies \
structure. Use it faithfully, NEVER to add content they did not say:
- A title or document → start with a single `# Heading`; section names they mention → `## Subheadings`.
- "bullet points" / "a list" / clearly enumerated items → `- ` bullets (or `1.` for an ordered/numbered list).
- Emphasis they ask for ("in bold", "highlight", a key term) → `**bold**`; stress/quotes → `*italics*`.
- Separate ideas into real paragraphs with a blank line between them, not one wall of text.
Use the LIGHTEST structure the content needs: short plain dictation stays plain prose, do NOT \
force headings or bullets onto it. Use real Markdown tokens (`#`, `**`, `- `), never literal \
words like "bold" or fake bullets. Do not wrap the whole answer in a code fence.
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
    var vision: Bool = false            // Context mode: capture the screen and act on it
    var targetLanguage: String? = nil   // Translate mode: render the dictation in THIS language
    var seedHash: String? = nil         // sha256 of the systemPrompt as seeded; nil = legacy save (pre-stamping)

    /// The prompt actually sent to Claude. A mode with a target language becomes a translator:
    /// whatever language you speak, the output is written in that language.
    var effectiveSystemPrompt: String {
        guard let lang = targetLanguage?.trimmingCharacters(in: .whitespaces), !lang.isEmpty else { return systemPrompt }
        return """
        You are a translator. Translate the user's dictated speech into \(lang), no matter what \
        language they speak in. Output ONLY the translation, written naturally and fluently in \
        \(lang), preserving the meaning, tone, register and intent. Keep proper nouns, code, \
        numbers and formatting intact. If the speech is already in \(lang), just clean it up in \
        \(lang). Resolve self-corrections to the final intended meaning. The output must be \
        100% in \(lang) with NO code-switching: translate every fragment, including any stray \
        words the transcription left in another language, into \(lang).
        Do not add any preamble, quotes, notes or commentary, output only the \(lang) text.
        NEVER use an em dash, en dash, or a spaced hyphen; use commas, periods, parentheses, or colons.
        """
    }
}

/// A reusable tone/format layer applied ON TOP of the active mode when reprompting.
/// Unlike a Profile (which defines WHAT Claude does with the transcript), a Style only
/// nudges HOW the result reads (tone, register, formatting). The built-in "Normal" style
/// has an empty prompt, so it changes nothing and keeps the default behaviour intact.
struct Style: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var prompt: String        // the style instructions appended to the mode's system prompt ("" = no change)
    var builtin: Bool = false

    /// The neutral default: an empty prompt means the dictation is unchanged. The id is hard-coded so
    /// the built-in's identity is stable across launches/re-seeds (a fresh UUID() each launch would
    /// break references that key off the Style id).
    static let normal = Style(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
                              name: "Normal", prompt: "", builtin: true)

    static let defaults: [Style] = [.normal]
}

/// Common targets for the Translate mode (the value stored is the language name, used in the prompt).
let translateLanguages = ["English", "French", "Spanish", "German", "Italian", "Portuguese", "Dutch",
                          "Russian", "Chinese", "Japanese", "Korean", "Arabic", "Hindi", "Turkish", "Polish"]

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
        builtin: true, hotkeyCode: 23 /* 5 */, hotkeyMods: kCtrlOpt, model: "claude-opus-4-8")

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
        - Keep the speaker's ONE dominant language unless the intent says otherwise. NEVER \
        code-switch or mix languages: if the transcript drops fragments of another language \
        (a transcription error), translate them into the dominant language so the output is \
        100% in a single language.

        NEVER use an em dash, en dash, or a spaced hyphen; use commas, \
        periods, parentheses, or colons instead.

        Output ONLY the final result. No preamble, no echo of the intent, no commentary.
        """,
        builtin: true, hotkeyCode: 19 /* 2 */, hotkeyMods: kCtrlOpt, model: "claude-sonnet-4-6")

    static let flow = Profile(
        name: "Flow",
        systemPrompt: "(Free-flow dictation, your words are transcribed exactly, with no AI reprompting or reordering.)",
        builtin: true, hotkeyCode: 18 /* 1 */, hotkeyMods: kCtrlOpt, raw: true)

    static let translate = Profile(
        name: "Translate",
        systemPrompt: "Translate the dictation into the chosen target language.",
        builtin: true, hotkeyCode: 20 /* 3 */, hotkeyMods: kCtrlOpt,
        model: nil /* use the user's default model */, targetLanguage: "English")

    static let custom = Profile(
        name: "Custom",
        systemPrompt: faithfulCore + """


        CONTEXT: (your own, edit this prompt in Settings to define exactly how Verba \
        should reorder and improve your dictation.)
        """,
        builtin: true, hotkeyCode: 23 /* 5 */, hotkeyMods: kCtrlOpt)

    static let context = Profile(
        name: "Context",
        systemPrompt: """
        You are Verba's Context mode. You receive a SCREENSHOT of the user's screen plus \
        a spoken request. LOOK carefully at what is on screen, then do exactly what the \
        request asks, grounded in the on-screen content. Examples: draft a reply to the \
        email or message that is visible, write the message they describe, comment on the \
        photo, answer the question shown, summarize or rewrite the selected text.

        Rules:
        - Use the screen as the source of truth. If the request refers to "this", "it", \
        "the email", "the message", "the photo", resolve it from what is on screen.
        - Output ONLY the text to insert where the cursor is. No preamble, no explanation, \
        no quotes around it, no "Here is".
        - LANGUAGE: write in the ONE language the speaker used, unless they explicitly ask for \
        another one (e.g. "reply in English"). For a reply, match the language of the \
        message on screen when that is clearly what they want. NEVER mix or code-switch \
        languages; the whole output must be in a single language.
        - Never invent facts that are neither on screen nor in the request.
        - NEVER use an em dash, an en dash, or a spaced hyphen. Use commas, periods, \
        parentheses, or colons instead.
        """,
        builtin: true, hotkeyCode: 21 /* 4 */, hotkeyMods: kCtrlOpt,
        model: "claude-sonnet-4-6", vision: true)

    static let defaults: [Profile] = [.flow, .intent, .translate, .context, .coding]
    /// Built-in modes that were shipped once and then retired — dropped on migration so they
    /// disappear for existing users too (not kept as orphan custom modes).
    static let retiredBuiltinNames: Set<String> = ["Polish", "Casual", "Custom"]
}

final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = UserDefaults.standard

    // Bump when the built-in profiles change so users get the new prompts/shortcuts.
    static let profilesVersion = 19  // order Flow/Intent/Translate/Context/Coding (⌃⌥1-5), retire Polish/Casual/Custom; default Flow

    @Published var engine: TranscriptionEngine { didSet { d.set(engine.rawValue, forKey: "engine") } }
    @Published var localModel: String { didSet { d.set(localModel, forKey: "localModel") } }
    @Published var claudeModel: String { didSet { d.set(claudeModel, forKey: "claudeModel") } }
    // Chosen microphone (CoreAudio device UID). "" = follow the system default input.
    @Published var micUID: String { didSet { d.set(micUID, forKey: "micUID") } }
    // Sidebar items the user hid (NavItem raw values). Home / Modes / Settings are always shown.
    @Published var hiddenNav: Set<String> { didSet { d.set(Array(hiddenNav), forKey: "hiddenNav") } }
    @Published var repromptBackend: RepromptBackend { didSet { d.set(repromptBackend.rawValue, forKey: "repromptBackend") } }
    @Published var openRouterModel: String { didSet { d.set(openRouterModel, forKey: "openRouterModel") } }
    @Published var localLLMModel: String { didSet { d.set(localLLMModel, forKey: "localLLMModel") } }
    @Published var overlayStyle: OverlayStyle { didSet { d.set(overlayStyle.rawValue, forKey: "overlayStyle") } }
    @Published var quipTone: QuipTone { didSet { d.set(quipTone.rawValue, forKey: "quipTone"); Quips.onToneChanged() } }
    @Published var language: String { didSet { d.set(language, forKey: "language") } }   // "" = auto-detect

    // Labs / advanced features (each individually toggleable).
    @Published var smartFormatting: Bool { didSet { d.set(smartFormatting, forKey: "smartFormatting") } }
    @Published var redoEnabled: Bool { didSet { d.set(redoEnabled, forKey: "redoEnabled") } }
    @Published var autoLearnDictionary: Bool { didSet { d.set(autoLearnDictionary, forKey: "autoLearnDictionary") } }
    @Published var toneMatch: Bool { didSet { d.set(toneMatch, forKey: "toneMatch") } }
    @Published var voiceEditLast: Bool { didSet { d.set(voiceEditLast, forKey: "voiceEditLast") } }
    // Context mode: turn a spoken command ("create an event tomorrow at 3pm") into a confirmable
    // Calendar event / Reminder / email draft instead of inserting text. Always asks first. Default OFF.
    @Published var agenticActions: Bool { didSet { d.set(agenticActions, forKey: "agenticActions") } }
    @Published var notesTabEnabled: Bool { didSet { d.set(notesTabEnabled, forKey: "notesTabEnabled") } }
    @Published var todosTabEnabled: Bool { didSet { d.set(todosTabEnabled, forKey: "todosTabEnabled") } }
    // Local reminder notifications 30 min before a to-do task's deadline.
    @Published var todoReminders: Bool {
        didSet { d.set(todoReminders, forKey: "todoReminders"); TodoReminders.shared.onSettingChanged(enabled: todoReminders) }
    }
    @Published var soundsEnabled: Bool { didSet { d.set(soundsEnabled, forKey: "soundsEnabled") } }
    @Published var soundVolume: Double { didSet { d.set(soundVolume, forKey: "soundVolume") } }   // 0...1
    // Fn-key behaviour: by default Verba takes over the globe key so macOS doesn't pop the
    // emoji/Fn HUD or the input-source switcher. Users can turn these back on.
    @Published var suppressFnPopup: Bool { didSet { d.set(suppressFnPopup, forKey: "suppressFnPopup"); FnSystemPref.reapply() } }
    @Published var disableInputSwitcher: Bool { didSet { d.set(disableInputSwitcher, forKey: "disableInputSwitcher"); FnSystemPref.reapply() } }
    @Published var autoPaste: Bool { didSet { d.set(autoPaste, forKey: "autoPaste") } }
    @Published var copyToClipboard: Bool { didSet { d.set(copyToClipboard, forKey: "copyToClipboard") } }
    @Published var richTextPaste: Bool { didSet { d.set(richTextPaste, forKey: "richTextPaste") } }
    @Published var reviewBeforeSend: Bool { didSet { d.set(reviewBeforeSend, forKey: "reviewBeforeSend") } }
    @Published var autoDetectProfile: Bool { didSet { d.set(autoDetectProfile, forKey: "autoDetectProfile") } }
    @Published var useSelectionContext: Bool { didSet { d.set(useSelectionContext, forKey: "useSelectionContext") } }
    @Published var voiceCommands: Bool { didSet { d.set(voiceCommands, forKey: "voiceCommands") } }
    // Language-consistency guard: if the transcription engine code-switches (mixes French and
    // English mid-sentence), normalize the output to its single dominant language. Applies to
    // EVERY result, including Flow/raw mode. Default ON.
    @Published var languageGuard: Bool { didSet { d.set(languageGuard, forKey: "languageGuard") } }
    @Published var repromptEnabled: Bool { didSet { d.set(repromptEnabled, forKey: "repromptEnabled") } }
    @Published var recordStyle: RecordStyle { didSet { d.set(recordStyle.rawValue, forKey: "recordStyle") } }
    // How the Fn (globe) primary trigger behaves: tap-to-toggle (latched) or hold-to-talk (push-to-talk).
    @Published var triggerStyle: TriggerStyle { didSet { d.set(triggerStyle.rawValue, forKey: "triggerStyle") } }
    @Published var useFnAsPrimary: Bool { didSet { d.set(useFnAsPrimary, forKey: "useFnAsPrimary") } }
    @Published var onboarded: Bool { didSet { d.set(onboarded, forKey: "onboarded") } }
    @Published var showInDock: Bool { didSet { d.set(showInDock, forKey: "showInDock") } }
    @Published var showMenuBarIcon: Bool { didSet { d.set(showMenuBarIcon, forKey: "showMenuBarIcon") } }

    // Multi-style system: a tone/format layer applied on top of the active mode when
    // reprompting. `styles` is the CRUD list (mirrors `profiles`); `activeStyleID` is the
    // chosen one (default = Normal, an empty prompt that changes nothing).
    @Published var styles: [Style] { didSet { persistStyles() } }
    @Published var activeStyleID: UUID { didSet { d.set(activeStyleID.uuidString, forKey: "activeStyleID") } }

    // Primary trigger shortcut (active/auto-detected mode). Default ⌃⌥Space.
    @Published var primaryKeyCode: UInt32 { didSet { d.set(Int(primaryKeyCode), forKey: "primaryKeyCode") } }
    @Published var primaryMods: UInt32 { didSet { d.set(Int(primaryMods), forKey: "primaryMods") } }
    // Global shortcut to open the mode picker. Default ⌃⌥M. (⌥+Fn now pops the to-do glance.)
    @Published var modePickerKeyCode: UInt32 { didSet { d.set(Int(modePickerKeyCode), forKey: "modePickerKeyCode") } }
    @Published var modePickerMods: UInt32 { didSet { d.set(Int(modePickerMods), forKey: "modePickerMods") } }
    // When true the change-mode gesture jumps straight to the NEXT mode (no list); works live
    // while recording too. When false it opens the numbered picker. Default: cycle.
    @Published var modeGestureCycles: Bool { didSet { d.set(modeGestureCycles, forKey: "modeGestureCycles") } }
    // ⌥ + Fn pops up a compact glance of today's to-dos (due today + overdue, checkable). Default ON.
    @Published var todoGlanceEnabled: Bool { didSet { d.set(todoGlanceEnabled, forKey: "todoGlanceEnabled") } }
    // After each dictation, make the mode that was actually used the new default for next time. Default ON.
    @Published var rememberLastMode: Bool { didSet { d.set(rememberLastMode, forKey: "rememberLastMode") } }
    // Custom global shortcut to record a new note (in addition to the built-in Fn + Z). Default none.
    @Published var noteRecordKeyCode: UInt32 { didSet { d.set(Int(noteRecordKeyCode), forKey: "noteRecordKeyCode") } }
    @Published var noteRecordMods: UInt32 { didSet { d.set(Int(noteRecordMods), forKey: "noteRecordMods") } }

    @Published var profiles: [Profile] { didSet { persistProfiles() } }
    @Published var activeProfileID: UUID { didSet { d.set(activeProfileID.uuidString, forKey: "activeProfileID") } }

    // Pro entitlement (editing system prompts / custom modes is Pro-only).
    @Published var isPro: Bool { didSet { d.set(isPro, forKey: "verba.pro") } }
    @Published var proEmail: String { didSet { d.set(proEmail, forKey: "verba.email") } }
    @Published var referralCode: String { didSet { d.set(referralCode, forKey: "verba.referral") } }
    var referralLink: String { referralCode.isEmpty ? "https://verba.run/" : "https://verba.run/?ref=\(referralCode)" }
    /// Set when the server entitlement requires a fresh sign-in (no app-session token yet).
    @Published var needsReauth: Bool = false
    /// True once the USER explicitly picks/edits/shuffles their alias. When true, the local
    /// alias is authoritative: a launch-time reconcile pushes it to the account instead of
    /// pulling (and overwriting) it — that pull was resetting custom names back to the
    /// originally-seeded random alias on every restart.
    @Published var usernameCustomized: Bool = false { didSet { d.set(usernameCustomized, forKey: "verba.usernameCustomized") } }
    /// Set by reconcile when ADOPTING the account's alias, so the didSet below doesn't
    /// mis-flag that programmatic adoption as a user choice.
    var adoptingRemoteUsername = false
    @Published var username: String {
        didSet {
            d.set(username, forKey: "verba.username")
            if !adoptingRemoteUsername && username != oldValue { usernameCustomized = true }
        }
    }
    // S14: history controls. Off = nothing is written to disk, no audio copy, no cloud push.
    @Published var saveHistory: Bool { didSet { d.set(saveHistory, forKey: "verba.saveHistory") } }
    // History retention in days; 0 = keep forever (default). Options: 7 / 30 / 90.
    @Published var historyRetentionDays: Int { didSet { d.set(historyRetentionDays, forKey: "verba.historyRetentionDays") } }
    // Opt out of the public leaderboard: hide the profile and stop submitting scores.
    @Published var showOnLeaderboard: Bool {
        didSet {
            d.set(showOnLeaderboard, forKey: "verba.showOnLeaderboard")
            if showOnLeaderboard { Leaderboard.submit() } else { Leaderboard.remove(uid: uid) }
        }
    }

    /// A fun, anonymous public alias (Adjective+Animal+Number), never the real name.
    static func randomAlias() -> String {
        let adjectives = ["Swift", "Clever", "Bold", "Lucid", "Rapid", "Sharp", "Calm", "Witty", "Zen", "Turbo"]
        let nouns = ["Falcon", "Otter", "Comet", "Vox", "Scribe", "Quill", "Echo", "Nova", "Pilot", "Sage"]
        return "\(adjectives.randomElement()!)\(nouns.randomElement()!)\(Int.random(in: 10...99))"
    }
    /// Stable per-device anonymous uid, minted once. Never an email, never shared.
    private(set) lazy var deviceUid: String = {
        if let saved = d.string(forKey: "verba.deviceUid"), !saved.isEmpty { return saved }
        let fresh = "anon-" + String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)).lowercased()
        d.set(fresh, forKey: "verba.deviceUid")
        return fresh
    }()
    /// The single account identity used everywhere (leaderboard, history, wishlist).
    var uid: String { referralCode.isEmpty ? deviceUid : referralCode }

    var activeProfile: Profile {
        profiles.first { $0.id == activeProfileID } ?? profiles.first ?? .coding
    }

    var activeStyle: Style {
        styles.first { $0.id == activeStyleID } ?? styles.first ?? .normal
    }

    /// Sidebar visibility (Home / Modes / Settings are pinned and ignore this).
    func navVisible(_ item: NavItem) -> Bool { !hiddenNav.contains(item.rawValue) }
    func setNavVisible(_ item: NavItem, _ on: Bool) {
        if on { hiddenNav.remove(item.rawValue) } else { hiddenNav.insert(item.rawValue) }
    }

    /// Verify the subscription against verba.run (token-authenticated) and update `isPro`.
    /// THE RULE: once Pro, the ONLY thing that revokes Pro is an explicit server "no"
    /// (HTTP 200, active:false, on a token-authenticated check). Wifi changes, offline,
    /// server errors, rejected/missing tokens — none of these ever downgrade the user or
    /// nag them to subscribe. Unreachable just means "keep the last known state and
    /// quietly revalidate later".
    @MainActor
    func verifyPro() async -> Bool {
        switch await Entitlement.check() {
        case .active:
            isPro = true
            needsReauth = false
            d.set(Date().timeIntervalSince1970, forKey: "verba.proVerifiedAt")
        case .inactive:
            isPro = false                                  // explicit server "no" = the one real revoke
            needsReauth = false
        case .unreachable:
            // Migration: a signed-in user with no app-session token yet must re-auth (the
            // server now requires the token); surface the one-click prompt, never a paywall.
            if !proEmail.isEmpty && AuthToken.current == nil { needsReauth = true }
            // Keep the last known state indefinitely; quietly revalidate in 30 min.
            if isPro {
                Task { try? await Task.sleep(nanoseconds: 1_800_000_000_000); _ = await self.verifyPro() }
            }
        }
        return isPro
    }

    private init() {
        // Default to a LOCAL engine so a fresh user can dictate with no API key at all
        // (Parakeet: on-device, multilingual, auto-downloads on first run).
        engine = TranscriptionEngine(rawValue: d.string(forKey: "engine") ?? "") ?? .parakeet
        localModel = d.string(forKey: "localModel") ?? "large-v3-v20240930_turbo"
        claudeModel = d.string(forKey: "claudeModel") ?? "claude-sonnet-4-6"
        micUID = d.string(forKey: "micUID") ?? ""
        hiddenNav = Set(d.stringArray(forKey: "hiddenNav") ?? [])
        repromptBackend = RepromptBackend(rawValue: d.string(forKey: "repromptBackend") ?? "") ?? .auto
        openRouterModel = d.string(forKey: "openRouterModel") ?? "anthropic/claude-3.7-sonnet"
        localLLMModel = d.string(forKey: "localLLMModel") ?? "qwen2.5:7b"
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
        languageGuard = d.object(forKey: "languageGuard") as? Bool ?? true
        repromptEnabled = d.object(forKey: "repromptEnabled") as? Bool ?? true
        recordStyle = RecordStyle(rawValue: d.string(forKey: "recordStyle") ?? "") ?? .lock
        // Default to tap-to-toggle (the long-standing hands-free behaviour).
        triggerStyle = TriggerStyle(rawValue: d.string(forKey: "triggerStyle") ?? "") ?? .toggle
        useFnAsPrimary = d.object(forKey: "useFnAsPrimary") as? Bool ?? true
        onboarded = d.object(forKey: "onboarded") as? Bool ?? false
        showInDock = d.object(forKey: "showInDock") as? Bool ?? true
        showMenuBarIcon = d.object(forKey: "showMenuBarIcon") as? Bool ?? true
        smartFormatting = d.object(forKey: "smartFormatting") as? Bool ?? true
        redoEnabled = d.object(forKey: "redoEnabled") as? Bool ?? true
        autoLearnDictionary = d.object(forKey: "autoLearnDictionary") as? Bool ?? true
        toneMatch = d.object(forKey: "toneMatch") as? Bool ?? false
        voiceEditLast = d.object(forKey: "voiceEditLast") as? Bool ?? true
        agenticActions = d.object(forKey: "agenticActions") as? Bool ?? false
        notesTabEnabled = d.object(forKey: "notesTabEnabled") as? Bool ?? true
        todosTabEnabled = d.object(forKey: "todosTabEnabled") as? Bool ?? true
        todoReminders = d.object(forKey: "todoReminders") as? Bool ?? true
        soundsEnabled = d.object(forKey: "soundsEnabled") as? Bool ?? true
        soundVolume = d.object(forKey: "soundVolume") as? Double ?? 0.8
        suppressFnPopup = d.object(forKey: "suppressFnPopup") as? Bool ?? true
        disableInputSwitcher = d.object(forKey: "disableInputSwitcher") as? Bool ?? true
        primaryKeyCode = UInt32(d.object(forKey: "primaryKeyCode") as? Int ?? 49 /* Space */)
        primaryMods = UInt32(d.object(forKey: "primaryMods") as? Int ?? Int(kCtrlOpt))
        // No extra global change-mode shortcut by default: the built-in gesture is Fn + Tab.
        modePickerKeyCode = UInt32(d.object(forKey: "modePickerKeyCode") as? Int ?? 0)
        modePickerMods = UInt32(d.object(forKey: "modePickerMods") as? Int ?? 0)
        modeGestureCycles = d.object(forKey: "modeGestureCycles") as? Bool ?? true
        todoGlanceEnabled = d.object(forKey: "todoGlanceEnabled") as? Bool ?? true
        rememberLastMode = d.object(forKey: "rememberLastMode") as? Bool ?? true
        noteRecordKeyCode = UInt32(d.object(forKey: "noteRecordKeyCode") as? Int ?? 0)
        noteRecordMods = UInt32(d.object(forKey: "noteRecordMods") as? Int ?? 0)
        isPro = (ProcessInfo.processInfo.environment["VERBA_PRO"] != nil) || d.bool(forKey: "verba.pro")
        proEmail = d.string(forKey: "verba.email") ?? ""
        showOnLeaderboard = d.object(forKey: "verba.showOnLeaderboard") as? Bool ?? true
        saveHistory = d.object(forKey: "verba.saveHistory") as? Bool ?? true
        historyRetentionDays = d.object(forKey: "verba.historyRetentionDays") as? Int ?? 0
        // Public alias for the leaderboard (never the email or real name). Fun default if unset.
        usernameCustomized = d.bool(forKey: "verba.usernameCustomized")
        if let u = d.string(forKey: "verba.username"), !u.isEmpty {
            username = u
        } else {
            let name = Settings.randomAlias()
            username = name
            d.set(name, forKey: "verba.username")
        }
        // The referral code is the ACCOUNT identity, issued by the server at sign-in. Legacy
        // builds minted one locally even without an account; such a code was never attributable
        // server-side and would collide with the new device-auth model (non-"anon-" uids need an
        // account token to register), so drop it and let `uid` fall back to the per-device
        // anonymous uid. Signed-in users keep their server-issued code.
        let savedEmail = d.string(forKey: "verba.email") ?? ""
        if let saved = d.string(forKey: "verba.referral"), !saved.isEmpty, !savedEmail.isEmpty {
            referralCode = saved
        } else {
            referralCode = ""
            d.set("", forKey: "verba.referral")
        }

        // Re-seed built-ins when the profiles version bumps (new prompts/shortcuts).
        // S3: a version bump MERGES the new defaults with the user's saved profiles instead of
        // wiping them. Custom modes are kept verbatim; an edited built-in is never overwritten
        // (detected via `seedHash`, the sha256 of the prompt as last seeded); an untouched
        // built-in adopts the new prompt while preserving its id / app matches / user hotkey.
        let upToDate = d.integer(forKey: "profilesVersion") >= Self.profilesVersion
        var saved: [Profile] = []
        if let data = d.data(forKey: "profiles"),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data) {
            saved = decoded
        }
        let stampedDefaults = Settings.stampedDefaults()
        let loaded: [Profile]
        if saved.isEmpty {
            loaded = stampedDefaults                      // fresh install
        } else if upToDate {
            loaded = saved                                // up to date → saved unchanged
        } else {
            // Version bump → merge. Drop any retired built-in (Polish/Casual) up front so it
            // disappears for existing users instead of lingering as an orphan custom mode.
            let saved2 = saved.filter { !($0.builtin && Profile.retiredBuiltinNames.contains($0.name)) }
            let saved = saved2
            let customs = saved.filter { !$0.builtin }    // user modes, kept verbatim in order
            var mergedBuiltins: [Profile] = []
            var matchedNames = Set<String>()
            for D in stampedDefaults {
                guard let S = saved.first(where: { $0.builtin && $0.name == D.name }) else {
                    mergedBuiltins.append(D)              // new built-in mode appears
                    continue
                }
                matchedNames.insert(D.name)
                // Untouched ⇔ the prompt still matches its seed (or a legacy save whose prompt
                // equals the new default). Anything else — including a legacy prompt that
                // differs — is treated as edited and never overwritten.
                let untouched = (S.seedHash != nil && S.seedHash == sha256Hex(S.systemPrompt))
                    || (S.seedHash == nil && S.systemPrompt == D.systemPrompt)
                if untouched {
                    var u = D                             // new prompt/model/vision/raw/targetLanguage + fresh seedHash
                    u.id = S.id
                    u.matchBundleIDs = S.matchBundleIDs
                    if S.hotkeyCode != nil || S.hotkeyMods != nil {
                        u.hotkeyCode = S.hotkeyCode       // a user-set hotkey wins over the default's
                        u.hotkeyMods = S.hotkeyMods
                    }
                    mergedBuiltins.append(u)
                } else {
                    mergedBuiltins.append(S)              // edited → keep verbatim (seedHash stays)
                }
            }
            // Saved built-ins matching no current default (renamed/retired): keep them as
            // user profiles — never silently deleted.
            let retired = saved.filter { $0.builtin && !matchedNames.contains($0.name) }
                .map { p -> Profile in var c = p; c.builtin = false; return c }
            loaded = mergedBuiltins + retired + customs
        }
        // Keep the saved active mode if it survived the merge; else Flow (the default on a
        // fresh install); else first.
        let savedActive = d.string(forKey: "activeProfileID").flatMap(UUID.init)
        activeProfileID = savedActive.flatMap { id in loaded.first { $0.id == id }?.id }
            ?? loaded.first(where: { $0.name == "Flow" })?.id ?? loaded.first!.id
        profiles = loaded
        if !upToDate || saved.isEmpty {
            d.set(Self.profilesVersion, forKey: "profilesVersion")
            if let data = try? JSONEncoder().encode(loaded) { d.set(data, forKey: "profiles") }
        }

        // Styles: load the saved list, else seed [Normal]. Migrate the legacy single global
        // style (styleEnabled + styleText) into a named style on first run so nobody loses it.
        var loadedStyles: [Style] = []
        if let data = d.data(forKey: "styles"),
           let saved = try? JSONDecoder().decode([Style].self, from: data), !saved.isEmpty {
            loadedStyles = saved
        }
        if loadedStyles.isEmpty {
            loadedStyles = Style.defaults
            // One-time migration of the old global style into a "My style" entry.
            let legacyText = (d.string(forKey: "styleText") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let legacyOn = d.object(forKey: "styleEnabled") as? Bool ?? false
            if !legacyText.isEmpty {
                let migrated = Style(name: "My style", prompt: legacyText)
                loadedStyles.append(migrated)
                if legacyOn { d.set(migrated.id.uuidString, forKey: "activeStyleID") }
            }
        }
        // Always guarantee a built-in Normal at the head of the list.
        if !loadedStyles.contains(where: { $0.builtin && $0.name == "Normal" }) {
            loadedStyles.insert(.normal, at: 0)
        }
        styles = loadedStyles
        let savedStyle = d.string(forKey: "activeStyleID").flatMap(UUID.init)
        activeStyleID = (savedStyle.flatMap { id in loadedStyles.first { $0.id == id }?.id })
            ?? loadedStyles.first(where: { $0.builtin && $0.name == "Normal" })?.id
            ?? loadedStyles.first!.id
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) { d.set(data, forKey: "profiles") }
    }

    private func persistStyles() {
        if let data = try? JSONEncoder().encode(styles) { d.set(data, forKey: "styles") }
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

    var modePickerHasShortcut: Bool { modePickerMods != 0 }

    var noteRecordHasShortcut: Bool { noteRecordMods != 0 }

    private func combo(of t: ShortcutTarget) -> (UInt32, UInt32)? {
        switch t {
        case .primary: return primaryMods == 0 ? nil : (primaryKeyCode, primaryMods)
        case .modePicker: return modePickerMods == 0 ? nil : (modePickerKeyCode, modePickerMods)
        case .noteRecord: return noteRecordMods == 0 ? nil : (noteRecordKeyCode, noteRecordMods)
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
        case .modePicker:
            modePickerKeyCode = combo?.0 ?? 0
            modePickerMods = combo?.1 ?? 0
        case .noteRecord:
            noteRecordKeyCode = combo?.0 ?? 0
            noteRecordMods = combo?.1 ?? 0
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
        if modePickerMods != 0, modePickerKeyCode == k, modePickerMods == m { return .modePicker }
        if noteRecordMods != 0, noteRecordKeyCode == k, noteRecordMods == m { return .noteRecord }
        return nil
    }

    /// The canonical built-ins with their seed hash stamped (S3: every seed writes `seedHash`
    /// so "untouched vs edited" detection is exact at future version bumps).
    static func stampedDefaults() -> [Profile] {
        Profile.defaults.map { p -> Profile in
            var c = p; c.seedHash = sha256Hex(p.systemPrompt); return c
        }
    }

    /// Restore the built-in profiles (used after prompt changes ship in an update).
    func resetProfilesToDefaults() {
        profiles = Settings.stampedDefaults()
        activeProfileID = profiles.first!.id
    }

    /// Restore the built-in styles (just "Normal"), dropping any custom ones.
    func resetStylesToDefaults() {
        styles = Style.defaults
        activeStyleID = styles.first!.id
    }

    /// Advance the active style by `delta` (wraps). Returns the new active style.
    @discardableResult
    func cycleStyle(_ delta: Int) -> Style {
        guard !styles.isEmpty else { return .normal }
        let cur = styles.firstIndex { $0.id == activeStyleID } ?? 0
        let next = ((cur + delta) % styles.count + styles.count) % styles.count
        activeStyleID = styles[next].id
        return styles[next]
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
