import SwiftUI
import AppKit
import Combine

// MARK: - Feed item model

/// One entry in the JARVIS action feed: a thing the assistant understood and is doing (or proposing).
/// Persisted (last N) so reopening the panel shows recent activity, like a quiet activity log.
struct ActionFeedItem: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case thinking       // the planner is reasoning / reading context
        case pendingConfirm // a WRITE is proposed and waiting on the user's Confirm
        case running        // confirmed; the executor is performing it
        case done           // completed successfully
        case failed         // the executor (or planner) errored
        case clarify        // the planner needs the user to pick between candidates
        case needsInput     // the planner needs the user to type missing values (editable fields)
        case cancelled      // the user dismissed a pending write
        case chat           // a conversational reply, nothing to execute
    }

    let id: UUID
    /// Short headline, e.g. the planner summary or the action label.
    var title: String
    /// Composio toolkit slug for the app logo (gmail, slack, …); nil → an SF-symbol fallback.
    var appLogoSlug: String?
    /// SF Symbol fallback when there's no app logo (the VerbaAction icon).
    var symbol: String
    var status: Status
    /// JARVIS conversational lines, shown stacked under the title.
    var messages: [String]
    var createdAt: Date

    /// A localized error line surfaced on `.failed`.
    var errorText: String?

    /// A suggested next step offered after this action succeeds (e.g. "Invite people to the event?").
    /// `followupIntent` is the spoken request re-planned if the user accepts.
    var followupQuestion: String?
    var followupIntent: String?

    init(id: UUID = UUID(), title: String, appLogoSlug: String? = nil, symbol: String = "sparkles",
         status: Status, messages: [String] = [], createdAt: Date = Date(), errorText: String? = nil) {
        self.id = id; self.title = title; self.appLogoSlug = appLogoSlug; self.symbol = symbol
        self.status = status; self.messages = messages; self.createdAt = createdAt; self.errorText = errorText
    }
}

// MARK: - Feed store (state machine)

/// The action feed's state. Holds the persisted history of recent actions plus, for the item the
/// user is currently being asked to confirm, the live `VerbaAction` + clarification (which are NOT
/// persisted — they're transient to one session). The view confirms/cancels through this store; the
/// store calls back out to whoever wired `onConfirm` (AppDelegate, which owns execution).
final class ActionFeedStore: ObservableObject {
    static let shared = ActionFeedStore()

    /// Newest first. Persisted (capped) across launches.
    @Published private(set) var items: [ActionFeedItem] = []

    /// Live, non-persisted side-tables keyed by item id:
    ///  the WRITE awaiting confirmation, and the clarification options awaiting a pick.
    @Published private(set) var pendingActions: [UUID: VerbaAction] = [:]
    @Published private(set) var clarifications: [UUID: PlanClarification] = [:]
    /// The fields to collect for a `.needsInput` item, and the user's live edits keyed by field key.
    @Published private(set) var inputRequests: [UUID: PlanInputRequest] = [:]
    @Published var inputDrafts: [UUID: [String: String]] = [:]

    /// Called when the user taps Confirm on a pending write. Wired by AppDelegate.
    var onConfirm: ((_ itemID: UUID, _ action: VerbaAction) -> Void)?
    /// Called when the user picks a clarification option (re-plan with that choice). Wired by AppDelegate.
    var onResolveChoice: ((_ itemID: UUID, _ optionID: String) -> Void)?
    /// Called when the user accepts a post-action follow-up — re-plans `intent` as a new request.
    var onFollowup: ((_ intent: String) -> Void)?

    private let maxItems = 30
    private let storeKey = "actionFeed.items.v1"

    private init() { load() }

    // MARK: Mutations

