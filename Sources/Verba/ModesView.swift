import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
                            if p.id == settings.activeProfileID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint).font(.caption)
                            }
                            if let c = p.hotkeyCode, let m = p.hotkeyMods {
                                keycap(shortcutLabel(keyCode: c, modifiers: m))
                            }
                        }
                        .padding(.vertical, 3)
                        .tag(p.id)
                    }
                    .onMove { from, to in settings.profiles.move(fromOffsets: from, toOffset: to) }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                HStack(spacing: 14) {
                    Button { addProfile() } label: { Label("New", systemImage: "plus") }
                        .disabled(!settings.isPro)
                        .help(settings.isPro ? "New mode" : "Custom modes are a Pro feature")
                    Spacer()
                    Button { settings.resetProfilesToDefaults(); selectedID = settings.activeProfileID } label: {
                        Label("Reset defaults", systemImage: "arrow.counterclockwise")
                    }.help("Restore Coding / Polish / Casual / Intent / Custom / Flow")
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .padding(.horizontal, 14).padding(.vertical, 9)
                Text("Drag to reorder · the active mode (✓) is what a single Fn tap dictates with")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(.horizontal, 10).padding(.bottom, 6)
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
        let isRaw = p?.raw ?? false
        let isActive = settings.activeProfileID == id
        let bundleIDs = p?.matchBundleIDs ?? []
        let shortcut: String = { guard let p, let c = p.hotkeyCode, let m = p.hotkeyMods else { return "" }
            return shortcutLabel(keyCode: c, modifiers: m) }()

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Name + actions (delete right next to the name; any mode is deletable).
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240)
                    Button { settings.activeProfileID = id } label: {
                        Label(isActive ? "Active" : "Make active", systemImage: isActive ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.borderless).disabled(isActive)
                    Spacer()
                    Button(role: .destructive) { deleteProfile(id) } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this mode")
                }

                // Shortcut — moved up, right under the name.
                field("Dedicated shortcut") {
                    ShortcutRecorder(label: shortcut,
                        onCapture: { c, m in settings.assignShortcut(keyCode: c, modifiers: m, to: .profile(id)) },
                        onClear: { settings.clearShortcut(.profile(id)) })
                }

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

                field("Auto-match apps", hint: "dictate straight into this mode when these apps are frontmost") {
                    VStack(alignment: .leading, spacing: 8) {
                        if !bundleIDs.isEmpty {
                            FlowChips(items: bundleIDs) { bid in
                                if let i = index(of: id) { settings.profiles[i].matchBundleIDs.removeAll { $0 == bid } }
                            }
                        }
                        HStack {
                            Button { chooseApps(for: id) } label: { Label("Choose apps…", systemImage: "app.badge") }
                            Spacer()
                        }
                        TextField("…or paste bundle IDs (comma-separated)", text: bundlesB).cleanField()
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func deleteProfile(_ id: UUID) {
        selectedID = nil
        settings.profiles.removeAll { $0.id == id }
        if settings.activeProfileID == id, let first = settings.profiles.first { settings.activeProfileID = first.id }
    }

    /// Pick .app bundles in a Finder panel and add their bundle identifiers.
    private func chooseApps(for id: UUID) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Add"
        panel.message = "Choose apps that should auto-select this mode"
        guard panel.runModal() == .OK, let i = index(of: id) else { return }
        for url in panel.urls {
            if let bid = Bundle(url: url)?.bundleIdentifier,
               !settings.profiles[i].matchBundleIDs.contains(bid) {
                settings.profiles[i].matchBundleIDs.append(bid)
            }
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

    private func keycap(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .foregroundStyle(.secondary)
    }

    private func addProfile() {
        let p = Profile(name: "New mode", systemPrompt: Profile.custom.systemPrompt)
        settings.profiles.append(p); selectedID = p.id
    }
}

/// Removable app chips, wrapping onto multiple lines.
struct FlowChips: View {
    let items: [String]
    let onRemove: (String) -> Void
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { bid in
                HStack(spacing: 5) {
                    Text(Self.shortName(bid)).font(.caption)
                    Button { onRemove(bid) } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(.softFill, in: Capsule())
            }
        }
    }
    static func shortName(_ bundleID: String) -> String {
        bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    }
}

/// Minimal wrapping (flow) layout.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.minX + maxWidth, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
