import SwiftUI

/// Usage-pulled discovery (roadmap §8a). After enough real use, surfaces ONE small, dismissable hint
/// suggesting a relevant feature the user hasn't turned on. Budget: at most one hint per day; a
/// dismissed hint never returns. 100% on-device: it reads only the local lifetime dictation count
/// and which features are enabled, never transcript content.
final class DiscoveryEngine: ObservableObject {
    static let shared = DiscoveryEngine()

    @Published private(set) var hint: Hint?
    /// Bumped when the user taps a hint's CTA — MainWindow observes it and opens the Features page.
    @Published var openFeaturesSignal = 0
    /// Bumped by a page's shortcut-hint bar "Change in Settings" button. MainWindow navigates to
    /// Settings; SettingsView reads `wantShortcuts` on appear to jump straight to the Shortcuts section.
    @Published var openShortcutsSignal = 0
    var wantShortcuts = false

    struct Hint: Identifiable, Equatable {
        let id: String        // == the suggested feature key
        let text: String
        let cta: String
    }

    private let d = UserDefaults.standard
    private var dismissed: Set<String> {
        get { Set(d.stringArray(forKey: "discovery.dismissed") ?? []) }
        set { d.set(Array(newValue), forKey: "discovery.dismissed") }
    }
    private var today: Int { Int(Date().timeIntervalSince1970 / 86_400) }

    /// Count-based candidates in priority order. Content-based and frontmost-app triggers are
    /// intentionally omitted for privacy. Each suggests turning ON an inactive feature.
    private func candidate() -> Hint? {
        let n = Stats.shared.totalCount
        let s = Settings.shared
        let rules: [(Int, String, String, String)] = [
            (10, FeatureFlags.notes, "You dictate a lot. Notes records long thoughts and structures them for you.", "See Notes"),
            (15, FeatureFlags.tasks, "Speaking your to-dos out loud? Tasks turns speech into organized task lists.", "See Tasks"),
            (30, FeatureFlags.jarvis, "Ready for more? JARVIS acts across 1,000+ apps by voice: send, create, schedule.", "Meet JARVIS"),
        ]
        for (threshold, key, text, cta) in rules
        where n >= threshold && !s.isFeatureEnabled(key) && !dismissed.contains(key) {
            return Hint(id: key, text: text, cta: cta)
        }
        return nil
    }

    /// Recompute the current hint, honoring the one-per-day budget. Call on Home appear + after a dictation.
    func refresh() {
        guard let c = candidate() else { hint = nil; return }
        let last = d.integer(forKey: "discovery.lastDay")
        let shownToday = d.string(forKey: "discovery.todayHint")
        if last == today {
            // A hint was already surfaced today: keep showing only if it's the same one.
            hint = (shownToday == c.id) ? c : nil
            return
        }
        d.set(today, forKey: "discovery.lastDay")
        d.set(c.id, forKey: "discovery.todayHint")
        hint = c
    }

    /// "Don't suggest this again" — permanent for this feature.
    func dismiss() {
        guard let h = hint else { return }
        var set = dismissed; set.insert(h.id); dismissed = set
        hint = nil
    }

    /// CTA tapped → open Features; hide the bubble for now (it's not permanently dismissed).
    func act() {
        openFeaturesSignal &+= 1
        hint = nil
    }
}

/// A small, non-modal discovery bubble shown at the top of Home when a hint is available.
struct DiscoveryHintBubble: View {
    @ObservedObject private var discovery = DiscoveryEngine.shared

    var body: some View {
        Group {
            if let h = discovery.hint {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 14)).foregroundStyle(.tint).padding(.top, 1)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(h.text).font(.callout).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 14) {
                            Button(h.cta) { discovery.act() }.buttonStyle(.borderless).font(.callout.weight(.semibold))
                            Button(L("Don't suggest this again")) { discovery.dismiss() }
                                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear { discovery.refresh() }
    }
}
