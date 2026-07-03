import SwiftUI

/// The Features catalog — the heart of the progressive-disclosure model (roadmap 2026-07-03).
/// New installs start with the four Essentials; everything else is turned on here, one card at a
/// time. An inactive feature is invisible everywhere else (no sidebar entry, no picker mode).
/// Turning a feature OFF only hides its surfaces; it never deletes notes, tasks, or history.
struct FeaturesView: View {
    @ObservedObject private var settings = Settings.shared

    /// One catalog entry. `key` empty ⇒ a Level-1 essential (always active, no toggle).
    private struct Feature: Identifiable {
        let key: String
        let name: String
        let benefit: String
        let icon: String
        var id: String { key.isEmpty ? name : key }
        var gated: Bool { !key.isEmpty }
    }

    private let essentials: [Feature] = [
        .init(key: "", name: "Raw dictation", benefit: "Press Fn, speak, your exact words land at the cursor.", icon: "waveform"),
        .init(key: "", name: "Polish", benefit: "Cleans grammar, filler and self-corrections as you speak.", icon: "sparkles"),
        .init(key: "", name: "Translate", benefit: "Speak one language, get the text in another.", icon: "globe"),
        .init(key: "", name: "Prompt", benefit: "Turns a rambling thought into a clean, optimized AI prompt.", icon: "text.cursor"),
    ]
    private let advanced: [Feature] = [
        .init(key: FeatureFlags.notes, name: "Notes", benefit: "Long recordings, structured into notes with tags and lock.", icon: "doc.badge.ellipsis"),
        .init(key: FeatureFlags.tasks, name: "Tasks", benefit: "Turn speech into projects, tasks and reminders.", icon: "checklist"),
        .init(key: FeatureFlags.advancedModes, name: "Advanced modes", benefit: "Intent, Context (reads your screen), and your own custom modes.", icon: "wand.and.stars"),
        .init(key: FeatureFlags.transcribe, name: "Transcribe files", benefit: "Drop in an audio or video file, get the transcript.", icon: "waveform.badge.plus"),
    ]
    private let power: [Feature] = [
        .init(key: FeatureFlags.jarvis, name: "JARVIS", benefit: "Your voice acts across 1,000+ apps: send, create, schedule.", icon: "bolt.fill"),
        .init(key: FeatureFlags.snippets, name: "Snippets", benefit: "Expand short spoken triggers into saved blocks of text.", icon: "text.badge.plus"),
        .init(key: FeatureFlags.transforms, name: "Transforms", benefit: "Select text, speak an instruction, get it rewritten in place.", icon: "arrow.triangle.2.circlepath"),
    ]

    private var allOn: Bool { FeatureFlags.allToggleable.allSatisfy { settings.isFeatureEnabled($0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                section(L("Essentials"), L("On by default. This is 80% of Verba."), essentials)
                section(L("Advanced"), L("Turn on what fits your work."), advanced)
                section(L("Power"), L("The deep end. Bring your voice to everything."), power)
                Text(L("Turning a feature off only hides it. Your notes, tasks and history are never deleted."))
                    .font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Features")).font(.system(size: 22, weight: .bold))
                Text(L("Verba grows with you. Turn on what you need, when you need it."))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if !allOn {
                Button(L("Enable everything")) { settings.enableAllFeatures() }
                    .help(L("Turn on every feature (I know what I'm doing)."))
            }
        }
    }

    @ViewBuilder private func section(_ title: String, _ subtitle: String, _ items: [Feature]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.tertiary)
            }
            ForEach(items) { f in card(f) }
        }
    }

    private func card(_ f: Feature) -> some View {
        let on = f.gated ? settings.isFeatureEnabled(f.key) : true
        return HStack(spacing: 12) {
            Image(systemName: f.icon)
                .font(.system(size: 16))
                .foregroundStyle(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(f.name).font(.system(size: 14, weight: .semibold))
                Text(f.benefit).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if f.gated {
                Toggle("", isOn: Binding(
                    get: { settings.isFeatureEnabled(f.key) },
                    set: { settings.setFeature(f.key, $0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            } else {
                Label(L("Active"), systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium)).foregroundStyle(.green).labelStyle(.titleAndIcon)
            }
        }
        .padding(14)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
