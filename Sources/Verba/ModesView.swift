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
    @State private var pendingDeleteID: UUID?   // built-in mode awaiting delete confirmation
    @State private var pendingReset = false     // restore-defaults awaiting confirmation
    @State private var explaining = false       // generating the AI "what this mode does" blurb
    @State private var explainError: String?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // Header (Notes grammar): title + primary "new mode" action; reset-defaults is a
                // quiet secondary borderless icon beside it.
                HStack(spacing: 10) {
                    Text("Modes").font(.system(size: 17, weight: .bold))
                    Spacer()
                    Button { pendingReset = true } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help("Restore the built-in modes; this removes your custom ones")
                    Button { genError = nil; genDescription = ""; showGenerator = true } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless)
                        .help("Describe a mode and let Verba build it")
                }
                .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

                // EXACT same container as NotesView.sidebar: ScrollView + LazyVStack(spacing:4),
                // padding h8/v4 — so the cards float with the same gap, not a contiguous List
                // table. Reorder is via each card's context menu (Move up / Move down) since
                // LazyVStack has no .onMove.
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(settings.profiles.enumerated()), id: \.element.id) { idx, p in
                            modeRow(p, index: idx)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: 270)

            Divider().opacity(0.4)   // same separator as the main sidebar (Notes/Dictionary/Snippets/Style)

            Group {
                if let id = selectedID, settings.profiles.contains(where: { $0.id == id }) {
                    editor(id: id)
                } else {
                    VStack(spacing: 16) {
                        EmptyState(icon: "wand.and.stars",
                                   title: settings.profiles.isEmpty ? "No modes yet" : "Select a mode",
                                   message: settings.profiles.isEmpty
                                       ? "Modes are the different ways Claude reorders and improves your dictation. Create one, or restore the built-in modes."
                                       : "Each mode is a different way Claude reorders and improves your dictation.")
                        HStack(spacing: 10) {
                            Button { genError = nil; genDescription = ""; showGenerator = true } label: {
                                Label("New mode", systemImage: "plus")
                            }
                            .glassProminentButton()
                            Button { pendingReset = true } label: {
                                Label("Restore built-in modes", systemImage: "arrow.counterclockwise")
                            }
                            .glassButton()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { if selectedID == nil { selectedID = settings.activeProfileID } }
        .sheet(isPresented: $showGenerator) { generatorSheet }
        .confirmationDialog("Delete this built-in mode?",
                            isPresented: Binding(get: { pendingDeleteID != nil },
                                                 set: { if !$0 { pendingDeleteID = nil } }),
                            titleVisibility: .visible) {
            Button("Delete mode", role: .destructive) {
                if let id = pendingDeleteID { deleteProfile(id) }
                pendingDeleteID = nil
            }
            Button("Cancel", role: .cancel) { pendingDeleteID = nil }
        } message: {
            Text("You can bring the built-in modes back anytime with Restore.")
        }
        .confirmationDialog("Restore the built-in modes?",
                            isPresented: $pendingReset,
                            titleVisibility: .visible) {
            Button("Restore defaults", role: .destructive) {
                settings.resetProfilesToDefaults()
                selectedID = settings.activeProfileID
                pendingReset = false
            }
            Button("Cancel", role: .cancel) { pendingReset = false }
        } message: {
            Text("This removes any custom modes you’ve created and restores the built-in ones.")
        }
    }

    /// Deleting a built-in mode asks first (they can be restored); custom modes delete immediately.
    private func confirmOrDelete(_ id: UUID) {
        if settings.profiles.first(where: { $0.id == id })?.builtin == true {
            pendingDeleteID = id
        } else {
            deleteProfile(id)
        }
    }

    // MARK: Sidebar rows — IDENTICAL grammar to NotesView.noteRow: a spacious 2-line card
    // (icon + title line, secondary subtitle line), radius 12, padding 12/9, fill 0.04 idle /
    // 0.12 selected + 0.4 stroke. Active mode marked with a check by the name; model + shortcut
    // live on the quiet subtitle line (not crammed onto one row like before).
    private func modeRow(_ p: Profile, index: Int) -> some View {
        let selected = p.id == selectedID
        let isActive = p.id == settings.activeProfileID
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: p.raw ? "waveform" : "wand.and.stars")
                .font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(p.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 5) {
                    // The per-mode model is only meaningful on the cloud backend; under Local /
                    // OpenRouter one configured model rewrites every mode, so we don't imply a
                    // per-mode choice here (raw modes always show "raw").
                    let isCloud = settings.repromptBackend != .localLLM && settings.repromptBackend != .openRouter
                    let hasModelPill = p.raw || isCloud
                    if hasModelPill {
                        Text(modelPillLabel(p)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .glassCard(selected: selected, cornerRadius: 12)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedID = p.id }
        }
        .contextMenu {
            Button { move(index, by: -1) } label: { Label("Move up", systemImage: "arrow.up") }
                .disabled(index == 0)
            Button { move(index, by: 1) } label: { Label("Move down", systemImage: "arrow.down") }
                .disabled(index >= settings.profiles.count - 1)
        }
    }

    /// Reorder helper (replaces List.onMove now that the list is a LazyVStack like Notes).
    private func move(_ index: Int, by delta: Int) {
        let dest = index + delta
        guard settings.profiles.indices.contains(index), settings.profiles.indices.contains(dest) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            settings.profiles.swapAt(index, dest)
        }
    }

    private func modelPillLabel(_ p: Profile) -> String {
        if p.raw { return "raw" }
        switch settings.repromptBackend {
        case .localLLM:
            return shortModelName(settings.localLLMModel)
        case .openRouter:
            return settings.openRouterModel.isEmpty ? "openrouter" : shortModelName(settings.openRouterModel)
        default:
            let m = p.model ?? ""
            return shortModelName(m.isEmpty ? settings.claudeModel : m)
        }
    }

    private func shortModelName(_ m: String) -> String {
        m.hasPrefix("claude-") ? String(m.dropFirst("claude-".count)) : m
    }

    // MARK: New mode assistant — describe a need (typed or dictated), Verba builds the mode.
    private var generatorSheet: some View {
        GlassDialog(icon: "wand.and.stars",
                    title: "New mode",
                    subtitle: "Describe what this mode should do, in plain words. You can type it or dictate it with Verba. It uses your configured AI, no extra setup.",
                    width: 520,
                    drawsCard: true) {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $genDescription)
                    .font(.system(.body, design: .default)).scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(.horizontal, 8).padding(.vertical, 10)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if genDescription.isEmpty {
                            // Aligned to the text cursor: 8 outer pad + ~5 NSTextView lineFragmentPadding
                            // horizontally; 10 outer pad vertically. Sits exactly on the first line.
                            Text("e.g. \u{201C}A mode for short, friendly customer-support replies that keep every detail I mention and stay polite.\u{201D}")
                                .font(.body).foregroundStyle(.tertiary)
                                .padding(.horizontal, 13).padding(.vertical, 10).allowsHitTesting(false)
                        }
                    }
                    .disabled(genBusy)

                if let genError {
                    Text(genError).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                }
            }
        } buttons: {
            Button("Create blank instead") { let p = addBlankProfile(); showGenerator = false; selectedID = p }
                .buttonStyle(.borderless).disabled(genBusy)
            Spacer()
            Button("Cancel") { showGenerator = false }
                .dialogSecondary()
                .keyboardShortcut(.cancelAction)
                .disabled(genBusy)
            Button {
                runGenerate()
            } label: {
                if genBusy { HStack(spacing: 8) { ProgressView().controlSize(.small); Text("Building…") } }
                else { Text("Build mode") }
            }
            .dialogPrimary()
            .disabled(genBusy || genDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .presentationBackground(.clear)
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

    /// Generate (or regenerate) the friendly "what this mode does" blurb with AI, store it.
    private func explainMode(id: UUID) {
        guard !explaining, let p = settings.profiles.first(where: { $0.id == id }) else { return }
        explaining = true; explainError = nil
        Task {
            do {
                let text = try await ModeGenerator.explain(
                    name: p.name, systemPrompt: p.systemPrompt, raw: p.raw,
                    vision: p.vision, targetLanguage: p.targetLanguage)
                await MainActor.run {
                    if let i = index(of: id) { settings.profiles[i].explainer = text }
                    explaining = false
                }
            } catch {
                await MainActor.run { explainError = error.localizedDescription; explaining = false }
            }
        }
    }

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
        let isVision = p?.vision ?? false
        let langB = Binding(get: { settings.profiles.first { $0.id == id }?.targetLanguage ?? "English" },
                            set: { v in if let i = index(of: id) { settings.profiles[i].targetLanguage = v } })
        let isActive = settings.activeProfileID == id
        let bundleIDs = p?.matchBundleIDs ?? []
        // A non-raw, non-translate mode reprompts through Claude using systemPrompt. If that prompt
        // is blanked, Claude runs with no instructions and may echo/summarize/mangle the transcript.
        // Flag it so the editor can warn and refuse to make such a mode active.
        let usesSystemPrompt = !isRaw && !isTranslate
        let promptBlank = usesSystemPrompt
            && (p?.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Name + actions (delete right next to the name; any mode is deletable).
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240)
                    TagChip(icon: isActive ? "checkmark.circle.fill" : "circle",
                            label: isActive ? "Active" : "Make active",
                            selected: isActive) { if !promptBlank { settings.activeProfileID = id } }
                        .disabled(isActive || promptBlank)
                        .help(promptBlank ? "Add a system prompt before making this mode active — an empty prompt gives Claude no instructions." : "")
                    Spacer()
                    Button(role: .destructive) { confirmOrDelete(id) } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this mode")
                }

                if isVision {
                    field("Screen capture") {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 16)).foregroundStyle(.secondary)
                                .frame(width: 20).padding(.top, 1)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This mode screenshots the frontmost window and sends it to Claude along with your spoken request, so it can act on what's on screen (reply to the visible email, comment on a photo, answer the question shown).")
                                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                Label("The screenshot is sent to your AI backend only for this request and is never stored.",
                                      systemImage: "lock.shield")
                                    .font(.caption).foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard(cornerRadius: 14)
                    }
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
                            HStack(spacing: 8) {
                                TagChip(label: "Default", selected: modelB.wrappedValue == "") { modelB.wrappedValue = "" }
                                    .help("App-wide default (\(settings.claudeModel))")
                                ForEach(Profile.selectableModels, id: \.id) { m in
                                    TagChip(label: m.label, selected: modelB.wrappedValue == m.id) { modelB.wrappedValue = m.id }
                                        .help(m.help)
                                }
                            }
                        }
                    }
                }
                // Friendly, AI-written "what this mode does + how to use it" for the user.
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Description").font(.subheadline.weight(.semibold))
                        Text("what it's for, in plain words").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if explaining { ProgressView().controlSize(.small) }
                        Button {
                            explainMode(id: id)
                        } label: {
                            Label(p?.explainer?.isEmpty == false ? "Regenerate" : "Explain with AI",
                                  systemImage: "sparkles")
                        }
                        .buttonStyle(.borderless).disabled(explaining)
                    }
                    if let ex = p?.explainer, !ex.isEmpty {
                        Text(ex).font(.callout).foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Text(explainError ?? "Tap Explain with AI for a plain-language summary of what this mode does and how to use it.")
                            .font(.caption).foregroundStyle(explainError == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
                    }
                }

                if !isRaw && !isTranslate {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("System prompt").font(.subheadline.weight(.semibold))
                            Text(isVision ? "what Claude does with the screenshot + your spoken request"
                                          : "how Claude reinterprets your audio")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        TextEditor(text: promptB)
                            .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                            .frame(minHeight: 220).padding(12)
                            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        if promptBlank {
                            Label("This mode has no system prompt. Claude would get no instructions and may echo or mangle your dictation. Add a prompt to make it active.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
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
        settings.profiles.removeAll { $0.id == id }
        // If we just removed the active mode, promote the first remaining one.
        if settings.activeProfileID == id, let first = settings.profiles.first { settings.activeProfileID = first.id }
        // Land the selection on the (new) active mode rather than a dangling empty state.
        selectedID = settings.profiles.contains(where: { $0.id == settings.activeProfileID })
            ? settings.activeProfileID
            : settings.profiles.first?.id
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
