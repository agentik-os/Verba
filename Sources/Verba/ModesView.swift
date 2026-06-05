import SwiftUI

/// The modes (profiles) editor — used both in the main window and Settings.
struct ModesView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    ForEach(settings.profiles) { p in
                        HStack(spacing: 8) {
                            Image(systemName: p.raw ? "waveform" : "wand.and.stars")
                                .foregroundStyle(.secondary).frame(width: 16)
                            Text(p.name).lineLimit(1)
                            Spacer(minLength: 6)
                            if let c = p.hotkeyCode, let m = p.hotkeyMods {
                                Text(shortcutLabel(keyCode: c, modifiers: m))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                            if p.id == settings.activeProfileID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint).font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                        .tag(p.id)
                    }
                }
                .listStyle(.inset)
                HStack(spacing: 12) {
                    Button { addProfile() } label: { Image(systemName: "plus") }
                        .disabled(!settings.isPro)
                        .help(settings.isPro ? "New mode" : "Custom modes are a Pro feature")
                    Button { settings.resetProfilesToDefaults(); selectedID = settings.activeProfileID } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }.help("Restore the built-in modes")
                    Spacer()
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 14).padding(.vertical, 8)
            }
            .frame(width: 232)

            Group {
                if let id = selectedID, settings.profiles.contains(where: { $0.id == id }) {
                    editor(id: id)
                } else {
                    ContentUnavailableView("Select a mode", systemImage: "wand.and.stars",
                                           description: Text("Each mode is a different way Claude reorders and improves your dictation."))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                field("Name") { TextField("", text: nameB).cleanField().frame(maxWidth: 280) }

                if isRaw {
                    field("Behaviour") {
                        Text("Free-flow dictation — your words are transcribed exactly, with no AI reprompting.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("System prompt").font(.subheadline.weight(.semibold))
                            Text("how Claude reinterprets your audio").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if !settings.isPro { Label("Pro", systemImage: "lock.fill").font(.caption).foregroundStyle(.tint) }
                        }
                        TextEditor(text: promptB)
                            .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                            .frame(minHeight: 220).padding(12)
                            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .disabled(!settings.isPro).opacity(settings.isPro ? 1 : 0.55)
                        if !settings.isPro {
                            Text("Editing modes is a Pro feature. Free includes the built-in modes as-is.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                field("Dedicated shortcut") {
                    ShortcutRecorder(label: shortcut,
                        onCapture: { c, m in if let i = index(of: id) { settings.profiles[i].hotkeyCode = c; settings.profiles[i].hotkeyMods = m } },
                        onClear: { if let i = index(of: id) { settings.profiles[i].hotkeyCode = nil; settings.profiles[i].hotkeyMods = nil } })
                }

                field("Auto-match apps", hint: "comma-separated bundle IDs") {
                    TextField("com.apple.dt.Xcode, …", text: bundlesB).cleanField()
                }

                HStack {
                    Button("Make active") { settings.activeProfileID = id }.buttonStyle(.borderedProminent)
                    Spacer()
                    if !isBuiltin {
                        Button("Delete", role: .destructive) {
                            selectedID = nil
                            settings.profiles.removeAll { $0.id == id }
                            if settings.activeProfileID == id { settings.activeProfileID = settings.profiles.first?.id ?? id }
                        }.buttonStyle(.borderless)
                    }
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private func addProfile() {
        let p = Profile(name: "New mode", systemPrompt: Profile.custom.systemPrompt)
        settings.profiles.append(p); selectedID = p.id
    }
}
