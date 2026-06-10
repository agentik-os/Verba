import SwiftUI

enum NavItem: String, CaseIterable, Identifiable {
    case home, notes, todos, insights, modes, dictionary, snippets, style, transforms, scratchpad, files, history, leaderboard, wishlist, feedback, freeMonth, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"; case .notes: return "Notes"; case .todos: return "Task Manager"; case .insights: return "Insights"; case .modes: return "Modes"
        case .dictionary: return "Dictionary"; case .snippets: return "Snippets"; case .style: return "Style"
        case .transforms: return "Transforms"; case .scratchpad: return "Scratchpad"; case .files: return "Transcribe file"
        case .history: return "History"; case .leaderboard: return "Leaderboard"
        case .wishlist: return "Wishlist"; case .feedback: return "Feedback"; case .freeMonth: return "Free Month"; case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"; case .notes: return "doc.badge.ellipsis"; case .todos: return "checklist"; case .insights: return "chart.bar"; case .modes: return "wand.and.stars"
        case .dictionary: return "character.book.closed"; case .snippets: return "text.badge.plus"
        case .style: return "paintbrush"; case .transforms: return "arrow.triangle.2.circlepath"
        case .scratchpad: return "note.text"; case .files: return "waveform.badge.plus"
        case .history: return "clock.arrow.circlepath"
        case .leaderboard: return "trophy"; case .wishlist: return "lightbulb"
        case .feedback: return "bubble.left.and.text.bubble.right"
        case .freeMonth: return "gift"; case .settings: return "gearshape"
        }
    }
}

/// Verba's black-and-white app mark (matches the Dock icon).
struct VerbaMark: View {
    var size: CGFloat = 26
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Color.black)
            .frame(width: size, height: size)
            .overlay(Image(systemName: "mic.fill").font(.system(size: size * 0.5, weight: .medium)).foregroundStyle(.white))
            .overlay(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).strokeBorder(.white.opacity(0.14)))
    }
}

/// One sidebar nav row: selected = primary pill with inverted label (adapts to
/// light/dark), idle rows get a quiet soft-fill on hover. Same Button, same action.
private struct SidebarRow: View {
    let item: NavItem
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon).frame(width: 18)
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.secondary))
                Text(item.title)
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.primary))
                Spacer(minLength: 0)
            }
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 11).padding(.vertical, 9)
            .background(
                // macOS-26 source-list selection: a soft accent-tinted highlight, never a
                // black inverted block. Hover is an even quieter neutral fill.
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.primary.opacity(0.07))
                          : (hovered ? AnyShapeStyle(Color.primary.opacity(0.05)) : AnyShapeStyle(Color.clear)))
            )
            .overlay(alignment: .leading) {
                // Thin accent bar marks the selected row (Linear/Things grammar).
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary)
                        .frame(width: 3, height: 16)
                        .padding(.leading, 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.12), value: hovered)
    }
}