    /// Begin a new feed item in the `.thinking` state and return its id. While the planner reasons,
    /// the headline is a clean status and the (sometimes mis-heard) transcript is quoted underneath —
    /// never make the raw transcript the bold headline.
    @discardableResult
    func begin(title: String) -> UUID {
        let heard = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ActionFeedItem(title: L("Working on it…"), status: .thinking,
                                  messages: heard.isEmpty ? [] : ["\u{201C}\(heard)\u{201D}"])
        prepend(item)
        watchdog(item.id)
        return item.id
    }

    /// Safety net: if an item is still thinking/running after a while (a hung relay or a stalled
    /// executor), collapse it to a friendly failure instead of spinning forever.
    private func watchdog(_ id: UUID) {
        // A LOCAL model runs the 2-phase agentic plan (PLAN + RESOLVE) on-device and is far slower
        // than a hosted one, so give it a generous budget; a hung hosted relay still fails in ~2.5 min.
        let seconds: UInt64 = Settings.shared.repromptBackend.resolved == .localLLM ? 300 : 150
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
            if items[idx].status == .thinking || items[idx].status == .running {
                failed(id, error: L("That took too long — try again."))
            }
        }
    }

    /// Apply a resolved plan to the item: set its messages, and either surface a clarification,
    /// queue a pending write, or mark it chat/done.
    func apply(_ plan: VerbaPlan, to id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].messages = plan.messages.isEmpty ? [plan.summary].filter { !$0.isEmpty } : plan.messages
        if plan.summary.isEmpty == false { items[idx].title = plan.summary }
        // A suggested next step shown once this action succeeds (rule 8).
        if let f = plan.followup, !f.question.isEmpty, !f.intent.isEmpty {
            items[idx].followupQuestion = f.question
            items[idx].followupIntent = f.intent
        }

        if let req = plan.inputRequest, !req.tool.isEmpty, !req.fields.isEmpty {
            // The planner needs the user to type missing values into editable fields.
            items[idx].status = .needsInput
            if req.label.isEmpty == false { items[idx].title = req.label }
            items[idx].appLogoSlug = Self.logoSlug(forTool: req.tool)
            inputRequests[id] = req
            inputDrafts[id] = Dictionary(req.fields.map { ($0.key, $0.value) }, uniquingKeysWith: { a, _ in a })
        } else if let clar = plan.clarification {
            items[idx].status = .clarify
            clarifications[id] = clar
        } else if let first = plan.proposedActions.first, let action = first.action {
            items[idx].status = .pendingConfirm
            if first.label.isEmpty == false { items[idx].title = first.label }
            items[idx].symbol = action.icon
            items[idx].appLogoSlug = Self.logoSlug(for: action)
            pendingActions[id] = action
        } else {
            // No write proposed: a pure conversational / read-only answer.
            items[idx].status = .chat
        }
        persist()
    }

    /// User tapped Confirm on item `id` → mark running and hand the action to the executor.
    func confirm(_ id: UUID) {
        guard let action = pendingActions[id] else { return }
        setStatus(id, .running, messages: [L("Doing it now…")])
        pendingActions[id] = nil
        watchdog(id)
        onConfirm?(id, action)
    }

    /// User tapped Cancel on a pending write.
    func cancel(_ id: UUID) {
        pendingActions[id] = nil
        clarifications[id] = nil
        inputRequests[id] = nil
        inputDrafts[id] = nil
        setStatus(id, .cancelled, messages: [L("Cancelled.")])
    }

    /// Update one editable field of a `.needsInput` item.
    func setInputDraft(_ id: UUID, key: String, value: String) {
        inputDrafts[id, default: [:]][key] = value
    }

    /// User picked a clarification option → re-plan with it pinned.
    func resolve(_ id: UUID, optionID: String) {
        clarifications[id] = nil
        setStatus(id, .thinking, messages: [L("On it…")])
        watchdog(id)
        onResolveChoice?(id, optionID)
    }

    /// The user filled the requested fields and submitted → build the composio action from those
    /// values and run it through the normal confirm→execute path.
    func submitInput(_ id: UUID) {
        guard let req = inputRequests[id] else { return }
        let values = inputDrafts[id] ?? [:]
        // Drop empty optional fields; keep what the user typed.
        let args = values.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let action = VerbaAction.composio(tool: req.tool, label: req.label, arguments: args)
        inputRequests[id] = nil
        inputDrafts[id] = nil
        pendingActions[id] = action
        confirm(id)
    }

    /// The user accepted the post-action follow-up → re-plan its intent as a fresh request and
    /// clear the offer so it isn't shown twice.
    func acceptFollowup(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }), let intent = items[idx].followupIntent else { return }
        items[idx].followupQuestion = nil
        items[idx].followupIntent = nil
        persist()
        onFollowup?(intent)
    }

    /// The user dismissed the follow-up offer.
    func dismissFollowup(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].followupQuestion = nil
        items[idx].followupIntent = nil
        persist()
    }

    /// True when every REQUIRED field of a `.needsInput` item has a non-empty value (gates Submit).
    func inputReady(_ id: UUID) -> Bool {
        guard let req = inputRequests[id] else { return false }
        let values = inputDrafts[id] ?? [:]
        return req.fields.allSatisfy { f in
            !f.required || !(values[f.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// The executor finished. `announce` is the JARVIS success line (falls back to a generic one).
    func succeeded(_ id: UUID, announce: String?) {
        let line = (announce?.isEmpty == false) ? announce! : L("Done.")
        setStatus(id, .done, messages: [line])
    }

    /// The planner or executor errored.
    func failed(_ id: UUID, error: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].status = .failed
        items[idx].errorText = error
        items[idx].messages = [L("That didn't work.")]
        persist()
    }

    /// Set an item's status (and optionally replace its messages).
    func setStatus(_ id: UUID, _ status: ActionFeedItem.Status, messages: [String]? = nil) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].status = status
        if let messages { items[idx].messages = messages }
        persist()
    }

    /// Remove one item from the feed.
    func remove(_ id: UUID) {
        pendingActions[id] = nil
        clarifications[id] = nil
        inputRequests[id] = nil
        inputDrafts[id] = nil
        items.removeAll { $0.id == id }
        persist()
    }

    /// Clear the whole feed (keeps any in-flight pending writes out too).
    func clearAll() {
        items.removeAll()
        pendingActions.removeAll()
        clarifications.removeAll()
        inputRequests.removeAll()
        inputDrafts.removeAll()
        persist()
    }

    // MARK: Internals

    private func prepend(_ item: ActionFeedItem) {
        items.insert(item, at: 0)
        if items.count > maxItems { items = Array(items.prefix(maxItems)) }
        persist()
    }

    /// Map an action to a Composio toolkit slug for its logo, when it's a connected-app action.
    private static func logoSlug(for action: VerbaAction) -> String? {
        if case let .composio(tool, _, _) = action { return logoSlug(forTool: tool) }
        return nil
    }

    /// Tool slugs are TOOLKIT_ACTION (e.g. GMAIL_SEND_EMAIL) → take the toolkit prefix for the logo.
    private static func logoSlug(forTool tool: String) -> String? {
        tool.split(separator: "_").first.map { String($0).lowercased() }
    }

    // MARK: Persistence

    /// Persist only the durable history (transient pending writes are never written to disk).
    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([ActionFeedItem].self, from: data) else { return }
        // Any item left mid-flight from a previous launch is stale — collapse to a terminal state.
        items = decoded.map { item in
            switch item.status {
            case .thinking, .running, .pendingConfirm, .clarify, .needsInput:
                var s = item; s.status = .cancelled; return s
            default: return item
            }
        }
    }
}

