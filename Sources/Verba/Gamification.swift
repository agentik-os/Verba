import SwiftUI
import Combine

// MARK: - Gamification engine
//
// Turns raw dictation Stats into a game: XP + levels, unlockable achievements, a daily goal,
// streak milestones, and a weekly league tier (the social ladder on the leaderboard). Everything
// is DERIVED from Stats (+ a few behavior flags), so it stays correct across devices once stats
// sync. Newly-earned things are enqueued as `Celebration`s for the UI to confetti.

// MARK: Behavior flags (things Stats alone can't see: which modes were used, etc.)

enum GameFlag: String, CaseIterable {
    case usedTranslate, usedContext, usedCoding, usedIntent, usedPolish, usedFlow
    case usedActionMode, usedVoiceNote, usedVoiceTodo, usedTransform
    case nightOwl        // dictated between 00:00 and 04:00
    case earlyBird       // dictated between 05:00 and 07:00
}

// MARK: Level model

struct LevelInfo {
    let level: Int
    let title: String
    let xpInLevel: Int
    let xpForNext: Int
    var progress: Double { xpForNext > 0 ? min(1, Double(xpInLevel) / Double(xpForNext)) : 1 }
}

// MARK: Achievement

struct Achievement: Identifiable {
    enum Tier: Int { case bronze, silver, gold, platinum
        var color: Color { [Color.orange, .gray, .yellow, .purple][rawValue] }
        var label: String { ["Bronze", "Silver", "Gold", "Platinum"][rawValue] }
    }
    let id: String
    let title: String
    let blurb: String
    let icon: String
    let tier: Tier
    /// Earned when this returns true, evaluated against current Stats + flags.
    let earned: (Stats, Set<GameFlag>) -> Bool
}

// MARK: Celebration (consumed by the UI to show confetti / a toast)

struct Celebration: Identifiable, Equatable {
    enum Kind: Equatable { case achievement(String), levelUp(Int), milestone(String) }
    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    static func == (a: Celebration, b: Celebration) -> Bool { a.id == b.id }
}

// MARK: Weekly league

enum League: Int, CaseIterable {
    case bronze, silver, gold, platinum, diamond
    var name: String { ["Bronze", "Silver", "Gold", "Platinum", "Diamond"][rawValue] }
    var icon: String { ["shield.lefthalf.filled", "shield.fill", "rosette", "crown.fill", "diamond.fill"][rawValue] }
    var color: Color { [Color.orange, .gray, .yellow, .teal, .cyan][rawValue] }
    /// Weekly-words thresholds to enter each league.
    var floor: Int { [0, 1500, 5000, 15000, 40000][rawValue] }
    static func tier(forWeeklyWords w: Int) -> League {
        allCases.last { w >= $0.floor } ?? .bronze
    }
    var next: League? { League(rawValue: rawValue + 1) }
}

// MARK: - The store

final class Gamification: ObservableObject {
    static let shared = Gamification()

    @Published private(set) var unlocked: Set<String>
    @Published var pending: [Celebration] = []      // UI pops these to celebrate
    @Published var dailyGoal: Int { didSet { d.set(dailyGoal, forKey: kGoal) } }

    private let d = UserDefaults.standard
    private let kUnlocked = "verba.game.unlocked"
    private let kGoal = "verba.game.dailyGoal"
    private let kLevel = "verba.game.seenLevel"
    private let kFlags = "verba.game.flags"
    private let kBackfilled = "verba.game.backfilled"

    private var flags: Set<GameFlag>

    private init() {
        unlocked = Set(d.stringArray(forKey: kUnlocked) ?? [])
        dailyGoal = d.object(forKey: kGoal) as? Int ?? 400
        flags = Set((d.stringArray(forKey: kFlags) ?? []).compactMap(GameFlag.init))
    }

    // MARK: XP + level

    /// XP rewards depth + consistency: every word, a bonus per finished dictation, a fat streak bonus.
    var xp: Int {
        let s = Stats.shared
        return s.totalWords / 4 + s.totalCount * 3 + s.streak * 40
    }

