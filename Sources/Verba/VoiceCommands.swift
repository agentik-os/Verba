import Foundation

/// Turns spoken formatting/editing commands into real punctuation, line breaks
/// and edits — Wispr "Command Mode" style. Bilingual (EN + FR). Runs on the raw
/// transcript so it works even in Flow (raw) mode, before any Claude reprompt.
enum VoiceCommands {
    static func apply(_ text: String) -> String {
        var t = text

        // 1. Line / paragraph / bullet (consume surrounding spaces).
        t = re(t, #"\s*\b(new paragraph|nouveau paragraphe)\b\s*"#, "\n\n")
        t = re(t, #"\s*\b(new line|nouvelle ligne|à la ligne|retour à la ligne)\b\s*"#, "\n")
        t = re(t, #"\s*\b(bullet point|new bullet|nouvelle puce|à la puce|tiret)\b\s*"#, "\n- ")

        // 2. Punctuation (eat the preceding space so it attaches to the word).
        t = re(t, #"\s*\b(comma|virgule)\b"#, ",")
        t = re(t, #"\s*\b(period|full stop|point final)\b"#, ".")
        t = re(t, #"\s*\b(question mark|point d'interrogation)\b"#, "?")
        t = re(t, #"\s*\b(exclamation mark|exclamation point|point d'exclamation)\b"#, "!")
        t = re(t, #"\s*\b(colon|deux points)\b"#, ":")
        t = re(t, #"\s*\b(semicolon|semi colon|point[- ]virgule)\b"#, ";")
        t = re(t, #"\s*\b(open paren|open parenthesis|ouvrez la parenthèse)\b\s*"#, " (")
        t = re(t, #"\s*\b(close paren|close parenthesis|fermez la parenthèse)\b"#, ")")
        t = re(t, #"\s*\b(dash|hyphen|tiret du six)\b"#, " - ")

        // 3. "scratch that" — delete back to the start of the current sentence.
        t = re(t, #"[^.!?\n]*\b(scratch that|delete that|oublie ça|supprime ça)\b[\s,]*"#, "")

        // 4. Tidy spacing + sentence capitalization.
        t = re(t, #"[ \t]+([,.;:!?\)])"#, "$1")          // no space before punctuation
        t = re(t, #"([,;:!?])([^\s\d])"#, "$1 $2")        // space after , ; : ! ? (not before digits)
        t = re(t, #"\.([A-Za-zÀ-ÿ])"#, ". $1")            // space after period before a letter
        t = re(t, #"[ \t]{2,}"#, " ")                     // collapse runs of spaces
        t = capitalizeSentences(t)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func re(_ s: String, _ pattern: String, _ template: String) -> String {
        guard let r = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return s }
        return r.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
    }

    private static func capitalizeSentences(_ s: String) -> String {
        var out = ""
        var capNext = true
        for ch in s {
            if ch == "\n" { out.append(ch); capNext = true; continue }
            if ch == " " || ch == "\t" { out.append(ch); continue }
            if capNext, ch.isLetter {
                out.append(contentsOf: ch.uppercased()); capNext = false
            } else {
                out.append(ch); capNext = false
            }
            if ch == "." || ch == "!" || ch == "?" { capNext = true }
        }
        return out
    }
}
