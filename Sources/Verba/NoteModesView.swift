import SwiftUI
import AppKit

/// CRUD editor for the NOTE modes (parallel to ModesView for dictation modes). Add, customize the
/// name + system prompt + model, or delete a mode; reset to the shipped defaults. The "Intent" mode
/// takes a one-off instruction at record time, so its editor explains that rather than offering a
/// fixed prompt to send verbatim.
struct NoteModesView: View {
    @ObservedObject var store = NoteModesStore.shared
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    ForEach(store.modes) { m in
                        HStack(spacing: 8) {
                            Image(systemName: m.icon).foregroundStyle(.secondary).frame(width: 16)
                            Text(m.name).lineLimit(1)
                            Spacer(minLength: 6)
                            if m.builtin { Text("Built-in").font(.caption2).foregroundStyle(.tertiary) }
                        }
                        .padding(.vertical, 3)
                        .tag(m.id)
                    }
                    .onMove { from, to in store.modes.move(fromOffsets: from, toOffset: to) }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                HStack(spacing: 14) {
                    Button { let m = store.addBlank(); selectedID = m.id } label: { Label("New", systemImage: "plus") }
                        .help("Create a new note mode")
                    Spacer()
                    Button { store.resetToDefaults(); selectedID = store.modes.first?.id } label: {
                        Label("Reset defaults", systemImage: "arrow.counterclockwise")
                    }.help("Restore the shipped note modes")
                }
                .buttonStyle(.borderless).font(.callout)
                .padding(.horizontal, 14).padding(.vertical, 9).padding(.bottom, 4)
            }
            .frame(width: 232)

            Group {
                if let id = selectedID, store.modes.contains(where: { $0.id == id }) {
                    editor(id: id)
                } else {
                    ContentUnavailableView("Select a note mode", systemImage: "doc.text",
                        description: Text("Each mode is a different way Verba turns your recording into a written note."))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // The hosting sheet (NotesView) no longer draws a hard Divider; this view owns its top spacing.
        .padding(.top, 6)
        .onAppear { if selectedID == nil { selectedID = store.modes.first?.id } }
    }

    private func index(of id: UUID) -> Int? { store.modes.firstIndex { $0.id == id } }

    private func editor(id: UUID) -> some View {
        let nameB = Binding(get: { store.modes.first { $0.id == id }?.name ?? "" },
                            set: { v in if let i = index(of: id) { store.modes[i].name = v } })
        let promptB = Binding(get: { store.modes.first { $0.id == id }?.systemPrompt ?? "" },
                              set: { v in if let i = index(of: id) { store.modes[i].systemPrompt = v } })
        let modelB = Binding(get: { store.modes.first { $0.id == id }?.model ?? "" },
                             set: { v in if let i = index(of: id) { store.modes[i].model = v.isEmpty ? nil : v } })
        let m = store.modes.first { $0.id == id }
        let isIntent = m?.intent ?? false

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240)
                    Spacer()
                    Button(role: .destructive) { delete(id) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this mode")
                }

                field("Model", hint: "which Claude model turns the recording into this note") {
                    Picker("", selection: modelB) {
                        Text("Default (\(Settings.shared.claudeModel))").tag("")
                        Text("Haiku 4.5, fastest, cheapest").tag("claude-haiku-4-5")
                        Text("Sonnet 4.6, balanced").tag("claude-sonnet-4-6")
                        Text("Opus 4.8, most capable").tag("claude-opus-4-8")
                    }
                    .labelsHidden().pickerStyle(.menu).frame(maxWidth: 320, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("System prompt").font(.subheadline.weight(.semibold))
                        Text(isIntent ? "the base prompt; your spoken/typed instruction is added on top each time"
                                      : "how Claude turns your words into the note").font(.caption).foregroundStyle(.secondary)
                    }
                    TextEditor(text: promptB)
                        .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                        .frame(minHeight: 220).padding(12)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if isIntent {
                        Text("This is the Intent mode: when you pick it in Notes, you also give a one-off instruction (e.g. \u{201C}as a bug report\u{201D}) that shapes that single recording.")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func delete(_ id: UUID) {
        selectedID = nil
        store.delete(id)
        selectedID = store.modes.first?.id
    }

    @ViewBuilder
    private func field<C: View>(_ title: String, hint: String? = nil, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title).font(.subheadline.weight(.semibold))
                if let hint { Text(hint).font(.caption).foregroundStyle(.secondary) }
            }
            content()
        }
    }
}
