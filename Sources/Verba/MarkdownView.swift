import SwiftUI

/// Lightweight native markdown renderer: headings, bold/italic/code (inline), bullet &
/// numbered lists, and checkboxes. Lays out naturally in SwiftUI (wraps, self-sizes).
struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
                line(raw)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder private func line(_ raw: String) -> some View {
        let t = raw.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            Spacer().frame(height: 5)
        } else if t.hasPrefix("### ") {
            Text(inline(String(t.dropFirst(4)))).font(.system(size: 15, weight: .semibold))
        } else if t.hasPrefix("## ") {
            Text(inline(String(t.dropFirst(3)))).font(.system(size: 17, weight: .bold))
        } else if t.hasPrefix("# ") {
            Text(inline(String(t.dropFirst(2)))).font(.system(size: 20, weight: .bold))
        } else if t.hasPrefix("- [ ] ") || t.lowercased().hasPrefix("- [x] ") {
            let checked = t.lowercased().hasPrefix("- [x] ")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(checked ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                Text(inline(String(t.dropFirst(6)))).strikethrough(checked, color: .secondary)
                    .foregroundStyle(checked ? .secondary : .primary)
            }
        } else if t == "---" || t == "***" || t == "___" {
            Divider().opacity(0.5)
        } else if t.hasPrefix("> ") {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(Color.primary.opacity(0.25)).frame(width: 3)
                Text(inline(String(t.dropFirst(2)))).foregroundStyle(.secondary)
            }
        } else if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•").foregroundStyle(.secondary)
                Text(inline(String(t.dropFirst(2))))
            }
        } else if let r = t.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(t[r]).trimmingCharacters(in: .whitespaces)).foregroundStyle(.secondary).monospacedDigit()
                Text(inline(String(t[r.upperBound...])))
            }
        } else {
            Text(inline(t))
        }
    }

    /// Inline markdown (**bold**, *italic*, `code`, ~~strike~~) plus `<u>…</u>` underline (which
    /// standard markdown has no syntax for) for a single line.
    private func inline(_ s: String) -> AttributedString {
        var attr = (try? AttributedString(
            markdown: s.replacingOccurrences(of: "<u>", with: "").replacingOccurrences(of: "</u>", with: ""),
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
        // Underline each <u>payload</u> span by finding the payload in the rendered string.
        var scan = s
        while let open = scan.range(of: "<u>"), let close = scan.range(of: "</u>"), open.upperBound <= close.lowerBound {
            let payload = String(scan[open.upperBound..<close.lowerBound])
            if !payload.isEmpty, let r = attr.range(of: payload) { attr[r].underlineStyle = .single }
            scan.replaceSubrange(scan.startIndex..<close.upperBound, with: "")
        }
        return attr
    }
}
