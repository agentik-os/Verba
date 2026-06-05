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
                    Text("Press \(triggerLabel) and talk. Switch mode on the fly from the floating bar, or use ⌃⌥1-6.")
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
                        Card(padding: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(e.reprompted.isEmpty ? e.original : e.reprompted).lineLimit(3)
                                HStack {
                                    Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Spacer()
                                    Button { Output.copyToClipboard(e.reprompted) } label: { Image(systemName: "doc.on.doc") }
                                        .buttonStyle(.borderless).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
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
                        .foregroundStyle(Color.primary.opacity(0.7))
                        .cornerRadius(5)
                }
                .frame(height: 220)
            }
            HStack(spacing: 14) {
                metric("\(stats.totalCount)", "dictations")
                metric("\(Int(stats.totalSeconds / 60)) min", "spoken")
                metric(estimatedTimeSaved(), "≈ time saved typing")
            }
        }
    }
    private func estimatedTimeSaved() -> String {
        let typeMin = Double(stats.totalWords) / 40.0
        return "\(Int(max(0, typeMin - stats.totalSeconds / 60))) min"
    }
    private func metric(_ v: String, _ l: String) -> some View {
        Card { VStack(alignment: .leading, spacing: 4) {
            Text(v).font(.title2.bold()); Text(l).font(.caption).foregroundStyle(.secondary) } }
    }
}

// MARK: - Dictionary

struct DictionaryView: View {
    @ObservedObject var store = DictionaryStore.shared
    var body: some View {
        SectionScaffold(title: "Dictionary",
                        subtitle: "Teach Verba names and terms it should always spell right.") {
            VStack(spacing: 10) {
                ForEach($store.terms) { $t in
                    HStack(spacing: 10) {
                        TextField("Said (optional)", text: $t.spoken).cleanField()
                        Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                        TextField("Written", text: $t.written).cleanField()
                        removeButton { store.terms.removeAll { $0.id == t.id } }
                    }
                }
                addButton("Add term") { store.terms.append(DictTerm(spoken: "", written: "")) }
            }
            Text("“Written” terms are sent to the transcriber as hints; any “Said → Written” pair is auto-corrected in the result.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Snippets

struct SnippetsView: View {
    @ObservedObject var store = SnippetsStore.shared
    var body: some View {
        SectionScaffold(title: "Snippets",
                        subtitle: "Say a trigger; Verba expands it into longer text.") {
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

    var body: some View {
        SectionScaffold(title: "Transforms",
                        subtitle: "One-tap rewrites you can run on the Scratchpad text.") {
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
            }
        }
    }

    private func run(_ t: Transform) {
        running = t.id
        let input = pad.text
        Task {
            let out = try? await Reprompter(model: Settings.shared.claudeModel)
                .reprompt(transcript: input, systemPrompt: t.prompt + "\nOutput ONLY the transformed text.")
            await MainActor.run { if let out { pad.text = out }; running = nil }
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
                Button { Output.copyToClipboard(pad.text) } label: { Label("Copy", systemImage: "doc.on.doc") }
                    .buttonStyle(.borderless)
                Button(role: .destructive) { pad.text = "" } label: { Label("Clear", systemImage: "trash") }
                    .buttonStyle(.borderless)
            }
            .padding(32)
            TextEditor(text: $pad.text)
                .font(.system(size: 15)).scrollContentBackground(.hidden)
                .padding(.horizontal, 24).padding(.vertical, 20)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 32).padding(.bottom, 32)
        }
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
