import SwiftUI
import Charts

// Borderless card.
private struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View { content().cleanCard(padding: padding) }
}

private struct SectionScaffold<Content: View, Actions: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title).font(.system(size: 17, weight: .bold))
                        Spacer()
                        actions()
                    }
                    if let subtitle { Text(subtitle).font(.callout).foregroundStyle(.secondary) }
                }
                content()
            }
            .padding(.horizontal, 28).padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension SectionScaffold where Actions == EmptyView {
    init(title: String, subtitle: String?, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, subtitle: subtitle, content: content, actions: { EmptyView() })
    }
}

/// Capsule tag chip — the exemplar's metric-chip grammar (LeaderboardView): SF symbol + label,
/// inverted fill when selected, soft 1px border otherwise. Internal so ModesView shares it.
struct TagChip: View {
    var icon: String? = nil
    let label: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 10, weight: .semibold)) }
                Text(label).font(.system(size: 12, weight: selected ? .semibold : .medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 6.5)
            .foregroundStyle(selected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(selected ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home

struct HomeView: View {
    @ObservedObject var stats = Stats.shared
    @ObservedObject var history = History.shared
    @ObservedObject var settings = Settings.shared

    // Per-card UI state for the "Recent" list.
    @State private var expandedText: HistoryEntry.ID?     // card showing full text
    @State private var expandedAdapt: HistoryEntry.ID?    // card with its Adapt panel open

    var body: some View {
        SectionScaffold(title: "Home", subtitle: "Talk, and Claude cleans it up.") {
            HStack(spacing: 14) {
                stat("\(stats.totalWords.formatted())", "total words", "text.word.spacing")
                stat("\(stats.avgWPM)", "words / min", "gauge.with.dots.needle.67percent")
                stat("\(stats.streak)", "day streak", "flame.fill")
            }
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start dictating").font(.headline)
                    Text("Press \(triggerLabel) and talk. Fn + Tab jumps to the next mode (even mid-sentence), ⌃ pauses & resumes, or use ⌃⌥1-6 for a specific mode.")
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(settings.profiles.prefix(6)) { p in
                            Text(p.name).font(.caption.weight(.medium))
                                .padding(.horizontal, 11).padding(.vertical, 5)
                                .background(.softFill, in: Capsule())
                        }
                    }
                }
            }
            Text("Recent").font(.headline)
            if history.entries.isEmpty {
                Card { Text("Your dictations will show up here.").foregroundStyle(.secondary) }
            } else {
                VStack(spacing: 10) {
                    ForEach(history.entries.prefix(6)) { e in
                        recentCard(e)
                    }
                }
            }
        }
    }

    /// A "Recent" card: full-text expand toggle, copy, and an inline Adapt panel (one open at a time).
    @ViewBuilder
    private func recentCard(_ e: HistoryEntry) -> some View {
        let full = e.reprompted.isEmpty ? e.original : e.reprompted
        let textExpanded = expandedText == e.id
        let adaptOpen = expandedAdapt == e.id
        let long = full.count > 160 || full.contains("\n")
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(full)
                    .lineLimit(textExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                if long {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedText = textExpanded ? nil : e.id
                        }
                    } label: {
                        Text(textExpanded ? "Show less" : "Show more")
                            .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedAdapt = adaptOpen ? nil : e.id
                        }
                    } label: {
                        Label("Adapt", systemImage: "wand.and.stars")
                            .font(.caption2.weight(.semibold))
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    CopyButton(text: full)
                }
                if adaptOpen {
                    Divider().padding(.vertical, 2)
                    AdaptPanel(source: full).id(e.id)
                }
            }
        }
    }

    private var triggerLabel: String {
        if settings.useFnAsPrimary { return "Fn 🌐" }
        return settings.primaryHasShortcut
            ? shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods)
            : "⌃⌥ + number"
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.title3).foregroundStyle(.secondary)
                Text(value).font(.system(size: 30, weight: .bold)).monospacedDigit().contentTransition(.numericText())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Insights

/// Fetches the public leaderboard once so Insights can show the user's standing (rank / percentile /
/// words behind #1) without leaving the tab — mirrors LeaderboardModel, but read-only for one card.
@MainActor
final class InsightsStanding: ObservableObject {
    @Published var entries: [LeaderEntry] = []
    @Published var loading = true

    /// Rows sorted by total words, descending — the canonical leaderboard ordering.
    private var ranked: [LeaderEntry] { entries.sorted { $0.words > $1.words } }

