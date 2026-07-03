import SwiftUI

enum NavItem: String, CaseIterable, Identifiable {
    case home, features, notes, todos, insights, modes, dictionary, snippets, style, transforms, scratchpad, files, connectedApps, history, achievements, leaderboard, wishlist, feedback, freeMonth, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .achievements: return "Achievements"; case .home: return "Home"; case .notes: return "Notes"; case .todos: return "Task Manager"; case .insights: return "Insights"; case .modes: return "Modes"
        case .dictionary: return "Dictionary"; case .snippets: return "Snippets"; case .style: return "Style"
        case .transforms: return "Transforms"; case .scratchpad: return "Scratchpad"; case .files: return "Transcribe file"
        case .features: return "Features"
        case .connectedApps: return "Connected apps"
        case .history: return "History"; case .leaderboard: return "Leaderboard"
        case .wishlist: return "Wishlist"; case .feedback: return "Feedback"; case .freeMonth: return "Free Month"; case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .achievements: return "rosette"; case .home: return "house"; case .notes: return "doc.badge.ellipsis"; case .todos: return "checklist"; case .insights: return "chart.bar"; case .modes: return "wand.and.stars"
        case .dictionary: return "character.book.closed"; case .snippets: return "text.badge.plus"
        case .style: return "paintbrush"; case .transforms: return "arrow.triangle.2.circlepath"
        case .scratchpad: return "note.text"; case .files: return "waveform.badge.plus"
        case .features: return "square.grid.2x2"
        case .connectedApps: return "app.connected.to.app.below.fill"
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
                Text(L(item.title))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.primary))
                Spacer(minLength: 0)
            }
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 11).padding(.vertical, 9)
            .background(
                // macOS-26 source-list selection: a soft accent-tinted highlight, never a
                // black inverted block. Hover is an even quieter neutral fill.
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(VerbaAppearance.shared.accentColor.opacity(0.10))
                          : (hovered ? AnyShapeStyle(Color.primary.opacity(0.05)) : AnyShapeStyle(Color.clear)))
            )
            .overlay(alignment: .leading) {
                // Thin accent bar marks the selected row (Linear/Things grammar).
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(VerbaAppearance.shared.accentColor)
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
    @ObservedObject private var appearance = VerbaAppearance.shared
    @ObservedObject private var updater = Updater.shared   // VER-17: surface "update available" in the sidebar
    @State private var selection: NavItem? = .home
    @State private var qwenInstalling = false
    @State private var qwenProgress: Double = 0
    @State private var qwenStatus = ""

    private let sidebarWidth: CGFloat = 240
    @ObservedObject private var feedbackInbox = FeedbackInbox.shared
    @ObservedObject private var discovery = DiscoveryEngine.shared
    @State private var feedbackDropTargeted = false
    @AppStorage("toolsCollapsed") private var toolsCollapsed = true
    @AppStorage("libraryCollapsed") private var libraryCollapsed = true
    @AppStorage("communityCollapsed") private var communityCollapsed = true
    @Environment(\.openURL) private var openURL

    var body: some View {
        // The WHOLE window is glass (the user's chosen Customize material), and the page content
        // floats as an inset rounded CARD with padding on top/right/bottom — modern, not edge-to-edge.
        // The floating card's corner radius honors the Customize 'Corner radius' slider.
        let r = VAppr.corner(16, scale: appearance.cornerScale)
        return ZStack {
            // Whole-window glass. The material does its own blur of what's behind it; the optional
            // extra blur is a clean GPU CAFilter (GlassBlurView), never a SwiftUI .blur() haze.
            VisualEffectView(blurRadius: appearance.blur)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebar
                    .frame(width: sidebarWidth)   // transparent: the window glass shows through it

                detail(selection ?? .home)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // A readable content material, clipped to a rounded card so text stays crisp
                    // while the glass window shows around the inset edges.
                    .background(VisualEffectView(material: .contentBackground))
                    .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                    .padding(.top, 12).padding(.trailing, 12).padding(.bottom, 12)
                    .padding(.leading, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        // Gamification: confetti + reward card for any newly-earned achievement / level-up.
        .overlay(CelebrationOverlay())
        // Customize: monochrome by default (.primary); a chosen accent + color mode apply app-wide.
        .tint(appearance.accentColor)
        .preferredColorScheme(appearance.colorMode.colorScheme)
        .onChange(of: notesCtl.navSignal) { _, _ in selection = .notes }   // Fn+Z → jump to Notes
        .onChange(of: feedbackInbox.openSignal) { _, _ in selection = .feedback }   // screenshot dropped on the Feedback row
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
        .onChange(of: discovery.openFeaturesSignal) { _, _ in selection = .features }   // hint CTA → Features
        .onChange(of: settings.enabledFeatures) { _, _ in
            // Disabling a feature hides its tab; if you're viewing it, fall back to the Features page.
            let gated: [NavItem: String] = [
                .notes: FeatureFlags.notes, .todos: FeatureFlags.tasks, .files: FeatureFlags.transcribe,
                .connectedApps: FeatureFlags.jarvis, .snippets: FeatureFlags.snippets, .transforms: FeatureFlags.transforms,
            ]
            if let sel = selection, let key = gated[sel], !settings.isFeatureEnabled(key) { selection = .features }
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
                    row(.features)   // permanent: the catalog where inactive features are turned on
                    if settings.navVisible(.insights) { row(.insights) }
                    if settings.navVisible(.history) { row(.history) }

                    // Collapsible "Tools" group (Task Manager + Notes + Scratchpad).
                    groupHeader(L("Tools"), collapsed: toolsCollapsed) {
                        withAnimation(appearance.reduceMotion ? nil : .easeInOut(duration: 0.18)) { toolsCollapsed.toggle() }
                    }
                    if !toolsCollapsed {
                        if settings.isFeatureEnabled(FeatureFlags.tasks) && settings.todosTabEnabled { row(.todos) }
                        if settings.isFeatureEnabled(FeatureFlags.notes) && settings.notesTabEnabled { row(.notes) }
                        if settings.navVisible(.scratchpad) { row(.scratchpad) }
                    }

                    groupHeader(L("Library"), collapsed: libraryCollapsed) {
                        withAnimation(appearance.reduceMotion ? nil : .easeInOut(duration: 0.18)) { libraryCollapsed.toggle() }
                    }
                    if !libraryCollapsed {
                        row(.modes)
                        if settings.navVisible(.dictionary) { row(.dictionary) }
                        if settings.isFeatureEnabled(FeatureFlags.snippets) && settings.navVisible(.snippets) { row(.snippets) }
                        if settings.navVisible(.style) { row(.style) }
                        if settings.isFeatureEnabled(FeatureFlags.transforms) && settings.navVisible(.transforms) { row(.transforms) }
                        if settings.isFeatureEnabled(FeatureFlags.transcribe) && settings.navVisible(.files) { row(.files) }
                        if settings.isFeatureEnabled(FeatureFlags.jarvis) { row(.connectedApps) }   // JARVIS connected apps
                    }

                    // Collapsible "Community" group (leaderboard / wishlist / free month + Telegram).
                    groupHeader(L("Community"), collapsed: communityCollapsed) {
                        withAnimation(appearance.reduceMotion ? nil : .easeInOut(duration: 0.18)) { communityCollapsed.toggle() }
                    }
                    if !communityCollapsed {
                        if settings.navVisible(.achievements) { row(.achievements) }
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
                    Text(qwenStatus.isEmpty ? L("Downloading…") : qwenStatus)
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    ProgressView(value: qwenProgress).controlSize(.small)
                } else {
                    Button(action: startQwenDownload) {
                        HStack(spacing: 9) {
                            Image(systemName: "arrow.down.circle.fill").font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(L("Set up AI rewriting")).font(.caption.weight(.semibold))
                                Text(L("Download a free local model")).font(.caption2).foregroundStyle(.secondary)
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
        qwenInstalling = true; qwenProgress = 0; qwenStatus = L("Starting local engine…")
        LocalLLM.ensureServer { up in
            if up { pullQwen() }
            else {
                qwenStatus = L("Installing engine…")
                LocalLLM.installBinary { ok in
                    if ok { pullQwen() } else { qwenInstalling = false; qwenStatus = L("Install failed") }
                }
            }
        }
    }

    private func pullQwen() {
        qwenStatus = "\(L("Downloading")) \(settings.localLLMModel)…"
        LocalLLM.pull(settings.localLLMModel, progress: { qwenProgress = $0 }) { ok in
            qwenInstalling = false
            if ok { settings.repromptBackend = .localLLM; qwenStatus = "" }
            else { qwenStatus = L("Download failed, try Settings") }
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
        Button { if let u = URL(string: "https://t.me/verbarun") { openURL(u) } } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill").frame(width: 18)
                Text(L("Telegram"))
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .font(.system(size: 13))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 11).padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(L("Join the Verba community on Telegram"))
    }

    /// A nav row. Selected = solid primary pill with inverted label, so it stands
    /// out in light AND dark mode (primary/background flip with the appearance).
    @ViewBuilder
    private func row(_ item: NavItem) -> some View {
        let base = SidebarRow(item: item, isSelected: selection == item) {
            withAnimation(appearance.reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) { selection = item }
        }
        if item == .feedback {
            // Drop a screenshot directly onto the Feedback row → it attaches + opens Feedback.
            base.onDrop(of: [.fileURL, .image], isTargeted: $feedbackDropTargeted) { providers in
                FeedbackInbox.shared.ingest(providers)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(appearance.accentColor.opacity(feedbackDropTargeted ? 0.4 : 0), lineWidth: 2)
            )
        } else {
            base
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 8) {
            // VER-17: a prominent, eye-catching banner the moment Sparkle finds a newer build, so
            // users actually update instead of missing fixes buried behind Settings ▸ Check for updates.
            if updater.updateAvailable {
                Button { updater.installUpdate() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.down.circle.fill")
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L("New version available")).font(.caption.weight(.semibold)).lineLimit(1)
                            if let v = updater.latestVersion {
                                Text(L("Click to update to") + " \(v)").font(.caption2).opacity(0.9).lineLimit(1)
                            } else {
                                Text(L("Click to update")).font(.caption2).opacity(0.9).lineLimit(1)
                            }
                        }
                        Spacer(minLength: 4)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(VerbaAppearance.shared.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .help(L("A new version of Verba is available — click to install and relaunch"))
            }
            footerPanel
        }
        .padding(.vertical, 10)
        .onAppear { if !settings.proEmail.isEmpty { Task { _ = await settings.verifyPro() } } }
    }

    private var footerPanel: some View {
        HStack(spacing: 8) {
            Button { selection = .settings } label: {
                HStack(spacing: 9) {
                    VerbaMark(size: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(settings.username.isEmpty ? L("Not signed in") : settings.username)
                            .font(.caption.weight(.medium)).lineLimit(1).truncationMode(.middle)
                        Text(settings.isPro ? L("Pro plan") : L("Free trial"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)   // monochrome, discreet (no green) to match the design
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Output-language switcher (flag), then the gear, then the mic-source picker last on the right.
            FooterLanguageButton()
            Button { selection = .settings } label: {
                Image(systemName: "gearshape").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            FooterMicButton()
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private func detail(_ item: NavItem) -> some View {
        switch item {
        case .home: HomeView()
        case .features: FeaturesView()
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
        case .connectedApps: ConnectedAppsPage()
        case .history: HistoryView()
        case .achievements: BadgesView()
        case .leaderboard: LeaderboardView()
        case .wishlist: WishlistView()
        case .feedback: FeedbackView()
        case .freeMonth: FreeMonthView()
        case .settings: SettingsView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
