import Foundation

/// The "loading" line shown while Claude restructures the transcript.
/// - If the chosen tone is `.off`, we show a neutral word ("Transmuting…").
/// - Otherwise we show a joke in the chosen humor style, AI-generated and cached,
///   and never repeat the same line twice in the same day.
enum Quips {
    private static let poolKey = "aiQuips"
    private static let toneKey = "aiQuipsTone"
    private static let shownKey = "aiQuipsShown"     // [String] shown today
    private static let shownDayKey = "aiQuipsShownDay"
    private static var refilling = false

    /// Neutral status when jokes are off (kept short and a touch nicer than "Transforming").
    static let neutral = "Transmuting…"

    /// Instant fallback pool, used only until the AI has generated tone-matched lines.
    static let builtin: [String] = [
        "Compiling your thoughts…", "Reticulating splines…", "Untangling your sentences…",
        "Consulting the oracle…", "Polishing every word…", "Tidying up the rambles…",
        "Connecting the dots…", "Finding the through-line…", "Sharpening the phrasing…",
        "Making it make sense…", "Smoothing the edges…", "Lining up your points…",
    ]

    /// A fresh line to display. Honors the tone and avoids repeating within the day.
    static func current() -> String {
        let tone = Settings.shared.quipTone
        if tone == .off { return neutral }

        rolloverIfNewDay()
        let pool = aiPool.isEmpty ? builtin : aiPool
        let shown = Set(shownToday)
        let fresh = pool.filter { !shown.contains($0) }
        let pick = (fresh.isEmpty ? pool : fresh).randomElement() ?? neutral
        markShown(pick)
        refillIfLow(tone: tone)
        return pick
    }

    /// When the user changes tone, drop the old pool so we regenerate in the new style.
    static func onToneChanged() {
        let d = UserDefaults.standard
        if d.string(forKey: toneKey) != Settings.shared.quipTone.rawValue {
            d.removeObject(forKey: poolKey)
            d.set(Settings.shared.quipTone.rawValue, forKey: toneKey)
        }
        if Settings.shared.quipTone != .off { refillIfLow(tone: Settings.shared.quipTone) }
    }

    // MARK: storage
    private static var aiPool: [String] {
        get { UserDefaults.standard.stringArray(forKey: poolKey) ?? [] }
        set { UserDefaults.standard.set(Array(newValue.suffix(400)), forKey: poolKey) }
    }
    private static var shownToday: [String] {
        get { UserDefaults.standard.stringArray(forKey: shownKey) ?? [] }
        set { UserDefaults.standard.set(Array(newValue.suffix(600)), forKey: shownKey) }
    }
    private static func markShown(_ s: String) { shownToday = shownToday + [s] }
    private static func rolloverIfNewDay() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        let today = f.string(from: Date())
        let d = UserDefaults.standard
        if d.string(forKey: shownDayKey) != today {
            d.set(today, forKey: shownDayKey)
            d.removeObject(forKey: shownKey)   // a brand-new day of jokes
        }
    }

    /// Top up the AI-generated pool (in the tone) when it runs low or unseen lines run out.
    static func refillIfLow(tone: QuipTone) {
        guard tone != .off, !refilling else { return }
        let unseen = Set(aiPool).subtracting(shownToday).count
        guard aiPool.count < 40 || unseen < 12 else { return }
        let hasKey = !(Keychain.anthropicKey ?? "").isEmpty
        guard Settings.shared.repromptBackend == .claudeCode || hasKey else { return }
        refilling = true
        let style = tone.styleInstruction
        Task.detached(priority: .background) {
            defer { Quips.refilling = false }
            let sys = """
            You are a witty comedian writing in this exact humor style: \(style). \
            Output ONLY a plain numbered list of 30 ORIGINAL, very short (max 6 words each) \
            funny one-liners suitable for a loading spinner shown while an AI cleans up a \
            voice dictation. Each ends with an ellipsis. No emojis, no quotes, no commentary, \
            no repetition, and never use a dash. Ignore any transcript you are given; just produce the list.
            """
            do {
                let out = try await Reprompter(model: Settings.shared.claudeModel)
                    .reprompt(transcript: "Generate 30 fresh ones now.", systemPrompt: sys)
                let lines: [String] = out.split(separator: "\n").map { raw in
                    var s = raw.trimmingCharacters(in: .whitespaces)
                    s = s.replacingOccurrences(of: #"^\s*\d+[\.\)]\s*"#, with: "", options: .regularExpression)
                    s = s.replacingOccurrences(of: #"^[\-•*]\s*"#, with: "", options: .regularExpression)
                    return s.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
                }.filter { $0.count >= 4 && $0.count <= 52 }
                guard !lines.isEmpty else { return }
                Quips.aiPool = Quips.aiPool + lines
            } catch { /* keep the built-ins */ }
        }
    }
}