    /// The caller's own row + its 1-based rank, when present on the board.
    var mine: (rank: Int, entry: LeaderEntry)? {
        guard let idx = ranked.firstIndex(where: { $0.me == true }) else { return nil }
        return (idx + 1, ranked[idx])
    }
    var total: Int { entries.count }
    /// "Top X%" — smaller is better; 1 means you're #1.
    var percentile: Int? {
        guard let m = mine, total > 0 else { return nil }
        return max(1, Int((Double(m.rank) / Double(total) * 100).rounded()))
    }
    /// Words the leader has beyond you (0 when you ARE the leader).
    var wordsBehindLeader: Int? {
        guard let m = mine, let top = ranked.first else { return nil }
        return max(0, Int(top.words - m.entry.words))
    }

    func load() {
        loading = true
        Leaderboard.fetch { [weak self] in self?.entries = $0; self?.loading = false }
    }
}

struct InsightsView: View {
    @ObservedObject var stats = Stats.shared
    @ObservedObject private var settings = Settings.shared
    @StateObject private var standing = InsightsStanding()
    private let notesCtl = NotesController.shared

    var body: some View {
        SectionScaffold(title: "Insights", subtitle: "Your dictation, by the numbers.") {
            // The chart stays the hero, unchanged.
            Card {
                Chart(stats.recentDays(14), id: \.label) { day in
                    BarMark(x: .value("Day", day.label), y: .value("Words", day.words))
                        .foregroundStyle(Color.primary.opacity(0.75))
                        .cornerRadius(5)
                }
                .frame(height: 220)
                // Clean: no dashed background grid, just the labels.
                .chartXAxis { AxisMarks { AxisValueLabel() } }
                .chartYAxis { AxisMarks { AxisValueLabel() } }
            }

            // STANDING — the gamification hero: rank, percentile, gap to #1.
            standingCard

            // TODAY
            group("Today", "sun.max") {
                grid([
                    kpi("\(wordsToday.formatted())", "words today", "text.word.spacing",
                        delta: dayDelta),
                    kpi("\(wordsYesterday.formatted())", "words yesterday", "calendar"),
                    kpi("\(stats.streak)", "day streak", "flame.fill",
                        caption: stats.streak >= longestStreak && stats.streak > 0 ? "your best ever" : "best \(longestStreak)"),
                ])
            }

            // THIS WEEK
            group("This week", "calendar") {
                grid([
                    kpi("\(stats.wordsThisWeek.formatted())", "words this week", "text.alignleft",
                        delta: weekDelta),
                    kpi("\(sevenDayAvg.formatted())", "7-day average", "chart.bar",
                        caption: "words / day"),
                    kpi(mostProductiveDay.label, "most productive day", "star.fill",
                        caption: mostProductiveDay.words > 0 ? "\(mostProductiveDay.words.formatted()) words" : "—"),
                    kpi("\(activeDays7)/7", "active days", "checkmark.circle"),
                    kpi("\(stats.wordsThisMonth.formatted())", "words this month", "calendar.badge.clock"),
                    kpi(speedMultiple, "faster than typing", "hare.fill",
                        caption: "vs ~40 wpm by hand"),
                ])
            }

            // ALL TIME
            group("All time", "infinity") {
                grid([
                    kpi("\(stats.totalWords.formatted())", "total words", "text.word.spacing"),
                    kpi("\(stats.totalCount.formatted())", "dictations", "mic.fill"),
                    kpi("\(stats.avgWPM)", "words / min", "gauge.with.dots.needle.67percent"),
                    kpi("\(stats.avgWordsPerDictation)", "avg / dictation", "number"),
                    kpi("\(stats.bestDayWords.formatted())", "best day ever", "trophy.fill"),
                    kpi(spokenTime, "time spoken", "waveform"),
                    kpi(timeSaved, "time saved typing", "clock.arrow.circlepath",
                        caption: "vs typing it by hand"),
                    kpi("\(longestStreak)", "longest streak", "flame",
                        caption: stats.streak == longestStreak && longestStreak > 0 ? "you're on it now" : "days in a row"),
                ])
            }

            // MILESTONE — the next round-number target, with a thin progress bar.
            milestoneCard
        }
        .onAppear { if standing.entries.isEmpty { standing.load() } }
    }

    // MARK: Standing hero

    @ViewBuilder private var standingCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Text("Your standing").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Button { notesCtl.leaderboardNavSignal &+= 1 } label: {
                        HStack(spacing: 4) {
                            Text("Leaderboard").font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).help("Open the full leaderboard")
                }

