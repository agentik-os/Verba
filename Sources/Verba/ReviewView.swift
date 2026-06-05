import SwiftUI

/// Shown when "Review / edit before sending" is on: lets the user tweak Claude's
/// output (or fall back to the raw transcript) before it's pasted.
struct ReviewView: View {
    let original: String
    @State var text: String
    @State private var showOriginal = false
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
            TextEditor(text: $text)
                .font(.system(.body))
                .frame(minWidth: 460, minHeight: 220)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                Spacer()
                Button("Copy") { Output.copyToClipboard(text); onCancel() }
                Button("Paste") { onConfirm(text) }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 520)
    }
}
