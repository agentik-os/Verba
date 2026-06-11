import SwiftUI
import AppKit

// MARK: - Shareable stats card
//
// A fixed-size, always-dark card rendered to an image for sharing on socials. Self-contained
// (all values passed in) so ImageRenderer can rasterize it off-screen.

struct ShareStatsCard: View {
    let level: Int
    let title: String
    let words: Int
    let streak: Int
    let avgWPM: Int
    let rank: Int?
    let totalPlayers: Int
    let badges: Int
    let totalBadges: Int
    let topIcons: [String]
    let accent: Color

    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.white)
                    .frame(width: 34, height: 34)
                    .overlay(Image(systemName: "mic.fill").foregroundStyle(.black).font(.system(size: 16, weight: .bold)))
                Text("Verba").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("verba.run").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.5))
            }

            Spacer(minLength: 30)

            // Level
            Text("LEVEL \(level)").font(.system(size: 15, weight: .heavy)).foregroundStyle(accent).tracking(2)
            Text(title).font(.system(size: 46, weight: .bold)).foregroundStyle(.white)
            Text("My voice, in numbers").font(.system(size: 16)).foregroundStyle(.white.opacity(0.55))

            Spacer(minLength: 30)

            // Stats grid
            HStack(spacing: 12) {
                stat(compact(words), "words")
                stat("\(streak)", "day streak")
                stat(rank != nil ? "#\(rank!)" : "\(avgWPM)", rank != nil ? "of \(totalPlayers)" : "avg wpm")
                stat("\(badges)", "badges")
            }

            Spacer(minLength: 26)

            // Top badge icons
            HStack(spacing: 10) {
                ForEach(Array(topIcons.prefix(6).enumerated()), id: \.offset) { _, ic in
                    ZStack {
                        Circle().fill(.white.opacity(0.08)).frame(width: 44, height: 44)
                        Image(systemName: ic).font(.system(size: 19, weight: .semibold)).foregroundStyle(.white)
                    }
                }
                Spacer()
                Text("\(badges)/\(totalBadges)").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(36)
        .frame(width: 560, height: 720)
        .background(
            ZStack {
                LinearGradient(colors: [Color(red: 0.07, green: 0.07, blue: 0.09), .black], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [accent.opacity(0.28), .clear], center: .topTrailing, startRadius: 10, endRadius: 520)
            }
        )
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(size: 30, weight: .bold)).foregroundStyle(.white).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
    }
}
