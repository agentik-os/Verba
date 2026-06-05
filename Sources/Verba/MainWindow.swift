import SwiftUI

enum NavItem: String, CaseIterable, Identifiable {
    case home, insights, modes, dictionary, snippets, style, transforms, scratchpad, history, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"; case .insights: return "Insights"; case .modes: return "Modes"
        case .dictionary: return "Dictionary"; case .snippets: return "Snippets"; case .style: return "Style"
        case .transforms: return "Transforms"; case .scratchpad: return "Scratchpad"
        case .history: return "History"; case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"; case .insights: return "chart.bar"; case .modes: return "wand.and.stars"
        case .dictionary: return "character.book.closed"; case .snippets: return "text.badge.plus"
        case .style: return "paintbrush"; case .transforms: return "arrow.triangle.2.circlepath"
        case .scratchpad: return "note.text"; case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
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

/// The main, dockable window: kaset-style sidebar + section detail.
struct MainWindow: View {
    @ObservedObject var settings = Settings.shared
    @State private var selection: NavItem? = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section {
                    row(.home); row(.insights); row(.history)
                }
                Section("Library") {
                    row(.modes); row(.dictionary); row(.snippets); row(.style); row(.transforms); row(.scratchpad)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .toolbar(removing: .sidebarToggle)        // drop the default toggle + its titlebar divider
            .safeAreaInset(edge: .bottom) { sidebarFooter }
        } detail: {
            detail(selection ?? .home)
                .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
                .toolbar {
                    if columnVisibility == .detailOnly {
                        ToolbarItem(placement: .navigation) {
                            Button { withAnimation { columnVisibility = .all } } label: {
                                Image(systemName: "sidebar.leading")
                            }.help("Show sidebar")
                        }
                    }
                }
        }
        .frame(minWidth: 940, minHeight: 620)
    }

    private func row(_ item: NavItem) -> some View {
        Label(item.title, systemImage: item.icon).tag(item)
    }

    private var sidebarFooter: some View {
        HStack(spacing: 10) {
            VerbaMark(size: 26)
            VStack(alignment: .leading, spacing: 0) {
                Text("Verba").font(.callout.weight(.semibold))
                Text(settings.isPro ? "Pro" : "Free").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button { selection = .settings } label: { Image(systemName: "gearshape") }
                .buttonStyle(.borderless).help("Settings")
            Button { withAnimation { columnVisibility = .detailOnly } } label: { Image(systemName: "sidebar.leading") }
                .buttonStyle(.borderless).help("Hide sidebar")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private func detail(_ item: NavItem) -> some View {
        switch item {
        case .home: HomeView()
        case .insights: InsightsView()
        case .modes:
            VStack(alignment: .leading, spacing: 0) {
                Text("Modes").font(.system(size: 28, weight: .bold))
                    .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 6)
                ModesView()
            }
        case .dictionary: DictionaryView()
        case .snippets: SnippetsView()
        case .style: StyleView()
        case .transforms: TransformsView()
        case .scratchpad: ScratchpadView()
        case .history: HistoryView()
        case .settings: SettingsView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
