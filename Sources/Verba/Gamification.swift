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
    // Feature-exploration flags — power the "Explore Verba" gamified self-onboarding category.
    case savedNote       // created/saved a long-form Note
    case taggedNote      // filed a note with a #tag (Bear-style)
    case lockedNote      // password-protected a note
    case createdTask     // created a task in the Task Manager
    case checkedTask     // checked off a task
    case usedDictionary  // added a word to the dictionary
    case usedScratchpad  // used the Scratchpad (block note)
    case usedSnippet     // saved a snippet
    case connectedApp    // connected an app for JARVIS
    case changedStyle    // cycled a style on top of a mode
    // More features + shortcuts (also Explore).
    case usedPushToTalk  // held Fn to talk, released to send
    case pickedModeNum   // picked a mode with Fn + number
    case switchedMode    // switched mode mid-flight (Fn+Tab / Option)
    case pausedRec       // paused a recording with Control
    case cancelledRec    // cancelled with Esc
    case usedTodoGlance  // ⌥+Fn today's to-dos glance
    case chainedDictation // started a 2nd dictation while one was still processing
    case createdCustomMode // built a custom dictation mode
    case usedOwnAI       // ran on a local model or your own key
    case reworkedHistory // re-ran / adapted a past dictation
    case transcribedFile // transcribed an audio/video file
    // Fun context flags (Special).
    case weekendWarrior, lateNightShip, fridayEve, mondayAM, lunchBreak, holidayHustle, comebackKid
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
    enum Tier: Int { case bronze, silver, gold, platinum, diamond
        var color: Color { [Color.orange, .gray, .yellow, .purple, .cyan][rawValue] }
        var label: String { ["Bronze", "Silver", "Gold", "Platinum", "Diamond"][rawValue] }
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

    // Fun counters (how many times you said "thanks", "ship it", mentioned AI, …) + the set of
    // timezones you've dictated from. Persisted; read by the playful Special achievements. All
    // on-device: a tiny word scan of YOUR final text to light up a badge, never uploaded.
    @Published private(set) var counters: [String: Int] = [:]
    private var seenTZ: Set<String> = []
    private let kCounters = "verba.game.counters"
    private let kTZ = "verba.game.seenTZ"
    private let kLastActive = "verba.game.lastActiveDay"

    private init() {
        unlocked = Set(d.stringArray(forKey: kUnlocked) ?? []).intersection(Set(Gamification.all.map(\.id)))
        dailyGoal = d.object(forKey: kGoal) as? Int ?? 400
        flags = Set((d.stringArray(forKey: kFlags) ?? []).compactMap(GameFlag.init))
        counters = (d.dictionary(forKey: kCounters) as? [String: Int]) ?? [:]
        seenTZ = Set(d.stringArray(forKey: kTZ) ?? [])
    }

    func counter(_ key: String) -> Int { counters[key] ?? 0 }
    var timezoneCount: Int { seenTZ.count }

    private func bump(_ key: String, by n: Int = 1) {
        counters[key, default: 0] += n
        d.set(counters, forKey: kCounters)
    }

    /// Scan the delivered text for fun, legit patterns and bump the matching counters. Pure local
    /// word-matching (FR + EN), case-insensitive, on word boundaries so substrings never false-fire.
    func scanText(_ raw: String) {
        let text = " " + raw.lowercased() + " "
        func has(_ words: [String]) -> Bool {
            words.contains { w in
                guard let re = try? NSRegularExpression(pattern: "\\b" + NSRegularExpression.escapedPattern(for: w) + "\\b") else { return false }
                return re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
            }
        }
        if has(["thank you", "thanks", "thank u", "merci"]) { bump("thanks") }
        if has(["please", "s'il te plaît", "stp", "s'il vous plaît"]) { bump("please") }
        if has(["sorry", "my bad", "désolé", "pardon"]) { bump("sorry") }
        if has(["ship it", "ship this", "let's ship", "on déploie", "deploy", "go live"]) { bump("ship") }
        if has(["bug", "broken", "crash", "doesn't work", "ne marche pas", "fix this", "error"]) { bump("bug") }
        if has(["refactor", "merge", "commit", "pull request", "code", "function", "endpoint", "api"]) { bump("vibe") }
        if has(["ai", "gpt", "claude", "llm", "prompt", "model", "agent", "neural"]) { bump("ai") }
        if has(["startup", "fundraise", "raise", "investor", "mrr", "arr", "runway", "users", "growth", "revenue", "launch"]) { bump("founder") }
        if has(["billion", "unicorn", "world", "change the world", "moonshot", "10x", "empire"]) { bump("dreamer") }
        if has(["coffee", "café", "espresso", "caffeine"]) { bump("coffee") }
        if has(["love", "amazing", "awesome", "génial", "incroyable", "let's go", "let's gooo"]) { bump("hype") }
        if has(["idea", "what if", "imagine", "concept", "brainstorm"]) { bump("idea") }
        evaluate()
    }

    /// Record the timezone of a dictation (for the globe-trotter badges).
    func noteTimezone(_ id: String = TimeZone.current.identifier) {
        guard !id.isEmpty, !seenTZ.contains(id) else { return }
        seenTZ.insert(id)
        d.set(Array(seenTZ), forKey: kTZ)
        evaluate()
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

    /// Note the current time-of-day / day-of-week context (call on each dictation) then evaluate.
    func noteDictationTime(_ date: Date = Date()) {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let wd = cal.component(.weekday, from: date)   // 1 = Sunday … 7 = Saturday
        let comps = cal.dateComponents([.month, .day], from: date)
        if h < 4 { flag(.nightOwl) }
        else if (5...7).contains(h) { flag(.earlyBird) }
        if h >= 1 && h < 5 { flag(.lateNightShip) }                 // shipping at 1–5 AM
        if wd == 1 || wd == 7 { flag(.weekendWarrior) }             // Sat / Sun
        if wd == 6 && h >= 17 { flag(.fridayEve) }                  // Friday evening
        if wd == 2 && (6...10).contains(h) { flag(.mondayAM) }      // Monday morning
        if (12...13).contains(h) { flag(.lunchBreak) }
        // A few playful "holiday" days (Jan 1, Dec 24/25/31).
        if (comps.month == 1 && comps.day == 1) || (comps.month == 12 && [24, 25, 31].contains(comps.day ?? 0)) {
            flag(.holidayHustle)
        }
        // Comeback: dictated again after a 7+ day gap.
        let day = Int(date.timeIntervalSince1970 / 86400)
        if let last = d.object(forKey: kLastActive) as? Int, day - last >= 7 { flag(.comebackKid) }
        d.set(day, forKey: kLastActive)
        noteTimezone()
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

    // MARK: - The catalog (categorized, ordered)
    //
    // Grouped by category for the Achievements grid; `all` is the flat list used for
    // counting + evaluation. IDs are stable so previously-earned badges stay earned.
    struct Group: Identifiable { let id: String; let icon: String; let items: [Achievement] }

    static let all: [Achievement] = groups.flatMap(\.items)

    static let groups: [Group] = [
        // FIRST: a gamified self-onboarding — one badge per feature + shortcut, so the user
        // discovers everything Verba can do and sees each one tick off as they try it.
        Group(id: "Explore Verba", icon: "wand.and.stars.inverse", items: cat_Explore_Verba),
        Group(id: "Words Spoken", icon: "text.word.spacing", items: cat_Words_Spoken),
        Group(id: "Dictations", icon: "mic.fill", items: cat_Dictations),
        Group(id: "Streaks", icon: "flame.fill", items: cat_Streaks),
        Group(id: "Dedication", icon: "calendar", items: cat_Dedication),
        Group(id: "Speed", icon: "speedometer", items: cat_Speed),
        Group(id: "Big Days", icon: "sun.max.fill", items: cat_Big_Days),
        Group(id: "Time Saved", icon: "clock.arrow.circlepath", items: cat_Time_Saved),
        Group(id: "Airtime", icon: "waveform", items: cat_Airtime),
        Group(id: "Special", icon: "sparkles", items: cat_Special),
    ]

    private static let cat_Words_Spoken: [Achievement] = [
        .init(id: "w1k", title: "Wordsmith", blurb: "1,000 words spoken.", icon: "text.word.spacing", tier: .bronze) { s,_ in s.totalWords >= 1000 },
        .init(id: "w2k", title: "Getting Wordy", blurb: "2,000 words spoken.", icon: "text.bubble.fill", tier: .bronze) { s,_ in s.totalWords >= 2000 },
        .init(id: "w3k", title: "Chatterbox", blurb: "3,000 words spoken.", icon: "bubble.left.and.bubble.right.fill", tier: .bronze) { s,_ in s.totalWords >= 3000 },
        .init(id: "w5k", title: "Storyteller", blurb: "5,000 words spoken.", icon: "book.fill", tier: .bronze) { s,_ in s.totalWords >= 5000 },
        .init(id: "w7k", title: "Wordfall", blurb: "7,500 words spoken.", icon: "text.append", tier: .bronze) { s,_ in s.totalWords >= 7500 },
        .init(id: "w10k", title: "Prolific", blurb: "10,000 words spoken.", icon: "doc.text.fill", tier: .silver) { s,_ in s.totalWords >= 10000 },
        .init(id: "w15k", title: "Verbose", blurb: "15,000 words spoken.", icon: "doc.plaintext.fill", tier: .silver) { s,_ in s.totalWords >= 15000 },
        .init(id: "w20k", title: "Essayist", blurb: "20,000 words spoken.", icon: "doc.richtext.fill", tier: .silver) { s,_ in s.totalWords >= 20000 },
        .init(id: "w25k", title: "Chronicler", blurb: "25,000 words spoken.", icon: "scroll.fill", tier: .silver) { s,_ in s.totalWords >= 25000 },
        .init(id: "w30k", title: "Author", blurb: "30,000 words spoken.", icon: "pencil.and.scribble", tier: .silver) { s,_ in s.totalWords >= 30000 },
        .init(id: "w40k", title: "Wordmonger", blurb: "40,000 words spoken.", icon: "character.book.closed.fill", tier: .silver) { s,_ in s.totalWords >= 40000 },
        .init(id: "w50k", title: "Novelist", blurb: "50,000 words spoken.", icon: "books.vertical.fill", tier: .silver) { s,_ in s.totalWords >= 50000 },
        .init(id: "w75k", title: "Bestseller", blurb: "75,000 words spoken.", icon: "star.square.fill", tier: .silver) { s,_ in s.totalWords >= 75000 },
        .init(id: "w100k", title: "Centurion", blurb: "100,000 words spoken.", icon: "crown.fill", tier: .gold) { s,_ in s.totalWords >= 100000 },
        .init(id: "w150k", title: "Epic", blurb: "150,000 words spoken.", icon: "books.vertical.circle.fill", tier: .gold) { s,_ in s.totalWords >= 150000 },
        .init(id: "w200k", title: "Saga", blurb: "200,000 words spoken.", icon: "text.book.closed.fill", tier: .gold) { s,_ in s.totalWords >= 200000 },
        .init(id: "w250k", title: "Mythmaker", blurb: "250,000 words spoken.", icon: "building.columns.fill", tier: .gold) { s,_ in s.totalWords >= 250000 },
        .init(id: "w300k", title: "Library", blurb: "300,000 words spoken.", icon: "building.columns.circle.fill", tier: .gold) { s,_ in s.totalWords >= 300000 },
        .init(id: "w400k", title: "Canon", blurb: "400,000 words spoken.", icon: "seal.fill", tier: .gold) { s,_ in s.totalWords >= 400000 },
        .init(id: "w500k", title: "Half a Million", blurb: "500,000 words spoken.", icon: "infinity", tier: .gold) { s,_ in s.totalWords >= 500000 },
        .init(id: "w750k", title: "Tome Lord", blurb: "750,000 words spoken.", icon: "books.vertical.fill", tier: .gold) { s,_ in s.totalWords >= 750000 },
        .init(id: "w1m", title: "One in a Million", blurb: "1,000,000 words spoken.", icon: "crown.fill", tier: .platinum) { s,_ in s.totalWords >= 1000000 },
        .init(id: "w1m5", title: "Wordquake", blurb: "1,500,000 words spoken.", icon: "waveform.path", tier: .platinum) { s,_ in s.totalWords >= 1500000 },
        .init(id: "w2m", title: "Two Million", blurb: "2,000,000 words spoken.", icon: "2.circle.fill", tier: .platinum) { s,_ in s.totalWords >= 2000000 },
        .init(id: "w3m", title: "Wordstorm", blurb: "3,000,000 words spoken.", icon: "cloud.bolt.rain.fill", tier: .platinum) { s,_ in s.totalWords >= 3000000 },
        .init(id: "w5m", title: "Five Million", blurb: "5,000,000 words spoken.", icon: "5.circle.fill", tier: .platinum) { s,_ in s.totalWords >= 5000000 },
        .init(id: "w7m5", title: "Word Titan", blurb: "7,500,000 words spoken.", icon: "mountain.2.fill", tier: .platinum) { s,_ in s.totalWords >= 7500000 },
        .init(id: "w10m", title: "Ten Million", blurb: "10,000,000 words spoken.", icon: "10.circle.fill", tier: .platinum) { s,_ in s.totalWords >= 10000000 },
        .init(id: "w25m", title: "Word Colossus", blurb: "25,000,000 words spoken.", icon: "flame.circle.fill", tier: .platinum) { s,_ in s.totalWords >= 25000000 },
        .init(id: "w50m", title: "Fifty Million", blurb: "50,000,000 words spoken.", icon: "hexagon.fill", tier: .platinum) { s,_ in s.totalWords >= 50000000 },
        .init(id: "w100m", title: "Hundred Million", blurb: "100,000,000 words spoken.", icon: "100.circle.fill", tier: .diamond) { s,_ in s.totalWords >= 100000000 },
        .init(id: "w250m", title: "Word Leviathan", blurb: "250,000,000 words spoken.", icon: "tornado", tier: .diamond) { s,_ in s.totalWords >= 250000000 },
        .init(id: "w500m", title: "Half a Billion", blurb: "500,000,000 words spoken.", icon: "sparkles", tier: .diamond) { s,_ in s.totalWords >= 500000000 },
        .init(id: "w1b", title: "Billionaire of Babble", blurb: "1,000,000,000 words spoken.", icon: "crown.fill", tier: .diamond) { s,_ in s.totalWords >= 1000000000 },
        .init(id: "w10b", title: "Ten Billion", blurb: "10,000,000,000 words spoken.", icon: "globe.americas.fill", tier: .diamond) { s,_ in s.totalWords >= 10000000000 },
        .init(id: "w100b", title: "Hundred Billion", blurb: "100,000,000,000 words spoken.", icon: "sun.max.circle.fill", tier: .diamond) { s,_ in s.totalWords >= 100000000000 },
        .init(id: "w1t", title: "Trillion Word March", blurb: "1,000,000,000,000 words spoken.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.totalWords >= 1000000000000 },
    ]
    private static let cat_Dictations: [Achievement] = [
        .init(id: "first", title: "First Words", blurb: "Your first dictation.", icon: "mic.fill", tier: .bronze) { s,_ in s.totalCount >= 1 },
        .init(id: "ten", title: "Warmed Up", blurb: "10 dictations.", icon: "flame", tier: .bronze) { s,_ in s.totalCount >= 10 },
        .init(id: "c25", title: "Two Dozen", blurb: "25 dictations.", icon: "25.circle.fill", tier: .silver) { s,_ in s.totalCount >= 25 },
        .init(id: "c50", title: "Fifty Up", blurb: "50 dictations.", icon: "50.circle.fill", tier: .silver) { s,_ in s.totalCount >= 50 },
        .init(id: "c100", title: "Century", blurb: "100 dictations.", icon: "100.circle.fill", tier: .silver) { s,_ in s.totalCount >= 100 },
        .init(id: "c250", title: "Regular Caller", blurb: "250 dictations.", icon: "phone.circle.fill", tier: .gold) { s,_ in s.totalCount >= 250 },
        .init(id: "c500", title: "Five Hundred", blurb: "500 dictations.", icon: "circle.grid.cross.fill", tier: .gold) { s,_ in s.totalCount >= 500 },
        .init(id: "c750", title: "Seven Fifty", blurb: "750 dictations.", icon: "circle.hexagongrid.fill", tier: .gold) { s,_ in s.totalCount >= 750 },
        .init(id: "c1000", title: "Thousand Voices", blurb: "1,000 dictations.", icon: "waveform.circle.fill", tier: .gold) { s,_ in s.totalCount >= 1000 },
        .init(id: "c1500", title: "Fifteen Hundred", blurb: "1,500 dictations.", icon: "waveform.path.ecg.rectangle", tier: .gold) { s,_ in s.totalCount >= 1500 },
        .init(id: "c2500", title: "Voice Machine", blurb: "2,500 dictations.", icon: "waveform.path.ecg", tier: .platinum) { s,_ in s.totalCount >= 2500 },
        .init(id: "c3500", title: "Relentless", blurb: "3,500 dictations.", icon: "gauge.high", tier: .platinum) { s,_ in s.totalCount >= 3500 },
        .init(id: "c5000", title: "Unmuted", blurb: "5,000 dictations.", icon: "infinity.circle.fill", tier: .platinum) { s,_ in s.totalCount >= 5000 },
        .init(id: "c7500", title: "Voice Engine", blurb: "7,500 dictations.", icon: "engine.combustion.fill", tier: .platinum) { s,_ in s.totalCount >= 7500 },
        .init(id: "c10k", title: "Ten Thousand", blurb: "10,000 dictations.", icon: "10.circle.fill", tier: .platinum) { s,_ in s.totalCount >= 10000 },
        .init(id: "c25k", title: "Voice Veteran", blurb: "25,000 dictations.", icon: "shield.lefthalf.filled", tier: .platinum) { s,_ in s.totalCount >= 25000 },
        .init(id: "c50k", title: "Fifty Thousand", blurb: "50,000 dictations.", icon: "50.circle.fill", tier: .platinum) { s,_ in s.totalCount >= 50000 },
        .init(id: "c100k", title: "Voice Legend", blurb: "100,000 dictations.", icon: "crown.fill", tier: .diamond) { s,_ in s.totalCount >= 100000 },
        .init(id: "c250k", title: "Quarter Million Calls", blurb: "250,000 dictations.", icon: "medal.fill", tier: .diamond) { s,_ in s.totalCount >= 250000 },
        .init(id: "c500k", title: "Half Million Calls", blurb: "500,000 dictations.", icon: "trophy.fill", tier: .diamond) { s,_ in s.totalCount >= 500000 },
        .init(id: "c1mil", title: "Million Dictations", blurb: "1,000,000 dictations.", icon: "infinity", tier: .diamond) { s,_ in s.totalCount >= 1000000 },
    ]
    private static let cat_Streaks: [Achievement] = [
        .init(id: "s2", title: "Back Again", blurb: "2 day streak.", icon: "arrow.clockwise", tier: .bronze) { s,_ in s.streak >= 2 },
        .init(id: "s3", title: "On a Roll", blurb: "3 day streak.", icon: "flame.fill", tier: .bronze) { s,_ in s.streak >= 3 },
        .init(id: "s4", title: "Four in a Row", blurb: "4 day streak.", icon: "flame.fill", tier: .bronze) { s,_ in s.streak >= 4 },
        .init(id: "s5", title: "Habit Forming", blurb: "5 day streak.", icon: "flame", tier: .bronze) { s,_ in s.streak >= 5 },
        .init(id: "s6", title: "Six Strong", blurb: "6 day streak.", icon: "flame.fill", tier: .bronze) { s,_ in s.streak >= 6 },
        .init(id: "s7", title: "Week Warrior", blurb: "7 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 7 },
        .init(id: "s8", title: "Eight Days", blurb: "8 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 8 },
        .init(id: "s10", title: "Double Digits", blurb: "10 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 10 },
        .init(id: "s12", title: "Twelve Up", blurb: "12 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 12 },
        .init(id: "s14", title: "Fortnight", blurb: "14 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 14 },
        .init(id: "s16", title: "Sixteen Strong", blurb: "16 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 16 },
        .init(id: "s21", title: "Three Weeks", blurb: "21 day streak.", icon: "flame.fill", tier: .silver) { s,_ in s.streak >= 21 },
        .init(id: "s30", title: "Unstoppable", blurb: "30 day streak.", icon: "flame.fill", tier: .gold) { s,_ in s.streak >= 30 },
        .init(id: "s40", title: "Forty Days", blurb: "40 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 40 },
        .init(id: "s50", title: "Half Century", blurb: "50 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 50 },
        .init(id: "s60", title: "Two Months", blurb: "60 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 60 },
        .init(id: "s75", title: "Seventy-Five", blurb: "75 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 75 },
        .init(id: "s90", title: "A Season", blurb: "90 day streak.", icon: "flame.circle.fill", tier: .gold) { s,_ in s.streak >= 90 },
        .init(id: "s100", title: "Centennial", blurb: "100 day streak.", icon: "flame.fill", tier: .platinum) { s,_ in s.streak >= 100 },
        .init(id: "s120", title: "Four Months", blurb: "120 day streak.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.streak >= 120 },
        .init(id: "s150", title: "Iron Habit", blurb: "150 day streak.", icon: "shield.fill", tier: .platinum) { s,_ in s.streak >= 150 },
        .init(id: "s180", title: "Half a Year", blurb: "180 day streak.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.streak >= 180 },
        .init(id: "s200", title: "Two Hundred", blurb: "200 day streak.", icon: "200.circle", tier: .platinum) { s,_ in s.streak >= 200 },
        .init(id: "s250", title: "Iron Will", blurb: "250 day streak.", icon: "shield.fill", tier: .platinum) { s,_ in s.streak >= 250 },
        .init(id: "s300", title: "Three Hundred", blurb: "300 day streak.", icon: "flame.circle.fill", tier: .platinum) { s,_ in s.streak >= 300 },
        .init(id: "s365", title: "Year One", blurb: "365 day streak.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.streak >= 365 },
        .init(id: "s500", title: "Diamond Streak", blurb: "500 day streak.", icon: "diamond.fill", tier: .diamond) { s,_ in s.streak >= 500 },
        .init(id: "s730", title: "Two Years Strong", blurb: "730 day streak.", icon: "crown.fill", tier: .diamond) { s,_ in s.streak >= 730 },
        .init(id: "s1000", title: "Thousand-Day Flame", blurb: "1,000 day streak.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.streak >= 1000 },
    ]
    private static let cat_Dedication: [Achievement] = [
        .init(id: "d2", title: "Twice Over", blurb: "Dictated on 2 different days.", icon: "2.circle.fill", tier: .bronze) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 2 },
        .init(id: "d3", title: "Three Times", blurb: "Dictated on 3 different days.", icon: "3.circle.fill", tier: .bronze) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 3 },
        .init(id: "d5", title: "Five Days", blurb: "Dictated on 5 different days.", icon: "5.circle.fill", tier: .bronze) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 5 },
        .init(id: "days7", title: "First Week", blurb: "Dictated on 7 different days.", icon: "7.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 7 },
        .init(id: "d10", title: "Ten Days", blurb: "Dictated on 10 different days.", icon: "10.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 10 },
        .init(id: "d14", title: "Two Weeks In", blurb: "Dictated on 14 different days.", icon: "14.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 14 },
        .init(id: "d21", title: "Three Weeks In", blurb: "Dictated on 21 different days.", icon: "21.circle.fill", tier: .silver) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 21 },
        .init(id: "loyal", title: "Regular", blurb: "Dictated on 30 different days.", icon: "calendar", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 30 },
        .init(id: "d45", title: "Six Weeks", blurb: "Dictated on 45 different days.", icon: "calendar.circle", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 45 },
        .init(id: "d50", title: "Fifty Days", blurb: "Dictated on 50 different days.", icon: "50.circle.fill", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 50 },
        .init(id: "days60", title: "Devoted", blurb: "Dictated on 60 different days.", icon: "calendar.badge.checkmark", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 60 },
        .init(id: "d90", title: "Quarter", blurb: "Dictated on 90 different days.", icon: "calendar.badge.plus", tier: .gold) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 90 },
        .init(id: "d100", title: "Hundred Days", blurb: "Dictated on 100 different days.", icon: "100.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 100 },
        .init(id: "d120", title: "Four Months In", blurb: "Dictated on 120 different days.", icon: "calendar.circle", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 120 },
        .init(id: "d150", title: "Committed", blurb: "Dictated on 150 different days.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 150 },
        .init(id: "d180", title: "Half-Year Habit", blurb: "Dictated on 180 different days.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 180 },
        .init(id: "d200", title: "Two Hundred Days", blurb: "Dictated on 200 different days.", icon: "200.circle", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 200 },
        .init(id: "d250", title: "Quarter Thousand", blurb: "Dictated on 250 different days.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 250 },
        .init(id: "d300", title: "Three Hundred Days", blurb: "Dictated on 300 different days.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 300 },
        .init(id: "d365", title: "All Year", blurb: "Dictated on 365 different days.", icon: "star.circle.fill", tier: .platinum) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 365 },
        .init(id: "d500", title: "Five Hundred Days", blurb: "Dictated on 500 different days.", icon: "diamond.fill", tier: .diamond) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 500 },
        .init(id: "d730", title: "Two-Year Voice", blurb: "Dictated on 730 different days.", icon: "crown.fill", tier: .diamond) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 730 },
        .init(id: "d1000", title: "Thousand Days In", blurb: "Dictated on 1,000 different days.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.days.values.filter { $0.count > 0 }.count >= 1000 },
    ]
    private static let cat_Speed: [Achievement] = [
        .init(id: "wpm60", title: "Warmed Tongue", blurb: "60+ words per minute.", icon: "speedometer", tier: .bronze) { s,_ in s.avgWPM >= 60 },
        .init(id: "wpm70", title: "Easy Talker", blurb: "70+ words per minute.", icon: "speedometer", tier: .bronze) { s,_ in s.avgWPM >= 70 },
        .init(id: "wpm80", title: "Conversational", blurb: "80+ words per minute.", icon: "speedometer", tier: .bronze) { s,_ in s.avgWPM >= 80 },
        .init(id: "wpm90", title: "Smooth Speaker", blurb: "90+ words per minute.", icon: "gauge.with.needle", tier: .silver) { s,_ in s.avgWPM >= 90 },
        .init(id: "wpm100", title: "Quick Tongue", blurb: "100+ words per minute.", icon: "gauge.with.needle", tier: .silver) { s,_ in s.avgWPM >= 100 },
        .init(id: "wpm110", title: "Brisk", blurb: "110+ words per minute.", icon: "gauge.with.needle", tier: .silver) { s,_ in s.avgWPM >= 110 },
        .init(id: "fast", title: "Speed Demon", blurb: "120+ words per minute.", icon: "gauge.with.dots.needle.67percent", tier: .silver) { s,_ in s.avgWPM >= 120 },
        .init(id: "wpm130", title: "Fast Talker", blurb: "130+ words per minute.", icon: "bolt.horizontal", tier: .gold) { s,_ in s.avgWPM >= 130 },
        .init(id: "wpm140", title: "Rapid Fire", blurb: "140+ words per minute.", icon: "bolt.horizontal.fill", tier: .gold) { s,_ in s.avgWPM >= 140 },
        .init(id: "wpm150", title: "Blistering", blurb: "150+ words per minute.", icon: "bolt.horizontal.fill", tier: .gold) { s,_ in s.avgWPM >= 150 },
        .init(id: "fast160", title: "Lightning", blurb: "160+ words per minute.", icon: "bolt.fill", tier: .gold) { s,_ in s.avgWPM >= 160 },
        .init(id: "wpm180", title: "Supersonic", blurb: "180+ words per minute.", icon: "bolt.fill", tier: .platinum) { s,_ in s.avgWPM >= 180 },
        .init(id: "wpm200", title: "Auctioneer", blurb: "200+ words per minute.", icon: "bolt.fill", tier: .platinum) { s,_ in s.avgWPM >= 200 },
        .init(id: "wpm225", title: "Velocity", blurb: "225+ words per minute.", icon: "hare.fill", tier: .platinum) { s,_ in s.avgWPM >= 225 },
        .init(id: "wpm250", title: "Motormouth", blurb: "250+ words per minute.", icon: "bolt.trianglebadge.exclamationmark.fill", tier: .diamond) { s,_ in s.avgWPM >= 250 },
        .init(id: "wpm300", title: "Speed of Sound", blurb: "300+ words per minute.", icon: "airplane", tier: .diamond) { s,_ in s.avgWPM >= 300 },
    ]
    private static let cat_Big_Days: [Achievement] = [
        .init(id: "bd500", title: "Warm Morning", blurb: "500 words in a single day.", icon: "sunrise.fill", tier: .bronze) { s,_ in s.bestDayWords >= 500 },
        .init(id: "bd1k", title: "Productive Day", blurb: "1,000 words in a single day.", icon: "sun.max.fill", tier: .bronze) { s,_ in s.bestDayWords >= 1000 },
        .init(id: "bd1200", title: "Solid Day", blurb: "1,200 words in a single day.", icon: "sun.max.fill", tier: .bronze) { s,_ in s.bestDayWords >= 1200 },
        .init(id: "bd1750", title: "Heads Down", blurb: "1,750 words in a single day.", icon: "sun.max.fill", tier: .bronze) { s,_ in s.bestDayWords >= 1750 },
        .init(id: "bd2k", title: "Big Day", blurb: "2,000 words in a single day.", icon: "calendar.badge.clock", tier: .silver) { s,_ in s.bestDayWords >= 2000 },
        .init(id: "bd3k", title: "On a Tear", blurb: "3,000 words in a single day.", icon: "flame.fill", tier: .silver) { s,_ in s.bestDayWords >= 3000 },
        .init(id: "bd4k", title: "Deep Work", blurb: "4,000 words in a single day.", icon: "scope", tier: .silver) { s,_ in s.bestDayWords >= 4000 },
        .init(id: "bigday", title: "Marathon", blurb: "5,000 words in a single day.", icon: "figure.run", tier: .gold) { s,_ in s.bestDayWords >= 5000 },
        .init(id: "bd6k", title: "Sprint Day", blurb: "6,000 words in a single day.", icon: "figure.run.circle.fill", tier: .gold) { s,_ in s.bestDayWords >= 6000 },
        .init(id: "bd7k", title: "Locked In", blurb: "7,500 words in a single day.", icon: "scope", tier: .gold) { s,_ in s.bestDayWords >= 7500 },
        .init(id: "bd8k", title: "Powerhouse Day", blurb: "8,000 words in a single day.", icon: "bolt.heart.fill", tier: .gold) { s,_ in s.bestDayWords >= 8000 },
        .init(id: "big10k", title: "Ultramarathon", blurb: "10,000 words in a single day.", icon: "figure.run.circle.fill", tier: .gold) { s,_ in s.bestDayWords >= 10000 },
        .init(id: "bd12k", title: "Machine Day", blurb: "12,000 words in a single day.", icon: "gearshape.2.fill", tier: .gold) { s,_ in s.bestDayWords >= 12000 },
        .init(id: "bd15k", title: "Unstoppable Day", blurb: "15,000 words in a single day.", icon: "hare.fill", tier: .platinum) { s,_ in s.bestDayWords >= 15000 },
        .init(id: "bd20k", title: "Monster Day", blurb: "20,000 words in a single day.", icon: "flame.circle.fill", tier: .platinum) { s,_ in s.bestDayWords >= 20000 },
        .init(id: "bd25k", title: "Day of Legend", blurb: "25,000 words in a single day.", icon: "crown.fill", tier: .platinum) { s,_ in s.bestDayWords >= 25000 },
        .init(id: "bd50k", title: "Impossible Day", blurb: "50,000 words in a single day.", icon: "diamond.fill", tier: .diamond) { s,_ in s.bestDayWords >= 50000 },
        .init(id: "bd100k", title: "Day of the Trillion", blurb: "100,000 words in a single day.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.bestDayWords >= 100000 },
    ]
    private static let cat_Time_Saved: [Achievement] = [
        .init(id: "sv1h", title: "An Hour Back", blurb: "1 hour saved versus typing.", icon: "clock.fill", tier: .bronze) { s,_ in s.timeSavedMinutes >= 60 },
        .init(id: "sv2h", title: "Two Hours Saved", blurb: "2 hours saved versus typing.", icon: "clock.fill", tier: .bronze) { s,_ in s.timeSavedMinutes >= 120 },
        .init(id: "sv5h", title: "Half a Day", blurb: "5 hours saved versus typing.", icon: "clock.badge.checkmark", tier: .silver) { s,_ in s.timeSavedMinutes >= 300 },
        .init(id: "saver", title: "Time Lord", blurb: "10 hours saved versus typing.", icon: "clock.arrow.circlepath", tier: .silver) { s,_ in s.timeSavedMinutes >= 600 },
        .init(id: "sv25h", title: "A Full Day", blurb: "25 hours saved versus typing.", icon: "calendar.day.timeline.left", tier: .gold) { s,_ in s.timeSavedMinutes >= 1500 },
        .init(id: "save50h", title: "Time Wizard", blurb: "50 hours saved versus typing.", icon: "hourglass", tier: .gold) { s,_ in s.timeSavedMinutes >= 3000 },
        .init(id: "sv75h", title: "Three Days Saved", blurb: "75 hours saved versus typing.", icon: "hourglass", tier: .gold) { s,_ in s.timeSavedMinutes >= 4500 },
        .init(id: "sv100h", title: "Time Bank", blurb: "100 hours saved versus typing.", icon: "banknote.fill", tier: .platinum) { s,_ in s.timeSavedMinutes >= 6000 },
        .init(id: "sv150h", title: "A Week Reclaimed", blurb: "150 hours saved versus typing.", icon: "calendar.badge.clock", tier: .platinum) { s,_ in s.timeSavedMinutes >= 9000 },
        .init(id: "sv200h", title: "Time Hoarder", blurb: "200 hours saved versus typing.", icon: "banknote.fill", tier: .platinum) { s,_ in s.timeSavedMinutes >= 12000 },
        .init(id: "sv250h", title: "Time Bender", blurb: "250 hours saved versus typing.", icon: "hourglass.bottomhalf.filled", tier: .platinum) { s,_ in s.timeSavedMinutes >= 15000 },
        .init(id: "sv500h", title: "Time Tycoon", blurb: "500 hours saved versus typing.", icon: "banknote.fill", tier: .platinum) { s,_ in s.timeSavedMinutes >= 30000 },
        .init(id: "sv750h", title: "A Month Back", blurb: "750 hours saved versus typing.", icon: "calendar.circle.fill", tier: .platinum) { s,_ in s.timeSavedMinutes >= 45000 },
        .init(id: "sv1000h", title: "Thousand Hours", blurb: "1,000 hours saved versus typing.", icon: "infinity", tier: .diamond) { s,_ in s.timeSavedMinutes >= 60000 },
        .init(id: "sv2500h", title: "Time Sovereign", blurb: "2,500 hours saved versus typing.", icon: "crown.fill", tier: .diamond) { s,_ in s.timeSavedMinutes >= 150000 },
        .init(id: "sv5000h", title: "Master of Time", blurb: "5,000 hours saved versus typing.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.timeSavedMinutes >= 300000 },
    ]
    private static let cat_Airtime: [Achievement] = [
        .init(id: "air10m", title: "Warming the Mic", blurb: "10 minutes of talking, total.", icon: "waveform", tier: .bronze) { s,_ in s.totalSeconds >= 600 },
        .init(id: "air30m", title: "Half Hour Live", blurb: "30 minutes of talking, total.", icon: "waveform", tier: .bronze) { s,_ in s.totalSeconds >= 1800 },
        .init(id: "air1h", title: "An Hour Out Loud", blurb: "1 hour of talking, total.", icon: "waveform.circle", tier: .silver) { s,_ in s.totalSeconds >= 3600 },
        .init(id: "air3h", title: "Three Hours Live", blurb: "3 hours of talking, total.", icon: "waveform.circle.fill", tier: .silver) { s,_ in s.totalSeconds >= 10800 },
        .init(id: "air5h", title: "Five Hours Spoken", blurb: "5 hours of talking, total.", icon: "mic.circle.fill", tier: .silver) { s,_ in s.totalSeconds >= 18000 },
        .init(id: "air10h", title: "Ten Hours Live", blurb: "10 hours of talking, total.", icon: "mic.circle.fill", tier: .gold) { s,_ in s.totalSeconds >= 36000 },
        .init(id: "air24h", title: "A Full Day Talking", blurb: "24 hours of talking, total.", icon: "clock.badge.fill", tier: .gold) { s,_ in s.totalSeconds >= 86400 },
        .init(id: "air50h", title: "Fifty Hours Live", blurb: "50 hours of talking, total.", icon: "mic.fill", tier: .platinum) { s,_ in s.totalSeconds >= 180000 },
        .init(id: "air100h", title: "Hundred Hours Out Loud", blurb: "100 hours of talking, total.", icon: "mic.fill", tier: .platinum) { s,_ in s.totalSeconds >= 360000 },
        .init(id: "air250h", title: "Voice Marathoner", blurb: "250 hours of talking, total.", icon: "infinity", tier: .platinum) { s,_ in s.totalSeconds >= 900000 },
        .init(id: "air500h", title: "Endless Voice", blurb: "500 hours of talking, total.", icon: "infinity.circle.fill", tier: .diamond) { s,_ in s.totalSeconds >= 1800000 },
    ]
    // "Explore Verba" — the gamified onboarding: a checklist of every feature + shortcut, ordered
    // roughly how you'd discover them. Existing ids are preserved so earned badges stay earned.
    private static let cat_Explore_Verba: [Achievement] = [
        .init(id: "ex_dictate", title: "First Words", blurb: "Make your first dictation.", icon: "mic.fill", tier: .bronze) { s,_ in s.totalCount >= 1 },
        .init(id: "flower", title: "In the Flow", blurb: "Dictate in Flow (verbatim) mode.", icon: "waveform", tier: .bronze) { _,f in f.contains(.usedFlow) },
        .init(id: "polisher", title: "Polished", blurb: "Use Polish mode to clean up your speech.", icon: "sparkles", tier: .bronze) { _,f in f.contains(.usedPolish) },
        .init(id: "intentful", title: "Intentful", blurb: "Use Intent mode — say what you want done.", icon: "scope", tier: .bronze) { _,f in f.contains(.usedIntent) },
        .init(id: "polyglot", title: "Polyglot", blurb: "Translate live with Translate mode.", icon: "globe", tier: .bronze) { _,f in f.contains(.usedTranslate) },
        .init(id: "seer", title: "Second Sight", blurb: "Use Context mode — Verba reads your screen.", icon: "eye.fill", tier: .silver) { _,f in f.contains(.usedContext) },
        .init(id: "coder", title: "Shipped It", blurb: "Use Coding mode.", icon: "chevron.left.forwardslash.chevron.right", tier: .bronze) { _,f in f.contains(.usedCoding) },
        .init(id: "changedstyle", title: "Stylist", blurb: "Cycle a style on top of a mode (Fn + ] / [).", icon: "paintbrush", tier: .bronze) { _,f in f.contains(.changedStyle) },
        .init(id: "notetaker", title: "Voice Note", blurb: "Capture a voice note (Fn + Z).", icon: "doc.text", tier: .bronze) { _,f in f.contains(.usedVoiceNote) },
        .init(id: "savednote", title: "First Note", blurb: "Save a long-form note in the Notes tab.", icon: "note.text", tier: .bronze) { _,f in f.contains(.savedNote) },
        .init(id: "taggednote", title: "Filed It", blurb: "Tag a note with a #hashtag (Bear-style filing).", icon: "number", tier: .bronze) { _,f in f.contains(.taggedNote) },
        .init(id: "lockednote", title: "Top Secret", blurb: "Protect a note with a password.", icon: "lock.fill", tier: .silver) { _,f in f.contains(.lockedNote) },
        .init(id: "doer", title: "Voice To-do", blurb: "Capture a to-do by voice (Fn + T).", icon: "checklist", tier: .bronze) { _,f in f.contains(.usedVoiceTodo) },
        .init(id: "createdtask", title: "Task Maker", blurb: "Create a task in the Task Manager.", icon: "checklist.checked", tier: .bronze) { _,f in f.contains(.createdTask) },
        .init(id: "checkedtask", title: "Done!", blurb: "Check off a task.", icon: "checkmark.circle.fill", tier: .bronze) { _,f in f.contains(.checkedTask) },
        .init(id: "usedscratch", title: "Scratch That", blurb: "Jot something in the Scratchpad.", icon: "pencil.and.scribble", tier: .bronze) { _,f in f.contains(.usedScratchpad) },
        .init(id: "useddict", title: "Word Wise", blurb: "Teach Verba a word in the Dictionary.", icon: "character.book.closed.fill", tier: .bronze) { _,f in f.contains(.usedDictionary) },
        .init(id: "usedsnippet", title: "Snippet Saver", blurb: "Save a snippet you can insert by voice.", icon: "text.append", tier: .bronze) { _,f in f.contains(.usedSnippet) },
        .init(id: "shaper", title: "Reshaper", blurb: "Transform selected text (⌥ + X).", icon: "wand.and.stars", tier: .bronze) { _,f in f.contains(.usedTransform) },
        .init(id: "commander", title: "Hands Free", blurb: "Run a voice Action with JARVIS (Fn + X).", icon: "wand.and.rays", tier: .silver) { _,f in f.contains(.usedActionMode) },
        .init(id: "connectedapp", title: "Plugged In", blurb: "Connect an app for JARVIS to act on.", icon: "app.connected.to.app.below.fill", tier: .silver) { _,f in f.contains(.connectedApp) },
        // Shortcuts — each blurb names the keys, so the badge doubles as a cheat sheet.
        .init(id: "pushtotalk", title: "Push to Talk", blurb: "Hold Fn while you speak, release to send.", icon: "hand.tap.fill", tier: .bronze) { _,f in f.contains(.usedPushToTalk) },
        .init(id: "bynumbers", title: "By the Numbers", blurb: "Pick a mode with Fn + 1…9.", icon: "number.circle", tier: .bronze) { _,f in f.contains(.pickedModeNum) },
        .init(id: "quickswitch", title: "Quick Switch", blurb: "Switch mode mid-sentence — Fn + Tab (or ⌥).", icon: "arrow.left.arrow.right", tier: .bronze) { _,f in f.contains(.switchedMode) },
        .init(id: "takeabreath", title: "Take a Breath", blurb: "Pause a recording with ⌃ (Control).", icon: "pause.circle", tier: .bronze) { _,f in f.contains(.pausedRec) },
        .init(id: "nevermind", title: "Never Mind", blurb: "Cancel a recording with Esc.", icon: "xmark.circle", tier: .bronze) { _,f in f.contains(.cancelledRec) },
        .init(id: "ataglance", title: "At a Glance", blurb: "Peek at today's to-dos — ⌥ + Fn.", icon: "calendar.day.timeline.left", tier: .bronze) { _,f in f.contains(.usedTodoGlance) },
        .init(id: "chainreaction", title: "Chain Reaction", blurb: "Start a new dictation while the last still processes.", icon: "square.stack.3d.up.fill", tier: .silver) { _,f in f.contains(.chainedDictation) },
        .init(id: "makeityours", title: "Make It Yours", blurb: "Build your own custom mode (Settings ▸ Modes).", icon: "slider.horizontal.3", tier: .silver) { _,f in f.contains(.createdCustomMode) },
        .init(id: "yourengine", title: "Your Engine", blurb: "Run on a local model or your own AI key.", icon: "cpu", tier: .silver) { _,f in f.contains(.usedOwnAI) },
        .init(id: "rewind", title: "Rewind", blurb: "Re-run a past dictation in another mode from History.", icon: "clock.arrow.circlepath", tier: .bronze) { _,f in f.contains(.reworkedHistory) },
        .init(id: "dropdone", title: "Drop & Done", blurb: "Transcribe an audio or video file.", icon: "waveform.and.magnifyingglass", tier: .bronze) { _,f in f.contains(.transcribedFile) },
        .init(id: "allmodes", title: "Mode Master", blurb: "Try all six dictation modes.", icon: "square.grid.3x3.fill", tier: .gold) { _,f in [GameFlag.usedFlow, .usedPolish, .usedIntent, .usedTranslate, .usedContext, .usedCoding].allSatisfy { f.contains($0) } },
        .init(id: "explorer_all", title: "Verba Explorer", blurb: "Try every core feature and shortcut. You know Verba inside out.", icon: "trophy.fill", tier: .diamond) { _,f in
            [GameFlag.usedFlow, .usedPolish, .usedIntent, .usedTranslate, .usedContext, .usedCoding,
             .usedVoiceNote, .usedVoiceTodo, .usedActionMode, .usedTransform, .changedStyle,
             .savedNote, .taggedNote, .lockedNote, .createdTask, .checkedTask,
             .usedScratchpad, .usedDictionary, .usedSnippet, .connectedApp].allSatisfy { f.contains($0) } },
    ]
    // Fun, legit Special badges — lit up by an on-device word scan of your own text + your
    // computer's time/timezone. Nothing is uploaded; it's just for the joy of the unlock.
    private static func said(_ key: String) -> Int { Gamification.shared.counter(key) }
    private static let cat_Special: [Achievement] = [
        // Time of day / week
        .init(id: "dawn", title: "Early Bird", blurb: "Dictate at dawn (5–7 AM).", icon: "sunrise.fill", tier: .silver) { _,f in f.contains(.earlyBird) },
        .init(id: "night", title: "Night Owl", blurb: "Dictate after midnight.", icon: "moon.stars.fill", tier: .silver) { _,f in f.contains(.nightOwl) },
        .init(id: "roundclock", title: "Round the Clock", blurb: "Dictate both after midnight and at dawn.", icon: "clock.badge.checkmark.fill", tier: .gold) { _,f in f.contains(.nightOwl) && f.contains(.earlyBird) },
        .init(id: "midnightoil", title: "Burning the Midnight Oil", blurb: "Ship something between 1 and 5 AM.", icon: "flame.fill", tier: .gold) { _,f in f.contains(.lateNightShip) },
        .init(id: "weekendwar", title: "Weekend Warrior", blurb: "Dictate on a Saturday or Sunday.", icon: "figure.run", tier: .bronze) { _,f in f.contains(.weekendWarrior) },
        .init(id: "fridayfeel", title: "Friday Feeling", blurb: "Still going on a Friday evening.", icon: "party.popper.fill", tier: .bronze) { _,f in f.contains(.fridayEve) },
        .init(id: "mondaymotiv", title: "Monday Motivation", blurb: "Up and dictating on a Monday morning.", icon: "sun.max.fill", tier: .bronze) { _,f in f.contains(.mondayAM) },
        .init(id: "lunchlaunch", title: "Lunch & Launch", blurb: "Working through the lunch hour.", icon: "fork.knife", tier: .bronze) { _,f in f.contains(.lunchBreak) },
        .init(id: "holidayhustle", title: "Holiday Hustler", blurb: "Dictate on a holiday. The grind never stops.", icon: "gift.fill", tier: .gold) { _,f in f.contains(.holidayHustle) },
        .init(id: "comeback", title: "Comeback Kid", blurb: "Return to Verba after a week away.", icon: "arrow.uturn.up.circle.fill", tier: .silver) { _,f in f.contains(.comebackKid) },
        // Where in the world (your computer's timezone)
        .init(id: "globetrot", title: "Globe Trotter", blurb: "Dictate from 2 different time zones.", icon: "globe.americas.fill", tier: .silver) { _,_ in Gamification.shared.timezoneCount >= 2 },
        .init(id: "nomad", title: "Digital Nomad", blurb: "Dictate from 3 different time zones.", icon: "airplane", tier: .gold) { _,_ in Gamification.shared.timezoneCount >= 3 },
        .init(id: "jetsetter", title: "Jet Setter", blurb: "Dictate from 5 different time zones.", icon: "airplane.departure", tier: .platinum) { _,_ in Gamification.shared.timezoneCount >= 5 },
        // Politeness — being nice to the AI 🤝
        .init(id: "manners", title: "Mind Your Manners", blurb: "Say thank you to your AI.", icon: "hands.sparkles.fill", tier: .bronze) { _,_ in said("thanks") >= 1 },
        .init(id: "gracious", title: "Gracious", blurb: "Thank the AI 10 times. It appreciates it.", icon: "heart.fill", tier: .silver) { _,_ in said("thanks") >= 10 },
        .init(id: "aiwhisperer", title: "AI Whisperer", blurb: "Thank the AI 50 times. Friends for life.", icon: "sparkles", tier: .gold) { _,_ in said("thanks") >= 50 },
        .init(id: "polite", title: "Please & Thank You", blurb: "Say “please” 5 times.", icon: "hand.raised.fill", tier: .bronze) { _,_ in said("please") >= 5 },
        .init(id: "noworries", title: "No Worries", blurb: "Apologize 5 times (to a machine).", icon: "face.smiling", tier: .bronze) { _,_ in said("sorry") >= 5 },
        // Vibe-coding & AI-native founder life 🚀
        .init(id: "shipit", title: "Ship It", blurb: "Say “ship it” once. Done is better than perfect.", icon: "paperplane.fill", tier: .bronze) { _,_ in said("ship") >= 1 },
        .init(id: "serialshipper", title: "Serial Shipper", blurb: "Say “ship it” 25 times. Velocity.", icon: "shippingbox.fill", tier: .gold) { _,_ in said("ship") >= 25 },
        .init(id: "bughunter", title: "Bug Hunter", blurb: "Mention a bug 10 times. It's never your code.", icon: "ant.fill", tier: .silver) { _,_ in said("bug") >= 10 },
        .init(id: "vibecoder", title: "Vibe Coder", blurb: "Drop 10 coding words (refactor, merge, deploy…).", icon: "chevron.left.forwardslash.chevron.right", tier: .silver) { _,_ in said("vibe") >= 10 },
        .init(id: "prompteng", title: "Prompt Engineer", blurb: "Talk about AI 10 times.", icon: "brain.head.profile", tier: .silver) { _,_ in said("ai") >= 10 },
        .init(id: "ainative", title: "AI Native", blurb: "Talk about AI 50 times. You live in the future.", icon: "cpu.fill", tier: .gold) { _,_ in said("ai") >= 50 },
        .init(id: "foundermode", title: "Founder Mode", blurb: "Mention startup life 10 times (MRR, users, runway…).", icon: "chart.line.uptrend.xyaxis", tier: .silver) { _,_ in said("founder") >= 10 },
        .init(id: "raising", title: "Raising a Round", blurb: "Founder-talk 50 times. To the moon.", icon: "banknote.fill", tier: .gold) { _,_ in said("founder") >= 50 },
        .init(id: "bigdreamer", title: "Big Dreamer", blurb: "Say “billion”, “unicorn” or “change the world”.", icon: "moon.stars.fill", tier: .silver) { _,_ in said("dreamer") >= 1 },
        .init(id: "moonshot", title: "Moonshot", blurb: "Dream big 25 times.", icon: "sparkle", tier: .gold) { _,_ in said("dreamer") >= 25 },
        .init(id: "ideamachine", title: "Idea Machine", blurb: "Start 25 thoughts with an idea (“what if…”).", icon: "lightbulb.fill", tier: .silver) { _,_ in said("idea") >= 25 },
        .init(id: "hypebeast", title: "Hype Beast", blurb: "Say “let's go / amazing / génial” 25 times.", icon: "flame.circle.fill", tier: .silver) { _,_ in said("hype") >= 25 },
        .init(id: "caffeinated", title: "Caffeinated", blurb: "Mention coffee 5 times. Fuel.", icon: "cup.and.saucer.fill", tier: .bronze) { _,_ in said("coffee") >= 5 },
    ]

}
