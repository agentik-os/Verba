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

/// The main, dockable window: kaset-style sidebar + section detail.
struct MainWindow: View {
    @ObservedObject var settings = Settings.shared
    @State private var selection: NavItem? = .home

    var body: some View {
        NavigationSplitView {
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
            .safeAreaInset(edge: .bottom) { sidebarFooter }
        } detail: {
            detail(selection ?? .home)
                .frame(minWidth: 560)
        }
        .frame(minWidth: 940, minHeight: 620)
    }

    private func row(_ item: NavItem) -> some View {
        Label(item.title, systemImage: item.icon).tag(item)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 10) {
                ZStack { Circle().fill(LinearGradient(colors: [Color(red: 0.40, green: 0.32, blue: 0.95),
                                                               Color(red: 0.20, green: 0.70, blue: 0.85)],
                                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                    Image(systemName: "mic.fill").font(.system(size: 12)).foregroundStyle(.white) }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Verba").font(.callout.weight(.semibold))
                    Text(settings.isPro ? "Pro" : "Free").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button { selection = .settings } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func detail(_ item: NavItem) -> some View {
        switch item {
        case .home: HomeView()
        case .insights: InsightsView()
        case .modes:
            VStack(alignment: .leading, spacing: 0) {
                Text("Modes").font(.largeTitle.bold()).padding(.horizontal, 28).padding(.top, 28)
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
