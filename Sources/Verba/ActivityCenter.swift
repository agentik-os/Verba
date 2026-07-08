import SwiftUI
import AppKit
import Combine

// MARK: - Activity model

/// One in-flight (or just-finished) background operation shown as a chip in the bottom-right stack.
/// While `done == false` the chip shows a spinner + label; on finish it flips to ✓ / ✗ with the
/// result label, then auto-fades after a short delay. Multiple items stack so every concurrent task
/// stays visible (a dictation processing while a to-do saves while JARVIS runs, …).
struct ActivityItem: Identifiable, Equatable {
    enum Kind: Equatable { case dictation, todo, note, jarvis }
    let id: UUID
    let kind: Kind
    var label: String
    var done: Bool
    var ok: Bool
    let startedAt: Date

    /// SF Symbol for the kind, shown once the spinner is replaced by the terminal glyph.
    var kindSymbol: String {
        switch kind {
        case .dictation: return "waveform"
        case .todo:      return "checklist"
        case .note:      return "doc.text"
        case .jarvis:    return "sparkles"
        }
    }
}

// MARK: - Activity center (singleton)

/// Lightweight, in-memory registry of background operations for the activity-toast overlay.
/// `begin` returns a token; `finish(token, …)` flips it to a terminal chip that auto-removes after
/// ~3s. All mutations happen on the main thread (every call site is already main-actor). Also owns
/// the bridge that mirrors the JARVIS `ActionFeedStore` state machine into activity chips.
final class ActivityCenter: ObservableObject {
    static let shared = ActivityCenter()

    /// Oldest first, so new chips appear at the bottom of the stack (nearest the corner).
    @Published private(set) var items: [ActivityItem] = []

    /// How long a finished chip lingers before auto-fading.
    private let lingerSeconds: TimeInterval = 3.0

    private init() { wireJarvisBridge() }

    // MARK: Public API

    /// Register a new in-flight operation and return its token. Label is what shows next to the spinner.
    @discardableResult
    func begin(kind: ActivityItem.Kind, label: String) -> UUID {
        let item = ActivityItem(id: UUID(), kind: kind, label: label, done: false, ok: true, startedAt: Date())
        items.append(item)
        return item.id
    }

    /// Update the live label of an in-flight chip (e.g. "Transcribing…" → "Reprompting…").
    func update(_ token: UUID, label: String) {
        guard let idx = items.firstIndex(where: { $0.id == token }), !items[idx].done else { return }
        items[idx].label = label
    }

    /// Flip a chip to its terminal state (✓ on success, ✗ on failure), then auto-remove after a beat.
    func finish(_ token: UUID, ok: Bool = true, resultLabel: String? = nil) {
        guard let idx = items.firstIndex(where: { $0.id == token }) else { return }
        items[idx].done = true
        items[idx].ok = ok
        if let resultLabel, !resultLabel.isEmpty { items[idx].label = resultLabel }
        DispatchQueue.main.asyncAfter(deadline: .now() + lingerSeconds) { [weak self] in
            self?.items.removeAll { $0.id == token }
        }
    }

    /// Remove a chip immediately (a non-event: silence tap, cancellation, a JARVIS row handed to the
    /// user for confirmation) — no ✓/✗ flash.
    func drop(_ token: UUID) {
        items.removeAll { $0.id == token }
    }

    // MARK: JARVIS bridge

    /// Feed-item id → activity token, for the JARVIS actions currently mirrored as chips.
    private var jarvisTokens: [UUID: UUID] = [:]
    private var bridgeCancellable: AnyCancellable?

    /// Mirror the JARVIS action feed's state machine into activity chips: thinking/running items are
    /// active (spinner); done → ✓, failed → ✗. Anything else (awaiting confirm/clarify/input, cancelled,
    /// chat, or the row vanished) drops the spinner — those are either user-owned or non-events.
    private func wireJarvisBridge() {
        // DISABLED: JARVIS actions already show in the centered Action feed widget (with their own
        // Done state). Mirroring them into a bottom-right toast produced a duplicate "Done" clone.
        // The bottom-right toasts are only for genuinely-background ops (a to-do captured / a note
        // transcribing while you do something else) that otherwise have no visible confirmation.
        // (syncJarvis is kept below but no longer wired.)
    }

