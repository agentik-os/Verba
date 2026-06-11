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
    private let kGrandSlam = "verba.game.grandslam"

    private var flags: Set<GameFlag>

    private init() {
        unlocked = Set(d.stringArray(forKey: kUnlocked) ?? []).intersection(Set(Gamification.all.map(\.id)))
        dailyGoal = d.object(forKey: kGoal) as? Int ?? 400
        flags = Set((d.stringArray(forKey: kFlags) ?? []).compactMap(GameFlag.init))
    }

    // MARK: XP + level

    /// XP rewards depth + consistency: every word, a bonus per finished dictation, a fat streak bonus.
    var xp: Int {
        let s = Stats.shared
        return s.totalWords / 4 + s.totalCount * 3 + s.streak * 40
    }

    /// There are 100 levels. Reaching 100 is the ultimate, aspirational goal.
    static let maxLevel = 100

    /// Level curve: each level costs more (quadratic), capped at 100.
    func level(for xp: Int) -> LevelInfo {
        // xp needed to REACH level n (n>=1) = 90 * (n-1)^2
        func threshold(_ n: Int) -> Int { 90 * (n - 1) * (n - 1) }
        var n = 1
        while n < Gamification.maxLevel && threshold(n + 1) <= xp { n += 1 }
        if n >= Gamification.maxLevel {
            let base = threshold(Gamification.maxLevel)
            return LevelInfo(level: Gamification.maxLevel, title: Gamification.title(for: Gamification.maxLevel),
                             xpInLevel: xp - base, xpForNext: xp - base)   // maxed
        }
        let base = threshold(n), next = threshold(n + 1)
        return LevelInfo(level: n, title: Gamification.title(for: n),
                         xpInLevel: xp - base, xpForNext: next - base)
    }
    var levelInfo: LevelInfo { level(for: xp) }

    static func title(for level: Int) -> String {
        switch level {
        case ..<3:    return "Newcomer"
        case 3..<6:   return "Speaker"
        case 6..<10:  return "Orator"
        case 10..<15: return "Wordsmith"
        case 15..<22: return "Virtuoso"
        case 22..<30: return "Maestro"
        case 30..<40: return "Luminary"
        case 40..<52: return "Sage"
        case 52..<65: return "Oracle"
        case 65..<80: return "Mythic"
        case 80..<100: return "Legend"
        default:      return "Voice Immortal"
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
        let newFlag: GameFlag? = h < 4 ? .nightOwl : (5...7).contains(h) ? .earlyBird : nil
        if let f = newFlag { flag(f) }
        evaluate()
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

            // GRAND SLAM: earning every badge unlocks Lifetime Pro. Granted once.
            if Gamification.all.allSatisfy({ self.unlocked.contains($0.id) }), !self.d.bool(forKey: self.kGrandSlam) {
                self.d.set(true, forKey: self.kGrandSlam)
                Settings.shared.grantLifetimePro()
                self.pending.append(Celebration(
                    kind: .milestone("grandslam"),
                    title: "Grand Slam",
                    subtitle: "You earned every single badge. Verba Pro is now yours for life. Legendary.",
                    icon: "trophy.fill", tint: .yellow))
            }

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
                self.pushProfile()   // publish the backfilled profile too
                return
            }
            self.pushProfile()   // publish my updated profile for others to see
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

    // MARK: - Social: publish my profile + read others'

    private var profilePushTask: DispatchWorkItem?

    /// Publish my level / XP / league / badges so others can see them on the leaderboard.
    func pushProfile() {
        guard !Settings.shared.proEmail.isEmpty else { return }   // signed-in only
        profilePushTask?.cancel()
        let work = DispatchWorkItem {
            ConvexClient.registerDevice(token: AuthToken.current)
            ConvexClient.call("mutation", "profiles:push", ConvexClient.authedArgs([
                "alias": Settings.shared.username,
                "level": self.levelInfo.level,
                "xp": self.xp,
                "league": self.league.name,
                "badges": Array(self.unlocked),
            ])) { _ in }
        }
        profilePushTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    /// Another player's public profile, fetched by their leaderboard alias.
    struct OtherProfile { let alias: String; let level: Int; let league: String; let badges: Set<String> }

    func fetchProfile(alias: String, _ done: @escaping (OtherProfile?) -> Void) {
        ConvexClient.call("query", "profiles:byAlias", ["alias": alias]) { data in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let v = obj["value"] as? [String: Any] else { DispatchQueue.main.async { done(nil) }; return }
            let p = OtherProfile(
                alias: v["alias"] as? String ?? alias,
                level: (v["level"] as? Int) ?? Int((v["level"] as? Double) ?? 0),
                league: v["league"] as? String ?? "Bronze",
                badges: Set((v["badges"] as? [String]) ?? []))
            DispatchQueue.main.async { done(p) }
        }
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
    static let all: [Achievement] = volume + streaks + craft + modes + misc + bonus + words2 + streaks2 + counts2 + craft2 + days2

    private static let words2: [Achievement] = [
        .init(id: "w2k", title: "Getting Wordy", blurb: "2,000 words spoken.", icon: "text.bubble.fill", tier: .bronze) { s,_ in s.totalWords >= 2000 },
        .init(id: "w3k", title: "Chatterbox", blurb: "3,000 words spoken.", icon: "bubble.left.and.bubble.right.fill", tier: .bronze) { s,_ in s.totalWords >= 3000 },
        .init(id: "w7k", title: "Wordfall", blurb: "7,500 words spoken.", icon: "text.append", tier: .bronze) { s,_ in s.totalWords >= 7500 },
        .init(id: "w15k", title: "Verbose", blurb: "15,000 words spoken.", icon: "doc.plaintext.fill", tier: .silver) { s,_ in s.totalWords >= 15000 },
        .init(id: "w20k", title: "Essayist", blurb: "20,000 words spoken.", icon: "doc.richtext.fill", tier: .silver) { s,_ in s.totalWords >= 20000 },
        .init(id: "w25k", title: "Chronicler", blurb: "25,000 words spoken.", icon: "scroll.fill", tier: .silver) { s,_ in s.totalWords >= 25000 },
        .init(id: "w30k", title: "Author", blurb: "30,000 words spoken.", icon: "pencil.and.scribble", tier: .silver) { s,_ in s.totalWords >= 30000 },
        .init(id: "w40k", title: "Wordmonger", blurb: "40,000 words spoken.", icon: "character.book.closed.fill", tier: .silver) { s,_ in s.totalWords >= 40000 },
        .init(id: "w75k", title: "Bestseller", blurb: "75,000 words spoken.", icon: "star.square.fill", tier: .gold) { s,_ in s.totalWords >= 75000 },
        .init(id: "w150k", title: "Epic", blurb: "150,000 words spoken.", icon: "books.vertical.circle.fill", tier: .gold) { s,_ in s.totalWords >= 150000 },
        .init(id: "w200k", title: "Saga", blurb: "200,000 words spoken.", icon: "text.book.closed.fill", tier: .gold) { s,_ in s.totalWords >= 200000 },
        .init(id: "w300k", title: "Library", blurb: "300,000 words spoken.", icon: "building.columns.circle.fill", tier: .platinum) { s,_ in s.totalWords >= 300000 },
        .init(id: "w400k", title: "Canon", blurb: "400,000 words spoken.", icon: "seal.fill", tier: .platinum) { s,_ in s.totalWords >= 400000 },
        .init(id: "w750k", title: "Tome Lord", blurb: "750,000 words spoken.", icon: "books.vertical.fill", tier: .platinum) { s,_ in s.totalWords >= 750000 },
        .init(id: "w1m", title: "One in a Million", blurb: "1,000,000 words spoken.", icon: "crown.fill", tier: .platinum) { s,_ in s.totalWords >= 1000000 },
    ]
    private static let streaks2: [Achievement] = [
        .init(id: "s2", title: "Back Again", blurb: "2 day streak.", icon: "arrow.clockwise", tier: .bronze) { s,_ in s.streak >= 2 },
        .init(id: "s5", title: "Habit Forming", blurb: "5 day streak.", icon: "flame", tier: .bronze) { s,_ in s.streak >= 5 },
        .init(id: "s10", title: "Double Digits", blurb: "10 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 10 },
        .init(id: "s21", title: "Three Weeks", blurb: "21 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 21 },
        .init(id: "s50", title: "Half Century", blurb: "50 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 50 },
        .init(id: "s60", title: "Two Months", blurb: "60 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 60 },
        .init(id: "s90", title: "A Season", blurb: "90 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 90 },
        .init(id: "s180", title: "Half a Year", blurb: "180 day streak.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.streak >= 180 },
        .init(id: "s250", title: "Iron Will", blurb: "250 day streak.", icon: "shield.fill", tier: .platinum) { s,_ in s.streak >= 250 },
    ]
    private static let counts2: [Achievement] = [
        .init(id: "c25", title: "Two Dozen", blurb: "25 dictations.", icon: "25.circle.fill", tier: .bronze) { s,_ in s.totalCount >= 25 },
        .init(id: "c50", title: "Fifty Up", blurb: "50 dictations.", icon: "50.circle.fill", tier: .bronze) { s,_ in s.totalCount >= 50 },
        .init(id: "c250", title: "Regular Caller", blurb: "250 dictations.", icon: "phone.circle.fill", tier: .silver) { s,_ in s.totalCount >= 250 },
        .init(id: "c500", title: "Five Hundred", blurb: "500 dictations.", icon: "circle.grid.cross.fill", tier: .gold) { s,_ in s.totalCount >= 500 },
        .init(id: "c2500", title: "Voice Machine", blurb: "2,500 dictations.", icon: "waveform.path.ecg", tier: .platinum) { s,_ in s.totalCount >= 2500 },
        .init(id: "c5000", title: "Unmuted", blurb: "5,000 dictations.", icon: "infinity.circle.fill", tier: .platinum) { s,_ in s.totalCount >= 5000 },
    ]
    private static let craft2: [Achievement] = [
        .init(id: "wpm80", title: "Conversational", blurb: "80+ words per minute.", icon: "speedometer", tier: .bronze) { s,_ in s.avgWPM >= 80 },
        .init(id: "wpm100", title: "Quick Tongue", blurb: "100+ words per minute.", icon: "gauge.with.needle", tier: .silver) { s,_ in s.avgWPM >= 100 },
        .init(id: "wpm140", title: "Rapid Fire", blurb: "140+ words per minute.", icon: "bolt.horizontal.fill", tier: .gold) { s,_ in s.avgWPM >= 140 },
        .init(id: "wpm200", title: "Auctioneer", blurb: "200+ words per minute.", icon: "bolt.fill", tier: .platinum) { s,_ in s.avgWPM >= 200 },
        .init(id: "bd1k", title: "Productive Day", blurb: "1,000 words in a day.", icon: "sun.max.fill", tier: .bronze) { s,_ in s.bestDayWords >= 1000 },
        .init(id: "bd2k", title: "Big Day", blurb: "2,000 words in a day.", icon: "calendar.badge.clock", tier: .silver) { s,_ in s.bestDayWords >= 2000 },
        .init(id: "bd3k", title: "On a Tear", blurb: "3,000 words in a day.", icon: "flame.fill", tier: .silver) { s,_ in s.bestDayWords >= 3000 },
        .init(id: "bd7k", title: "Locked In", blurb: "7,500 words in a day.", icon: "scope", tier: .gold) { s,_ in s.bestDayWords >= 7500 },
        .init(id: "bd15k", title: "Unstoppable Day", blurb: "15,000 words in a day.", icon: "hare.fill", tier: .platinum) { s,_ in s.bestDayWords >= 15000 },
        .init(id: "sv1h", title: "An Hour Back", blurb: "1 hour saved versus typing.", icon: "clock.fill", tier: .bronze) { s,_ in s.timeSavedMinutes >= 60 },
        .init(id: "sv5h", title: "Half a Day", blurb: "5 hours saved versus typing.", icon: "clock.badge.checkmark", tier: .silver) { s,_ in s.timeSavedMinutes >= 300 },
        .init(id: "sv25h", title: "A Full Day", blurb: "25 hours saved versus typing.", icon: "calendar.day.timeline.left", tier: .gold) { s,_ in s.timeSavedMinutes >= 1500 },
        .init(id: "sv100h", title: "Time Bank", blurb: "100 hours saved versus typing.", icon: "banknote.fill", tier: .platinum) { s,_ in s.timeSavedMinutes >= 6000 },
        .init(id: "sv250h", title: "Time Bender", blurb: "250 hours saved versus typing.", icon: "hourglass.bottomhalf.filled", tier: .platinum) { s,_ in s.timeSavedMinutes >= 15000 },
    ]
    private static let days2: [Achievement] = [
        .init(id: "d3", title: "Three Times", blurb: "Dictated on 3 different days.", icon: "3.circle.fill", tier: .bronze) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 3 },
        .init(id: "d14", title: "Two Weeks In", blurb: "Dictated on 14 different days.", icon: "14.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 14 },
        .init(id: "d21", title: "Three Weeks In", blurb: "Dictated on 21 different days.", icon: "21.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 21 },
        .init(id: "d45", title: "Six Weeks", blurb: "Dictated on 45 different days.", icon: "calendar.circle", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 45 },
        .init(id: "d90", title: "Quarter", blurb: "Dictated on 90 different days.", icon: "calendar.badge.plus", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 90 },
        .init(id: "d100", title: "Hundred Days", blurb: "Dictated on 100 different days.", icon: "100.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 100 },
        .init(id: "d180", title: "Half-Year Habit", blurb: "Dictated on 180 different days.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 180 },
        .init(id: "d365", title: "All Year", blurb: "Dictated on 365 different days.", icon: "star.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 365 },
    ]

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
