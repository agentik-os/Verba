import SwiftUI

private enum Metric: String, CaseIterable, Identifiable {
    case words = "Total words", wpm = "Words / min", streak = "Day streak", saved = "Time saved"
    var id: String { rawValue }
    var icon: String {
        switch self { case .words: "text.word.spacing"; case .wpm: "gauge.with.needle"; case .streak: "flame"; case .saved: "clock.arrow.circlepath" }
    }
    func value(_ e: LeaderEntry) -> Double {
        switch self { case .words: e.words; case .wpm: e.wpm; case .streak: e.streak; case .saved: e.saved ?? 0 }
    }
    func format(_ v: Double) -> String {
        switch self {
        case .words: Int(v).formatted()
        case .wpm: "\(Int(v)) wpm"
        case .streak: "\(Int(v)) day\(Int(v) == 1 ? "" : "s")"
        case .saved: v >= 60 ? "\(Int(v) / 60)h \(Int(v) % 60)m" : "\(Int(v)) min"
        }
    }
    /// One-line explanation of what the metric measures, shown under the chips so a
    /// freshly-picked "Time saved" / "Words / min" column isn't an unexplained number.
    var caption: String {
        switch self {
        case .words:  L("Total words dictated across all your sessions.")
        case .wpm:    L("Average words per minute while dictating.")
        case .streak: L("Consecutive days you've dictated at least once.")
        case .saved:  L("Estimated minutes saved versus typing by hand.")
        }
    }
}

final class LeaderboardModel: ObservableObject {
    @Published var entries: [LeaderEntry] = []
    @Published var loading = true
    /// True from the moment an alias/visibility change is made until the deferred reload lands,
    /// so the user's pinned row can show a subtle "updating…" indicator.
    @Published var refreshing = false
    func load() {
        loading = true
        // Push our latest alias/stats first, then fetch so the board reflects it immediately.
        Leaderboard.submit { [weak self] in
            Leaderboard.fetch { self?.entries = $0; self?.loading = false; self?.refreshing = false }
        }
    }
    /// Reload AFTER the debounced alias→submit sink (0.9s in AppDelegate) has pushed,
    /// so the fresh fetch reflects the new alias / visibility.
    func reloadSoon(after seconds: Double = 1.3) {
        refreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in self?.load() }
    }
}

struct LeaderboardView: View {
    @StateObject private var model = LeaderboardModel()
    @ObservedObject private var settings = Settings.shared
    @State private var metric: Metric = .words
    @State private var query = ""
    @State private var preShuffleAlias: String?   // the alias before the last shuffle, for one-tap Undo
    @State private var viewing: AliasRef?         // a tapped row → view that player's achievements
    @FocusState private var aliasFocused: Bool

    struct AliasRef: Identifiable { let id = UUID(); let alias: String }

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
    // HANDOFF-3: the server no longer exposes uids; it marks the caller's own row with `me`.
    private var mine: (rank: Int, entry: LeaderEntry)? { ranked.first { $0.entry.me == true } }

    /// True when the selected metric is 0/absent for (nearly) every row, so ranking by it
    /// would show a wall of "0" — used to swap in a "not enough data yet" note instead.
    private var metricIsSparse: Bool {
        guard !model.entries.isEmpty else { return false }
        let populated = model.entries.filter { metric.value($0) > 0 }.count
        return populated <= max(0, model.entries.count / 10)   // <=10% have data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("Leaderboard")).font(.system(size: 17, weight: .bold))
                Spacer()
                Button { model.load() } label: { Image(systemName: "arrow.clockwise") }.buttonStyle(.borderless).help(L("Refresh"))
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)
            Text(L("Where you rank against everyone using Verba. Aliases only, no names or emails."))
                .font(.callout).foregroundStyle(.secondary).padding(.horizontal, 28).padding(.bottom, 14)

            identityCard
                .padding(.horizontal, 28).padding(.bottom, 12)

            metricChips
                .padding(.horizontal, 28).padding(.bottom, 6)