    private func syncJarvis(_ feed: [ActionFeedItem]) {
        let byID = Dictionary(feed.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // Begin (or relabel) chips for in-flight actions.
        for item in feed where item.status == .thinking || item.status == .running {
            if let token = jarvisTokens[item.id] {
                update(token, label: jarvisLabel(item))
            } else {
                jarvisTokens[item.id] = begin(kind: .jarvis, label: jarvisLabel(item))
            }
        }

        // Resolve chips whose feed row left the in-flight state (or disappeared entirely).
        for (feedID, token) in jarvisTokens {
            switch byID[feedID]?.status {
            case .thinking, .running:
                continue
            case .done:
                finish(token, ok: true, resultLabel: byID[feedID].map(jarvisResultLabel))
                jarvisTokens[feedID] = nil
            case .failed:
                finish(token, ok: false, resultLabel: L("JARVIS failed"))
                jarvisTokens[feedID] = nil
            default:
                // pendingConfirm / clarify / needsInput (user-owned) or cancelled / chat / gone.
                drop(token)
                jarvisTokens[feedID] = nil
            }
        }
    }

    private func jarvisLabel(_ item: ActionFeedItem) -> String {
        let t = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if item.status == .thinking || t.isEmpty { return L("JARVIS: thinking…") }
        return "JARVIS: \(t)"
    }

    private func jarvisResultLabel(_ item: ActionFeedItem) -> String {
        let t = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? L("JARVIS done") : "JARVIS: \(t)"
    }
}

// MARK: - Toast overlay view

/// A small, non-intrusive vertical stack of activity chips. Purely informational — it never captures
/// clicks (the panel sets `ignoresMouseEvents`), so it can't block whatever the user is doing.
struct ActivityToastsView: View {
    @ObservedObject var center = ActivityCenter.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(center.items) { item in
                chip(item)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(12)
        .frame(maxWidth: 360, alignment: .trailing)
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: center.items)
    }

    @ViewBuilder private func chip(_ item: ActivityItem) -> some View {
        HStack(spacing: 9) {
            glyph(item)
                .frame(width: 16, height: 16)
            Text(item.label.isEmpty ? L("Working…") : item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1).truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 13).padding(.vertical, 9)
        .glass(in: Capsule())
        .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .frame(maxWidth: 340, alignment: .trailing)
    }

    @ViewBuilder private func glyph(_ item: ActivityItem) -> some View {
        if !item.done {
            ProgressView().controlSize(.small)
        } else if item.ok {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(VerbaAppearance.shared.accentOr(.green))
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Floating panel controller

/// Owns the borderless, click-through activity-toast panel anchored bottom-right. Auto-shows while
/// there's ≥1 item (and the setting is on) and hides when the stack empties. Cloned from the
/// TodoGlance / ActionFeed panel pattern, minus the key-focus / dismiss monitors (it's informational).
final class ActivityToastsController {
    static let shared = ActivityToastsController()

    private var panel: NSPanel?
    private var resizeObserver: NSObjectProtocol?
    private var itemsCancellable: AnyCancellable?
    private var settingCancellable: AnyCancellable?
    private let margin: CGFloat = 18

    /// Begin observing the activity center + the gating setting. Called once at launch.
    func start() {
        itemsCancellable = ActivityCenter.shared.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
        settingCancellable = Settings.shared.$showActivityToasts
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        let shouldShow = Settings.shared.showActivityToasts && !ActivityCenter.shared.items.isEmpty
        if shouldShow { show() } else { hide() }
    }

    private func build() {
        guard panel == nil else { return }
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 80),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false                 // each chip carries its own soft shadow
        p.ignoresMouseEvents = true          // purely informational: never block clicks
        let host = NSHostingController(rootView: ActivityToastsView())
        host.sizingOptions = [.preferredContentSize]
        host.view.wantsLayer = true
        p.contentViewController = host
        p.alphaValue = 1
        panel = p
        p.layoutIfNeeded()
    }

    private func show() {
        build()
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        reposition(panel, on: screen.visibleFrame)
        installResizeObserver(on: panel)
        panel.orderFrontRegardless()
    }

    private func hide() {
        removeResizeObserver()
        panel?.orderOut(nil)
    }

    /// Pin the panel to the bottom-right of the visible frame, honoring its current fitting size.
    private func reposition(_ panel: NSPanel, on vf: NSRect) {
        let fit = panel.contentView?.fittingSize ?? NSSize(width: 360, height: 80)
        let frameSize = panel.frameRect(forContentRect: NSRect(origin: .zero, size: fit)).size
        let x = vf.maxX - frameSize.width - margin
        let y = vf.minY + margin
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: frameSize), display: true)
    }

    /// The stack grows/shrinks as chips come and go; AppKit keeps the bottom-left origin fixed, so
    /// re-anchor to the bottom-right on every resize (keeping the right edge + bottom margin fixed).
    private func installResizeObserver(on panel: NSPanel) {
        removeResizeObserver()
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: panel, queue: .main
        ) { [weak panel] _ in
            guard let panel, let screen = panel.screen ?? NSScreen.main else { return }
            let vf = screen.visibleFrame
            let s = panel.frame.size
            let origin = NSPoint(x: vf.maxX - s.width - 18, y: vf.minY + 18)
            if abs(panel.frame.origin.x - origin.x) > 0.5 || abs(panel.frame.origin.y - origin.y) > 0.5 {
                panel.setFrameOrigin(origin)
            }
        }
    }

    private func removeResizeObserver() {
        if let o = resizeObserver { NotificationCenter.default.removeObserver(o); resizeObserver = nil }
    }
}