                if standing.loading {
                    HStack(spacing: 10) { ProgressView().controlSize(.small); Text("Ranking you…").font(.callout).foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if !settings.showOnLeaderboard {
                    standingNote("eye.slash", "You're hidden from the leaderboard. Flip “Show me” there to claim your rank.")
                } else if let m = standing.mine {
                    HStack(alignment: .top, spacing: 0) {
                        bigStat(rankText(m.rank), "global rank", "of \(standing.total.formatted()) people")
                        Divider().frame(height: 56)
                        if let p = standing.percentile {
                            bigStat("top \(p)%", "percentile", p <= 1 ? "the very top" : "you're ahead of \(100 - p)%")
                            Divider().frame(height: 56)
                        }
                        if let behind = standing.wordsBehindLeader {
                            bigStat(behind == 0 ? "—" : behind.formatted(), behind == 0 ? "you lead 🥇" : "words behind #1",
                                    behind == 0 ? "everyone's chasing you" : "keep dictating to close it")
                        }
                    }
                } else {
                    standingNote("flag.checkered", "You're not on the board yet — dictate anything to claim your spot.")
                }
            }
        }
    }

    private func bigStat(_ value: String, _ label: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold)).monospacedDigit().contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(sub).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private func standingNote(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(text).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func rankText(_ r: Int) -> String {
        switch r { case 1: "🥇 #1"; case 2: "🥈 #2"; case 3: "🥉 #3"; default: "#\(r)" }
    }

    // MARK: Milestone

    @ViewBuilder private var milestoneCard: some View {
        let target = nextMilestone
        let done = stats.totalCount
        let prev = previousMilestone
        let span = max(1, target - prev)
        let progress = min(1, max(0, Double(done - prev) / Double(span)))
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "target").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Text("Next milestone").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(done.formatted()) / \(target.formatted())").font(.caption.weight(.medium)).monospacedDigit().foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08)).frame(height: 8)
                        Capsule().fill(Color.primary.opacity(0.75)).frame(width: max(8, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)
                Text("\(max(0, target - done).formatted()) more dictation\(target - done == 1 ? "" : "s") to reach \(target.formatted()).")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Layout helpers — a labelled group + a responsive KPI grid.

    @ViewBuilder private func group<Content: View>(_ title: String, _ icon: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).textCase(.uppercase).kerning(0.5)
            }
            content()
        }
    }

    private func grid(_ cards: [KPI]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
            ForEach(cards) { $0 }
        }
    }

    // MARK: KPI card — big monospaced number + caption + SF symbol + optional delta.

    struct KPI: View, Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let icon: String
        var caption: String? = nil
        var delta: Delta? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.secondary)
                    Spacer()
                    if let delta { delta.badge }
                }
                Text(value).font(.system(size: 26, weight: .bold)).monospacedDigit().contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.7)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    if let caption { Text(caption).font(.caption2).foregroundStyle(.tertiary).lineLimit(1) }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .cleanCard(padding: 14)
        }
    }

    /// A comparison delta: a direction arrow + percent. Monochrome — "up" reads bold/primary,
    /// "down"/"flat" sit quiet in secondary (the app is strict B&W, no green/red accents here).
    struct Delta {
        let percent: Int   // signed; 0 = flat
        var badge: some View {
            Group {
                if percent == 0 {
                    HStack(spacing: 3) { Image(systemName: "equal"); Text("flat") }
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: percent > 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(percent))%")
                    }
                    .foregroundStyle(percent > 0 ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.secondary))
                }
            }
            .font(.system(size: 11, weight: .semibold)).monospacedDigit()
        }
    }

    private func kpi(_ value: String, _ label: String, _ icon: String, caption: String? = nil, delta: Delta? = nil) -> KPI {
        KPI(value: value, label: label, icon: icon, caption: caption, delta: delta)
    }

    // MARK: Derived values (all from Stats.shared — no new persistence)

    private var recent: [(label: String, words: Int)] { stats.recentDays(14) }

    private var wordsToday: Int { recent.last?.words ?? 0 }
    private var wordsYesterday: Int { recent.count >= 2 ? recent[recent.count - 2].words : 0 }

    /// Today vs yesterday, as a signed percent (nil-safe: needs a yesterday baseline).
    private var dayDelta: Delta? {
        guard wordsYesterday > 0 else { return wordsToday > 0 ? Delta(percent: 100) : nil }
        return Delta(percent: Int(((Double(wordsToday) - Double(wordsYesterday)) / Double(wordsYesterday) * 100).rounded()))
    }

    /// This week (last 7d) vs the previous 7 days — the key "comparing" hook.
    private var weekDelta: Delta? {
        let last7 = recent.suffix(7).reduce(0) { $0 + $1.words }
        let prev7 = recent.prefix(max(0, recent.count - 7)).suffix(7).reduce(0) { $0 + $1.words }
        guard prev7 > 0 else { return last7 > 0 ? Delta(percent: 100) : nil }
        return Delta(percent: Int(((Double(last7) - Double(prev7)) / Double(prev7) * 100).rounded()))
    }

    private var sevenDayAvg: Int { recent.suffix(7).reduce(0) { $0 + $1.words } / 7 }

    /// Active days in the last 7 (days with any words).
    private var activeDays7: Int { recent.suffix(7).filter { $0.words > 0 }.count }

    /// The best single day in the last 14 (label + words) — "most productive day".
    private var mostProductiveDay: (label: String, words: Int) {
        recent.max { $0.words < $1.words } ?? (label: "—", words: 0)
    }

    /// How many times faster dictation is than ~40 wpm typing.
    private var speedMultiple: String {
        guard stats.avgWPM > 0 else { return "—" }
        let x = Double(stats.avgWPM) / 40.0
        return x >= 10 ? "\(Int(x.rounded()))×" : String(format: "%.1f×", x)
    }

    private var spokenTime: String {
        let m = Int(stats.totalSeconds / 60)
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m) min"
    }

    private var timeSaved: String {
        let m = stats.timeSavedMinutes
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m) min"
    }

    /// Longest run of consecutive active days across all recorded history.
    private var longestStreak: Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let active = Set(stats.days.filter { $0.value.count > 0 }.keys)
        guard !active.isEmpty else { return 0 }
        // Walk every active day; a day starts a run if the day before it is inactive.
        var best = 0
        for key in active {
            guard let d = f.date(from: key) else { continue }
            let prevKey = f.string(from: d.addingTimeInterval(-86400))
            if active.contains(prevKey) { continue }   // not a run start
            var len = 1
            var cur = d
            while true {
                let nextKey = f.string(from: cur.addingTimeInterval(86400))
                if active.contains(nextKey) { len += 1; cur = cur.addingTimeInterval(86400) } else { break }
            }
            best = max(best, len)
        }
        return best
    }

    /// Next round-number dictation milestone (100 / 500 / 1000 / 2500 / 5000 / 10k…).
    private var nextMilestone: Int {
        let ladder = [100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000]
        let c = stats.totalCount
        return ladder.first { $0 > c } ?? (((c / 100000) + 1) * 100000)
    }
    /// The milestone just below the current count (the progress-bar floor).
    private var previousMilestone: Int {
        let ladder = [0, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000]
        let c = stats.totalCount
        return ladder.last { $0 <= c } ?? 0
    }
}

