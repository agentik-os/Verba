import AppKit

/// Converts Claude's Markdown output into styled rich text, so pasting into apps
/// that support formatting (Notes, Mail, Slack, Pages…) shows real bold/headings/
/// lists instead of literal **stars** and #.
///
/// Built with NATIVE NSAttributedString runs — deliberately NOT `NSAttributedString(html:)`.
/// That API silently spins up a full WebKit instance on the main thread; on macOS Sequoia the
/// WebKit init inspects the general pasteboard, so if the clipboard holds a file reference from
/// ANOTHER app (e.g. a CleanShot screenshot) macOS fired the "Verba would like to access data
/// from other apps" prompt on every rich paste. It was also needlessly slow. This native builder
/// produces the same visual result with zero WebKit and zero pasteboard access.
enum Markdown {
    static func attributed(_ md: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        var inCode = false
        var codeBuf: [String] = []
        var pendingNewline = false

        func appendBlock(_ block: NSAttributedString) {
            if pendingNewline { out.append(NSAttributedString(string: "\n")) }
            out.append(block)
            pendingNewline = true
        }
        func flushCode() {
            guard !codeBuf.isEmpty else { return }
            appendBlock(codeParagraph(codeBuf.joined(separator: "\n")))
            codeBuf = []
        }

        for raw in md.components(separatedBy: "\n") {
            // Fenced code blocks ``` … ```
            if raw.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode { flushCode(); inCode = false }
                else { inCode = true }
                continue
            }
            if inCode { codeBuf.append(raw); continue }

            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }

