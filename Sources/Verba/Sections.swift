import SwiftUI
import Charts

// Shared card container
private struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.08)))
    }
}

private struct SectionScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.largeTitle.bold())
                    if let subtitle { Text(subtitle).foregroundStyle(.secondary) }
                }
                content()
            }
            .padding(28)
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
                stat("\(stats.streak)", stats.streak == 1 ? "day streak" : "day streak", "flame.fill")
            }
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start dictating").font(.headline)
                    Text("Press \(triggerLabel) and talk. Switch mode on the fly from the floating bar, or use ⌃⌥1–6.")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(settings.profiles.prefix(6)) { p in
                            Text(p.name).font(.caption).padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(.white.opacity(0.08)))
                        }
                    }.padding(.top, 4)
                }
            }
            Text("Recent").font(.headline)
            if history.entries.isEmpty {
                Card { Text("Your dictations will show up here.").foregroundStyle(.secondary) }
            } else {
                ForEach(history.entries.prefix(6)) { e in
                    Card {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.reprompted.isEmpty ? e.original : e.reprompted).lineLimit(3)
                            HStack {
                                Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                                Button { Output.copyToClipboard(e.reprompted) } label: { Image(systemName: "doc.on.doc") }
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
        }
    }

    private var triggerLabel: String {
        settings.triggerMode == .hotkey
            ? shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods)
            : settings.triggerMode.label
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(.tint)
                Text(value).font(.system(size: 30, weight: .bold))
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
                        .foregroundStyle(.tint)
                        .cornerRadius(4)
                }
                .frame(height: 220)
            }
            HStack(spacing: 14) {
                metric("\(stats.totalCount)", "dictations")
                metric("\(Int(stats.totalSeconds / 60)) min", "spoken")
                metric("\(estimatedTimeSaved())", "≈ time saved typing")
            }
        }
    }
    // Rough: speaking ~3x faster than typing → words/40wpm typing minus spoken time.
    private func estimatedTimeSaved() -> String {
        let typeMin = Double(stats.totalWords) / 40.0
        let saved = max(0, typeMin - stats.totalSeconds / 60)
        return "\(Int(saved)) min"
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
            Card {
                VStack(spacing: 0) {
                    ForEach($store.terms) { $t in
                        HStack {
                            TextField("Said (optional)", text: $t.spoken).textFieldStyle(.roundedBorder)
                            Image(systemName: "arrow.right").foregroundStyle(.secondary)
                            TextField("Written", text: $t.written).textFieldStyle(.roundedBorder)
                            Button { store.terms.removeAll { $0.id == t.id } } label: { Image(systemName: "minus.circle.fill") }
                                .buttonStyle(.borderless).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    }
                    Button { store.terms.append(DictTerm(spoken: "", written: "")) } label: {
                        Label("Add term", systemImage: "plus")
                    }.buttonStyle(.borderless).padding(.top, 6).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Text("“Written” terms are sent to the transcriber as hints, and any “Said → Written” pair is auto-corrected in the result.")
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
            Card {
                VStack(spacing: 10) {
                    ForEach($store.items) { $s in
                        HStack(alignment: .top) {
                            TextField("Trigger", text: $s.trigger).textFieldStyle(.roundedBorder).frame(width: 160)
                            TextField("Expands to…", text: $s.expansion, axis: .vertical).textFieldStyle(.roundedBorder)
                            Button { store.items.removeAll { $0.id == s.id } } label: { Image(systemName: "minus.circle.fill") }
                                .buttonStyle(.borderless).foregroundStyle(.secondary)
                        }
                    }
                    Button { store.items.append(Snippet(trigger: "", expansion: "")) } label: {
                        Label("Add snippet", systemImage: "plus")
                    }.buttonStyle(.borderless).frame(maxWidth: .infinity, alignment: .leading)
                }
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
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Apply my style to every dictation", isOn: $settings.styleEnabled)
                    TextEditor(text: $settings.styleText)
                        .font(.body).frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.1)))
                        .disabled(!settings.styleEnabled).opacity(settings.styleEnabled ? 1 : 0.5)
                    Text("e.g. “British English, no exclamation marks, sign off with ‘— G’.” Applies to all modes except Flow.")
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
            ForEach($store.items) { $t in
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Name", text: $t.name).textFieldStyle(.roundedBorder).frame(width: 220)
                            Spacer()
                            Button { run(t) } label: {
                                Label(running == t.id ? "Running…" : "Run on Scratchpad", systemImage: "play.fill")
                            }.disabled(running != nil || pad.text.isEmpty)
                            Button { store.items.removeAll { $0.id == t.id } } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless).foregroundStyle(.secondary)
                        }
                        TextField("Prompt", text: $t.prompt, axis: .vertical).textFieldStyle(.roundedBorder)
                    }
                }
            }
            Button { store.items.append(Transform(name: "New transform", prompt: "Rewrite the text…")) } label: {
                Label("Add transform", systemImage: "plus")
            }.buttonStyle(.borderless)
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
                Text("Scratchpad").font(.largeTitle.bold())
                Spacer()
                Button { Output.copyToClipboard(pad.text) } label: { Label("Copy", systemImage: "doc.on.doc") }
                Button(role: .destructive) { pad.text = "" } label: { Label("Clear", systemImage: "trash") }
            }
            .padding(28)
            TextEditor(text: $pad.text)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 28).padding(.bottom, 28)
        }
    }
}
