import Foundation

/// Fun, ever-changing "loading" lines shown while Claude restructures the transcript.
/// A built-in pool fires instantly; in the background we ask Claude for fresh geeky
/// one-liners and cache them, so over time it's AI-generated and basically never the same.
enum Quips {
    private static let key = "aiQuips"
    private static var last: String?
    private static var refilling = false

    /// Instant fallback pool — geeky, short, always available offline.
    static let builtin: [String] = [
        "Compiling your thoughts…",
        "Reticulating splines…",
        "Bribing the language model…",
        "Asking the rubber duck…",
        "Dividing by zero, carefully…",
        "Negotiating with the AI…",
        "Feeding the hamsters…",
        "Buffering brilliance…",
        "Petting Schrödinger's cat…",
        "Downloading more RAM…",
        "Consulting the oracle…",
        "Recompiling reality…",
        "Spinning up neurons…",
        "Defragging your prose…",
        "Aligning the tensors…",
        "git commit -m 'words'…",
        "Tabs vs spaces, deciding…",
        "Refactoring your rant…",
        "Warming up the GPUs…",
        "Convincing the transformer…",
        "Counting to 42…",
        "Herding the tokens…",
        "Bending spacetime slightly…",
        "Translating from human…",
        "Caffeinating the model…",
        "Decoding your genius…",
        "Casting Detect Typos…",
        "Rolling for initiative…",
        "Massaging the matrix…",
        "Quantum-entangling words…",
        "sudo make sense…",
        "Loading witty response…",
        "Engaging hyperdrive…",
        "Untangling your sentences…",
        "Summoning a wizard…",
    ]

    /// A fresh quip, never the same twice in a row. Kicks a background AI refill if low.
    static func current() -> String {
        let pool = aiPool + builtin
        var pick = pool.randomElement() ?? "Working on it…"
        if pool.count > 1 { while pick == last { pick = pool.randomElement()! } }
        last = pick
        refillIfLow()
        return pick
    }

    private static var aiPool: [String] {
        get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
        set { UserDefaults.standard.set(Array(newValue.suffix(250)), forKey: key) }
    }

    /// Top up the AI-generated pool in the background when it runs low.
    static func refillIfLow() {
        guard aiPool.count < 30, !refilling else { return }
        let hasKey = !(Keychain.anthropicKey ?? "").isEmpty
        guard Settings.shared.repromptBackend == .claudeCode || hasKey else { return }   // need a Claude backend
        refilling = true
        Task.detached(priority: .background) {
            defer { Quips.refilling = false }
            let sys = """
            You are a witty geek comedian. Output ONLY a plain numbered list of 25 ORIGINAL, \
            very short (max 6 words each) funny one-liners suitable for a loading spinner shown \
            while an AI cleans up a voice dictation. Programmer / sci-fi / internet humor. \
            Each ends with an ellipsis. No emojis, no quotes, no commentary, no repetition. \
            Ignore any transcript you are given — just produce the list.
            """
            do {
                let out = try await Reprompter(model: Settings.shared.claudeModel)
                    .reprompt(transcript: "Generate 25 fresh ones now.", systemPrompt: sys)
                let lines: [String] = out.split(separator: "\n").map { raw in
                    var s = raw.trimmingCharacters(in: .whitespaces)
                    s = s.replacingOccurrences(of: #"^\s*\d+[\.\)]\s*"#, with: "", options: .regularExpression)
                    s = s.replacingOccurrences(of: #"^[\-•*]\s*"#, with: "", options: .regularExpression)
                    return s.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
                }.filter { $0.count >= 4 && $0.count <= 48 }
                guard !lines.isEmpty else { return }
                Quips.aiPool = Quips.aiPool + lines
            } catch { /* keep the built-ins */ }
        }
    }
}
