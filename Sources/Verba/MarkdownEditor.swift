import SwiftUI
import AppKit

/// Holds a weak ref to the live NSTextView so a SwiftUI formatting toolbar can wrap the selection
/// (**bold**, *italic*, ~~strike~~, `code`) or toggle a line prefix (# heading, - bullet, 1. number).
final class MarkdownEditorController: ObservableObject {
    weak var textView: NSTextView?

    /// Wrap the selection in `marker` (or insert an empty pair and place the caret inside).
    func wrap(_ marker: String) {
        guard let tv = textView else { return }
        let ns = tv.string as NSString
        let sel = tv.selectedRange()
        let selected = ns.substring(with: sel)
        let replacement = marker + selected + marker
        guard tv.shouldChangeText(in: sel, replacementString: replacement) else { return }
        tv.textStorage?.replaceCharacters(in: sel, with: replacement)
        tv.didChangeText()
        // Re-select the inner text (or place the caret between the markers).
        tv.setSelectedRange(NSRange(location: sel.location + marker.count, length: (selected as NSString).length))
        tv.window?.makeFirstResponder(tv)
    }

    /// Add (or remove, if already present) `prefix` at the start of every line in the selection.
    func toggleLinePrefix(_ prefix: String) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let ns = tv.string as NSString
        let lineRange = ns.lineRange(for: tv.selectedRange())
        let block = ns.substring(with: lineRange)
        let lines = block.components(separatedBy: "\n")
        // Drop a trailing empty element from a final newline so we don't prefix a phantom line.
        let hadTrailingNewline = block.hasSuffix("\n")
        var work = lines
        if hadTrailingNewline { work.removeLast() }
        let allPrefixed = work.allSatisfy { $0.hasPrefix(prefix) || $0.trimmingCharacters(in: .whitespaces).isEmpty }
        let transformed = work.map { line -> String in
            if line.trimmingCharacters(in: .whitespaces).isEmpty { return line }
            if allPrefixed { return String(line.dropFirst(line.hasPrefix(prefix) ? prefix.count : 0)) }
            return prefix + line
        }
        var newBlock = transformed.joined(separator: "\n")
        if hadTrailingNewline { newBlock += "\n" }
        guard tv.shouldChangeText(in: lineRange, replacementString: newBlock) else { return }
        storage.replaceCharacters(in: lineRange, with: newBlock)
        tv.didChangeText()
        tv.setSelectedRange(NSRange(location: lineRange.location, length: (newBlock as NSString).length))
        tv.window?.makeFirstResponder(tv)
    }
}

