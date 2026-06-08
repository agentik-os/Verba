import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// The modes (profiles) editor, used both in the main window and Settings.
struct ModesView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selectedID: UUID?
    @State private var showGenerator = false
    @State private var genDescription = ""
    @State private var genBusy = false
    @State private var genError: String?

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
                    Button { genError = nil; genDescription = ""; showGenerator = true } label: { Label("New", systemImage: "plus") }
                        .disabled(!settings.isPro)
                        .help(settings.isPro ? "Describe a mode and let Verba build it" : "Custom modes are a Pro feature")
                    Spacer()
                    Button { settings.resetProfilesToDefaults(); selectedID = settings.activeProfileID } label: {
                        Label("Reset defaults", systemImage: "arrow.counterclockwise")
                    }.help("Restore Flow / Intent / Context / Coding / Translate / Custom")
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .padding(.horizontal, 14).padding(.vertical, 9).padding(.bottom, 4)
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
        .sheet(isPresented: $showGenerator) { generatorSheet }
    }

    // MARK: New mode assistant — describe a need (typed or dictated), Verba builds the mode.
    private var generatorSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("New mode").font(.title3.weight(.semibold))
                Text("Describe what this mode should do, in plain words. You can type it or dictate it with Verba. It uses your configured AI, no extra setup.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }

            TextEditor(text: $genDescription)
                .font(.system(.body, design: .default)).scrollContentBackground(.hidden)
                .frame(minHeight: 130).padding(12)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if genDescription.isEmpty {
                        Text("e.g. \u{201C}A mode for short, friendly customer-support replies that keep every detail I mention and stay polite.\u{201D}")
                            .font(.body).foregroundStyle(.tertiary)
                            .padding(.horizontal, 17).padding(.vertical, 20).allowsHitTesting(false)
                    }
                }
                .disabled(genBusy)

            if let genError {
                Text(genError).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Create blank instead") { let p = addBlankProfile(); showGenerator = false; selectedID = p }
                    .buttonStyle(.borderless).disabled(genBusy)
                Spacer()
                Button("Cancel") { showGenerator = false }.disabled(genBusy)
                Button {
                    runGenerate()
                } label: {
                    if genBusy { HStack(spacing: 8) { ProgressView().controlSize(.small); Text("Building…") } }
                    else { Text("Build mode") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(genBusy || genDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func runGenerate() {
        genError = nil
        genBusy = true
        let desc = genDescription
        Task {
            do {
                let draft = try await ModeGenerator.generate(from: desc)
                var p = Profile(name: draft.name, systemPrompt: draft.systemPrompt)
                p.model = draft.model
                p.matchBundleIDs = draft.matchBundleIDs
                p.raw = draft.raw
                await MainActor.run {
                    settings.profiles.append(p)
                    selectedID = p.id
                    genBusy = false
                    showGenerator = false
                }
            } catch {
                await MainActor.run {
                    genError = error.localizedDescription
                    genBusy = false
                }
            }
        }
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
        let isTranslate = (p?.targetLanguage != nil)
        let langB = Binding(get: { settings.profiles.first { $0.id == id }?.targetLanguage ?? "English" },
                            set: { v in if let i = index(of: id) { settings.profiles[i].targetLanguage = v } })
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

                // Shortcut, moved up, right under the name.
                field("Dedicated shortcut") {
                    ShortcutRecorder(label: shortcut,
                        onCapture: { c, m in settings.assignShortcut(keyCode: c, modifiers: m, to: .profile(id)) },
                        onClear: { settings.clearShortcut(.profile(id)) })
                }

                if isTranslate {
                    field("Translate into", hint: "whatever language you speak, the result is written in this one") {
                        Picker("", selection: langB) {
                            ForEach(translateLanguages, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden().pickerStyle(.menu).frame(maxWidth: 320, alignment: .leading)
                    }
                }

                if isRaw {
                    field("Behaviour") {
                        Text("Free-flow dictation, your words are transcribed exactly, with no AI reprompting.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    let modelB = Binding(
                        get: { settings.profiles.first { $0.id == id }?.model ?? "" },
                        set: { v in if let i = index(of: id) { settings.profiles[i].model = v.isEmpty ? nil : v } })
                    // The model offered must match the AI backend in use. Cloud (Claude / API)
                    // lets you pick a model per mode; the open-source and OpenRouter backends
                    // use a single configured model, so we only show that one.
                    switch settings.repromptBackend {
                    case .localLLM:
                        field("Model", hint: "your local open-source model (set in Settings ▸ AI rewriting) rewrites every mode") {
                            Text("Local: \(settings.localLLMModel)")
                                .foregroundStyle(.secondary)
                        }
                    case .openRouter:
                        field("Model", hint: "your OpenRouter model (set in Settings ▸ AI rewriting) rewrites every mode") {
                            Text(settings.openRouterModel.isEmpty ? "OpenRouter default model" : "OpenRouter: \(settings.openRouterModel)")
                                .foregroundStyle(.secondary)
                        }
                    default:
                        field("Model", hint: "which Claude model rewrites this mode (Anthropic / Claude Code)") {
                            Picker("", selection: modelB) {
                                Text("Default (\(settings.claudeModel))").tag("")
                                Text("Haiku 4.5, fastest, cheapest").tag("claude-haiku-4-5")
                                Text("Sonnet 4.6, balanced").tag("claude-sonnet-4-6")
                                Text("Opus 4.8, most capable").tag("claude-opus-4-8")
                            }
                            .labelsHidden().pickerStyle(.menu).frame(maxWidth: 320, alignment: .leading)
                        }
                    }
                }
                if !isRaw && !isTranslate {
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

    @discardableResult
    private func addBlankProfile() -> UUID {
        let p = Profile(name: "New mode", systemPrompt: Profile.custom.systemPrompt)
        settings.profiles.append(p)
        return p.id
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
    var alignment: HorizontalAlignment = .leading

    private func rows(_ subviews: Subviews, maxW: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(Int, CGSize)]] = [[]]
        var x: CGFloat = 0
        for (i, v) in subviews.enumerated() {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > maxW { rows.append([]); x = 0 }
            rows[rows.count - 1].append((i, s))
            x += s.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        let rs = rows(subviews, maxW: maxW)
        var h: CGFloat = 0
        for (ri, row) in rs.enumerated() {
            h += (row.map { $0.size.height }.max() ?? 0) + (ri > 0 ? spacing : 0)
        }
        let widest = rs.map { $0.reduce(0) { $0 + $1.size.width + spacing } }.max() ?? 0
        return CGSize(width: maxW.isFinite ? maxW : widest, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var y = bounds.minY
        for row in rows(subviews, maxW: maxW) {
            let rowW = row.reduce(0) { $0 + $1.size.width } + spacing * CGFloat(max(0, row.count - 1))
            let rowH = row.map { $0.size.height }.max() ?? 0
            var x = bounds.minX + (alignment == .center ? max(0, (maxW - rowW) / 2) : 0)
            for (i, s) in row {
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
                x += s.width + spacing
            }
            y += rowH + spacing
        }
    }
}
