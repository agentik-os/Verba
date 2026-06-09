import SwiftUI
import AppKit

/// Holds a weak ref to the live review NSTextView so the toolbar can read the current selection
/// (used by "Add to Dictionary", enabled only when exactly one word is selected). `selectedWord`
/// republishes on every selection change so the button's enabled state stays live.
final class ReviewEditorController: ObservableObject {
    weak var textView: NSTextView?
    /// The currently selected token if the selection is exactly one word (no whitespace, non-empty),
    /// otherwise nil. Drives the "Add to Dictionary" button's enabled state + tooltip.
    @Published var selectedWord: String? = nil

    func refresh() {
        guard let tv = textView else { selectedWord = nil; return }
        let ns = tv.string as NSString
        let sel = tv.selectedRange()
        guard sel.length > 0, sel.location >= 0, sel.location + sel.length <= ns.length else {
            selectedWord = nil; return
        }
        let raw = ns.substring(with: sel)
        let word = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Exactly one token: non-empty and contains no internal whitespace.
        if !word.isEmpty, !word.contains(where: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
            selectedWord = word
        } else {
            selectedWord = nil
        }
    }
}

/// Plain, editable text view that reports selection changes so a SwiftUI toolbar can act on the
/// current selection. Mirrors the MarkdownEditor NSViewRepresentable pattern but without styling.
struct ReviewTextEditor: NSViewRepresentable {
    @Binding var text: String
    var controller: ReviewEditorController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false

        let tv = NSTextView()
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = NSFont.systemFont(ofSize: 14)
        tv.textContainerInset = NSSize(width: 10, height: 10)
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
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        tv.string = text
        scroll.documentView = tv
        controller.textView = tv
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let tv = scroll.documentView as? NSTextView else { return }
        controller.textView = tv
        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            tv.setSelectedRange(NSRange(location: min(sel.location, (text as NSString).length), length: 0))
            DispatchQueue.main.async { context.coordinator.parent.controller.refresh() }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: ReviewTextEditor
        init(_ parent: ReviewTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            parent.controller.refresh()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            parent.controller.refresh()
        }
    }
}

/// Shown when "Review / edit before sending" is on: lets the user tweak Claude's
/// output (or fall back to the raw transcript) before it's pasted.
struct ReviewView: View {
    let original: String
    @State var text: String
    @State private var showOriginal = false
    @State private var didAddWord = false
    @StateObject private var editor = ReviewEditorController()
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Review dictation").font(.headline)
                Spacer()
                Toggle("Show raw transcript", isOn: $showOriginal).toggleStyle(.switch)
            }
            if showOriginal {
                ScrollView { Text(original).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                Button("Use raw transcript instead") { text = original }
                    .font(.caption)
            }
            ReviewTextEditor(text: $text, controller: editor)
                .font(.system(.body))
                .frame(minWidth: 460, minHeight: 220).padding(2)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(spacing: 8) {
                Button(action: addSelectedWord) {
                    Label(didAddWord ? "Added" : "Add to Dictionary",
                          systemImage: didAddWord ? "checkmark" : "text.book.closed")
                }
                .disabled(editor.selectedWord == nil)
                .help(editor.selectedWord == nil ? "Please select one word"
                                                 : "Add “\(editor.selectedWord ?? "")” to the dictionary")
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                Button("Copy") { Output.copyToClipboard(text); onCancel() }
                Button("Paste") { onConfirm(text) }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 520)
    }

    /// Add the single selected word as a pure vocabulary entry (empty spoken form), consistent with
    /// the "Add a word" option in the dictionary settings. Skips duplicates.
    private func addSelectedWord() {
        guard let word = editor.selectedWord, !word.isEmpty else { return }
        let store = DictionaryStore.shared
        let exists = store.terms.contains {
            $0.spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.written.caseInsensitiveCompare(word) == .orderedSame
        }
        if !exists { store.terms.append(DictTerm(spoken: "", written: word)) }
        didAddWord = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { didAddWord = false }
    }
}