/// A single, always-editable note editor that styles Markdown live as you type (Bear-style):
/// headings grow + bold, **bold**/*italic*/~~strike~~/`code` render inline, list & checkbox markers dim.
/// You edit the real Markdown source (markers stay, just de-emphasized) — no Preview/Edit toggle.
struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    var controller: MarkdownEditorController? = nil
    var minHeight: CGFloat = 320

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false

        let container = NSTextContainer()
        container.widthTracksTextView = true
        let lm = NSLayoutManager()
        lm.addTextContainer(container)
        lm.delegate = context.coordinator        // lets us hide marker glyphs (** ## etc.)
        let storage = NSTextStorage()
        storage.addLayoutManager(lm)

        let tv = MDTextView(frame: .zero, textContainer: container)
        tv.delegate = context.coordinator
        tv.isRichText = false                 // we own styling; store stays plain Markdown
        tv.allowsUndo = true
        tv.font = NSFont.systemFont(ofSize: 14)
        tv.textContainerInset = NSSize(width: 16, height: 14)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.minSize = NSSize(width: 0, height: 0)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        tv.string = text
        // When the editor gains/loses focus, restyle so markers reveal (editing) or hide (reading).
        tv.onFocusChange = { [weak tv, weak coord = context.coordinator] in
            guard let tv, let coord else { return }
            DispatchQueue.main.async { coord.restyle(tv, force: false) }
        }
        scroll.documentView = tv
        context.coordinator.restyle(tv, force: true)
        controller?.textView = tv
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let tv = scroll.documentView as? NSTextView else { return }
        controller?.textView = tv
        if tv.string != text {                // external change (load a note, re-format) → replace
            let sel = tv.selectedRange()
            tv.string = text
            context.coordinator.restyle(tv, force: true)
            tv.setSelectedRange(NSRange(location: min(sel.location, (text as NSString).length), length: 0))
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate, NSLayoutManagerDelegate {
        let parent: MarkdownEditor
        var hidden = Set<Int>()              // character indexes of markers to render as zero-width
        private var lastActive = NSRange(location: -1, length: 0)
        init(_ parent: MarkdownEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            let sel = tv.selectedRange()
            restyleEdited(tv)                  // re-scan only the edited paragraph(s), not the whole doc
            tv.setSelectedRange(sel)          // restyle must not move the caret
        }

        // Incremental restyle for live typing: re-run `style()` over just the paragraph range that
        // contains the caret/edit, and invalidate glyphs for that sub-range only. Restyling the
        // whole NSTextStorage on every keystroke caused visible input lag in long (multi-KB) notes,
        // because the per-line enumeration + full-range glyph invalidate/ensureLayout aren't guarded.
        func restyleEdited(_ tv: NSTextView) {
            guard let ts = tv.textStorage, let lm = tv.layoutManager else { return }
            let editing = (tv.window?.firstResponder === tv)
            let ns = ts.string as NSString
            // Edited scope = the paragraph(s) touched by the current selection.
            let scope = ns.lineRange(for: tv.selectedRange())
            let active = editing ? scope : NSRange(location: -1, length: 0)
            lastActive = active
            // Drop any previously-hidden marker indexes inside the scope; the rescan re-adds the
            // current ones. Indexes outside the scope are unaffected by a single-paragraph edit.
            hidden = hidden.filter { !NSLocationInRange($0, scope) }
            let scoped = MarkdownEditor.style(ts, activeLine: active, in: scope)
            hidden.formUnion(scoped)
            lm.invalidateGlyphs(forCharacterRange: scope, changeInLength: 0, actualCharacterRange: nil)
            lm.ensureLayout(forCharacterRange: scope)
        }

        // Reveal markers on the line the caret is on (so you can edit the syntax), hide elsewhere.
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let active = (tv.string as NSString).lineRange(for: tv.selectedRange())
            if NSEqualRanges(active, lastActive) { return }   // same line → nothing to re-hide
            restyle(tv, force: false)
        }

        func restyle(_ tv: NSTextView, force: Bool) {
            guard let ts = tv.textStorage, let lm = tv.layoutManager else { return }
            // Reveal markers only while the editor is focused (you're editing). When just reading a
            // note, hide every marker so headings/bold render clean — no `#`/`**` on the first line.
            let editing = (tv.window?.firstResponder === tv)
            let active = editing ? (tv.string as NSString).lineRange(for: tv.selectedRange())
                                 : NSRange(location: -1, length: 0)
            lastActive = active
            hidden = MarkdownEditor.style(ts, activeLine: active)
            let full = NSRange(location: 0, length: ts.length)
            lm.invalidateGlyphs(forCharacterRange: full, changeInLength: 0, actualCharacterRange: nil)
            lm.ensureLayout(forCharacterRange: full)
        }

        // NSLayoutManagerDelegate: drop marker glyphs (zero width) so ** and ## don't show.
        func layoutManager(_ layoutManager: NSLayoutManager,
                           shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
                           properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
                           characterIndexes charIndexes: UnsafePointer<Int>,
                           font aFont: NSFont,
                           forGlyphRange glyphRange: NSRange) -> Int {
            guard !hidden.isEmpty else {
                layoutManager.setGlyphs(glyphs, properties: props, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
                return glyphRange.length
            }
            let n = glyphRange.length
            let out = UnsafeMutablePointer<NSLayoutManager.GlyphProperty>.allocate(capacity: n)
            defer { out.deallocate() }
            for i in 0..<n { out[i] = hidden.contains(charIndexes[i]) ? .null : props[i] }
            layoutManager.setGlyphs(glyphs, properties: out, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
            return n
        }
    }

    // MARK: - Live styling. Applies fonts/colors AND returns the marker character indexes to hide
    // (markers on the active line are NOT hidden, so they stay editable). Never mutates characters.
    @discardableResult
    static func style(_ ts: NSTextStorage, activeLine: NSRange = NSRange(location: -1, length: 0),
                      in scope: NSRange? = nil) -> Set<Int> {
        let full = NSRange(location: 0, length: ts.length)
        // `scope` limits the rescan to an edited paragraph range (clamped to the document) so live
        // typing doesn't re-style/re-enumerate the whole note; nil means restyle the full document.
        let range = scope.map { NSIntersectionRange($0, full) } ?? full
        guard range.length > 0 || ts.length == 0 else { return Set<Int>() }
        let ns = ts.string as NSString
        let base = NSFont.systemFont(ofSize: 14)
        let dim = NSColor.tertiaryLabelColor
        let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        var hide = Set<Int>()
        func conceal(_ loc: Int, _ len: Int) {
            let r = NSRange(location: loc, length: len)
            if NSIntersectionRange(r, activeLine).length > 0 { return }   // editing this line → keep visible
            for i in loc..<(loc + len) where i >= 0 && i < ns.length { hide.insert(i) }
        }

        ts.beginEditing()
        ts.setAttributes([.font: base, .foregroundColor: NSColor.labelColor], range: range)

        // Per-line: headings, list/checkbox markers.
        ns.enumerateSubstrings(in: range, options: .byLines) { sub, lineRange, _, _ in
            guard let line = sub else { return }
            let hashes = line.prefix(while: { $0 == "#" }).count
            if hashes >= 1, hashes <= 6, line.count > hashes, line[line.index(line.startIndex, offsetBy: hashes)] == " " {
                let sizes: [CGFloat] = [0, 24, 20, 17, 16, 15, 14]
                ts.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: sizes[hashes]), range: lineRange)
                conceal(lineRange.location, min(hashes + 1, lineRange.length))   // hide "## "
            } else if let r = line.range(of: "^\\s*([-*+]|\\d+\\.)\\s", options: .regularExpression) {
                let len = line.distance(from: line.startIndex, to: r.upperBound)
                ts.addAttribute(.foregroundColor, value: dim, range: NSRange(location: lineRange.location, length: min(len, lineRange.length)))
            }
            if let r = line.range(of: "^\\s*-\\s\\[[ xX]\\]", options: .regularExpression) {
                let len = line.distance(from: line.startIndex, to: r.upperBound)
                let checked = line.lowercased().contains("[x]")
                ts.addAttribute(.foregroundColor, value: checked ? NSColor.controlAccentColor : dim,
                                range: NSRange(location: lineRange.location, length: min(len, lineRange.length)))
            }
        }

        // Inline spans: style the content, HIDE the markers (revealed only on the active line).
        // The 20000-char guard applies to the *scanned* range, so a scoped paragraph edit in a huge
        // note still gets inline styling (only a full-document rescan of a 20k+ note skips it).
        guard range.length < 20000 else { ts.endEditing(); return hide }
        applyInline(ts, ns, in: range, pattern: "\\*\\*(.+?)\\*\\*", markerLen: 2, attrs: [.font: NSFont.boldSystemFont(ofSize: 14)], conceal: conceal)
        applyInline(ts, ns, in: range, pattern: "~~(.+?)~~", markerLen: 2, attrs: [.strikethroughStyle: NSUnderlineStyle.single.rawValue], conceal: conceal)
        applyInline(ts, ns, in: range, pattern: "(?<!\\*)\\*(?!\\*)([^*\\n]+?)\\*(?!\\*)", markerLen: 1, attrs: [.font: italicFont(14)], conceal: conceal)
        applyInline(ts, ns, in: range, pattern: "`([^`\\n]+?)`", markerLen: 1, attrs: [.font: codeFont, .foregroundColor: NSColor.systemPink], conceal: conceal)

        ts.endEditing()
        return hide
    }

    private static func applyInline(_ ts: NSTextStorage, _ ns: NSString, in range: NSRange, pattern: String,
                                    markerLen: Int, attrs: [NSAttributedString.Key: Any],
                                    conceal: (Int, Int) -> Void) {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return }
        for m in re.matches(in: ns as String, range: range) {
            let whole = m.range
            for (k, v) in attrs { ts.addAttribute(k, value: v, range: whole) }
            conceal(whole.location, markerLen)                              // opening marker
            conceal(whole.location + whole.length - markerLen, markerLen)   // closing marker
        }
    }

    private static func italicFont(_ size: CGFloat) -> NSFont {
        let base = NSFont.systemFont(ofSize: size)
        return NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
    }
}

/// NSTextView that reports focus gain/loss so the editor can reveal markers while editing and
/// hide them while reading.
final class MDTextView: NSTextView {
    var onFocusChange: (() -> Void)?
    override func becomeFirstResponder() -> Bool { let r = super.becomeFirstResponder(); onFocusChange?(); return r }
    override func resignFirstResponder() -> Bool { let r = super.resignFirstResponder(); onFocusChange?(); return r }
}
