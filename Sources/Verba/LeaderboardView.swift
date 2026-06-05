import SwiftUI

private enum Metric: String, CaseIterable, Identifiable {
    case words = "Total words", wpm = "Words / min", streak = "Day streak"
    var id: String { rawValue }
    func value(_ e: LeaderEntry) -> Double {
        switch self { case .words: e.words; case .wpm: e.wpm; case .streak: e.streak }
    }
    func format(_ v: Double) -> String {
        switch self {
        case .words: Int(v).formatted()
        case .wpm: "\(Int(v)) wpm"
        case .streak: "\(Int(v)) day\(Int(v) == 1 ? "" : "s")"
        }
    }
}

final class LeaderboardModel: ObservableObject {
    @Published var entries: [LeaderEntry] = []
    @Published var loading = true
    func load() {
        loading = true
        Leaderboard.submit()                      // push our latest stats first
        Leaderboard.fetch { [weak self] in self?.entries = $0; self?.loading = false }
    }
}

struct LeaderboardView: View {
    @StateObject private var model = LeaderboardModel()
    @ObservedObject private var settings = Settings.shared
    @State private var metric: Metric = .words
    @State private var query = ""

    private var myUID: String { settings.referralCode.isEmpty ? "anon-" + settings.proEmail : settings.referralCode }

    private var ranked: [(rank: Int, entry: LeaderEntry)] {
        model.entries
            .sorted { metric.value($0) > metric.value($1) }
            .enumerated().map { ($0.offset + 1, $0.element) }
    }
    private var filtered: [(rank: Int, entry: LeaderEntry)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return ranked }
        return ranked.filter { $0.entry.alias.lowercased().contains(q) }
    }
    private var mine: (rank: Int, entry: LeaderEntry)? { ranked.first { $0.entry.uid == myUID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Leaderboard").font(.system(size: 28, weight: .bold))
                Spacer()
                Button { model.load() } label: { Image(systemName: "arrow.clockwise") }.buttonStyle(.borderless).help("Refresh")
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)
            Text("Where you rank against everyone using Verba. Aliases only, no names or emails.")
                .font(.callout).foregroundStyle(.secondary).padding(.horizontal, 28).padding(.bottom, 12)

            Picker("", selection: $metric) { ForEach(Metric.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented).labelsHidden().padding(.horizontal, 28).padding(.bottom, 10)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 12))
                TextField("Search aliases", text: $query).textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .padding(.horizontal, 28).padding(.bottom, 10)

            if let mine, query.isEmpty {
                row(mine.rank, mine.entry, highlighted: true)
                    .padding(.horizontal, 28).padding(.bottom, 8)
            }

            if model.loading {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
            } else if filtered.isEmpty {
                Text(query.isEmpty ? "No one on the board yet. Dictate to claim a spot." : "No alias matches “\(query)”.")
                    .font(.callout).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 30)
            }

            ScrollView {
                LazyVStack(spacing: 6) {
                    // When the user is pinned on top (no search), don't list them again below.
                    let items = query.isEmpty ? filtered.filter { $0.entry.uid != myUID } : filtered
                    ForEach(items, id: \.entry.id) { item in
                        row(item.rank, item.entry, highlighted: item.entry.uid == myUID)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.load() }
    }

    private func row(_ rank: Int, _ e: LeaderEntry, highlighted: Bool) -> some View {
        HStack(spacing: 12) {
            Text(medal(rank)).font(.system(size: 15, weight: .semibold)).frame(width: 36, alignment: .leading)
            Text(e.alias + (highlighted ? "  (you)" : "")).fontWeight(highlighted ? .semibold : .regular).lineLimit(1)
            Spacer()
            Text(metric.format(metric.value(e))).font(.callout.weight(.medium)).foregroundStyle(highlighted ? .primary : .secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlighted ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(highlighted ? 0.4 : 0), lineWidth: 1))
    }

    private func medal(_ r: Int) -> String {
        switch r { case 1: "🥇"; case 2: "🥈"; case 3: "🥉"; default: "#\(r)" }
    }
}