/// The main, dockable window: a fixed left sidebar (always visible) + detail.
/// The sidebar is flush to the window edge and the traffic lights sit over its
/// top. No collapse control. Solid white backgrounds.
struct MainWindow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var notesCtl = NotesController.shared
    @State private var selection: NavItem? = .home
    @State private var qwenInstalling = false
    @State private var qwenProgress: Double = 0
    @State private var qwenStatus = ""

    private let sidebarWidth: CGFloat = 240
    @AppStorage("toolsCollapsed") private var toolsCollapsed = false
    @AppStorage("libraryCollapsed") private var libraryCollapsed = false
    @AppStorage("communityCollapsed") private var communityCollapsed = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: sidebarWidth)
                .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())

            Divider().opacity(0.4)

            detail(selection ?? .home)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor).ignoresSafeArea())  // crisp white content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .tint(.primary)   // full B&W: selection / accents are black, not blue
        .onChange(of: notesCtl.navSignal) { _, _ in selection = .notes }   // Fn+Z → jump to Notes
        .onChange(of: notesCtl.leaderboardNavSignal) { _, _ in selection = .leaderboard }   // Insights "your standing" → Leaderboard
        .onChange(of: settings.hiddenNav) { _, _ in
            // If the section you're on just got hidden, fall back to Home.
            if let sel = selection, sel != .home, sel != .modes, sel != .settings, !settings.navVisible(sel) {
                selection = .home
            }
        }
        // Notes / To-dos are gated by their own flags (not hiddenNav); fall back to
        // Home if the user disables the tab they're currently viewing.
        .onChange(of: settings.notesTabEnabled) { _, on in
            if !on, selection == .notes { selection = .home }
        }
        .onChange(of: settings.todosTabEnabled) { _, on in
            if !on, selection == .todos { selection = .home }
        }
    }

    // MARK: Sidebar (flush, full height; traffic lights overlap its top)

    private var sidebar: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 36)        // leave room for the traffic lights

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    row(.home)
                    if settings.navVisible(.insights) { row(.insights) }
                    if settings.navVisible(.history) { row(.history) }

                    // Collapsible "Tools" group (Task Manager + Notes).
                    groupHeader("Tools", collapsed: toolsCollapsed) {
                        withAnimation(.easeInOut(duration: 0.18)) { toolsCollapsed.toggle() }
                    }
                    if !toolsCollapsed {
                        if settings.todosTabEnabled { row(.todos) }
                        if settings.notesTabEnabled { row(.notes) }
                    }

                    groupHeader("Library", collapsed: libraryCollapsed) {
                        withAnimation(.easeInOut(duration: 0.18)) { libraryCollapsed.toggle() }
                    }
                    if !libraryCollapsed {
                        row(.modes)
                        if settings.navVisible(.dictionary) { row(.dictionary) }
                        if settings.navVisible(.snippets) { row(.snippets) }
                        if settings.navVisible(.style) { row(.style) }
                        if settings.navVisible(.transforms) { row(.transforms) }
                        if settings.navVisible(.scratchpad) { row(.scratchpad) }
                        if settings.navVisible(.files) { row(.files) }
                    }

                    // Collapsible "Community" group (leaderboard / wishlist / free month + Telegram).
                    groupHeader("Community", collapsed: communityCollapsed) {
                        withAnimation(.easeInOut(duration: 0.18)) { communityCollapsed.toggle() }
                    }
                    if !communityCollapsed {
                        if settings.navVisible(.leaderboard) { row(.leaderboard) }
                        if settings.navVisible(.wishlist) { row(.wishlist) }
                        if settings.navVisible(.feedback) { row(.feedback) }
                        if settings.navVisible(.freeMonth) { row(.freeMonth) }
                        telegramRow
                    }
                }
                .padding(.horizontal, 8).padding(.top, 4)
            }
            .scrollContentBackground(.hidden)

            qwenDownloadRow
            sidebarFooter
        }
    }

    /// Shown only when no AI rewriting backend works (no Claude Code, not signed in for the
    /// Verba proxy, no API key): offer a one-tap download of a free local model (Qwen via Ollama).
    private var needsLocalFallback: Bool {
        guard settings.repromptEnabled else { return false }
        if settings.repromptBackend == .localLLM { return false }
        if ClaudeCode.isAvailable { return false }                  // Claude Code works
        if !settings.proEmail.isEmpty { return false }              // Verba hosted works (signed in)
        if !(Keychain.anthropicKey ?? "").isEmpty { return false }  // API key works
        if !(Keychain.openRouterKey ?? "").isEmpty { return false } // OpenRouter works
        return true
    }

    @ViewBuilder private var qwenDownloadRow: some View {
        if needsLocalFallback {
            VStack(alignment: .leading, spacing: 6) {
                if qwenInstalling {
                    Text(qwenStatus.isEmpty ? "Downloading…" : qwenStatus)
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    ProgressView(value: qwenProgress).controlSize(.small)
                } else {
                    Button(action: startQwenDownload) {
                        HStack(spacing: 9) {
                            Image(systemName: "arrow.down.circle.fill").font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Set up AI rewriting").font(.caption.weight(.semibold))
                                Text("Download a free local model").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 8).padding(.bottom, 6)
        }
    }

    private func startQwenDownload() {
        qwenInstalling = true; qwenProgress = 0; qwenStatus = "Starting local engine…"
        LocalLLM.ensureServer { up in
            if up { pullQwen() }
            else {
                qwenStatus = "Installing engine…"
                LocalLLM.installBinary { ok in
                    if ok { pullQwen() } else { qwenInstalling = false; qwenStatus = "Install failed" }
                }
            }
        }
    }

    private func pullQwen() {
        qwenStatus = "Downloading \(settings.localLLMModel)…"
        LocalLLM.pull(settings.localLLMModel, progress: { qwenProgress = $0 }) { ok in
            qwenInstalling = false
            if ok { settings.repromptBackend = .localLLM; qwenStatus = "" }
            else { qwenStatus = "Download failed, try Settings" }
        }
    }

    /// A collapsible group header ("Library", "Community") with a rotating chevron.
    private func groupHeader(_ title: String, collapsed: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            HStack(spacing: 4) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(collapsed ? 0 : 90))
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 11).padding(.top, 14).padding(.bottom, 4)
    }

    /// Telegram community link, styled like a sidebar row.
    private var telegramRow: some View {
        Button { if let u = URL(string: "https://t.me/verba_run") { openURL(u) } } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill").frame(width: 18)
                Text("Telegram")
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .font(.system(size: 13))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 11).padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Join the Verba community on Telegram (@verba_run)")
    }

    /// A nav row. Selected = solid primary pill with inverted label, so it stands
    /// out in light AND dark mode (primary/background flip with the appearance).
    private func row(_ item: NavItem) -> some View {
        SidebarRow(item: item, isSelected: selection == item) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selection = item }
        }
    }

    private var sidebarFooter: some View {
        HStack(spacing: 8) {
            Button { selection = .settings } label: {
                HStack(spacing: 9) {
                    VerbaMark(size: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(settings.username.isEmpty ? "Not signed in" : settings.username)
                            .font(.caption.weight(.medium)).lineLimit(1).truncationMode(.middle)
                        Text(settings.isPro ? "Pro plan" : "Free trial")
                            .font(.caption2)
                            .foregroundStyle(settings.isPro ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Mic-source picker, just left of the settings gear.
            FooterMicButton()
            Button { selection = .settings } label: {
                Image(systemName: "gearshape").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 10).padding(.vertical, 10)
        .onAppear { if !settings.proEmail.isEmpty { Task { _ = await settings.verifyPro() } } }
    }

    @ViewBuilder
    private func detail(_ item: NavItem) -> some View {
        switch item {
        case .home: HomeView()
        case .notes: NotesView()
        case .todos: TodosView()
        case .insights: InsightsView()
        case .modes: ModesView()   // ModesView owns its own two-pane layout + header (like Notes)
        case .dictionary: DictionaryView()
        case .snippets: SnippetsView()
        case .style: StyleView()
        case .transforms: TransformsView()
        case .scratchpad: ScratchpadView()
        case .files: FileTranscribeView()
        case .history: HistoryView()
        case .leaderboard: LeaderboardView()
        case .wishlist: WishlistView()
        case .feedback: FeedbackView()
        case .freeMonth: FreeMonthView()
        case .settings: SettingsView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