    /// Level curve: each level costs more (quadratic), so leveling stays meaningful.
    func level(for xp: Int) -> LevelInfo {
        // xp needed to REACH level n (n>=1) = 100 * (n-1)^2
        func threshold(_ n: Int) -> Int { 100 * (n - 1) * (n - 1) }
        var n = 1
        while threshold(n + 1) <= xp { n += 1 }
        let base = threshold(n), next = threshold(n + 1)
        return LevelInfo(level: n, title: Gamification.title(for: n),
                         xpInLevel: xp - base, xpForNext: next - base)
    }
    var levelInfo: LevelInfo { level(for: xp) }

    static func title(for level: Int) -> String {
        switch level {
        case ..<3: return "Newcomer"
        case 3..<6: return "Speaker"
        case 6..<10: return "Orator"
        case 10..<15: return "Wordsmith"
        case 15..<22: return "Virtuoso"
        case 22..<30: return "Maestro"
        default: return "Legend"
        }
    }

    // MARK: Daily goal

    var todayWords: Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return Stats.shared.days[f.string(from: Date())]?.words ?? 0
    }
    var dailyProgress: Double { dailyGoal > 0 ? min(1, Double(todayWords) / Double(dailyGoal)) : 0 }

    /// Weekly goal = 5x the daily goal (a working week of dictation), progress from this week's words.
    var weeklyGoal: Int { dailyGoal * 5 }
    var weeklyProgress: Double { weeklyGoal > 0 ? min(1, Double(Stats.shared.wordsThisWeek) / Double(weeklyGoal)) : 0 }

    /// The next word milestone above the user's total, and how far it is (for a "next up" card).
    var nextWordMilestone: (target: Int, remaining: Int)? {
        let marks = [1000, 5000, 10000, 50000, 100000, 250000, 500000, 1000000]
        let total = Stats.shared.totalWords
        guard let next = marks.first(where: { $0 > total }) else { return nil }
        return (target: next, remaining: next - total)
    }
    /// The next streak milestone above the current streak.
    var nextStreakMilestone: (target: Int, remaining: Int)? {
        let marks = [3, 7, 14, 30, 100, 365]
        let st = Stats.shared.streak
        guard let next = marks.first(where: { $0 > st }) else { return nil }
        return (target: next, remaining: next - st)
    }

    // MARK: League

    var league: League { League.tier(forWeeklyWords: Stats.shared.wordsThisWeek) }

    // MARK: Flags + evaluation

    func flag(_ f: GameFlag) {
        guard !flags.contains(f) else { return }
        flags.insert(f)
        d.set(flags.map(\.rawValue), forKey: kFlags)
        evaluate()
    }

    /// Note the current time-of-day bucket (call on each dictation) then evaluate.
    func noteDictationTime(_ date: Date = Date()) {
        let h = Calendar.current.component(.hour, from: date)
        if h < 4 { flag(.nightOwl) } else if (5...7).contains(h) { flag(.earlyBird) } else { evaluate() }
    }

    /// Re-check every achievement + level-up against the current Stats; enqueue anything new.
    /// FIRST run (backfill): existing users get every achievement they've ALREADY earned from
    /// their accumulated stats, granted silently (no confetti flood), their level baseline set to
    /// their real level, and a single welcome card summarizing what they walked in with.
    func evaluate() {
        let s = Stats.shared
        DispatchQueue.main.async {
            let firstRun = !self.d.bool(forKey: self.kBackfilled)
            var newlyEarned = 0
            for a in Gamification.all where !self.unlocked.contains(a.id) && a.earned(s, self.flags) {
                self.unlocked.insert(a.id)
                newlyEarned += 1
                if !firstRun {
                    self.pending.append(Celebration(
                        kind: .achievement(a.id), title: a.title, subtitle: a.blurb,
                        icon: a.icon, tint: a.tier.color))
                }
            }
            self.d.set(Array(self.unlocked), forKey: self.kUnlocked)
            let lvl = self.levelInfo.level
            if firstRun {
                // Set the level baseline to the user's real level so we don't fire a fake level-up,
                // then welcome them with one card that shows the profile they already built.
                self.d.set(lvl, forKey: self.kLevel)
                self.d.set(true, forKey: self.kBackfilled)
                if newlyEarned > 0 {
                    self.pending.append(Celebration(
                        kind: .milestone("welcome"),
                        title: "Welcome to Achievements",
                        subtitle: "You walk in at Level \(lvl) with \(newlyEarned) badge\(newlyEarned == 1 ? "" : "s") already earned. Keep going.",
                        icon: "rosette", tint: .yellow))
                }
                return
            }
            // Level-up (normal path)
            let seen = self.d.object(forKey: self.kLevel) as? Int ?? 1
            if lvl > seen {
                self.d.set(lvl, forKey: self.kLevel)
                self.pending.append(Celebration(
                    kind: .levelUp(lvl), title: "Level \(lvl)", subtitle: Gamification.title(for: lvl),
                    icon: "sparkles", tint: .yellow))
            }
        }
    }

    func consume() -> Celebration? {
        guard !pending.isEmpty else { return nil }
        return pending.removeFirst()
    }

    /// Map a built-in mode name to its usage flag (defaults to Flow for custom/unknown).
    static func flagForMode(_ name: String) -> GameFlag {
        switch name {
        case "Translate": return .usedTranslate
        case "Context":   return .usedContext
        case "Coding":    return .usedCoding
        case "Intent":    return .usedIntent
        case "Polish":    return .usedPolish
        default:          return .usedFlow
        }
    }

    // MARK: - The catalog

    // Split into sub-arrays so the Swift type-checker doesn't choke on one huge literal.
    static let all: [Achievement] = volume + streaks + craft + modes + misc + bonus

    private static let bonus: [Achievement] = [
        .init(id: "w5k", title: "Storyteller", blurb: "5,000 words spoken.", icon: "book.fill", tier: .bronze) { s,_ in s.totalWords >= 5000 },
        .init(id: "w250k", title: "Mythmaker", blurb: "250,000 words spoken.", icon: "building.columns.fill", tier: .platinum) { s,_ in s.totalWords >= 250000 },
        .init(id: "w500k", title: "Half a Million", blurb: "500,000 words spoken.", icon: "infinity", tier: .platinum) { s,_ in s.totalWords >= 500000 },
        .init(id: "c100", title: "Century", blurb: "100 dictations.", icon: "100.circle.fill", tier: .silver) { s,_ in s.totalCount >= 100 },
        .init(id: "c1000", title: "Thousand Voices", blurb: "1,000 dictations.", icon: "waveform.circle.fill", tier: .gold) { s,_ in s.totalCount >= 1000 },
        .init(id: "s14", title: "Fortnight", blurb: "14 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 14 },
        .init(id: "s365", title: "Year One", blurb: "365 day streak.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.streak >= 365 },
        .init(id: "fast160", title: "Lightning", blurb: "160+ words per minute.", icon: "bolt.fill", tier: .gold) { s,_ in s.avgWPM >= 160 },
        .init(id: "big10k", title: "Ultramarathon", blurb: "10,000 words in a day.", icon: "figure.run.circle.fill", tier: .platinum) { s,_ in s.bestDayWords >= 10000 },
        .init(id: "save50h", title: "Time Wizard", blurb: "50 hours saved versus typing.", icon: "hourglass", tier: .platinum) { s,_ in s.timeSavedMinutes >= 3000 },
        .init(id: "days60", title: "Devoted", blurb: "Dictated on 60 different days.", icon: "calendar.badge.checkmark", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 60 },
        .init(id: "days7", title: "First Week", blurb: "Dictated on 7 different days.", icon: "7.circle.fill", tier: .bronze) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 7 },
    ]

    private static let volume: [Achievement] = [
        .init(id: "first", title: "First Words", blurb: "Your first dictation.", icon: "mic.fill", tier: .bronze) { s,_ in s.totalCount >= 1 },
        .init(id: "ten", title: "Warmed Up", blurb: "10 dictations.", icon: "flame", tier: .bronze) { s,_ in s.totalCount >= 10 },
        .init(id: "w1k", title: "Wordsmith", blurb: "1,000 words spoken.", icon: "text.word.spacing", tier: .bronze) { s,_ in s.totalWords >= 1000 },
        .init(id: "w10k", title: "Prolific", blurb: "10,000 words spoken.", icon: "doc.text.fill", tier: .silver) { s,_ in s.totalWords >= 10000 },
        .init(id: "w50k", title: "Novelist", blurb: "50,000 words spoken.", icon: "books.vertical.fill", tier: .gold) { s,_ in s.totalWords >= 50000 },
        .init(id: "w100k", title: "Centurion", blurb: "100,000 words spoken.", icon: "crown.fill", tier: .platinum) { s,_ in s.totalWords >= 100000 },
    ]
    private static let streaks: [Achievement] = [
        .init(id: "s3", title: "On a Roll", blurb: "3 day streak.", icon: "flame.fill", tier: .bronze) { s,_ in s.streak >= 3 },
        .init(id: "s7", title: "Week Warrior", blurb: "7 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 7 },
        .init(id: "s30", title: "Unstoppable", blurb: "30 day streak.", icon: "flame.fill", tier: .gold) { s,_ in s.streak >= 30 },
        .init(id: "s100", title: "Centennial", blurb: "100 day streak.", icon: "flame.fill", tier: .platinum) { s,_ in s.streak >= 100 },
    ]
    private static let craft: [Achievement] = [
        .init(id: "fast", title: "Speed Demon", blurb: "120+ words per minute.", icon: "gauge.with.dots.needle.67percent", tier: .silver) { s,_ in s.avgWPM >= 120 },
        .init(id: "bigday", title: "Marathon", blurb: "5,000 words in a single day.", icon: "figure.run", tier: .gold) { s,_ in s.bestDayWords >= 5000 },
        .init(id: "saver", title: "Time Lord", blurb: "10 hours saved versus typing.", icon: "clock.arrow.circlepath", tier: .gold) { s,_ in s.timeSavedMinutes >= 600 },
    ]
    private static let modes: [Achievement] = [
        .init(id: "polyglot", title: "Polyglot", blurb: "Used Translate mode.", icon: "globe", tier: .bronze) { _,f in f.contains(.usedTranslate) },
        .init(id: "seer", title: "Second Sight", blurb: "Used Context (screen-aware) mode.", icon: "eye.fill", tier: .silver) { _,f in f.contains(.usedContext) },
        .init(id: "coder", title: "Shipped It", blurb: "Used Coding mode.", icon: "chevron.left.forwardslash.chevron.right", tier: .bronze) { _,f in f.contains(.usedCoding) },
        .init(id: "allmodes", title: "Touch of Everything", blurb: "Used Flow, Polish, Intent, Translate, Context and Coding.", icon: "square.grid.3x3.fill", tier: .gold) { _,f in
            let need: [GameFlag] = [.usedFlow, .usedPolish, .usedIntent, .usedTranslate, .usedContext, .usedCoding]
            return need.allSatisfy { flag in f.contains(flag) } },
        .init(id: "commander", title: "Hands Free", blurb: "Ran an Action by voice.", icon: "wand.and.rays", tier: .silver) { _,f in f.contains(.usedActionMode) },
        .init(id: "notetaker", title: "Note to Self", blurb: "Captured a voice note.", icon: "note.text", tier: .bronze) { _,f in f.contains(.usedVoiceNote) },
        .init(id: "doer", title: "Just Say It", blurb: "Captured a to-do by voice.", icon: "checklist", tier: .bronze) { _,f in f.contains(.usedVoiceTodo) },
        .init(id: "shaper", title: "Reshaper", blurb: "Transformed a selection.", icon: "wand.and.stars", tier: .bronze) { _,f in f.contains(.usedTransform) },
    ]
    private static let misc: [Achievement] = [
        .init(id: "night", title: "Night Owl", blurb: "Dictated after midnight.", icon: "moon.stars.fill", tier: .silver) { _,f in f.contains(.nightOwl) },
        .init(id: "dawn", title: "Early Bird", blurb: "Dictated at dawn.", icon: "sunrise.fill", tier: .silver) { _,f in f.contains(.earlyBird) },
        .init(id: "loyal", title: "Regular", blurb: "Dictated on 30 different days.", icon: "calendar", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 30 },
    ]
}