// MARK: - Dictionary agent: clean up the user's terms with the AI, returning strict JSON.

enum DictionaryAgent {
    /// A cleaned term: corrected written form + optional proposed spoken variant.
    struct Cleaned { var written: String; var spoken: String }
    enum Err: LocalizedError {
        case empty, unparseable
        var errorDescription: String? {
            switch self {
            case .empty: return "Add a term first."
            case .unparseable: return "The AI didn't return a usable result."
            }
        }
    }

    private static let system = """
    You clean up a dictation dictionary. Each term has a "written" form (the correct spelling the app \
    should produce) and an optional "said" form (how the user would speak it, to auto-correct a mis-hearing).

    For every input term:
    - Fix the capitalization and spelling of the "written" form (proper nouns, brand names, acronyms).
    - Where helpful, propose the likely "said" spoken variant (lowercase, how someone would pronounce it). \
    If the term is a plain word that wouldn't be mis-heard, leave "said" empty.
    - Keep the SAME number of terms, in the SAME order — only correct them.

    Detect the user's language and keep EVERY value in that single language. NEVER mix two languages \
    in a value (no franglais).

    Reply with a SINGLE JSON object, nothing else (no prose, no code fence):
    {"terms":[{"written":"Corrected Form","said":"spoken variant or empty"}]}
    """

