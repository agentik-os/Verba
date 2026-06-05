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

/// The main, dockable window: a fully custom sidebar + detail (NO toolbar / top bar).
/// The sidebar extends to the top of the window; the collapse control lives inside
/// it (ChatGPT-style). Window is full-size-content + transparent titlebar.
struct MainWindow: View {
    @ObservedObject var settings = Settings.shared
    @State private var selection: NavItem? = .home
    @State private var sidebarOpen = true

    private let sidebarWidth: CGFloat = 250

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                if sidebarOpen {
                    sidebar
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .leading))
                }
                detail(selection ?? .home)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
            // When collapsed, a single reopen control floats just right of the traffic lights.
            if !sidebarOpen {
                toggle(open: true)
                    .padding(.leading, 78)
                    .padding(.top, 9)
            }
        }
        .frame(minWidth: 880, minHeight: 600)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.2), value: sidebarOpen)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Top region: leave room for the traffic lights, collapse control on the right.
            HStack(spacing: 0) {
                Spacer(minLength: 70)   // traffic-light clearance
                Spacer()
                toggle(open: false)
            }
            .frame(height: 40)
            .padding(.horizontal, 12)

            List(selection: $selection) {
                Section { row(.home); row(.insights); row(.history) }
                Section("Library") {
                    row(.modes); row(.dictionary); row(.snippets); row(.style); row(.transforms); row(.scratchpad)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            sidebarFooter
        }
        .background(.ultraThinMaterial)
    }

    private func toggle(open: Bool) -> some View {
        Button { withAnimation { sidebarOpen = open } } label: {
            Image(systemName: "sidebar.leading").font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help(open ? "Show sidebar" : "Hide sidebar")
    }

    private func row(_ item: NavItem) -> some View {
        Label(item.title, systemImage: item.icon).tag(item)
    }

    private var sidebarFooter: some View {
        HStack(spacing: 8) {
            VerbaMark(size: 22)
            Text("Verba").font(.callout.weight(.semibold)).fixedSize()
            Text(settings.isPro ? "Pro" : "Free")
                .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 1)
                .background(.quaternary, in: Capsule())
                .fixedSize()
            Spacer(minLength: 6)
            Button { selection = .settings } label: { Image(systemName: "gearshape") }
                .buttonStyle(.borderless).help("Settings")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
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
