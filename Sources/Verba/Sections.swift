import SwiftUI
import Charts

// Borderless card.
private struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View { content().cleanCard(padding: padding) }
}

private struct SectionScaffold<Content: View, Actions: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title).font(.system(size: 28, weight: .bold))
                        Spacer()
                        actions()
                    }
                    if let subtitle { Text(subtitle).font(.callout).foregroundStyle(.secondary) }
                }
                content()
            }
            .padding(.horizontal, 28).padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension SectionScaffold where Actions == EmptyView {
    init(title: String, subtitle: String?, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, subtitle: subtitle, content: content, actions: { EmptyView() })
    }
}

/// Capsule tag chip — the exemplar's metric-chip grammar (LeaderboardView): SF symbol + label,
/// inverted fill when selected, soft 1px border otherwise. Internal so ModesView shares it.
struct TagChip: View {
    var icon: String? = nil
    let label: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 10, weight: .semibold)) }
                Text(label).font(.system(size: 12, weight: selected ? .semibold : .medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 6.5)
            .foregroundStyle(selected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(selected ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Exemplar row card (Color.primary 0.04 fill, r12 continuous) whose trailing remove
/// button only appears on hover — quiet by default, discoverable on intent.
private struct HoverRowCard<Content: View>: View {
    var alignment: VerticalAlignment = .center
    let onRemove: () -> Void
    @ViewBuilder var content: () -> Content
    @State private var hovering = false
    var body: some View {
        HStack(alignment: alignment, spacing: 10) {
            content()
            Button(action: onRemove) { Image(systemName: "minus.circle.fill") }
                .buttonStyle(.borderless).foregroundStyle(.tertiary)
                .opacity(hovering ? 1 : 0)
                .help("Remove")
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
    }
}

// MARK: - Home

struct HomeView: View {
    @ObservedObject var stats = Stats.shared
    @ObservedObject var history = History.shared
    @ObservedObject var settings = Settings.shared

    // Per-card UI state for the "Recent" list.
    @State private var expandedText: HistoryEntry.ID?     // card showing full text
    @State private var expandedAdapt: HistoryEntry.ID?    // card with its Adapt panel open

    var body: some View {
        SectionScaffold(title: "Home", subtitle: "Talk, and Claude cleans it up.") {
            HStack(spacing: 14) {
                stat("\(stats.totalWords.formatted())", "total words", "text.word.spacing")
                stat("\(stats.avgWPM)", "words / min", "gauge.with.dots.needle.67percent")
                stat("\(stats.streak)", "day streak", "flame.fill")
            }
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start dictating").font(.headline)
                    Text("Press \(triggerLabel) and talk. Fn + Tab jumps to the next mode (even mid-sentence), ⌃ pauses & resumes, or use ⌃⌥1-6 for a specific mode.")
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(settings.profiles.prefix(6)) { p in
                            Text(p.name).font(.caption.weight(.medium))
                                .padding(.horizontal, 11).padding(.vertical, 5)
                                .background(.softFill, in: Capsule())
                        }
                    }
                }
            }
            Text("Recent").font(.headline)
            if history.entries.isEmpty {
                Card { Text("Your dictations will show up here.").foregroundStyle(.secondary) }
            } else {
                VStack(spacing: 10) {
                    ForEach(history.entries.prefix(6)) { e in
                        recentCard(e)
                    }
                }
            }
        }
    }

    /// A "Recent" card: full-text expand toggle, copy, and an inline Adapt panel (one open at a time).
    @ViewBuilder
    private func recentCard(_ e: HistoryEntry) -> some View {
        let full = e.reprompted.isEmpty ? e.original : e.reprompted
        let textExpanded = expandedText == e.id
        let adaptOpen = expandedAdapt == e.id
        let long = full.count > 160 || full.contains("\n")
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(full)
                    .lineLimit(textExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                if long {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedText = textExpanded ? nil : e.id
                        }
                    } label: {
                        Text(textExpanded ? "Show less" : "Show more")
                            .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedAdapt = adaptOpen ? nil : e.id
                        }
                    } label: {
                        Label("Adapt", systemImage: "wand.and.stars")
                            .font(.caption2.weight(.semibold))
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    CopyButton(text: full)
                }
                if adaptOpen {
                    Divider().padding(.vertical, 2)
                    AdaptPanel(source: full).id(e.id)
                }
            }
        }
    }

    private var triggerLabel: String {
        if settings.useFnAsPrimary { return "Fn 🌐" }
        return settings.primaryHasShortcut
            ? shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods)
            : "⌃⌥ + number"
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.title3).foregroundStyle(.secondary)
                Text(value).font(.system(size: 30, weight: .bold)).monospacedDigit().contentTransition(.numericText())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Insights

