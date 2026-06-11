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
                        // Their badges
                        Text(L("Badges earned")).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary).textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: cols, spacing: 10) {
                            ForEach(Gamification.all) { a in
                                badge(a, earned: p.badges.contains(a.id))
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

    private func headStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 18, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func badge(_ a: Achievement, earned: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(earned ? a.tier.color.opacity(0.18) : Color.primary.opacity(0.05)).frame(width: 44, height: 44)
                Image(systemName: a.icon).font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(earned ? AnyShapeStyle(a.tier.color) : AnyShapeStyle(.tertiary))
            }
            Text(a.title).font(.system(size: 11, weight: .medium))
                .foregroundStyle(earned ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 86).padding(8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(earned ? 0.05 : 0.02)))
        .opacity(earned ? 1 : 0.55)
    }
}
