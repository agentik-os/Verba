import SwiftUI

// MARK: - Achievements / progression view
//
// The gamification surface: your level + XP ring, today's goal ring, your weekly league, and the
// full achievement grid (earned vs locked). Self-contained; reads Gamification.shared + Stats.

struct BadgesView: View {
    @ObservedObject private var game = Gamification.shared
    @ObservedObject private var stats = Stats.shared
    @StateObject private var board = LeaderboardModel()

    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Text(L("Achievements")).font(.system(size: 17, weight: .bold))
                    Spacer()
                    let n = game.unlocked.count
                    Text("\(n) / \(Gamification.all.count)").font(.callout).foregroundStyle(.secondary).monospacedDigit()
                    Button { shareStats() } label: { Label(L("Share"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderless).help(L("Share a card of your stats"))
                }
                .padding(.horizontal, 28).padding(.top, 28)

                // Level + daily goal + league row.
                HStack(spacing: 14) {
                    levelCard
                    goalCard
                    leagueCard
                }
                .padding(.horizontal, 28)

                // Goals + next-up + records.
                HStack(alignment: .top, spacing: 14) {
                    weeklyCard
                    nextUpCard
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

                recordsCard.padding(.horizontal, 28)

                standingCard.padding(.horizontal, 28)

                Text(L("Badges")).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    .textCase(.uppercase).padding(.horizontal, 28)

                // Grouped by category, in a logical order (volume → consistency → speed → features).
                ForEach(Gamification.groups) { group in
                    let earnedIn = group.items.filter { game.unlocked.contains($0.id) }.count
                    let isExplore = group.id == "Explore Verba"
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: group.icon).font(.system(size: 13))
                                .foregroundStyle(isExplore ? AnyShapeStyle(VerbaAppearance.shared.accentColor) : AnyShapeStyle(.secondary)).frame(width: 18)
                            Text(L(group.id)).font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("\(earnedIn) / \(group.items.count)").font(.caption).foregroundStyle(.tertiary).monospacedDigit()
                        }
                        if isExplore {
                            // This category doubles as a feature tour — a gamified way to learn Verba.
                            Text(L("Try each feature and shortcut once — your guided tour of everything Verba can do."))
                                .font(.caption).foregroundStyle(.secondary).padding(.leading, 26)
                        }
                    }
                    .padding(.horizontal, 28).padding(.top, isExplore ? 4 : 10)
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(group.items) { a in badge(a) }
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 8)
                Spacer(minLength: 20)
            }
        }
        .onAppear { Gamification.shared.evaluate(); board.load() }
    }

    // MARK: Share card

    @MainActor private func shareStats() {
        let myRank = ranked.firstIndex(where: { $0.me == true }).map { $0 + 1 }
        let icons = Gamification.all.filter { game.unlocked.contains($0.id) }
            .sorted { $0.tier.rawValue > $1.tier.rawValue }.map { $0.icon }
        let card = ShareStatsCard(
            level: game.levelInfo.level, title: game.levelInfo.title,
            words: stats.totalWords, streak: stats.streak, avgWPM: stats.avgWPM,
            rank: myRank, totalPlayers: ranked.count,
            badges: game.unlocked.count, totalBadges: Gamification.all.count,
            topIcons: icons, accent: VerbaAppearance.shared.accentColor == .primary ? .yellow : VerbaAppearance.shared.accentColor)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("verba-stats.png")
        try? png.write(to: url)
        let picker = NSSharingServicePicker(items: [url])
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }

    // MARK: Wave 3 — social standing (rank + rivals) from the leaderboard

    private var ranked: [LeaderEntry] { board.entries.sorted { $0.words > $1.words } }

    @ViewBuilder private var standingCard: some View {
        let rows = ranked
        if let myIdx = rows.firstIndex(where: { $0.me == true }) {
            let ahead = myIdx > 0 ? rows[myIdx - 1] : nil
            let behind = myIdx < rows.count - 1 ? rows[myIdx + 1] : nil
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill").foregroundStyle(.secondary)
                    Text(L("Your standing")).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("#\(myIdx + 1) \(L("of")) \(rows.count)").font(.callout.weight(.bold)).monospacedDigit()
                }
                if let a = ahead {
                    rivalRow(icon: "arrow.up.right", tint: .orange,
                             text: "\(L("Catch")) \(a.alias)", detail: "\(Int(a.words - rows[myIdx].words)) \(L("words ahead"))")
                } else {
                    rivalRow(icon: "crown.fill", tint: .yellow, text: L("You're #1"), detail: L("everyone is chasing you"))
                }
                if let b = behind {
                    rivalRow(icon: "arrow.down.right", tint: .green,
                             text: "\(b.alias) \(L("is behind"))", detail: "\(Int(rows[myIdx].words - b.words)) \(L("words back"))")
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func rivalRow(icon: String, tint: Color, text: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 18)
            Text(text).font(.callout)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    // MARK: extra cards

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 13)).foregroundStyle(.secondary)
                Text(L("Your goals")).font(.subheadline.weight(.semibold))
                Spacer()
            }
            barRow(L("Today"), value: game.todayWords, goal: game.dailyGoal, progress: game.dailyProgress)
            barRow(L("This week"), value: stats.wordsThisWeek, goal: game.weeklyGoal, progress: game.weeklyProgress)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// A labelled monochrome progress row (matches the B&W design; the bar fills with .primary).
    private func barRow(_ label: String, value: Int, goal: Int, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text("\(value) / \(goal)").font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
            }
            ProgressBar(progress: progress, tint: progress >= 1 ? .primary : Color.primary.opacity(0.55))
        }
    }

    private var nextUpCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "target").font(.system(size: 13)).foregroundStyle(.secondary)
                Text(L("Next up")).font(.subheadline.weight(.semibold))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 9) {
                if let m = game.nextWordMilestone {
                    nextRow("text.word.spacing", "\(m.remaining.formatted()) \(L("words to")) \(compact(m.target))")
                }
                if let st = game.nextStreakMilestone {
                    nextRow("flame.fill", "\(st.remaining) \(st.remaining == 1 ? L("day") : L("days")) \(L("to a")) \(st.target) \(L("day streak"))")
                }
                let info = game.levelInfo
                nextRow("sparkles", "\(max(0, info.xpForNext - info.xpInLevel)) \(L("XP to Level")) \(info.level + 1)")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func nextRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 16)
            Text(text).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            Spacer(minLength: 0)
        }
    }

    private var recordsCard: some View {
        HStack(spacing: 0) {
            record("\(compact(stats.totalWords))", L("total words"), "text.word.spacing")
            Divider().frame(height: 38).opacity(0.3)
            record("\(stats.bestDayWords)", L("best day"), "trophy")
            Divider().frame(height: 38).opacity(0.3)
            record("\(stats.avgWPM)", L("avg wpm"), "gauge.with.dots.needle.67percent")
            Divider().frame(height: 38).opacity(0.3)
            record("\(stats.totalCount)", L("dictations"), "waveform")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func record(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 20, weight: .bold)).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }

    // MARK: cards

    private var levelCard: some View {
        let info = game.levelInfo
        return VStack(spacing: 10) {
            ProgressRing(progress: info.progress, tint: .primary, lineWidth: 7) {
                VStack(spacing: 0) {
                    Text(L("LVL")).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Text("\(info.level)").font(.system(size: 26, weight: .bold)).monospacedDigit()
                }
            }
            .frame(width: 78, height: 78)
            Text("\(info.title) · \(L("Lvl")) \(info.level)/\(Gamification.maxLevel)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(info.xpInLevel) / \(info.xpForNext) XP").font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .frame(maxWidth: .infinity).padding(.top, 24).padding(.bottom, 16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goalCard: some View {
        VStack(spacing: 10) {
            ProgressRing(progress: game.dailyProgress, tint: .primary, lineWidth: 7) {
                VStack(spacing: 0) {
                    Image(systemName: game.dailyProgress >= 1 ? "checkmark" : "sun.max.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(game.dailyProgress >= 1 ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                }
            }
            .frame(width: 78, height: 78)
            Text(L("Today's goal")).font(.subheadline.weight(.semibold))
            Text("\(game.todayWords) / \(game.dailyGoal) \(L("words"))").font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .frame(maxWidth: .infinity).padding(.top, 24).padding(.bottom, 16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var leagueCard: some View {
        let lg = game.league
        return VStack(spacing: 10) {
            ZStack {
                Circle().fill(lg.color.opacity(0.16)).frame(width: 78, height: 78)
                Image(systemName: lg.icon).font(.system(size: 30, weight: .semibold)).foregroundStyle(lg.color)
            }
            Text("\(lg.name) \(L("league"))").font(.subheadline.weight(.semibold))
            if let next = lg.next {
                Text("\(max(0, next.floor - stats.wordsThisWeek)) \(L("words to")) \(next.name)")
                    .font(.caption2).foregroundStyle(.tertiary).monospacedDigit().multilineTextAlignment(.center)
            } else {
                Text(L("top tier")).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 24).padding(.bottom, 16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func badge(_ a: Achievement) -> some View {
        let earned = game.unlocked.contains(a.id)
        return VStack(spacing: 8) {
            ZStack {
                Circle().fill(earned ? a.tier.color.opacity(0.18) : Color.primary.opacity(0.05))
                    .frame(width: 52, height: 52)
                Image(systemName: a.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(earned ? AnyShapeStyle(a.tier.color) : AnyShapeStyle(.tertiary))
            }
            Text(a.title).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(earned ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .multilineTextAlignment(.center).lineLimit(2)
            Text(a.blurb).font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center).lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 128).padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.primary.opacity(earned ? 0.05 : 0.02)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(earned ? a.tier.color.opacity(0.3) : Color.hairlineTint, lineWidth: 1))
        .opacity(earned ? 1 : 0.7)
        .help(earned ? L("Unlocked") : L("Locked"))
    }
}

/// A simple rounded progress bar.
struct ProgressBar: View {
    var progress: Double
    var tint: Color
    var body: some View {
        // No GeometryReader: the fill is the full-width track scaled horizontally to `progress`.
        // (A GeometryReader could resolve to width 0 in some card layouts, leaving the bar invisible.)
        let p = max(0.04, min(1.0, progress))   // always show a sliver so the bar never reads as empty
        Capsule().fill(Color.primary.opacity(0.14))
            .frame(height: 9)
            .overlay(alignment: .leading) {
                Capsule().fill(tint)
                    .frame(height: 9)
                    .scaleEffect(x: p, anchor: .leading)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
            .clipShape(Capsule())
    }
}

/// A circular progress ring with arbitrary center content.
struct ProgressRing<Content: View>: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 7
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle().trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            content()
        }
    }
}