            if let h = heading(t) {
                appendBlock(styledLine(h.1, base: headingFont(h.0), paragraph: headingParagraph()))
                continue
            }
            if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") {
                appendBlock(styledLine(String(t.dropFirst(2)), base: bodyFont,
                                       paragraph: listParagraph(), bullet: "•\t"))
                continue
            }
            if let item = numbered(t) {
                appendBlock(styledLine(item, base: bodyFont,
                                       paragraph: listParagraph(), bullet: "\(numberPrefix(t)).\t"))
                continue
            }
            appendBlock(styledLine(t, base: bodyFont, paragraph: bodyParagraph()))
        }
        if inCode { flushCode() }
        return out
    }

    // MARK: - Fonts & paragraph styles

    private static let bodyFont = NSFont.systemFont(ofSize: 14)
    private static let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    private static func headingFont(_ level: Int) -> NSFont {
        let size: CGFloat = [1: 22, 2: 18, 3: 16, 4: 15][level] ?? 14
        return NSFont.boldSystemFont(ofSize: size)
    }
    private static func bodyParagraph() -> NSParagraphStyle {
        let p = NSMutableParagraphStyle(); p.paragraphSpacing = 6; return p
    }
    private static func headingParagraph() -> NSParagraphStyle {
        let p = NSMutableParagraphStyle(); p.paragraphSpacingBefore = 6; p.paragraphSpacing = 4; return p
    }
    private static func listParagraph() -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.headIndent = 18; p.paragraphSpacing = 2
        p.tabStops = [NSTextTab(textAlignment: .left, location: 18)]
        return p
    }
    private static func codeParagraph(_ code: String) -> NSAttributedString {
        let p = NSMutableParagraphStyle(); p.headIndent = 12; p.firstLineHeadIndent = 12; p.paragraphSpacing = 6
        return NSAttributedString(string: code, attributes: [.font: codeFont, .paragraphStyle: p])
    }

    // MARK: - Block → styled line (with inline formatting applied)

    private static func styledLine(_ text: String, base: NSFont, paragraph: NSParagraphStyle,
                                   bullet: String? = nil) -> NSAttributedString {
        let line = NSMutableAttributedString(string: bullet ?? "",
                                             attributes: [.font: base, .paragraphStyle: paragraph])
        let body = NSMutableAttributedString(string: text, attributes: [.font: base, .paragraphStyle: paragraph])
        applyInline(body)
        line.append(body)
        return line
    }

    // MARK: - Inline formatting (bold / italic / code / links), WebKit-free

    /// Apply inline Markdown by rewriting delimiter spans into styled runs. Each pass scans the
    /// CURRENT string and processes matches LAST-to-FIRST so earlier locations stay valid while the
    /// string shrinks. Order: code first (its content is literal), then bold, italic, links.
    private static func applyInline(_ a: NSMutableAttributedString) {
        // Code first: its content is LITERAL. We tag the resulting run with .font == codeFont, and
        // every later pass skips any match sitting inside a code run — otherwise `a_b_c` inside
        // backticks would get its `_b_` italicised and `[x](y)` linkified (bug: code spans were
        // re-scanned and silently corrupted). skipCode:false only for this pass.
        pass(a, #"`([^`]+)`"#, skipCode: false) { r in
            let inner = a.attributedSubstring(from: r.range(at: 1))
            a.replaceCharacters(in: r.range(at: 0), with: inner)
            a.addAttribute(.font, value: codeFont,
                           range: NSRange(location: r.range(at: 0).location, length: inner.length))
        }
        for pattern in [#"\*\*([^*]+)\*\*"#, #"__([^_]+)__"#] {
            pass(a, pattern) { r in reStyle(a, r, trait: .boldFontMask) }
        }
        // Single-* italics, and single-_ italics only at word boundaries (leave snake_case alone).
        for pattern in [#"(?<!\*)\*([^*\n]+)\*(?!\*)"#, #"(?<![\w_])_([^_\n]+)_(?![\w_])"#] {
            pass(a, pattern) { r in reStyle(a, r, trait: .italicFontMask) }
        }
        pass(a, #"\[([^\]]+)\]\(([^)]+)\)"#) { r in
            let urlStr = (a.string as NSString).substring(with: r.range(at: 2))
            let inner = a.attributedSubstring(from: r.range(at: 1))
            a.replaceCharacters(in: r.range(at: 0), with: inner)
            let newRange = NSRange(location: r.range(at: 0).location, length: inner.length)
            if let url = URL(string: urlStr) { a.addAttribute(.link, value: url, range: newRange) }
            a.addAttribute(.foregroundColor, value: NSColor.linkColor, range: newRange)
        }
    }

    /// True if the character at `loc` is already part of a code run (font == codeFont), so inline
    /// passes leave it untouched.
    private static func isCode(_ a: NSMutableAttributedString, at loc: Int) -> Bool {
        guard loc < a.length else { return false }
        return (a.attribute(.font, at: loc, effectiveRange: nil) as? NSFont) == codeFont
    }

    /// Replace a `<delim>inner<delim>` match (group 1 = inner) with the inner run carrying an added
    /// font trait, preserving any traits an earlier pass already applied inside it.
    private static func reStyle(_ a: NSMutableAttributedString, _ r: NSTextCheckingResult, trait: NSFontTraitMask) {
        let inner = a.attributedSubstring(from: r.range(at: 1))
        a.replaceCharacters(in: r.range(at: 0), with: inner)
        let range = NSRange(location: r.range(at: 0).location, length: inner.length)
        a.enumerateAttribute(.font, in: range, options: []) { value, sub, _ in
            let current = (value as? NSFont) ?? bodyFont
            a.addAttribute(.font, value: NSFontManager.shared.convert(current, toHaveTrait: trait), range: sub)
        }
    }

    private static func pass(_ a: NSMutableAttributedString, _ pattern: String, skipCode: Bool = true,
                             _ body: (NSTextCheckingResult) -> Void) {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return }
        let full = NSRange(location: 0, length: (a.string as NSString).length)
        for m in re.matches(in: a.string, range: full).reversed() {
            if skipCode, isCode(a, at: m.range(at: 0).location) { continue }   // don't reformat inside a code span
            body(m)
        }
    }

    // MARK: - Block detection helpers

    private static func heading(_ s: String) -> (Int, String)? {
        var level = 0
        for c in s { if c == "#" { level += 1 } else { break } }
        guard level >= 1, level <= 6, s.dropFirst(level).first == " " else { return nil }
        return (level, String(s.dropFirst(level + 1)))
    }

    private static func numbered(_ s: String) -> String? {
        guard let dot = s.firstIndex(of: "."), s[s.startIndex..<dot].allSatisfy(\.isNumber),
              s.index(after: dot) < s.endIndex, s[s.index(after: dot)] == " " else { return nil }
        return String(s[s.index(dot, offsetBy: 2)...])
    }

    /// The leading number of an ordered-list item ("3. foo" → "3"), for the rendered bullet.
    private static func numberPrefix(_ s: String) -> String {
        String(s.prefix { $0.isNumber })
    }
}