struct InsightsView: View {
    @ObservedObject var stats = Stats.shared
    var body: some View {
        SectionScaffold(title: "Insights", subtitle: "Your dictation over the last 14 days.") {
            Card {
                Chart(stats.recentDays(14), id: \.label) { day in
                    BarMark(x: .value("Day", day.label), y: .value("Words", day.words))
                        .foregroundStyle(Color.primary.opacity(0.75))
                        .cornerRadius(5)
                }
                .frame(height: 220)
                // Clean: no dashed background grid, just the labels.
                .chartXAxis { AxisMarks { AxisValueLabel() } }
                .chartYAxis { AxisMarks { AxisValueLabel() } }
            }
            HStack(spacing: 14) {
                metric("\(stats.totalWords.formatted())", "total words")
                metric("\(stats.totalCount)", "dictations")
                metric("\(stats.avgWPM)", "words / min")
            }
            HStack(spacing: 14) {
                metric("\(stats.streak)", "day streak")
                metric("\(stats.wordsThisWeek.formatted())", "words this week")
                metric("\(stats.avgWordsPerDictation)", "avg / dictation")
            }
            HStack(spacing: 14) {
                metric("\(Int(stats.totalSeconds / 60)) min", "spoken")
                metric(timeSaved, "≈ time saved typing")
                metric("\(stats.bestDayWords.formatted())", "best day")
            }
        }
    }
    private var timeSaved: String {
        let m = stats.timeSavedMinutes
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m) min"
    }
    private func metric(_ v: String, _ l: String) -> some View {
        Card { VStack(alignment: .leading, spacing: 4) {
            Text(v).font(.title2.bold()).monospacedDigit(); Text(l).font(.caption).foregroundStyle(.secondary) } }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Dictionary agent: clean up the user's terms with the AI, returning strict JSON.

enum DictionaryAgent {
    /// A cleaned term: corrected written form + optional proposed spoken variant.
    struct Cleaned { var written: String; var spoken: String }
    enum Err: LocalizedError {
        case empty, unparseable
        var errorDescription: String? {
            switch self {
            case .empty: return "Add a term first."
            case .unparseable: return "The AI didn't return a usable result."
            }
        }
    }

    private static let system = """
    You clean up a dictation dictionary. Each term has a "written" form (the correct spelling the app \
    should produce) and an optional "said" form (how the user would speak it, to auto-correct a mis-hearing).

    For every input term:
    - Fix the capitalization and spelling of the "written" form (proper nouns, brand names, acronyms).
    - Where helpful, propose the likely "said" spoken variant (lowercase, how someone would pronounce it). \
    If the term is a plain word that wouldn't be mis-heard, leave "said" empty.
    - Keep the SAME number of terms, in the SAME order — only correct them.

    Detect the user's language and keep EVERY value in that single language. NEVER mix two languages \
    in a value (no franglais).

    Reply with a SINGLE JSON object, nothing else (no prose, no code fence):
    {"terms":[{"written":"Corrected Form","said":"spoken variant or empty"}]}
    """

    static func clean(_ terms: [DictTerm]) async throws -> [Cleaned] {
        let usable = terms.filter { !$0.written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !usable.isEmpty else { throw Err.empty }
        let payload = usable.map { ["written": $0.written, "said": $0.spoken] }
        let json = (try? JSONSerialization.data(withJSONObject: ["terms": payload]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let raw = try await Reprompter(model: model).reprompt(transcript: json, systemPrompt: system)
        return try parse(raw)
    }

    static func parse(_ text: String) throws -> [Cleaned] {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards), open.lowerBound <= close.lowerBound {
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw Err.unparseable }
        let rawTerms = obj["terms"] as? [Any] ?? []
        let cleaned: [Cleaned] = rawTerms.compactMap { item in
            guard let t = item as? [String: Any],
                  let w = (t["written"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !w.isEmpty else { return nil }
            let said = (t["said"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return Cleaned(written: w, spoken: said)
        }
        guard !cleaned.isEmpty else { throw Err.unparseable }
        return cleaned
    }
}

// MARK: - Dictionary

struct DictionaryView: View {
    @ObservedObject var store = DictionaryStore.shared
    @ObservedObject var settings = Settings.shared
    @State private var aiBusy = false
    @State private var aiError: String?

    private var autoCount: Int { store.terms.filter(\.auto).count }
    private var hasWritten: Bool {
        store.terms.contains { !$0.written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// A row is a misspelling correction when it carries a spoken form; an empty spoken form
    /// means it's a pure vocabulary hint ("Add a word"). New correction rows are seeded with a
    /// single space so they render as a correction before the user types anything.
    private func isCorrection(_ t: DictTerm) -> Bool { !t.spoken.isEmpty }

    @ViewBuilder private func rowBadges(_ t: DictTerm) -> some View {
        if t.auto {
            Text("auto")
                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.softFill, in: Capsule())
                .help("Auto-learned from one of your edits")
        }
    }

    var body: some View {
        SectionScaffold(title: "Dictionary",
                        subtitle: "Teach Verba names and terms it should always spell right.") {
            // Auto-add control, right where the terms live — in-place management glass card.
            HStack(spacing: 12) {
                Image(systemName: "wand.and.sparkles").font(.system(size: 18)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-add from your edits").font(.headline)
                    Text(autoCount > 0
                         ? "Verba learned \(autoCount) term\(autoCount == 1 ? "" : "s") from your corrections."
                         : "When you fix a word after pasting, Verba adds it here automatically.")
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                }
                Spacer()
                Toggle(isOn: $settings.autoLearnDictionary) {
                    Text("Auto-add").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                }
                .toggleStyle(.switch).controlSize(.small)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Clean up the existing terms with the AI.
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 18)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Improve with AI").font(.headline)
                    Text(aiError ?? "Fix the spelling and capitalization of your terms, and propose the spoken form where it helps.")
                        .font(.caption).foregroundStyle(aiError == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
                }
                Spacer()
                if aiBusy { ProgressView().controlSize(.small) }
                Button(action: improveWithAI) { Text("Improve with AI") }
                    .glassProminentButton()
                    .disabled(aiBusy || !hasWritten)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if store.terms.isEmpty {
                EmptyState(icon: "character.book.closed", title: "No terms yet",
                           message: "Teach Verba names, jargon, and acronyms it should always spell right. Use “Add a word” to give it a vocabulary hint (e.g. “Verba”), or “Correct a misspelling” to auto-fix a mis-hearing (say “verba” → write “Verba”). With Auto-add on, it also learns from the corrections you make after pasting.")
            }
            VStack(spacing: 10) {
                ForEach($store.terms) { $t in
                    // A row with an empty spoken form is a pure vocabulary hint ("Add a word");
                    // one with a spoken form is a misspelling correction.
                    if isCorrection(t) {
                        HoverRowCard(onRemove: { store.terms.removeAll { $0.id == t.id } }) {
                            TextField("Said", text: $t.spoken).cleanField()
                                .help("The word as it gets mis-heard. Verba auto-replaces it with the written form.")
                            Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                            TextField("Written", text: $t.written).cleanField()
                                .help("The correct spelling Verba should write instead.")
                            rowBadges(t)
                        }
                    } else {
                        HoverRowCard(onRemove: { store.terms.removeAll { $0.id == t.id } }) {
                            Image(systemName: "text.book.closed").foregroundStyle(.tertiary)
                            TextField("Word — the transcriber should spell right", text: $t.written).cleanField()
                                .help("A vocabulary hint sent to the transcriber so it recognizes and spells this word.")
                            rowBadges(t)
                        }
                    }
                }
                HStack(spacing: 10) {
                    primaryAddButton("Add a word") { store.terms.append(DictTerm(spoken: "", written: "")) }
                    addButton("Correct a misspelling") { store.terms.append(DictTerm(spoken: " ", written: "")) }
                    Spacer()
                }
                .padding(.top, 2)
            }
            Text("“Add a word” teaches the transcriber a name or term so it spells it right — no correction needed. “Correct a misspelling” pairs a mis-heard spoken word with the written form so Verba swaps it automatically. Auto-added terms work the same, edit or remove any of them.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func improveWithAI() {
        guard !aiBusy, hasWritten else { return }
        aiError = nil; aiBusy = true
        let snapshot = store.terms
        Task {
            do {
                let cleaned = try await DictionaryAgent.clean(snapshot)
                await MainActor.run {
                    merge(cleaned)
                    aiBusy = false
                }
            } catch {
                await MainActor.run { aiError = error.localizedDescription; aiBusy = false }
            }
        }
    }

    /// Merge AI-cleaned terms back in: update each written form's casing/spelling and fill an
    /// empty spoken form on correction rows, without dropping or duplicating any existing term. The
    /// AI returns the cleaned terms in the same order as the terms that had a written value, so we
    /// map them back positionally onto exactly those rows and leave every other term untouched.
    /// Pure vocabulary entries ("Add a word", empty spoken) keep their intent — only their spelling
    /// is cleaned, never converted into a correction.
    private func merge(_ cleaned: [DictionaryAgent.Cleaned]) {
        let writtenIdx = store.terms.indices.filter {
            !store.terms[$0].written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        for (cleanedTerm, idx) in zip(cleaned, writtenIdx) {
            store.terms[idx].written = cleanedTerm.written
            // Only an existing correction row may gain a proposed spoken form; a vocab-only row
            // (empty spoken) stays a vocab hint.
            if isCorrection(store.terms[idx]),
               store.terms[idx].spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !cleanedTerm.spoken.isEmpty {
                store.terms[idx].spoken = cleanedTerm.spoken
            }
        }
    }
}

// MARK: - Snippets

struct SnippetsView: View {
    @ObservedObject var store = SnippetsStore.shared
    var body: some View {
        SectionScaffold(title: "Snippets",
                        subtitle: "Say a trigger; Verba expands it into longer text.") {
            if store.items.isEmpty {
                EmptyState(icon: "text.badge.plus", title: "No snippets yet",
                           message: "Create shortcuts: say a short trigger and Verba expands it into longer text, like your address, an email signature, or a boilerplate reply. Add your first one below.")
            }
            VStack(spacing: 10) {
                ForEach($store.items) { $s in
                    HoverRowCard(alignment: .top, onRemove: { store.items.removeAll { $0.id == s.id } }) {
                        TextField("Trigger", text: $s.trigger).cleanField().frame(width: 160)
                        TextField("Expands to…", text: $s.expansion, axis: .vertical).cleanField()
                    }
                }
                HStack {
                    primaryAddButton("Add snippet") { store.items.append(Snippet(trigger: "", expansion: "")) }
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }
}

// MARK: - Style

struct StyleView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selectedID: UUID?

    var body: some View {
        SectionScaffold(title: "Styles",
                        subtitle: "A tone & format layer applied on top of the active mode.") {
            // Info bubble explaining what styles do.
            Card {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.tint).font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What is a style?").font(.subheadline.weight(.semibold))
                        Text("A style is a second prompt layer added on top of your dictation mode. The mode decides what Claude does with your words; the active style nudges how the result reads (tone, register, formatting). The built-in “Normal” style is neutral, so it changes nothing. Switch styles anytime with Fn + [ and Fn + ], or from the menu bar.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 0) {
                list
                Divider()
                Group {
                    if let id = selectedID, settings.styles.contains(where: { $0.id == id }) {
                        editor(id: id)
                    } else {
                        EmptyState(icon: "paintbrush", title: "Select a style",
                                   message: "Each style is a reusable tone/format layer added on top of your mode.")
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minHeight: 420)
        } actions: {
            Button { let id = addStyle(); selectedID = id } label: { Image(systemName: "plus") }
                .buttonStyle(.borderless).help("Add a new style")
            Button { settings.resetStylesToDefaults(); selectedID = settings.activeStyleID } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless).help("Remove all custom styles, keep only Normal")
        }
        .onAppear { if selectedID == nil { selectedID = settings.activeStyleID } }
    }

    private var list: some View {
        List {
            ForEach(settings.styles) { st in
                let selected = st.id == selectedID
                HStack(spacing: 8) {
                    Image(systemName: "paintbrush")
                        .foregroundStyle(.secondary).frame(width: 16)
                    Text(st.name).fontWeight(selected ? .semibold : .regular).lineLimit(1)
                    Spacer(minLength: 6)
                    if st.id == settings.activeStyleID {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint).font(.caption)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
                )
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedID = st.id }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            }
            .onMove { from, to in settings.styles.move(fromOffsets: from, toOffset: to) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(width: 220)
    }

    private func index(of id: UUID) -> Int? { settings.styles.firstIndex { $0.id == id } }

    private func editor(id: UUID) -> some View {
        let st = settings.styles.first { $0.id == id }
        let isNormal = (st?.builtin ?? false) && (st?.name == "Normal")
        let nameB = Binding(get: { settings.styles.first { $0.id == id }?.name ?? "" },
                            set: { v in if let i = index(of: id) { settings.styles[i].name = v } })
        let promptB = Binding(get: { settings.styles.first { $0.id == id }?.prompt ?? "" },
                              set: { v in if let i = index(of: id) { settings.styles[i].prompt = v } })
        let isActive = settings.activeStyleID == id

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    TextField("Name", text: nameB).cleanField().frame(maxWidth: 240).disabled(isNormal)
                    TagChip(icon: isActive ? "checkmark.circle.fill" : "circle",
                            label: isActive ? "Active" : "Make active",
                            selected: isActive) { settings.activeStyleID = id }
                        .disabled(isActive)
                    Spacer()
                    if !isNormal {
                        Button(role: .destructive) { deleteStyle(id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).foregroundStyle(.red).help("Delete this style")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Style prompt").font(.subheadline.weight(.semibold))
                        Text("layered on top of the mode when reprompting").font(.caption).foregroundStyle(.secondary)
                    }
                    if isNormal {
                        Text("“Normal” is neutral: it adds nothing, so your modes behave exactly as their own prompts define. Create a new style to add a tone or format layer.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    } else {
                        TextEditor(text: promptB)
                            .font(.system(.callout, design: .monospaced)).scrollContentBackground(.hidden)
                            .frame(minHeight: 200).padding(12)
                            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("e.g. “British English, no exclamation marks, sign off with ‘, G’.” Applies on top of every mode except Flow (raw dictation).")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @discardableResult
    private func addStyle() -> UUID {
        let st = Style(name: "New style", prompt: "")
        settings.styles.append(st)
        return st.id
    }

    private func deleteStyle(_ id: UUID) {
        selectedID = nil
        settings.styles.removeAll { $0.id == id }
        if settings.activeStyleID == id, let first = settings.styles.first { settings.activeStyleID = first.id }
    }
}

// MARK: - Transforms

struct TransformsView: View {
    @ObservedObject var store = TransformsStore.shared
    @State private var errorMessage: String?

    var body: some View {
        SectionScaffold(title: "Transforms",
                        subtitle: "Actions that run on text you’ve selected. Highlight some text in any app, then speak the transform’s Verbal Shortcut (e.g. “fix grammar”) — Verba runs it on your selection and replaces it. Works in every mode.") {
            if store.items.isEmpty {
                EmptyState(icon: "arrow.triangle.2.circlepath", title: "No transforms yet",
                           message: "Create reusable text actions like “Make it formal”, “Translate to English”, or “Turn into bullet points”. Give each a Verbal Shortcut (the phrase you’ll say) and a prompt. Then select text anywhere, say the shortcut, and Verba transforms the selection.")
            }
            VStack(spacing: 12) {
                ForEach($store.items) { $t in
                    TransformRow(t: $t) { store.items.removeAll { $0.id == t.id } }
                }
                HStack {
                    primaryAddButton("Add transform") { store.items.append(Transform(name: "New shortcut", prompt: "Rewrite the text…")) }
                    Spacer()
                }
                .padding(.top, 2)
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }
        }
    }
}

/// One transform card: exemplar chrome, remove revealed on hover (top-right).
private struct TransformRow: View {
    @Binding var t: Transform
    let onRemove: () -> Void
    @State private var hovering = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Verbal Shortcut", text: $t.name).cleanField().frame(width: 240)
                Spacer()
                Button(action: onRemove) { Image(systemName: "minus.circle.fill") }
                    .buttonStyle(.borderless).foregroundStyle(.tertiary)
                    .opacity(hovering ? 1 : 0)
                    .help("Remove")
            }
            TextField("Prompt", text: $t.prompt, axis: .vertical).cleanField()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
    }
}

// MARK: - Scratchpad

struct ScratchpadView: View {
    @ObservedObject var pad = Scratchpad.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scratchpad").font(.system(size: 28, weight: .bold))
                Spacer()
                CopyButton(text: pad.text, title: "Copy")
                Button(role: .destructive) { pad.text = "" } label: { Label("Clear", systemImage: "trash") }
                    .buttonStyle(.borderless)
            }
            .padding(28)
            TextEditor(text: $pad.text)
                .font(.system(size: 15)).scrollContentBackground(.hidden)
                .padding(.horizontal, 24).padding(.vertical, 20)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if pad.text.isEmpty {
                        EmptyState(icon: "note.text", title: "Empty scratchpad",
                                   message: "A free-form space for text. Dictate into it, paste notes, edit, and copy the result.")
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
        }
    }
}

// MARK: - Empty state (icon + title + explanation), shown when a section has no content yet.

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40, weight: .light)).foregroundStyle(.tertiary)
            Text(title).font(.headline)
            Text(message)
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

// MARK: - Small shared controls

/// Quiet secondary add affordance: soft-fill capsule with a plus.
private func addButton(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 5) {
            Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
            Text(title).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6.5)
        .foregroundStyle(.primary.opacity(0.75))
        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
        .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
}

/// Primary add affordance: Liquid Glass prominent button.
private func primaryAddButton(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) { Label(title, systemImage: "plus") }
        .glassProminentButton()
}
