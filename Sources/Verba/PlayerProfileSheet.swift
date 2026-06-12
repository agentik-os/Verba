import SwiftUI

/// Tapping a leaderboard row opens this: another player's public gamification profile, fetched by
/// alias (level, league, and the badges they have earned vs the full set).
struct PlayerProfileSheet: View {
    let alias: String
    var isMe: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var profile: Gamification.OtherProfile?
    @State private var loading = true

    private let cols = [GridItem(.adaptive(minimum: 130), spacing: 10)]
    /// MY own earned badges — used to mark, on someone else's profile, which of their (and the
    /// full set's) badges I also hold, so the grid doubles as a you-vs-them comparison.
    private let mine = Gamification.shared.unlocked

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(alias + (isMe ? L("  (you)") : "")).font(.title3.weight(.bold)).lineLimit(1)
                Spacer()
                Button(L("Done")) { dismiss() }.dialogPrimary()
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let p = profile {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header stats
                        HStack(spacing: 12) {
                            headStat(L("Lvl ") + "\(p.level)", L("of ") + "\(Gamification.maxLevel)", "rosette")
                            headStat(p.league, L("league"), "shield.fill")
                            headStat("\(p.badges.count)", L("of ") + "\(Gamification.all.count) " + L("badges"), "seal.fill")
                        }
                        // Their analytics — the same Insights the owner sees (when published).
                        if let st = p.stats { statsSection(st) }
                        // You-vs-them comparison (only when looking at someone else).
                        if !isMe { comparisonStrip(theirs: p.badges) }
                        // Their badges
                        Text(L("Badges earned")).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary).textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: cols, spacing: 10) {
                            ForEach(Gamification.all) { a in
                                badge(a, earned: p.badges.contains(a.id), mineHas: mine.contains(a.id))
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark").font(.system(size: 34)).foregroundStyle(.secondary)
                    Text("\(alias) " + L("hasn't shared a profile yet.")).font(.callout).foregroundStyle(.secondary)
                    Text(L("Profiles appear once they dictate on the latest version.")).font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            }
        }
        .frame(width: 520, height: 560)
        .onAppear {
            Gamification.shared.fetchProfile(alias: alias) { p in
                profile = p; loading = false
            }
        }
    }

    // MARK: - Social Insights (mirror of the owner's analytics)

    @ViewBuilder private func statsSection(_ st: Gamification.ProfileStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Insights")).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary).textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                kpi("\(st.wordsToday.formatted())", L("words today"), "text.word.spacing")
                kpi("\(st.streak)", L("day streak"), "flame.fill")
                kpi("\(st.wordsThisWeek.formatted())", L("words this week"), "calendar")
                kpi("\(st.totalWords.formatted())", L("total words"), "infinity")
                kpi("\(st.dictations.formatted())", L("dictations"), "mic.fill")
                kpi("\(st.wpm)", L("words / min"), "gauge.with.dots.needle.67percent")
                kpi(fmtMinutes(st.timeSavedMinutes), L("time saved"), "clock.arrow.circlepath")
                kpi("\(st.bestDayWords.formatted())", L("best day ever"), "trophy.fill")
                kpi("\(st.longestStreak)", L("longest streak"), "flame")
            }
        }
    }

    private func kpi(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 19, weight: .bold)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
    }

    private func fmtMinutes(_ m: Int) -> String {
        if m >= 60 { let h = m / 60, mm = m % 60; return mm > 0 ? "\(h)h \(mm)m" : "\(h)h" }
        return "\(m)m"
    }

    private func headStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 18, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func badge(_ a: Achievement, earned: Bool, mineHas: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(earned ? a.tier.color.opacity(0.18) : Color.primary.opacity(0.05)).frame(width: 44, height: 44)
                Image(systemName: a.icon).font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(earned ? AnyShapeStyle(a.tier.color) : AnyShapeStyle(.tertiary))
            }
            Text(a.title).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(earned ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .multilineTextAlignment(.center).lineLimit(2)
            // What the badge is for — so the name alone isn't a mystery (shown for every badge,
            // earned or not, so you also see what's left to chase).
            Text(a.blurb).font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .top).padding(8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(earned ? 0.05 : 0.02)))
        .opacity(earned ? 1 : 0.55)
        // "You have this too" mark — overlaid AFTER the opacity so it stays crisp even on a badge
        // the other player hasn't earned (that's exactly the case where I'm ahead of them).
        .overlay(alignment: .topTrailing) {
            if mineHas && !isMe { youMark.padding(6) }
        }
        .help(mineHas && !isMe ? L("You've earned this one too") : "")
    }

    /// High-contrast, theme-adaptive marker: a primary-filled disc with an inverted checkmark and a
    /// background ring, so it reads clearly over any tier color or a dimmed (unearned) badge.
    private var youMark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .frame(width: 16, height: 16)
            .background(Circle().fill(Color.primary))
            .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
    }

    // MARK: - You-vs-them badge comparison

    private func comparisonStrip(theirs: Set<String>) -> some View {
        let shared = theirs.intersection(mine).count
        let theyLead = theirs.subtracting(mine).count
        let youLead = mine.subtracting(theirs).count
        return VStack(spacing: 9) {
            HStack(spacing: 8) {
                cmpStat("\(shared)", L("you both have"), "checkmark.seal.fill")
                cmpStat("\(theyLead)", L("they have, you don't"), "arrow.down.right.circle")
                cmpStat("\(youLead)", L("you have, they don't"), "arrow.up.right.circle")
            }
            HStack(spacing: 6) {
                youMark
                Text(L("Badges with this mark are ones you've earned too — so you can see at a glance where you're ahead or behind."))
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
    }

    private func cmpStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 17, weight: .bold)).monospacedDigit()
            Text(label).font(.system(size: 9.5)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 11).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
    }
}