// MARK: - Feed view (JARVIS panel)

/// A floating, monochrome-glass JARVIS panel listing recent actions with per-item status,
/// conversational lines, and inline Confirm/Cancel for pending writes. Mirrors `TodoGlanceView`'s
/// aesthetic: glass card, soft fills, hairline borders, the brand accent for "go".
struct ActionFeedView: View {
    @ObservedObject var store = ActionFeedStore.shared
    @ObservedObject private var logos = LogoLoader.shared
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if store.items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 14)).foregroundStyle(.secondary)
                    Text(L("Nothing here yet. Speak an action and I'll handle it."))
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.items) { item in
                            row(item)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: 460)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(minWidth: 470, maxWidth: 470, minHeight: 84, alignment: .topLeading)
        .glass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: store.items)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            Text("JARVIS").font(.system(size: 15, weight: .semibold)).tracking(0.5)
            Spacer(minLength: 18)
            if !store.items.isEmpty {
                Button(action: { withAnimation { store.clearAll() } }) {
                    Text(L("Clear")).font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.softFill, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain).help(L("Clear the feed"))
            }
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary).padding(6).contentShape(Rectangle())
            }
            .buttonStyle(.plain).help(L("Close (Esc)"))
        }
    }

    // MARK: Row

    @ViewBuilder private func row(_ item: ActionFeedItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                statusGlyph(item)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title.isEmpty ? L("Action") : item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(item.messages.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)   // show the FULL spoken request, never clip it
                            .textSelection(.enabled)
                    }
                    if item.status == .failed, let err = item.errorText, !err.isEmpty {
                        Text(err).font(.system(size: 11)).foregroundStyle(.red)
                            .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 4)
                Text(timeLabel(item.createdAt))
                    .font(.system(size: 10, weight: .medium)).monospacedDigit()
                    .foregroundStyle(.tertiary)
            }

            // Inline clarification choices.
            if item.status == .clarify, let clar = store.clarifications[item.id] {
                VStack(alignment: .leading, spacing: 6) {
                    if !clar.question.isEmpty {
                        Text(clar.question).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        ForEach(clar.options) { opt in
                            Button(action: { store.resolve(item.id, optionID: opt.id) }) {
                                Text(opt.label).font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 11).padding(.vertical, 5)
                                    .background(.softFill, in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 30)
            }

            // Inline editable fields when the planner needs missing values (e.g. a recipient).
            if item.status == .needsInput, let req = store.inputRequests[item.id] {
                VStack(alignment: .leading, spacing: 7) {
                    if !req.prompt.isEmpty {
                        Text(req.prompt).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    ForEach(req.fields) { field in inputField(item.id, field) }
                    HStack(spacing: 8) {
                        Button(action: { store.cancel(item.id) }) {
                            Text(L("Cancel")).font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(.softFill, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                                .contentShape(Capsule())
                        }.buttonStyle(.plain)
                        let ready = store.inputReady(item.id)
                        Button(action: { store.submitInput(item.id) }) {
                            HStack(spacing: 5) {
                                Image(systemName: "paperplane.fill").font(.system(size: 10, weight: .bold))
                                Text(req.label.isEmpty ? L("Send") : req.label).font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(VerbaAppearance.shared.accentOr(.accentColor), in: Capsule())
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain).disabled(!ready).opacity(ready ? 1 : 0.45)
                    }
                }
                .padding(.leading, 30)
            }

            // Inline Confirm / Cancel for a pending write.
            if item.status == .pendingConfirm {
                HStack(spacing: 8) {
                    Button(action: { store.cancel(item.id) }) {
                        Text(L("Cancel")).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 13).padding(.vertical, 6)
                            .background(.softFill, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Button(action: { store.confirm(item.id) }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                            Text(L("Confirm")).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(VerbaAppearance.shared.accentOr(.accentColor), in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 30)
            }

            // Post-action follow-up: once the action is done, offer a smart next step (rule 8).
            if item.status == .done, let q = item.followupQuestion, !q.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.down.right").font(.system(size: 11)).foregroundStyle(.secondary)
                    Text(q).font(.system(size: 12)).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Button(action: { store.dismissFollowup(item.id) }) {
                        Text(L("Not now")).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                    }.buttonStyle(.plain)
                    Button(action: { store.acceptFollowup(item.id) }) {
                        Text(L("Yes")).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(VerbaAppearance.shared.accentOr(.accentColor), in: Capsule())
                    }.buttonStyle(.plain)
                }
                .padding(.leading, 30)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Editable input field

    /// One labeled, editable field bound to the store's draft for this item.
    @ViewBuilder private func inputField(_ id: UUID, _ field: PlanInputField) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !field.label.isEmpty {
                Text(field.label).font(.system(size: 10.5, weight: .medium)).foregroundStyle(.secondary)
            }
            Group {
                if field.multiline {
                    TextField(field.placeholder, text: fieldBinding(id, field.key), axis: .vertical)
                        .lineLimit(2...5)
                } else {
                    TextField(field.placeholder, text: fieldBinding(id, field.key))
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
        }
    }

    /// Two-way binding from a field key to the store's draft dictionary for this item.
    private func fieldBinding(_ id: UUID, _ key: String) -> Binding<String> {
        Binding(
            get: { store.inputDrafts[id]?[key] ?? "" },
            set: { store.setInputDraft(id, key: key, value: $0) }
        )
    }

    // MARK: Status glyph (per-item)

    @ViewBuilder private func statusGlyph(_ item: ActionFeedItem) -> some View {
        ZStack {
            switch item.status {
            case .thinking, .running:
                ProgressView().controlSize(.small)
            case .pendingConfirm:
                appOrSymbol(item, symbol: "questionmark.circle.fill", tint: AnyShapeStyle(.secondary))
            case .clarify:
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16)).foregroundStyle(.secondary)
            case .needsInput:
                appOrSymbol(item, symbol: "square.and.pencil", tint: AnyShapeStyle(.secondary))
            case .done:
                appOrSymbol(item, symbol: "checkmark.circle.fill",
                            tint: AnyShapeStyle(VerbaAppearance.shared.accentOr(.green)))
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15)).foregroundStyle(.red)
            case .cancelled:
                Image(systemName: "slash.circle").font(.system(size: 15)).foregroundStyle(.tertiary)
            case .chat:
                Image(systemName: "text.bubble").font(.system(size: 15)).foregroundStyle(.secondary)
            }
        }
        .frame(width: 20, height: 20)
    }

    /// Show the connected-app logo when present, else an SF-symbol status glyph. Uses the shared
    /// LogoLoader (SVG → bitmap) — NOT AsyncImage, which renders blank for the SVG logos and made the
    /// feed flip between a logo and a fallback glyph (the "design keeps changing" bug).
    @ViewBuilder private func appOrSymbol(_ item: ActionFeedItem, symbol: String, tint: AnyShapeStyle) -> some View {
        if let slug = item.appLogoSlug, !slug.isEmpty {
            Group {
                if let img = logos.image(for: slug) {
                    Image(nsImage: img).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } else {
                    Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(tint)
                }
            }
            .frame(width: 18, height: 18)
            .onAppear { logos.load(slug) }
        } else {
            Image(systemName: item.symbol.isEmpty ? symbol : item.symbol)
                .font(.system(size: 15)).foregroundStyle(tint)
        }
    }

    // MARK: Time label

    /// Compact relative time: "now", "5m", "2h", else a short time. Locale-aware.
    private func timeLabel(_ d: Date) -> String {
        let secs = Date().timeIntervalSince(d)
        if secs < 60 { return L("now") }
        if secs < 3600 { return "\(Int(secs / 60))m" }
        if secs < 86_400 { return "\(Int(secs / 3600))h" }
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f.string(from: d)
    }
}

// MARK: - Floating panel controller

/// Borderless panels can't become key by default; override so the feed owns key focus (without
/// activating the app, since it's .nonactivatingPanel) and receives Esc immediately.
private final class ActionFeedPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Owns the borderless floating action-feed panel. Toggle-on-repeat; Esc and click-away dismiss it.
/// Cloned from `TodoGlanceController` so the JARVIS panel matches the to-do glance exactly.
final class ActionFeedController {
    static let shared = ActionFeedController()

    private var panel: NSPanel?
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private var resizeObserver: NSObjectProtocol?
    private var inputObserver: AnyCancellable?
    private var centeringFrame: NSRect = .zero

    var isShowing: Bool { panel?.isVisible ?? false }

    /// Show if hidden, hide if showing.
    func toggle() { if isShowing { hide() } else { show() } }

    private func build() {
        guard panel == nil else { return }
        let p = ActionFeedPanel(contentRect: NSRect(x: 0, y: 0, width: 470, height: 120),
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.ignoresMouseEvents = false   // Confirm/Cancel + clarification chips must be clickable

        let host = NSHostingController(rootView: ActionFeedView(onClose: { [weak self] in self?.hide() }))
        host.sizingOptions = [.preferredContentSize]
        p.contentViewController = host
        p.alphaValue = 1
        host.view.wantsLayer = true
        host.view.layer?.cornerRadius = 20
        host.view.layer?.cornerCurve = .continuous
        host.view.layer?.masksToBounds = true
        panel = p
        p.layoutIfNeeded()

        // Typing into the editable fields needs a key window: the moment the planner asks for input,
        // activate Verba and re-key the panel so keystrokes land in the TextFields (a nonactivating
        // panel otherwise won't accept text). Only fires on the false→true edge, so the normal
        // confirm flow (mouse only) never steals focus.
        inputObserver = ActionFeedStore.shared.$items
            .map { items in items.contains { $0.status == .needsInput } }
            .removeDuplicates()
            .sink { [weak self] needsInput in
                guard needsInput, let self, self.isShowing else { return }
                NSApp.activate(ignoringOtherApps: true)
                self.panel?.makeKeyAndOrderFront(nil)
            }
    }

    func show() {
        build()
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 470, height: 160)
        let vf = screen.visibleFrame
        centeringFrame = vf
        let frameSize = panel.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size
        let x = vf.midX - frameSize.width / 2
        let y = vf.midY - frameSize.height / 2
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: frameSize), display: true)
        installResizeObserver(on: panel)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        installDismissMonitors()
    }

    func hide() {
        removeResizeObserver()
        panel?.orderOut(nil)
        removeDismissMonitors()
    }

    /// When the feed grows/shrinks, AppKit keeps the bottom-left origin fixed and the card drifts —
    /// re-center on every resize, exactly like the to-do glance.
    private func installResizeObserver(on panel: NSPanel) {
        removeResizeObserver()
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: panel, queue: .main
        ) { [weak self, weak panel] _ in
            guard let self, let panel else { return }
            let s = panel.frame.size
            let origin = NSPoint(x: self.centeringFrame.midX - s.width / 2,
                                 y: self.centeringFrame.midY - s.height / 2)
            if abs(panel.frame.origin.x - origin.x) > 0.5 || abs(panel.frame.origin.y - origin.y) > 0.5 {
                panel.setFrameOrigin(origin)
            }
        }
    }

    private func removeResizeObserver() {
        if let o = resizeObserver { NotificationCenter.default.removeObserver(o); resizeObserver = nil }
    }

    // Esc dismisses; a click outside the panel dismisses (click-away).
    private func installDismissMonitors() {
        removeDismissMonitors()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.hide(); return nil }   // 53 = Esc
            return event
        }
        // The Actions widget is now a PERSISTENT, toggleable window (⌃⌥X): it must NOT vanish the
        // moment you click into another app — that made it un-reopenable and lost the pending queue.
        // It closes only on Esc, the close button, or the ⌃⌥X toggle. (No global click-away monitor.)
    }

    private func removeDismissMonitors() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }
}
