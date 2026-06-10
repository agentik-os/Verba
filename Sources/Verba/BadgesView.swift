import SwiftUI

// MARK: - Achievements / progression view
//
// The gamification surface: your level + XP ring, today's goal ring, your weekly league, and the
// full achievement grid (earned vs locked). Self-contained; reads Gamification.shared + Stats.

struct BadgesView: View {
    @ObservedObject private var game = Gamification.shared
    @ObservedObject private var stats = Stats.shared

    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Achievements").font(.system(size: 17, weight: .bold))
                    Spacer()
                    let n = game.unlocked.count
                    Text("\(n) / \(Gamification.all.count)").font(.callout).foregroundStyle(.secondary).monospacedDigit()
                }
                .padding(.horizontal, 28).padding(.top, 28)

                // Level + daily goal + league row.
                HStack(spacing: 14) {
                    levelCard
                    goalCard
                    leagueCard
                }
                .padding(.horizontal, 28)

                Text("Badges").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    .textCase(.uppercase).padding(.horizontal, 28)

                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Gamification.all) { a in badge(a) }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }

    // MARK: cards

    private var levelCard: some View {
        let info = game.levelInfo
        return VStack(spacing: 10) {
            ProgressRing(progress: info.progress, tint: .primary, lineWidth: 7) {
                VStack(spacing: 0) {
                    Text("LVL").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Text("\(info.level)").font(.system(size: 26, weight: .bold)).monospacedDigit()
                }
            }
            .frame(width: 78, height: 78)
            Text(info.title).font(.subheadline.weight(.semibold))
            Text("\(info.xpInLevel) / \(info.xpForNext) XP").font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goalCard: some View {
        VStack(spacing: 10) {
            ProgressRing(progress: game.dailyProgress, tint: .orange, lineWidth: 7) {
                VStack(spacing: 0) {
                    Image(systemName: game.dailyProgress >= 1 ? "checkmark" : "sun.max.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(game.dailyProgress >= 1 ? AnyShapeStyle(.green) : AnyShapeStyle(.orange))
                }
            }
            .frame(width: 78, height: 78)
            Text("Today's goal").font(.subheadline.weight(.semibold))
            Text("\(game.todayWords) / \(game.dailyGoal) words").font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var leagueCard: some View {
        let lg = game.league
        return VStack(spacing: 10) {
            ZStack {
                Circle().fill(lg.color.opacity(0.16)).frame(width: 78, height: 78)
                Image(systemName: lg.icon).font(.system(size: 30, weight: .semibold)).foregroundStyle(lg.color)
            }
            Text("\(lg.name) league").font(.subheadline.weight(.semibold))
            if let next = lg.next {
                Text("\(max(0, next.floor - stats.wordsThisWeek)) words to \(next.name)")
                    .font(.caption2).foregroundStyle(.tertiary).monospacedDigit().multilineTextAlignment(.center)
            } else {
                Text("top tier").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
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
        .help(earned ? "Unlocked" : "Locked")
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
