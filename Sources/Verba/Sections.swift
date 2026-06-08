import SwiftUI
import Charts

// Borderless card.
private struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View { content().cleanCard(padding: padding) }
}

private struct SectionScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 28, weight: .bold))
                    if let subtitle { Text(subtitle).foregroundStyle(.secondary) }
                }
                content()
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                    HStack(spacing: 8) {
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
                Text(value).font(.system(size: 30, weight: .bold)).contentTransition(.numericText())
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
            Text(v).font(.title2.bold()); Text(l).font(.caption).foregroundStyle(.secondary) } }
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
            // Auto-add control, right where the terms live.
            HStack(spacing: 12) {
                Image(systemName: "wand.and.sparkles").font(.system(size: 18)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-add from your edits").font(.headline)
                    Text(autoCount > 0
                         ? "Verba learned \(autoCount) term\(autoCount == 1 ? "" : "s") from your corrections."
                         : "When you fix a word after pasting, Verba adds it here automatically.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $settings.autoLearnDictionary).labelsHidden()
            }
            .cleanCard(padding: 16)

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
                    .buttonStyle(.borderedProminent)
                    .disabled(aiBusy || !hasWritten)
            }
            .cleanCard(padding: 16)

            if store.terms.isEmpty {
                EmptyState(icon: "character.book.closed", title: "No terms yet",
                           message: "Teach Verba names, jargon, and acronyms it should always spell right. Use “Add a word” to give it a vocabulary hint (e.g. “Verba”), or “Correct a misspelling” to auto-fix a mis-hearing (say “verba” → write “Verba”). With Auto-add on, it also learns from the corrections you make after pasting.")
            }
            VStack(spacing: 10) {
                ForEach($store.terms) { $t in
                    // A row with an empty spoken form is a pure vocabulary hint ("Add a word");
                    // one with a spoken form is a misspelling correction.
                    if isCorrection(t) {
                        HStack(spacing: 10) {
                            TextField("Said", text: $t.spoken).cleanField()
                                .help("The word as it gets mis-heard. Verba auto-replaces it with the written form.")
                            Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                            TextField("Written", text: $t.written).cleanField()
                                .help("The correct spelling Verba should write instead.")
                            rowBadges(t)
                            removeButton { store.terms.removeAll { $0.id == t.id } }
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "text.book.closed").foregroundStyle(.tertiary)
                            TextField("Word — the transcriber should spell right", text: $t.written).cleanField()
                                .help("A vocabulary hint sent to the transcriber so it recognizes and spells this word.")
                            rowBadges(t)
                            removeButton { store.terms.removeAll { $0.id == t.id } }
                        }
                    }
                }
                HStack(spacing: 14) {
                    addButton("Add a word") { store.terms.append(DictTerm(spoken: "", written: "")) }
                    addButton("Correct a misspelling") { store.terms.append(DictTerm(spoken: " ", written: "")) }
                }
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
                    HStack(alignment: .top, spacing: 10) {
                        TextField("Trigger", text: $s.trigger).cleanField().frame(width: 160)
                        TextField("Expands to…", text: $s.expansion, axis: .vertical).cleanField()
                        removeButton { store.items.removeAll { $0.id == s.id } }
                    }
                }
                addButton("Add snippet") { store.items.append(Snippet(trigger: "", expansion: "")) }
            }
        }
    }
}

// MARK: - Style

struct StyleView: View {
    @ObservedObject var settings = Settings.shared
    var body: some View {
        SectionScaffold(title: "Style",
                        subtitle: "Global tone & formatting added on top of every mode.") {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Apply my style to every dictation", isOn: $settings.styleEnabled)
                    TextEditor(text: $settings.styleText)
                        .font(.body).scrollContentBackground(.hidden)
                        .frame(minHeight: 130).padding(10)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .disabled(!settings.styleEnabled).opacity(settings.styleEnabled ? 1 : 0.5)
                    Text("e.g. “British English, no exclamation marks, sign off with ‘, G’.” Applies to all modes except Flow.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Transforms

struct TransformsView: View {
    @ObservedObject var store = TransformsStore.shared
    @ObservedObject var pad = Scratchpad.shared
    @State private var running: UUID?
    @State private var errorMessage: String?

    var body: some View {
        SectionScaffold(title: "Transforms",
                        subtitle: "One-tap rewrites you can run on the Scratchpad text.") {
            if store.items.isEmpty {
                EmptyState(icon: "arrow.triangle.2.circlepath", title: "No transforms yet",
                           message: "Build one-tap rewrites for your Scratchpad text, like “Make it formal”, “Translate to English”, or “Turn into bullet points”. Give each a name and a prompt, then run it on whatever is in the Scratchpad.")
            }
            VStack(spacing: 12) {
                ForEach($store.items) { $t in
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField("Name", text: $t.name).cleanField().frame(width: 220)
                                Spacer()
                                Button { run(t) } label: {
                                    Label(running == t.id ? "Running…" : "Run on Scratchpad", systemImage: "play.fill")
                                }.disabled(running != nil || pad.text.isEmpty).buttonStyle(.borderless)
                                removeButton { store.items.removeAll { $0.id == t.id } }
                            }
                            TextField("Prompt", text: $t.prompt, axis: .vertical).cleanField()
                        }
                    }
                }
                addButton("Add transform") { store.items.append(Transform(name: "New transform", prompt: "Rewrite the text…")) }
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

    private func run(_ t: Transform) {
        running = t.id
        errorMessage = nil
        let input = pad.text
        Task {
            do {
                let out = try await Reprompter(model: Settings.shared.claudeModel)
                    .reprompt(transcript: input, systemPrompt: t.prompt + "\nOutput ONLY the transformed text.")
                await MainActor.run {
                    let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        errorMessage = "Transform returned an empty result."
                    } else {
                        pad.text = out
                    }
                    running = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Transform failed: \(error.localizedDescription)"
                    running = nil
                }
            }
        }
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
            .padding(32)
            TextEditor(text: $pad.text)
                .font(.system(size: 15)).scrollContentBackground(.hidden)
                .padding(.horizontal, 24).padding(.vertical, 20)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if pad.text.isEmpty {
                        EmptyState(icon: "note.text", title: "Empty scratchpad",
                                   message: "A free-form space for text. Dictate into it, paste notes, then run a Transform on it (make it formal, translate, summarize…) and copy the result.")
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 32).padding(.bottom, 32)
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

private func removeButton(_ action: @escaping () -> Void) -> some View {
    Button(action: action) { Image(systemName: "minus.circle.fill") }
        .buttonStyle(.borderless).foregroundStyle(.tertiary)
}

private func addButton(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) { Label(title, systemImage: "plus") }
        .buttonStyle(.borderless)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
}