    static func clean(_ terms: [DictTerm]) async throws -> [Cleaned] {
        let usable = terms.filter { !$0.written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !usable.isEmpty else { throw Err.empty }
        let payload = usable.map { ["written": $0.written, "said": $0.spoken] }
        let json = (try? JSONSerialization.data(withJSONObject: ["terms": payload]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let raw = try await Reprompter(model: model).reprompt(transcript: json, systemPrompt: system)
        return try parse(raw)
    }

    static func parse(_ text: String) throws -> [Cleaned] {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards), open.lowerBound <= close.lowerBound {
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw Err.unparseable }
        let rawTerms = obj["terms"] as? [Any] ?? []
        let cleaned: [Cleaned] = rawTerms.compactMap { item in
            guard let t = item as? [String: Any],
                  let w = (t["written"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !w.isEmpty else { return nil }
            let said = (t["said"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return Cleaned(written: w, spoken: said)
        }
        guard !cleaned.isEmpty else { throw Err.unparseable }
        return cleaned
    }
}

// MARK: - Dictionary

struct DictionaryView: View {
    @ObservedObject var store = DictionaryStore.shared
    @ObservedObject var settings = Settings.shared
    @State private var aiBusy = false
    @State private var aiError: String?
    @State private var selectedID: UUID?    // entry being edited; nil = the "Add" form
    @State private var search = ""
    @State private var filterCorrections: Bool? = nil   // nil = all, true = corrections, false = words

    private var autoCount: Int { store.terms.filter(\.auto).count }
    private var hasWritten: Bool {
        store.terms.contains { !$0.written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// A row is a misspelling correction when it carries a spoken form; an empty spoken form
    /// means it's a pure vocabulary hint ("Add a word"). New correction rows are seeded with a
    /// single space so they render as a correction before the user types anything.
    private func isCorrection(_ t: DictTerm) -> Bool { !t.spoken.isEmpty }

    /// Terms passing the search + correction/word filter, in store order.
    private var filtered: [DictTerm] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.terms.filter { t in
            if let want = filterCorrections, isCorrection(t) != want { return false }
            if q.isEmpty { return true }
            return t.written.lowercased().contains(q) || t.spoken.lowercased().contains(q)
        }
    }

    // MARK: Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider()
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: store.terms.count) { _, _ in
            // A removed selection falls back to the Add form.
            if let id = selectedID, !store.terms.contains(where: { $0.id == id }) { selectedID = nil }
        }
    }

    // MARK: Left — search + tap-selected list of terms
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dictionary").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { newWord() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless).help("Add a word")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("Search terms", text: $search).textFieldStyle(.plain)
            }
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .padding(.horizontal, 14).padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    paneChip(label: "All", icon: nil, on: filterCorrections == nil) { filterCorrections = nil }
                    paneChip(label: "Words", icon: "text.book.closed", on: filterCorrections == false) { filterCorrections = false }
                    paneChip(label: "Corrections", icon: "arrow.right", on: filterCorrections == true) { filterCorrections = true }
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
            }

            if filtered.isEmpty {
                Spacer()
                EmptyState(icon: "character.book.closed",
                           title: store.terms.isEmpty ? "No terms yet" : "No matches",
                           message: store.terms.isEmpty
                               ? "Teach Verba names, jargon, and acronyms it should always spell right."
                               : "Try another search or filter, or All to see every term.")
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filtered) { t in
                            termRow(t).onTapGesture { selectedID = t.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func termRow(_ t: DictTerm) -> some View {
        let selected = selectedID == t.id
        let correction = isCorrection(t)
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: correction ? "arrow.right" : "text.book.closed").font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(t.written.isEmpty ? "New term" : t.written)
                    .font(.system(size: 13, weight: .medium)).lineLimit(1)
                    .foregroundStyle(t.written.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                HStack(spacing: 5) {
                    if correction, !t.spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("said “\(t.spoken)”").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    } else {
                        Text(correction ? "correction" : "vocabulary").font(.caption2).foregroundStyle(.secondary)
                    }
                    if t.auto {
                        Text("·").font(.caption2).foregroundStyle(.tertiary)
                        Text("auto").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { remove(t) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: Right — editor for the selected term, or the add forms
    @ViewBuilder private var detail: some View {
        if let id = selectedID, let idx = store.terms.firstIndex(where: { $0.id == id }) {
            entryEditor(idx: idx)
        } else {
            addForms
        }
    }

    /// Editor for the selected term: edit its written form, the spoken form (when a correction),
    /// flip its auto badge, or delete it.
    private func entryEditor(idx: Int) -> some View {
        let t = store.terms[idx]
        let correction = isCorrection(t)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: correction ? "arrow.right" : "text.book.closed")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                    Text(correction ? "Misspelling correction" : "Vocabulary word")
                        .font(.system(size: 17, weight: .bold))
                    if t.auto {
                        Text("auto").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(.softFill, in: Capsule())
                            .help("Auto-learned from one of your edits")
                    }
                    Spacer()
                    Button(role: .destructive) { remove(t) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this term")
                }

                if correction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Said").font(.subheadline.weight(.semibold))
                        TextField("The word as it gets mis-heard", text: $store.terms[idx].spoken).cleanField()
                            .help("The word as it gets mis-heard. Verba auto-replaces it with the written form.")
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Written").font(.subheadline.weight(.semibold))
                    TextField(correction ? "The correct spelling Verba should write" : "Word the transcriber should spell right",
                              text: $store.terms[idx].written).cleanField()
                        .help(correction
                              ? "The correct spelling Verba should write instead."
                              : "A vocabulary hint sent to the transcriber so it recognizes and spells this word.")
                }

                Text(correction
                     ? "When Verba hears the “Said” word, it writes the “Written” form instead."
                     : "This teaches the transcriber a name or term so it always spells it right — no correction needed.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The two add paths + the auto-add toggle + Improve-with-AI — shown when nothing is selected.
    private var addForms: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add to dictionary").font(.system(size: 17, weight: .bold))
                    Text("Teach Verba names and terms it should always spell right.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    primaryAddButton("Add a word") { newWord() }
                    addButton("Correct a misspelling") {
                        store.terms.append(DictTerm(spoken: " ", written: ""))
                        selectedID = store.terms.last?.id
                    }
                    Spacer()
                }

                Text("“Add a word” teaches the transcriber a name or term so it spells it right — no correction needed. “Correct a misspelling” pairs a mis-heard spoken word with the written form so Verba swaps it automatically.")
                    .font(.caption).foregroundStyle(.secondary)

                // Auto-add control.
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.sparkles").font(.system(size: 18)).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-add from your edits").font(.headline)
                        Text(autoCount > 0
                             ? "Verba learned \(autoCount) term\(autoCount == 1 ? "" : "s") from your corrections."
                             : "When you fix a word after pasting, Verba adds it here automatically.")
                            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(isOn: $settings.autoLearnDictionary) {
                        Text("Auto-add").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    }
                    .toggleStyle(.switch).controlSize(.small)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Clean up the existing terms with the AI.
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.system(size: 18)).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Improve with AI").font(.headline)
                        Text(aiError ?? "Fix the spelling and capitalization of your terms, and propose the spoken form where it helps.")
                            .font(.caption).foregroundStyle(aiError == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
                    }
                    Spacer()
                    if aiBusy { ProgressView().controlSize(.small) }
                    Button(action: improveWithAI) { Text("Improve with AI") }
                        .glassProminentButton()
                        .disabled(aiBusy || !hasWritten)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 28).padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Append a fresh vocabulary word and jump to its editor.
    private func newWord() {
        store.terms.append(DictTerm(spoken: "", written: ""))
        selectedID = store.terms.last?.id
    }

    private func remove(_ t: DictTerm) {
        let wasSelected = (selectedID == t.id)
        store.terms.removeAll { $0.id == t.id }
        if wasSelected { selectedID = nil }
    }

    private func improveWithAI() {
        guard !aiBusy, hasWritten else { return }
        aiError = nil; aiBusy = true
        let snapshot = store.terms
        Task {
            do {
                let cleaned = try await DictionaryAgent.clean(snapshot)
                await MainActor.run {
                    merge(cleaned)
                    aiBusy = false
                }
            } catch {
                await MainActor.run { aiError = error.localizedDescription; aiBusy = false }
            }
        }
    }

    /// Merge AI-cleaned terms back in: update each written form's casing/spelling and fill an
    /// empty spoken form on correction rows, without dropping or duplicating any existing term. The
    /// AI returns the cleaned terms in the same order as the terms that had a written value, so we
    /// map them back positionally onto exactly those rows and leave every other term untouched.
    /// Pure vocabulary entries ("Add a word", empty spoken) keep their intent — only their spelling
    /// is cleaned, never converted into a correction.
    private func merge(_ cleaned: [DictionaryAgent.Cleaned]) {
        let writtenIdx = store.terms.indices.filter {
            !store.terms[$0].written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        for (cleanedTerm, idx) in zip(cleaned, writtenIdx) {
            store.terms[idx].written = cleanedTerm.written
            // Only an existing correction row may gain a proposed spoken form; a vocab-only row
            // (empty spoken) stays a vocab hint.
            if isCorrection(store.terms[idx]),
               store.terms[idx].spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !cleanedTerm.spoken.isEmpty {
                store.terms[idx].spoken = cleanedTerm.spoken
            }
        }
    }
}

// MARK: - Snippets

struct SnippetsView: View {
    @ObservedObject var store = SnippetsStore.shared
    @State private var selectedID: UUID?

    // MARK: Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider()
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: store.items.count) { _, _ in
            if let id = selectedID, !store.items.contains(where: { $0.id == id }) { selectedID = nil }
        }
    }

    // MARK: Left — list of snippet triggers as cards
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Snippets").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { newSnippet() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless).help("Add snippet")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            if store.items.isEmpty {
                Spacer()
                EmptyState(icon: "text.badge.plus", title: "No snippets yet",
                           message: "Say a short trigger and Verba expands it into longer text, like your address or an email signature.")
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(store.items) { s in
                            snippetRow(s).onTapGesture { selectedID = s.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func snippetRow(_ s: Snippet) -> some View {
        let selected = selectedID == s.id
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: "text.badge.plus").font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.trigger.isEmpty ? "New snippet" : s.trigger)
                    .font(.system(size: 13, weight: .medium)).lineLimit(1)
                    .foregroundStyle(s.trigger.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                if !s.expansion.isEmpty {
                    Text(s.expansion).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { remove(s) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: Right — trigger + expansion editor, or the add prompt
    @ViewBuilder private var detail: some View {
        if let id = selectedID, let idx = store.items.firstIndex(where: { $0.id == id }) {
            editor(idx: idx)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New snippet").font(.system(size: 17, weight: .bold))
                        Text("Create shortcuts: say a short trigger and Verba expands it into longer text, like your address, an email signature, or a boilerplate reply.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    HStack {
                        primaryAddButton("Add snippet") { newSnippet() }
                        Spacer()
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func editor(idx: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "text.badge.plus").font(.system(size: 15)).foregroundStyle(.secondary)
                    Text("Snippet").font(.system(size: 17, weight: .bold))
                    Spacer()
                    Button(role: .destructive) { remove(store.items[idx]) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this snippet")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger").font(.subheadline.weight(.semibold))
                    TextField("Trigger", text: $store.items[idx].trigger).cleanField()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expands to").font(.subheadline.weight(.semibold))
                    TextField("Expands to…", text: $store.items[idx].expansion, axis: .vertical)
                        .cleanField().lineLimit(4...12)
                }
                Text("Say the trigger and Verba inserts the expansion. In AI modes it inserts the block only when you ask for it by intent.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func newSnippet() {
        store.items.append(Snippet(trigger: "", expansion: ""))
        selectedID = store.items.last?.id
    }

    private func remove(_ s: Snippet) {
        let wasSelected = (selectedID == s.id)
        store.items.removeAll { $0.id == s.id }
        if wasSelected { selectedID = nil }
    }
}

// MARK: - Style

struct StyleView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selectedID: UUID?

    // MARK: Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider()
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { if selectedID == nil { selectedID = settings.activeStyleID } }
    }

    // MARK: Left — styles as cards (built-ins + custom), drag-reorderable
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Styles").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { settings.resetStylesToDefaults(); selectedID = settings.activeStyleID } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless).help("Remove all custom styles, keep only Normal")
                Button { let id = addStyle(); selectedID = id } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless).help("Add a new style")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            // A List (NOT List(selection:)) keeps drag-reorder via .onMove while rows render as
            // tap-selected cards — the exemplar card grammar, just inside a reorderable List.
            List {
                ForEach(settings.styles) { st in
                    styleRow(st)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
                .onMove { from, to in settings.styles.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func styleRow(_ st: Style) -> some View {
        let selected = st.id == selectedID
        let active = st.id == settings.activeStyleID
        return HStack(spacing: 9) {
            Image(systemName: "paintbrush").font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16)
            Text(st.name).font(.system(size: 13, weight: selected ? .semibold : .medium)).lineLimit(1)
            Spacer(minLength: 6)
            if active {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                    Text("Active").font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedID = st.id }
        }
    }

    // MARK: Right — the style prompt editor for the selected style
    @ViewBuilder private var detail: some View {
        if let id = selectedID, settings.styles.contains(where: { $0.id == id }) {
            editor(id: id)
        } else {
            EmptyState(icon: "paintbrush", title: "Select a style",
                       message: "Each style is a reusable tone/format layer added on top of your mode. Switch styles anytime with Fn + [ and Fn + ], or from the menu bar.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func index(of id: UUID) -> Int? { settings.styles.firstIndex { $0.id == id } }

    private func editor(id: UUID) -> some View {
        let st = settings.styles.first { $0.id == id }
        let isNormal = (st?.builtin ?? false) && (st?.name == "Normal")
        let nameB = Binding(get: { settings.styles.first { $0.id == id }?.name ?? "" },
                            set: { v in if let i = index(of: id) { settings.styles[i].name = v } })
        let promptB = Binding(get: { settings.styles.first { $0.id == id }?.prompt ?? "" },
                              set: { v in if let i = index(of: id) { settings.styles[i].prompt = v } })
        let isActive = settings.activeStyleID == id

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240).disabled(isNormal)
                    TagChip(icon: isActive ? "checkmark.circle.fill" : "circle",
                            label: isActive ? "Active" : "Make active",
                            selected: isActive) { settings.activeStyleID = id }
                        .disabled(isActive)
                    Spacer()
                    if !isNormal {
                        Button(role: .destructive) { deleteStyle(id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this style")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Style prompt").font(.subheadline.weight(.semibold))
                        Text("layered on top of the mode when reprompting").font(.caption).foregroundStyle(.secondary)
                    }
                    if isNormal {
                        Text("“Normal” is neutral: it adds nothing, so your modes behave exactly as their own prompts define. Create a new style to add a tone or format layer.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    } else {
                        TextEditor(text: promptB)
                            .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                            .frame(minHeight: 200).padding(12)
                            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("e.g. “British English, no exclamation marks, sign off with ‘, G’.” Applies on top of every mode except Flow (raw dictation).")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @discardableResult
    private func addStyle() -> UUID {
        let st = Style(name: "New style", prompt: "")
        settings.styles.append(st)
        return st.id
    }

    private func deleteStyle(_ id: UUID) {
        selectedID = nil
        settings.styles.removeAll { $0.id == id }
        if settings.activeStyleID == id, let first = settings.styles.first { settings.activeStyleID = first.id }
    }
}

// MARK: - Transforms

struct TransformsView: View {
    @ObservedObject var store = TransformsStore.shared
    @State private var errorMessage: String?
    @State private var selectedID: UUID?

    // MARK: Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider()
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: store.items.count) { _, _ in
            if let id = selectedID, !store.items.contains(where: { $0.id == id }) { selectedID = nil }
        }
    }

    // MARK: Left — transforms as cards
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transforms").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { newTransform() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless).help("Add transform")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            if store.items.isEmpty {
                Spacer()
                EmptyState(icon: "arrow.triangle.2.circlepath", title: "No transforms yet",
                           message: "Reusable text actions like “Make it formal” or “Translate to English”. Select text anywhere, say the shortcut, and Verba transforms the selection.")
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(store.items) { t in
                            transformRow(t).onTapGesture { selectedID = t.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func transformRow(_ t: Transform) -> some View {
        let selected = selectedID == t.id
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(t.name.isEmpty ? "New shortcut" : t.name)
                    .font(.system(size: 13, weight: .medium)).lineLimit(1)
                    .foregroundStyle(t.name.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                if !t.prompt.isEmpty {
                    Text(t.prompt).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { remove(t) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: Right — Verbal Shortcut + instruction editor, or the add prompt
    @ViewBuilder private var detail: some View {
        if let id = selectedID, let idx = store.items.firstIndex(where: { $0.id == id }) {
            editor(idx: idx)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New transform").font(.system(size: 17, weight: .bold))
                        Text("Actions that run on text you’ve selected. Highlight text in any app, speak the Verbal Shortcut (e.g. “fix grammar”), and Verba runs it on your selection and replaces it. Works in every mode.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    HStack {
                        primaryAddButton("Add transform") { newTransform() }
                        Spacer()
                    }
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func editor(idx: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 15)).foregroundStyle(.secondary)
                    Text("Transform").font(.system(size: 17, weight: .bold))
                    Spacer()
                    Button(role: .destructive) { remove(store.items[idx]) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this transform")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verbal Shortcut").font(.subheadline.weight(.semibold))
                    TextField("Verbal Shortcut", text: $store.items[idx].name).cleanField()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instruction").font(.subheadline.weight(.semibold))
                    TextField("Prompt", text: $store.items[idx].prompt, axis: .vertical)
                        .cleanField().lineLimit(4...12)
                }
                Text("Select text anywhere, say the Verbal Shortcut, and Verba runs this instruction on your selection and replaces it.")
                    .font(.caption).foregroundStyle(.secondary)
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout).foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func newTransform() {
        store.items.append(Transform(name: "New shortcut", prompt: "Rewrite the text…"))
        selectedID = store.items.last?.id
    }

    private func remove(_ t: Transform) {
        let wasSelected = (selectedID == t.id)
        store.items.removeAll { $0.id == t.id }
        if wasSelected { selectedID = nil }
    }
}

// MARK: - Scratchpad

struct ScratchpadView: View {
    @ObservedObject var pad = Scratchpad.shared
    var body: some View {
        // Single full-bleed text area (not split): header + toolbar pinned, the pad fills the rest —
        // aligned to the exemplar's detail-pane header/padding grammar.
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Scratchpad").font(.system(size: 17, weight: .bold))
                Spacer(minLength: 8)
                CopyButton(text: pad.text, title: "Copy")
                Button(role: .destructive) { pad.text = "" } label: { Label("Clear", systemImage: "trash") }
                    .buttonStyle(.borderless)
            }
            TextEditor(text: $pad.text)
                .font(.system(size: 15)).scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24).padding(.vertical, 20)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if pad.text.isEmpty {
                        EmptyState(icon: "note.text", title: "Empty scratchpad",
                                   message: "A free-form space for text. Dictate into it, paste notes, edit, and copy the result.")
                            .allowsHitTesting(false)
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
    }
}

// MARK: - Empty state (icon + title + explanation), shown when a section has no content yet.

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40, weight: .light)).foregroundStyle(.tertiary)
            Text(title).font(.headline)
            Text(message)
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

// MARK: - Small shared controls

/// Quiet secondary add affordance: soft-fill capsule with a plus.
private func addButton(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 5) {
            Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
            Text(title).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6.5)
        .foregroundStyle(.primary.opacity(0.75))
        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
        .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
}

/// Primary add affordance: Liquid Glass prominent button.
private func primaryAddButton(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) { Label(title, systemImage: "plus") }
        .glassProminentButton()
}

/// Sidebar filter chip — the exemplar (NotesView) chip grammar: monochrome capsule, soft neutral
/// fill, bold label + quiet border when selected. Shared by the two-pane manager sidebars.
@ViewBuilder
func paneChip(label: String, icon: String?, on: Bool, action: @escaping () -> Void) -> some View {
    Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
    } label: {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .semibold)) }
            Text(label).font(.system(size: 12, weight: on ? .semibold : .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6.5)
        .foregroundStyle(on ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
        .background(
            Capsule(style: .continuous)
                .fill(on ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
        )
        .overlay(Capsule(style: .continuous).strokeBorder(on ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
}
