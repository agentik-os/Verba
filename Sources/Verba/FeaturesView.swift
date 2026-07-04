import SwiftUI

/// The Features catalog — the heart of the progressive-disclosure model (roadmap 2026-07-03).
/// New installs start with the four Essentials; everything else is turned on here, one card at a
/// time. An inactive feature is invisible everywhere else (no sidebar entry, no picker mode).
/// Turning a feature OFF only hides its surfaces; it never deletes notes, tasks, or history.
struct FeaturesView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var detail: Feature?

    /// One catalog entry. `key` empty ⇒ a Level-1 essential (always active, no toggle).
    private struct Feature: Identifiable {
        let key: String
        let name: String
        let benefit: String
        let icon: String
        var requires: String = ""   // extra thing this feature needs (permission, connection…)
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
        .init(key: FeatureFlags.advancedModes, name: "Advanced modes", benefit: "Intent, Context (reads your screen), and your own custom modes.", icon: "wand.and.stars", requires: "Context mode asks for Screen Recording the first time you use it."),
        .init(key: FeatureFlags.transcribe, name: "Transcribe files", benefit: "Drop in an audio or video file, get the transcript.", icon: "waveform.badge.plus"),
    ]
    private let power: [Feature] = [
        .init(key: FeatureFlags.jarvis, name: "JARVIS", benefit: "Your voice acts across 1,000+ apps: send, create, schedule.", icon: "bolt.fill", requires: "Connect your apps in Connected apps, and sign in so actions can run on your behalf."),
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
        .sheet(item: $detail) { detailSheet($0) }
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

    /// The one motion signature reused across this surface (taste: a single spring, not per-view guesses).
    static let anim = Animation.spring(response: 0.34, dampingFraction: 0.86)

    private func card(_ f: Feature) -> some View {
        let on = f.gated ? settings.isFeatureEnabled(f.key) : true
        return HStack(spacing: 12) {
            // Tapping the icon/text opens the feature's detail sheet; the pill flips it quickly.
            Button { detail = f } label: {
                HStack(spacing: 12) {
                    Image(systemName: f.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.name).font(.system(size: 14, weight: .semibold))
                        Text(f.benefit).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            statusPill(f)
        }
        .padding(14)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        // Essentials read as the core, already-active tier: a hairline accent edge; gated features are plain.
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(f.gated ? Color.clear : Color.primary.opacity(0.14), lineWidth: 1)
        )
    }

    /// One coherent pill (no native switch, which jars with the glass): green "On" for essentials,
    /// a green "Active" / neutral "Activate" toggle for gated features.
    @ViewBuilder private func statusPill(_ f: Feature) -> some View {
        if f.gated {
            let active = settings.isFeatureEnabled(f.key)
            Button {
                withAnimation(Self.anim) { settings.setFeature(f.key, !active) }
            } label: {
                Text(active ? L("Active") : L("Activate"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(active ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(active ? Color.green.opacity(0.14) : Color.primary.opacity(0.06), in: Capsule())
                    .overlay(Capsule().strokeBorder(active ? Color.green.opacity(0.30) : Color.primary.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(.plain)
        } else {
            Label(L("On"), systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold)).foregroundStyle(.green).labelStyle(.titleAndIcon)
        }
    }

    /// Feature detail sheet (roadmap §5): benefit, what it needs, and Activate/Deactivate.
    @ViewBuilder private func detailSheet(_ f: Feature) -> some View {
        let active = f.gated ? settings.isFeatureEnabled(f.key) : true
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: f.icon).font(.system(size: 26)).foregroundStyle(.tint).frame(width: 40)
                Text(f.name).font(.system(size: 20, weight: .bold))
                Spacer()
            }
            Text(f.benefit).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            // Mini-demo placeholder (roadmap §5): a 5-second in-action clip lands here per feature.
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.softFill)
                VStack(spacing: 6) {
                    Image(systemName: f.icon).font(.system(size: 26)).foregroundStyle(.tint.opacity(0.7))
                    Text(L("Quick demo coming soon")).font(.caption).foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            if !f.requires.isEmpty {
                Label(f.requires, systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            shortcutSection(f)
            Spacer(minLength: 0)
            HStack {
                if !f.gated {
                    Label(L("Always on"), systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.callout.weight(.medium))
                    Spacer()
                } else if active {
                    Button(L("Turn off"), role: .destructive) { withAnimation(Self.anim) { settings.setFeature(f.key, false) }; detail = nil }
                    Spacer()
                    Text(L("Turning off only hides it, your data is kept.")).font(.caption).foregroundStyle(.tertiary)
                } else {
                    Button(L("Activate")) { withAnimation(Self.anim) { settings.setFeature(f.key, true) }; detail = nil }.keyboardShortcut(.defaultAction)
                    Spacer()
                }
                Button(L("Close")) { detail = nil }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 460, height: 460)
    }

    /// A feature's keyboard shortcut(s) — editable, plus the built-in Fn combo. Some features have
    /// several (Tasks = capture + today's glance), so this lists each with its own recorder.
    @ViewBuilder private func shortcutSection(_ f: Feature) -> some View {
        let rows = shortcutRows(f)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L("Shortcuts")).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                ForEach(rows, id: \.id) { r in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.label).font(.callout)
                            Text(L("Built-in: ") + r.builtin).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        ShortcutRecorder(
                            label: r.code == 0 ? L("Add a shortcut") : shortcutLabel(keyCode: r.code, modifiers: r.mods),
                            onCapture: r.set)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private struct ShortcutRow: Identifiable {
        let id: String
        let label: String
        let builtin: String
        let code: UInt32
        let mods: UInt32
        let set: (UInt32, UInt32) -> Void
    }

    private func shortcutRows(_ f: Feature) -> [ShortcutRow] {
        let s = settings
        switch f.key {
        case FeatureFlags.jarvis:
            return [ShortcutRow(id: "jarvis", label: L("Run JARVIS"), builtin: "Fn + X",
                                code: s.actionModeKeyCode, mods: s.actionModeMods,
                                set: { c, m in s.actionModeKeyCode = c; s.actionModeMods = m })]
        case FeatureFlags.notes:
            return [ShortcutRow(id: "note", label: L("Record a note"), builtin: "Fn + Z",
                                code: s.noteRecordKeyCode, mods: s.noteRecordMods,
                                set: { c, m in s.noteRecordKeyCode = c; s.noteRecordMods = m })]
        case FeatureFlags.tasks:
            return [
                ShortcutRow(id: "todo", label: L("Capture a to-do"), builtin: "Fn + T",
                            code: s.todoCaptureKeyCode, mods: s.todoCaptureMods,
                            set: { c, m in s.todoCaptureKeyCode = c; s.todoCaptureMods = m }),
                ShortcutRow(id: "glance", label: L("Today's to-dos"), builtin: "⌥ + Fn",
                            code: s.todoGlanceKeyCode, mods: s.todoGlanceMods,
                            set: { c, m in s.todoGlanceKeyCode = c; s.todoGlanceMods = m }),
            ]
        case FeatureFlags.transforms:
            return [ShortcutRow(id: "transform", label: L("Transform selection"), builtin: "⌥ + X",
                                code: UInt32(s.transformHotkeyCode), mods: UInt32(1 << 11) /* option */,
                                set: { c, _ in s.transformHotkeyCode = Int(c) })]
        default:
            return []
        }
    }
}
