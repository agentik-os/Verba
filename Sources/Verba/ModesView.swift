import SwiftUI

/// The modes (profiles) editor — used both in the main window and Settings.
struct ModesView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selectedID: UUID?

    var body: some View {
        HSplitView {
            List(selection: $selectedID) {
                ForEach(settings.profiles) { p in
                    HStack {
                        if p.raw { Image(systemName: "waveform").foregroundStyle(.secondary) }
                        Text(p.name)
                        if let c = p.hotkeyCode, let m = p.hotkeyMods {
                            Text(shortcutLabel(keyCode: c, modifiers: m)).font(.caption2).foregroundStyle(.secondary)
                        }
                        if p.id == settings.activeProfileID {
                            Spacer(); Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        }
                    }.tag(p.id)
                }
            }
            .frame(minWidth: 180)
            .toolbar {
                Button { addProfile() } label: { Image(systemName: "plus") }
                    .disabled(!settings.isPro)
                    .help(settings.isPro ? "New mode" : "Custom modes are a Pro feature")
                Button {
                    settings.resetProfilesToDefaults(); selectedID = settings.activeProfileID
                } label: { Image(systemName: "arrow.counterclockwise") }
                    .help("Restore the built-in modes")
            }

            if let id = selectedID, settings.profiles.contains(where: { $0.id == id }) {
                editor(id: id)
            } else {
                ContentUnavailableView("Select a mode", systemImage: "wand.and.stars",
                                       description: Text("Each mode is a different way Claude reorders and improves your dictation."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { if selectedID == nil { selectedID = settings.activeProfileID } }
    }

    private func index(of id: UUID) -> Int? { settings.profiles.firstIndex { $0.id == id } }

    private func editor(id: UUID) -> some View {
        let nameB = Binding(get: { settings.profiles.first { $0.id == id }?.name ?? "" },
                            set: { v in if let i = index(of: id) { settings.profiles[i].name = v } })
        let promptB = Binding(get: { settings.profiles.first { $0.id == id }?.systemPrompt ?? "" },
                              set: { v in if let i = index(of: id) { settings.profiles[i].systemPrompt = v } })
        let bundlesB = Binding(get: { settings.profiles.first { $0.id == id }?.matchBundleIDs.joined(separator: ", ") ?? "" },
                               set: { v in if let i = index(of: id) {
                                   settings.profiles[i].matchBundleIDs = v.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } } })
        let p = settings.profiles.first { $0.id == id }
        let isBuiltin = p?.builtin ?? true
        let isRaw = p?.raw ?? false
        let shortcut: String = { guard let p, let c = p.hotkeyCode, let m = p.hotkeyMods else { return "" }
            return shortcutLabel(keyCode: c, modifiers: m) }()

        return Form {
            TextField("Name", text: nameB)
            if isRaw {
                Section { Text("Free-flow dictation: your words are transcribed exactly, with no AI reprompting.")
                    .foregroundStyle(.secondary) }
            } else {
                Section {
                    TextEditor(text: promptB)
                        .font(.system(.body, design: .monospaced)).frame(minHeight: 200)
                        .disabled(!settings.isPro).opacity(settings.isPro ? 1 : 0.55)
                } header: {
                    HStack {
                        Text("System prompt (how Claude reinterprets your audio)")
                        if !settings.isPro { Spacer(); Label("Pro", systemImage: "lock.fill").font(.caption).foregroundStyle(.tint) }
                    }
                } footer: {
                    if !settings.isPro {
                        Text("Editing modes is a Pro feature. Free includes the built-in modes as-is.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Dedicated shortcut") {
                HStack {
                    Text("Dictate straight into this mode"); Spacer()
                    ShortcutRecorder(label: shortcut,
                        onCapture: { c, m in if let i = index(of: id) { settings.profiles[i].hotkeyCode = c; settings.profiles[i].hotkeyMods = m } },
                        onClear: { if let i = index(of: id) { settings.profiles[i].hotkeyCode = nil; settings.profiles[i].hotkeyMods = nil } })
                }
            }
            Section("Auto-match app bundle IDs (comma-separated)") {
                TextField("com.apple.dt.Xcode, …", text: bundlesB)
            }
            HStack {
                Button("Make active") { settings.activeProfileID = id }
                Spacer()
                if !isBuiltin {
                    Button("Delete", role: .destructive) {
                        selectedID = nil
                        settings.profiles.removeAll { $0.id == id }
                        if settings.activeProfileID == id { settings.activeProfileID = settings.profiles.first?.id ?? id }
                    }
                }
            }
        }
        .formStyle(.grouped).frame(minWidth: 340)
    }

    private func addProfile() {
        let p = Profile(name: "New mode", systemPrompt: Profile.custom.systemPrompt)
        settings.profiles.append(p); selectedID = p.id
    }
}
