import SwiftUI
import AppKit

/// CRUD editor for the NOTE modes (parallel to ModesView for dictation modes). Add, customize the
/// name + system prompt + model, or delete a mode; reset to the shipped defaults. The "Intent" mode
/// takes a one-off instruction at record time, so its editor explains that rather than offering a
/// fixed prompt to send verbatim.
struct NoteModesView: View {
    @ObservedObject var store = NoteModesStore.shared
    @State private var selectedID: UUID?
    @State private var confirmingReset = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    ForEach(store.modes) { m in
                        HStack(spacing: 8) {
                            Image(systemName: m.icon).foregroundStyle(.secondary).frame(width: 16)
                            Text(m.hasUsableName ? m.name : "Untitled")
                                .lineLimit(1)
                                .foregroundStyle(m.hasUsableName ? Color.primary : Color.secondary)
                            Spacer(minLength: 6)
                            // Flag the two states that change what this mode actually does, so the
                            // list tells the truth before the user picks a row (an empty prompt runs
                            // a fallback; a duplicate name is ambiguous when a note is reopened).
                            if !m.hasUsablePrompt {
                                badge("This mode has no prompt of its own")
                            } else if store.isNameDuplicated(m.id) {
                                badge("Another mode has this name")
                            }
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
                    Button { confirmingReset = true } label: {
                        Label("Reset defaults", systemImage: "arrow.counterclockwise")
                    }.help("Restore the shipped note modes")
                    .confirmationDialog("Reset note modes?", isPresented: $confirmingReset, titleVisibility: .visible) {
                        Button("Reset note modes", role: .destructive) {
                            store.resetToDefaults(); selectedID = store.modes.first?.id
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This removes your custom note modes and restores the shipped ones.")
                    }
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
        let promptIsBlank = !(m?.hasUsablePrompt ?? true)
        let nameIsBlank = !(m?.hasUsableName ?? true)
        let nameIsDuplicated = store.isNameDuplicated(id)
        let isLastMode = store.modes.count <= 1
        let deleteHelp = isLastMode ? "This is your last note mode, so it can't be deleted" : "Delete this mode"

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240)
                    Spacer()
                    if !isIntent {
                        Button(role: .destructive) { delete(id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).foregroundStyle(.red)
                            .disabled(isLastMode)
                            .help(deleteHelp)
                    }
                }
                if nameIsBlank {
                    warning("This mode has no name, so its chip in Notes will be blank. Give it one.")
                }
                if nameIsDuplicated {
                    // Notes store the format by name (NotesStore.formatName), so two modes sharing one
                    // name make reopening an old note ambiguous: the first match in this list wins.
                    warning("Another note mode is already called \u{201C}\(m?.name ?? "")\u{201D}. Reopening a saved note picks whichever of them comes first in this list.")
                }

                field("Model", hint: "which model turns the recording into this note") {
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
                                      : "how the AI turns your words into the note").font(.caption).foregroundStyle(.secondary)
                    }
                    TextEditor(text: promptB)
                        .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                        .frame(minHeight: 220).padding(12)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if promptIsBlank {
                        // Never let an empty prompt look like "no formatting": an empty system prompt
                        // still runs, unguided. NoteFormat.effectiveBasePrompt substitutes a shipped
                        // prompt, and this says which one, so the substitution is never a surprise.
                        warning(isIntent
                            ? "This prompt is empty, so recordings fall back to the shipped Intent prompt (it still reads the intent you speak at the start)."
                            : "This prompt is empty, so recordings fall back to the shipped Clean note prompt. Write a prompt to make this mode do something of its own.")
                    }
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
        // The store owns the rules now (the Intent mode is undeletable because it is the only source
        // of one-off instructions and cannot be re-created without a full reset; the list may never
        // empty out), so every caller inherits them. A refusal leaves the selection untouched rather
        // than clearing the editor as if something had happened.
        guard store.delete(id) else { return }
        selectedID = store.modes.first?.id
    }

    /// The list-row marker for a mode whose behaviour is not what its row suggests.
    private func badge(_ help: String) -> some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.caption2).foregroundStyle(.orange).help(help)
    }

    /// An inline caution about the selected mode. Used for the states that silently change what a
    /// run does: an empty prompt, a blank name, a name another mode already answers to.
    private func warning(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.orange)
            Text(text).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