            // Per-metric caption so "Time saved" / "Words / min" aren't unexplained numbers.
            Text(metric.caption)
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 28).padding(.bottom, 12)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 12))
                TextField(L("Search aliases"), text: $query).textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .padding(.horizontal, 28).padding(.bottom, 10)

            if !settings.showOnLeaderboard, query.isEmpty {
                hiddenNote
                    .padding(.horizontal, 28).padding(.bottom, 8)
            } else if let mine, query.isEmpty {
                row(mine.rank, mine.entry, highlighted: true)
                    .padding(.horizontal, 28).padding(.bottom, 8)
            }

            if model.loading {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
            } else if metricIsSparse, query.isEmpty {
                EmptyState(icon: metric.icon, title: L("Not enough data for this metric yet"),
                           message: L("Nobody has enough “\(metric.rawValue.lowercased())” data to rank by yet. Pick another metric, or keep dictating, this fills in over time."))
            } else if filtered.isEmpty {
                if query.isEmpty {
                    EmptyState(icon: "trophy", title: L("Nobody on the board yet"),
                               message: L("The leaderboard ranks Verba users by words dictated. Dictate anything to claim your spot, your public alias appears here (never your real name or email)."))
                } else {
                    Text(L("No alias matches “\(query)”."))
                        .font(.callout).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 30)
                }
            }

            if !(metricIsSparse && query.isEmpty) {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        // When the user is pinned on top (no search), don't list them again below.
                        let items = query.isEmpty ? filtered.filter { $0.entry.me != true } : filtered
                        ForEach(items, id: \.entry.id) { item in
                            row(item.rank, item.entry, highlighted: item.entry.me == true)
                        }
                    }
                    .padding(.horizontal, 28).padding(.bottom, 18)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.load() }
        .sheet(item: $viewing) { ref in
            PlayerProfileSheet(alias: ref.alias, isMe: ref.alias == settings.username)
        }
    }

    // MARK: Identity — edit the public alias + the visibility switch, right where they matter.
    // Writing to Settings is enough: the AppDelegate sink debounces alias changes to the
    // board + Clerk, and the showOnLeaderboard didSet submits/removes the row server-side.
    private var identityCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 22)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Your public alias")).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField(L("Alias"), text: $settings.username)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .focused($aliasFocused)
                        .onSubmit { aliasFocused = false; model.reloadSoon() }
                    // Undo appears only right after a shuffle, restoring the previous alias.
                    if let prev = preShuffleAlias, prev != settings.username {
                        Divider().frame(height: 12)
                        Button {
                            settings.username = prev
                            preShuffleAlias = nil
                            model.reloadSoon()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: 18)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless).help(L("Undo shuffle (restore your previous alias)"))
                    }
                    Divider().frame(height: 12)
                    Button {
                        // Stash the current alias so the shuffle is reversible in one tap.
                        preShuffleAlias = settings.username
                        settings.username = Settings.randomAlias()
                        model.reloadSoon()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless).help(L("Shuffle a new alias (you can undo it)"))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(maxWidth: 260)
            }
            Spacer()
            Toggle(isOn: $settings.showOnLeaderboard) {
                Text(L("Show me")).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
            .toggleStyle(.switch).controlSize(.small)
            .help(L("Show me on the public leaderboard"))
            .onChange(of: settings.showOnLeaderboard) { _, _ in model.reloadSoon(after: 0.8) }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var hiddenNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash").foregroundStyle(.secondary)
            Text(L("You're hidden from the public leaderboard. Flip “Show me” above to claim your spot."))
                .font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    // MARK: Metric switcher — capsule tag chips, not a cramped segmented control.
    private var metricChips: some View {
        HStack(spacing: 8) {
            ForEach(Metric.allCases) { m in
                let selected = metric == m
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { metric = m }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: m.icon).font(.system(size: 10, weight: .semibold))
                        Text(m.rawValue).font(.system(size: 12, weight: selected ? .semibold : .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6.5)
                    .foregroundStyle(selected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(selected ? VGlass.fillSelected : VGlass.fillSecondary))
                    )
                    .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(selected ? VGlass.hairlineSelected : VGlass.hairline), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func row(_ rank: Int, _ e: LeaderEntry, highlighted: Bool) -> some View {
        HStack(spacing: 12) {
            Text(medal(rank)).font(.system(size: 15, weight: .semibold)).frame(width: 36, alignment: .leading)
            Text(e.alias + (highlighted ? L("  (you)") : "")).fontWeight(highlighted ? .semibold : .regular).lineLimit(1)
            // Subtle "updating…" hint on the user's own row while a deferred reload is pending,
            // so an alias shuffle / visibility toggle visibly takes effect.
            if highlighted && model.refreshing {
                HStack(spacing: 4) {
                    ProgressView().controlSize(.small).scaleEffect(0.6)
                    Text(L("updating…")).font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(metric.format(metric.value(e))).font(.callout.weight(.medium)).monospacedDigit().foregroundStyle(highlighted ? .primary : .secondary)
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .glassCard(selected: highlighted, cornerRadius: 12)
        .contentShape(Rectangle())
        .onTapGesture { viewing = AliasRef(alias: e.alias) }   // open their achievements
    }

    private func medal(_ r: Int) -> String {
        switch r { case 1: "🥇"; case 2: "🥈"; case 3: "🥉"; default: "#\(r)" }
    }
}
