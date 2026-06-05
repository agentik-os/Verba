import AppKit

/// Converts Claude's Markdown output into styled rich text, so pasting into apps
/// that support formatting (Notes, Mail, Slack, Pages…) shows real bold/headings/
/// lists instead of literal **stars** and #. Goes through HTML → NSAttributedString.
enum Markdown {
    static func attributed(_ md: String) -> NSAttributedString {
        let style = """
        <style>
          body { font-family: -apple-system, Helvetica, sans-serif; font-size: 14px; line-height: 1.45; }
          h1 { font-size: 22px; margin: 0.4em 0; } h2 { font-size: 18px; margin: 0.4em 0; }
          h3 { font-size: 16px; margin: 0.3em 0; } p { margin: 0.3em 0; }
          ul, ol { margin: 0.2em 0 0.2em 1.2em; } li { margin: 0.1em 0; }
          code { font-family: ui-monospace, Menlo, monospace; font-size: 13px; }
          pre { font-family: ui-monospace, Menlo, monospace; font-size: 13px; }
        </style>
        """
        let html = style + toHTML(md)
        if let data = html.data(using: .utf8),
           let attr = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil) {
            return attr
        }
        return NSAttributedString(string: md)
    }

    // MARK: - Markdown → HTML (covers what the reprompt produces)

    static func toHTML(_ md: String) -> String {
        var out: [String] = []
        var inUL = false, inOL = false, inCode = false
        var codeBuf: [String] = []

        func closeLists() {
            if inUL { out.append("</ul>"); inUL = false }
            if inOL { out.append("</ol>"); inOL = false }
        }

        for raw in md.components(separatedBy: "\n") {
            // fenced code blocks ```
            if raw.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    out.append("<pre><code>" + codeBuf.map(escape).joined(separator: "\n") + "</code></pre>")
                    codeBuf = []; inCode = false
                } else {
                    closeLists(); inCode = true
                }
                continue
            }
            if inCode { codeBuf.append(raw); continue }

            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { closeLists(); continue }

            if let h = heading(t) {
                closeLists(); out.append("<h\(h.0)>\(inline(h.1))</h\(h.0)>"); continue
            }
            if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") {
                if !inUL { closeLists(); out.append("<ul>"); inUL = true }
                out.append("<li>\(inline(String(t.dropFirst(2))))</li>"); continue
            }
            if let item = numbered(t) {
                if !inOL { closeLists(); out.append("<ol>"); inOL = true }
                out.append("<li>\(inline(item))</li>"); continue
            }
            closeLists()
            out.append("<p>\(inline(t))</p>")
        }
        if inCode { out.append("<pre><code>" + codeBuf.map(escape).joined(separator: "\n") + "</code></pre>") }
        closeLists()
        return out.joined()
    }

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

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Inline: escape, then code → bold → italic → links.
    private static func inline(_ s: String) -> String {
        var t = escape(s)
        t = replace(t, #"`([^`]+)`"#, "<code>$1</code>")
        t = replace(t, #"\*\*([^*]+)\*\*"#, "<strong>$1</strong>")
        t = replace(t, #"__([^_]+)__"#, "<strong>$1</strong>")
        t = replace(t, #"(?<!\*)\*([^*\n]+)\*(?!\*)"#, "<em>$1</em>")
        t = replace(t, #"\[([^\]]+)\]\(([^)]+)\)"#, "<a href=\"$2\">$1</a>")
        return t
    }

    private static func replace(_ s: String, _ pattern: String, _ template: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
        let range = NSRange(s.startIndex..., in: s)
        return re.stringByReplacingMatches(in: s, range: range, withTemplate: template)
    }
}
