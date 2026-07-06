import SwiftUI
import AppKit
import AVFoundation
import IOKit.hid
import EventKit

// MARK: - Settings sections (the custom left rail)

private enum SettingsSection: String, CaseIterable, Identifiable {
    // Connected apps moved out of Settings into the sidebar (Library ▸ Connected apps) — it's a feature, not a setting.
    case account, dictation, rewriting, action, output, customize, styles, shortcuts, privacy, updates, changelog
    var id: String { rawValue }
    var title: String {
        switch self {
        case .account:       return L("Account & Plan")
        case .dictation:     return L("Dictation")
        case .rewriting:     return L("AI rewriting")
        case .action:        return L("Action mode")
        case .output:        return L("Output & feedback")
        case .customize:     return L("Customize")
        case .styles:        return L("Styles")
        case .shortcuts:     return L("Shortcuts")
        case .privacy:       return L("Privacy & history")
        case .updates:       return L("Updates & about")
        case .changelog:     return L("Changelog")
        }
    }
    var icon: String {
        switch self {
        case .account:       return "person.crop.circle"
        case .dictation:     return "waveform"
        case .rewriting:     return "wand.and.stars"
        case .action:        return "bolt.fill"
        case .output:        return "arrow.down.doc"
        case .customize:     return "paintpalette"
        case .styles:        return "paintbrush"
        case .shortcuts:     return "keyboard"
        case .privacy:       return "lock.shield"
        case .updates:       return "arrow.triangle.2.circlepath"
        case .changelog:     return "sparkles"
        }
    }
    var subtitle: String {
        switch self {
        case .account:       return L("Sign-in, plan, referrals")
        case .dictation:     return L("Engine, mic, language")
        case .rewriting:     return L("Backend, model, API keys")
        case .action:        return L("Destinations, search, tools")
        case .output:        return L("Paste, overlay, sounds")
        case .customize:     return L("Glass, accent, widget")
        case .styles:        return L("Tone & format layer")
        case .shortcuts:     return L("Triggers & chords")
        case .privacy:       return L("History, permissions")
        case .updates:       return L("Version & releases")
        case .changelog:     return L("What's new, every release")
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var appearance = VerbaAppearance.shared
    @State private var section: SettingsSection = .account

    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var axGranted = Output.accessibilityTrusted
    @State private var imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    @State private var screenGranted = ScreenCapture.hasPermission()
    private let permPoll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    @State private var eventCalendars: [(String, String)] = []   // (identifier, title) for the Action destination picker
    @State private var reminderLists: [(String, String)] = []
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var openRouterKey = Keychain.openRouterKey ?? ""
    @State private var keysSaved = false
    @State private var selectedStyleID: UUID?   // Styles section: which style's editor is expanded
    @State private var verifying = false
    @State private var verifyMsg = ""
    // Restore-subscription field is detached from the live account identity (settings.proEmail):
    // free-typing here must never overwrite/persist the signed-in account email. Only commit on a
    // successful verify.
    @State private var restoreEmail = ""
    @State private var signingIn = false
    @State private var confirmSignOut = false
    @State private var confirmCloudWipe = false
    @State private var cloudWiped = false
    @State private var cloudWiping = false
    @State private var cloudWipeError = false
    @State private var cloudWipeAttempt = UUID()
    @State private var confirmUninstall = false
    @State private var engineTab: TranscriptionEngine = Settings.shared.engine
    @State private var installing = false
    @State private var installProgress: Double = 0
    @State private var installMsg = ""
    @State private var ollamaUp = false
    @State private var ollamaHasModel = false
    @State private var pulling = false
    @State private var pullProgress: Double = 0
    @State private var engineInstalling = false
    @State private var engineRefresh = 0
    @State private var activating = false
    @State private var cacheBytes: Int64 = 0
    @ObservedObject private var updater = Updater.shared
    @State private var autoCheck = Updater.shared.autoCheck
    @State private var autoDownload = Updater.shared.autoDownload
    @State private var copiedReferral = false

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        HStack(spacing: 0) {
            rail
            Divider().opacity(0.5)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    detailHeader
                    detail
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26).padding(.top, 24).padding(.bottom, 28)
            }
        }
        .frame(minWidth: 720, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
        .tint(.primary)
        .onReceive(permPoll) { _ in
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            axGranted = Output.accessibilityTrusted
            imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
            screenGranted = ScreenCapture.hasPermission()
        }
        .onAppear {
            cacheBytes = History.shared.audioCacheBytes()
            autoCheck = updater.autoCheck; autoDownload = updater.autoDownload
            // Seed the (detached) restore field from the current account email so it defaults to the
            // signed-in identity without ever two-way-binding to it.
            if restoreEmail.isEmpty { restoreEmail = settings.proEmail }
        }
    }

    // MARK: - Left rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header matches the Notes sidebar exactly (17pt bold, same padding rhythm).
            Text(L("Settings")).font(.system(size: 17, weight: .bold))
                .padding(.horizontal, 4).padding(.top, 14).padding(.bottom, 8)
            ForEach(SettingsSection.allCases) { s in
                railRow(s)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(width: 270)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func railRow(_ s: SettingsSection) -> some View {
        let selected = section == s
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { section = s }
        } label: {
            // IDENTICAL grammar to NotesView.noteRow: icon + 2-line card, padding 12/9,
            // radius 12, fill 0.04 idle / 0.12 selected + 0.4 stroke (no accent bar).
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: s.icon)
                    .font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(s.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                    Text(s.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .glassCard(selected: selected, cornerRadius: 12)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(section.title).font(.system(size: 17, weight: .bold))
            Text(section.subtitle).font(.callout).foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }

    // MARK: Styles — a Settings-NATIVE single-column layout (the old embed dropped the full two-pane
    // StyleView in here, which looked broken: double "Styles" header, squished panes, empty gutters).
    @ViewBuilder private var stylesDetail: some View {
        card(L("Your styles"),
             footer: L("A style is a reusable tone/format layer added on top of your mode when reprompting. Switch anytime with Fn + [ and Fn + ], or from the menu bar.")) {
            ForEach(settings.styles) { st in
                styleSettingsRow(st)
                if st.id != settings.styles.last?.id { Divider().opacity(0.35) }
            }
            HStack(spacing: 14) {
                Button {
                    let st = Style(name: L("New style"), prompt: "")
                    settings.styles.append(st)
                    withAnimation { selectedStyleID = st.id }
                } label: { Label(L("Add a style"), systemImage: "plus.circle.fill") }
                    .buttonStyle(.borderless)
                Spacer()
                Button {
                    settings.resetStylesToDefaults()
                    selectedStyleID = nil
                } label: { Label(L("Restore defaults"), systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary).font(.callout)
            }
            .padding(.top, 4)
        }

        // Inline editor for the expanded style (no second pane — it flows under the list).
        if let id = selectedStyleID, let idx = settings.styles.firstIndex(where: { $0.id == id }) {
            let isNormal = settings.styles[idx].builtin && settings.styles[idx].name == "Normal"
            card(L("Edit style")) {
                if isNormal {
                    Text(L("“Normal” is neutral: it adds nothing, so your modes behave exactly as their own prompts define. Create a new style to add a tone or format layer."))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                } else {
                    labeledField(L("Name"), $settings.styles[idx].name, prompt: L("e.g. Formal, Concise, Friendly"))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("Style prompt")).font(.subheadline.weight(.semibold))
                        TextEditor(text: $settings.styles[idx].prompt)
                            .font(.body).scrollContentBackground(.hidden).frame(minHeight: 120)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.05)))
                        Text(L("Layered on top of the mode’s own prompt when Verba rewrites your dictation."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        withAnimation { selectedStyleID = nil }
                        settings.styles.removeAll { $0.id == id }
                        if settings.activeStyleID == id, let first = settings.styles.first { settings.activeStyleID = first.id }
                    } label: { Label(L("Delete this style"), systemImage: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.red)
                }
            }
        }
    }

    private func styleSettingsRow(_ st: Style) -> some View {
        let active = st.id == settings.activeStyleID
        let expanded = st.id == selectedStyleID
        return HStack(spacing: 10) {
            Image(systemName: "paintbrush").font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 16)
            Text(st.name).font(.system(size: 13, weight: expanded ? .semibold : .medium)).lineLimit(1)
            Spacer(minLength: 8)
            if active {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                    Text(L("Active")).font(.system(size: 10, weight: .semibold))
                }.foregroundStyle(.green)
            } else {
                Button(L("Make active")) { settings.activeStyleID = st.id }
                    .buttonStyle(.borderless).font(.system(size: 11, weight: .medium))
            }
            Image(systemName: expanded ? "chevron.up" : "chevron.right")
                .font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedStyleID = expanded ? nil : st.id } }
    }

    @ViewBuilder private var detail: some View {
        switch section {
        case .account:       accountDetail
        case .dictation:     dictationDetail
        case .rewriting:     rewritingDetail
        case .action:        actionDetail
        case .output:        outputDetail
        case .customize: customizeDetail
        case .styles: stylesDetail
        case .shortcuts: shortcutsDetail
        case .privacy:   privacyDetail
        case .updates:   updatesDetail
        case .changelog: changelogDetail
        }
    }

    // MARK: - Shared building blocks

    /// A titled grouping card: caption header + a glass-fill card body.
    /// Populate the Action-mode destination pickers with the user's calendars / reminder lists,
    /// requesting access if needed. Empty lists fall back to "macOS default" only.
    private func loadActionCalendars() {
        let store = EKEventStore()
        func load() {
            eventCalendars = store.calendars(for: .event).map { ($0.calendarIdentifier, $0.title) }
            reminderLists = store.calendars(for: .reminder).map { ($0.calendarIdentifier, $0.title) }
        }
        if #available(macOS 14.0, *) {
            Task { _ = try? await store.requestFullAccessToEvents(); await MainActor.run { load() } }
        } else { load() }
    }

    private func card<Content: View>(_ title: String? = nil, footer: String? = nil,
                                     @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased()).font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary).tracking(0.6)
            }
            VStack(alignment: .leading, spacing: 12) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.04)))
            if let footer {
                Text(footer).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 2)
            }
        }
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>, help: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: binding)
                .toggleStyle(.switch).controlSize(.small)
                .font(.system(size: 13))
            if let help {
                Text(help).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func labeledField(_ label: String, _ binding: Binding<String>,
                              prompt: String, width: CGFloat = 280, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Group {
                if secure { SecureField(prompt, text: binding) }
                else { TextField(prompt, text: binding) }
            }
            .textFieldStyle(.plain)
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(maxWidth: width)
        }
    }

    /// Generic capsule-chip enum picker (the exemplar grammar for small enums).
    private func chips<T: Hashable & Identifiable>(_ options: [T], selected: T,
                                                   label: @escaping (T) -> String, icon: ((T) -> String)? = nil,
                                                   help: ((T) -> String)? = nil,
                                                   onPick: @escaping (T) -> Void) -> some View {
        SettingsChips(options: options, selected: selected, label: label, icon: icon, help: help, onPick: onPick)
    }

    /// One-line description of what each glass material looks like, for chip tooltips.
    /// The scale runs Frosted (most opaque) → Ultra (most translucent).
    private func materialHelp(_ m: VAppr.Material) -> String {
        switch m {
        case .frosted: return L("Frosted — the most opaque, menu-like glass.")
        case .soft:    return L("Soft — a light popover-style frost.")
        case .sidebar: return L("Sidebar — the translucency macOS uses for sidebars.")
        case .hud:     return L("HUD — a darker heads-up-display glass.")
        case .crystal: return L("Crystal — deep, very translucent (Notification Center look).")
        case .ultra:   return L("Ultra — the most translucent, full-screen-style glass.")
        }
    }

    /// Preset chips whose selection reflects the REAL active preset (nil = a custom
    /// mix, so no chip is highlighted) instead of a hard-coded default.
    private func presetChips(selected: VAppr.Preset?,
                             onPick: @escaping (VAppr.Preset) -> Void) -> some View {
        SettingsChips(options: VAppr.Preset.allCases, selectedOptional: selected,
                      label: { $0.rawValue }, icon: nil, onPick: onPick)
    }

    // MARK: - Customize (LiquidPad-style personalization: app interface + widget)

    @ViewBuilder private var customizeDetail: some View {
        // INTERFACE
        card(L("Interface"), footer: L("Make the app yours. Defaults are monochrome and macOS-native; everything here is optional.")) {
            apprLabel(L("Presets"))
            presetChips(selected: appearance.activePreset) { appearance.applyPreset($0) }
            // Live preview — re-renders with the current material + blur + corner + accent.
            previewTile(material: appearance.material, blur: appearance.blur,
                        cornerScale: appearance.cornerScale, accent: appearance.accentColor,
                        colorMode: appearance.colorMode, shadow: appearance.shadow, label: L("App preview"))
            apprLabel(L("Appearance"))
            chips(VAppr.ColorMode.allCases, selected: appearance.colorMode, label: { $0.label }) { appearance.colorMode = $0 }
            apprLabel(L("Glass material"))
            chips(VAppr.Material.allCases, selected: appearance.material, label: { $0.label },
                  help: materialHelp) { appearance.material = $0 }
            apprLabel(L("Accent"))
            accentSwatches(selected: appearance.accent,
                           customHex: appearance.accentHex,
                           onPick: { appearance.accent = $0 },
                           onCustom: { appearance.setCustomAccent($0) })
            sliderRow(L("Glass blur"), value: $appearance.blur, range: 0...40, suffix: "pt")
            sliderRow(L("Corner radius"), value: $appearance.cornerScale, range: 0.7...1.4, suffix: "×")
            toggleRow(L("Shadow on panels"), $appearance.shadow)
            toggleRow(L("Reduce motion"), $appearance.reduceMotion)
        }

        // MENUS — the glass behind popovers, dialogs and confirmations.
        card(L("Menus & popovers"), footer: L("Style the glass behind menus, dialogs and confirmations, independently of the main window.")) {
            apprLabel(L("Menu glass material"))
            chips(VAppr.Material.allCases, selected: appearance.menuMaterial, label: { $0.label },
                  help: materialHelp) { appearance.menuMaterial = $0 }
            sliderRow(L("Menu glass blur"), value: $appearance.menuBlur, range: 0...40, suffix: "pt")
        }

        // WIDGET
        card(L("Widget"), footer: L("Style the macOS Task Manager widget independently from the app.")) {
            apprLabel(L("Presets"))
            presetChips(selected: appearance.activeWidgetPreset) { appearance.applyWidgetPreset($0) }
            previewTile(material: appearance.widgetMaterial, blur: appearance.widgetBlur,
                        cornerScale: appearance.widgetCornerScale, accent: appearance.widgetAccentColor,
                        colorMode: appearance.widgetColorMode, shadow: appearance.widgetShadow, label: L("Widget preview"))
            apprLabel(L("Appearance"))
            chips(VAppr.ColorMode.allCases, selected: appearance.widgetColorMode, label: { $0.label }) { appearance.widgetColorMode = $0 }
            apprLabel(L("Glass material"))
            chips(VAppr.Material.allCases, selected: appearance.widgetMaterial, label: { $0.label },
                  help: materialHelp) { appearance.widgetMaterial = $0 }
            apprLabel(L("Accent"))
            accentSwatches(selected: appearance.widgetAccent,
                           customHex: appearance.widgetAccentHex,
                           onPick: { appearance.widgetAccent = $0 },
                           onCustom: { appearance.setWidgetCustomAccent($0) })
            sliderRow(L("Blur"), value: $appearance.widgetBlur, range: 0...40, suffix: "pt")
            sliderRow(L("Corner radius"), value: $appearance.widgetCornerScale, range: 0.7...1.4, suffix: "×")
            toggleRow(L("Shadow"), $appearance.widgetShadow)
        }
    }

    /// A small live-preview tile that re-renders with the current material, blur,
    /// corner radius, accent and color mode, so Customize sliders/chips show their
    /// effect instead of being abstract numbers.
    private func previewTile(material: VAppr.Material, blur: Double, cornerScale: Double,
                             accent: Color, colorMode: VAppr.ColorMode, shadow: Bool,
                             label: String) -> some View {
        let radius = VAppr.corner(16, scale: cornerScale)
        return ZStack {
            // Drive the real glass code path: blurRadius routes through GlassBlurView's
            // CAFilter (Glass.swift) exactly like the live app/widget surfaces, instead of
            // a faint quarter-strength SwiftUI .blur smear. The tile's NSVisualEffectView is
            // themed by colorMode via its scoped NSAppearance (set in TileColorScheme below).
            VisualEffectView(material: material.nsMaterial, blurRadius: blur)
            HStack(spacing: 10) {
                Circle().fill(accent).frame(width: 26, height: 26)
                    .overlay(Image(systemName: "waveform").font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colorMode == .dark ? .white : .primary))
                VStack(alignment: .leading, spacing: 3) {
                    Capsule().fill(.primary.opacity(0.55)).frame(width: 96, height: 7)
                    Capsule().fill(.primary.opacity(0.22)).frame(width: 60, height: 6)
                }
                Spacer(minLength: 0)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 64).frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .hairline(radius)
        .softElevation(shadow)
        // Scope the appearance to THIS tile only. `.environment(\.colorScheme,)` is
        // subtree-scoped (unlike `.preferredColorScheme`, which propagates up to the
        // hosting scene and would flip the whole Settings window), so two tiles with
        // different color modes no longer fight over the window's appearance.
        .modifier(TileColorScheme(colorMode: colorMode))
    }

    /// Confines a preview tile's light/dark look to the tile's own subtree.
    /// Auto (nil) leaves the tile following the window; light/dark force the SwiftUI
    /// color scheme locally without touching the scene-level preference.
    private struct TileColorScheme: ViewModifier {
        let colorMode: VAppr.ColorMode
        func body(content: Content) -> some View {
            if let scheme = colorMode.colorScheme {
                content.environment(\.colorScheme, scheme)
            } else {
                content
            }
        }
    }

    private func apprLabel(_ t: String) -> some View {
        Text(t).font(.caption.weight(.medium)).foregroundStyle(.secondary)
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 13)).frame(width: 110, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: suffix == "×" ? "%.2f%@" : "%.0f%@", value.wrappedValue, suffix))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
    }

    /// Accent picker: monochrome + fixed colors as round swatches + a custom color well.
    private func accentSwatches(selected: VAppr.Accent, customHex: String,
                                onPick: @escaping (VAppr.Accent) -> Void,
                                onCustom: @escaping (Color) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(VAppr.Accent.allCases.filter { $0 != .custom }) { a in
                let isSel = selected == a
                let swatch = a.nsColor.map { Color(nsColor: $0) } ?? Color.primary
                Button { onPick(a) } label: {
                    ZStack {
                        Circle().fill(a.nsColor.map { Color(nsColor: $0) } ?? Color.primary.opacity(0.18))
                            .frame(width: 22, height: 22)
                        if a == .monochrome {
                            Image(systemName: "circle.lefthalf.filled").font(.system(size: 12)).foregroundStyle(.primary)
                        }
                        // Selected swatches read through the swatch's OWN tint ring (selection
                        // feedback, the one allowed accent exception); unselected stays a hairline.
                        Circle().strokeBorder(isSel ? swatch.opacity(0.9) : Color.hairlineTint, lineWidth: isSel ? 2 : 1)
                            .frame(width: 24, height: 24)
                    }
                    .softElevation(isSel)
                }.buttonStyle(.plain)
                .help(a == .monochrome
                      ? L("Mono — no tint, follows light/dark automatically (the default).")
                      : "\(a.label) — \(L("tints buttons, selections and the recording dot."))")
            }
            // Custom color: a CLEAN circular swatch (rainbow when unset, the chosen color when set).
            // The native ColorPicker well renders as an ugly wide pill, so it's kept invisible but
            // clickable on top of the circle — the visible UI is always a tidy 22pt round swatch.
            let customSel = selected == .custom
            let customColor = Color(nsColor: VAppr.resolved(.custom, hex: customHex) ?? .systemIndigo)
            ZStack {
                if customSel {
                    Circle().fill(customColor).frame(width: 22, height: 22)
                } else {
                    Circle().fill(AngularGradient(
                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                        center: .center))
                        .frame(width: 22, height: 22).opacity(0.9)
                }
                Circle().strokeBorder(customSel ? customColor.opacity(0.9) : Color.hairlineTint,
                                      lineWidth: customSel ? 2 : 1)
                    .frame(width: 24, height: 24)
                // A plain tap re-selects the existing custom accent (restoring the stored
                // hex) without forcing a trip through the system color picker. This sits
                // UNDER the ColorPicker, so a tap on the well still opens the picker to
                // change the hue, while a tap that misses the well still reactivates .custom.
                Button { onCustom(customColor) } label: {
                    Color.clear.frame(width: 24, height: 24).contentShape(Circle())
                }.buttonStyle(.plain)
                ColorPicker("", selection: Binding(get: { customColor }, set: { onCustom($0) }),
                            supportsOpacity: false)
                    .labelsHidden().opacity(0.02)   // invisible but still opens the system picker
                    .frame(width: 24, height: 24)
            }
            .frame(width: 24, height: 24)
            .softElevation(customSel)
            .help(L("Custom color"))
            Spacer()
        }
    }

    /// A selectable "card" for engines / backends: icon, title, subtitle, selected ring.
    private func selectCard(icon: String, title: String, subtitle: String, selected: Bool,
                            trailing: AnyView? = nil, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 26)
                    .foregroundStyle(selected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if let trailing { trailing }
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 13).padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(selected: selected, cornerRadius: 12)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func statusLabel(_ text: String, system: String, tint: Color) -> some View {
        Label(text, systemImage: system)
            .font(.caption).foregroundStyle(tint).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 1 · Account & Plan

    @ViewBuilder private var accountDetail: some View {
        // Pro/Free hero
        planHero

        // Sign in / out + reconnect
        card(L("Account")) {
            if settings.proEmail.isEmpty {
                HStack {
                    Label(L("Not signed in"), systemImage: "person.crop.circle.badge.questionmark")
                        .foregroundStyle(.secondary).font(.system(size: 13))
                    Spacer()
                    Button { startSignIn() } label: { Text(signingIn ? L("Signing in…") : L("Sign in")) }
                        .glassProminentButton().controlSize(.regular).disabled(signingIn)
                }
                Text(L("Sign in to sync your plan, use the included AI rewriting (no key needed), and earn referral rewards."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else {
                HStack {
                    Label(settings.proEmail, systemImage: "person.crop.circle.fill")
                        .font(.system(size: 13)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button(role: .destructive) { confirmSignOut = true } label: { Text(L("Sign out")) }
                        .glassButton().controlSize(.regular)
                        .confirmationDialog(L("Sign out of Verba?"), isPresented: $confirmSignOut, titleVisibility: .visible) {
                            Button(L("Sign out"), role: .destructive) { AuthSession.shared.signOut() }
                            Button(L("Cancel"), role: .cancel) { }
                        } message: {
                            Text(L("This detaches your account from this Mac. Your local notes, transcripts and to-dos stay on this device, you can sign back in anytime."))
                        }
                }
                if settings.needsReauth {
                    HStack(alignment: .top, spacing: 10) {
                        statusLabel(L("Please sign in again to keep Pro and sync secure."),
                                    system: "exclamationmark.triangle.fill", tint: .orange)
                        Spacer()
                        Button { startSignIn() } label: { Text(signingIn ? L("Signing in…") : L("Sign in again")) }
                            .glassButton().controlSize(.small).disabled(signingIn)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.orange.opacity(0.1)))
                }
                Text(L("Signed in. Signing out keeps everything stored locally on this Mac, it only disconnects this device from your account."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }

        // Restore / verify checkout email
        card(L("Restore a subscription"),
             footer: settings.isPro
             ? L("Thanks! Unlimited dictation, editable mode prompts and custom modes. Your subscription is active for this email.")
             : L("Already subscribed? Enter your checkout email and Verify to restore.")) {
            labeledField(L("Email used at checkout"), $restoreEmail, prompt: L("you@example.com"))
            HStack {
                Button {
                    verifying = true; verifyMsg = ""
                    Task {
                        let ok = await settings.verifyPro()
                        verifying = false
                        if ok {
                            // Only on a confirmed Pro result do we reconcile the displayed account
                            // identity with the email the user just verified — never on free-typing.
                            let typed = restoreEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !typed.isEmpty { settings.proEmail = typed }
                        }
                        verifyMsg = ok ? L("Pro unlocked ✓") : L("No active subscription for this email.")
                    }
                } label: { Text(verifying ? L("Checking…") : (settings.isPro ? L("Re-check") : L("Verify / restore"))) }
                    .glassButton().controlSize(.regular)
                    .disabled(verifying || restoreEmail.isEmpty)
                if !verifyMsg.isEmpty {
                    Text(verifyMsg).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let u = URL(string: Entitlement.accountURL) {
                    Link(L("Manage"), destination: u).font(.caption)
                }
            }
        }

        // Free trial usage bar
        if !settings.isPro {
            let used = Stats.shared.totalCount
            let limit = Entitlement.freeTrialDictations
            let exhausted = used >= limit
            card(L("Your plan"),
                 footer: L("Raw dictation is free forever and unlimited. Pro ($9.99/mo) unlocks every AI mode (Polish, Translate, Prompt…), Notes, Tasks, JARVIS, editable system prompts and custom modes.")) {
                if exhausted {
                    // AI modes locked: Raw stays free forever, Pro unlocks the rest.
                    HStack(spacing: 10) {
                        statusLabel(L("Raw stays free forever. Upgrade to Pro for the AI modes."),
                                    system: "checkmark.circle.fill", tint: .secondary)
                        Spacer()
                        if let u = URL(string: Entitlement.pricingURL) {
                            Link(L("Upgrade"), destination: u).glassProminentButton().controlSize(.small)
                        }
                    }
                } else {
                    HStack {
                        Text("\(used) / \(limit) \(L("dictations"))").font(.callout).monospacedDigit()
                        Spacer()
                        Text("\(limit - used) \(L("left"))").font(.callout).monospacedDigit().foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(used), total: Double(limit))
                }
            }
        }

        // Username + leaderboard visibility
        card(L("Public alias"),
             footer: L("Your username is PUBLIC on the leaderboard and synced to your account, so pick a nickname, never your real name or email.")) {
            HStack(spacing: 8) {
                TextField(L("Username"), text: $settings.username)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .frame(maxWidth: 240)
                Button { settings.username = Settings.randomAlias() } label: {
                    Image(systemName: "shuffle").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain).help(L("Shuffle a new username"))
                Spacer()
            }
            toggleRow(L("Show me on the public leaderboard"), $settings.showOnLeaderboard)
        }

        // Referral
        card(L("Refer friends — give a month, get a month"),
             footer: L("Every friend who subscribes through your link and dictates 15,000+ words earns you a free month, unlimited, no cap.")) {
            HStack(spacing: 10) {
                Text(settings.referralLink)
                    .font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                Spacer()
                Button {
                    let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) { copiedReferral = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation(.easeOut(duration: 0.2)) { copiedReferral = false }
                    }
                } label: {
                    Label(copiedReferral ? L("Copied") : L("Copy"), systemImage: copiedReferral ? "checkmark" : "doc.on.doc")
                }
                .glassButton().controlSize(.small)
                // Same Share affordance as the Free Month tab, so the referral surfaces match.
                Button { shareReferral() } label: { Label(L("Share…"), systemImage: "square.and.arrow.up") }
                    .glassButton().controlSize(.small)
            }
            .padding(.horizontal, 11).padding(.vertical, 9)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    /// Share the referral link through the native macOS share sheet — mirrors FreeMonthView.
    private func shareReferral() {
        let picker = NSSharingServicePicker(items: [URL(string: settings.referralLink) ?? settings.referralLink as Any])
        if let win = NSApp.keyWindow, let view = win.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }

    private var planHero: some View {
        HStack(spacing: 14) {
            Image(systemName: settings.isPro ? "sparkles" : "circle.dashed")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 46, height: 46)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(settings.isPro ? "Verba Pro" : L("Free plan")).font(.system(size: 17, weight: .bold))
                Text(settings.isPro ? L("Unlimited dictation, custom modes, editable prompts.")
                                    : L("Raw dictation free forever. Upgrade for the AI modes + features."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if !settings.isPro, let u = URL(string: Entitlement.pricingURL) {
                Link(destination: u) { Text(L("Upgrade · 7-day trial")) }
                    .glassProminentButton().controlSize(.large)
            } else if settings.isPro {
                Label(L("Active"), systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .softElevation(!settings.isPro)
    }

    // MARK: - 2 · Dictation

    @ViewBuilder private var actionDetail: some View {
        cardCaption(L("Action mode turns a spoken command into a confirmed action on your Mac. Trigger it with Fn+X (or rebind it in Shortcuts), speak your command, review the confirmation, and press ⌘↩ to run it. Examples: “create an event tomorrow at 3pm, lunch with Marc”, “remind me to call the bank Friday morning”, “search the best ramen in Paris on Google”, “open Spotify”, “run my Morning Routine shortcut”."))
        card(L("Allowed actions"),
             footer: L("Turn off any category you never want Verba to do.")) {
            ForEach(ActionKind.allCases, id: \.self) { k in
                Toggle(isOn: Binding(
                    get: { settings.isActionEnabled(k) },
                    set: { on in if on { settings.disabledActions.remove(k.rawValue) } else { settings.disabledActions.insert(k.rawValue) } }
                )) {
                    Label(k.label, systemImage: k.icon)
                }
                .toggleStyle(.switch)
            }
        }
        cardCaption(L("Connected apps now live in the sidebar, under Library ▸ Connected apps — connect Gmail, Slack, Notion and 1,000+ more, then act on them by voice."))
        card(L("Destinations"),
             footer: L("Calendar events and reminders are written here. Pick a specific calendar/list (e.g. a Google or Notion-synced one), or leave on the macOS default. Set up the account in Calendar.app / Reminders.app first.")) {
            Picker(L("Calendar"), selection: $settings.eventCalendarID) {
                Text(L("macOS default")).tag("")
                ForEach(eventCalendars, id: \.0) { Text($0.1).tag($0.0) }
            }
            Picker(L("Reminders list"), selection: $settings.reminderListID) {
                Text(L("macOS default")).tag("")
                ForEach(reminderLists, id: \.0) { Text($0.1).tag($0.0) }
            }
        }
        .onAppear { loadActionCalendars() }
        card(L("Web search targets"),
             footer: L("Say “search … on Google / ChatGPT / Claude”. {q} is replaced by what you said; add any site.")) {
            ForEach($settings.searchTargets) { $t in
                HStack(spacing: 8) {
                    TextField(L("Name"), text: $t.name).frame(width: 110).textFieldStyle(.roundedBorder)
                    TextField("https://…/search?q={q}", text: $t.urlTemplate).textFieldStyle(.roundedBorder)
                    Button { settings.searchTargets.removeAll { $0.id == t.id } } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.borderless).help(L("Remove"))
                }
            }
            HStack {
                Button { settings.searchTargets.append(SearchTarget(name: "New", urlTemplate: "https://example.com/search?q={q}")) } label: {
                    Label(L("Add search target"), systemImage: "plus")
                }.buttonStyle(.borderless)
                Spacer()
                Button(L("Reset to defaults")) { settings.searchTargets = SearchTarget.defaults }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var dictationDetail: some View {
        card(L("Transcription engine")) {
            VStack(spacing: 9) {
                ForEach(TranscriptionEngine.allCases) { e in
                    selectCard(
                        icon: e == .openAI ? "cloud" : (e == .whisper ? "waveform.circle" : "cpu"),
                        title: e.label,
                        subtitle: engineSubtitle(e),
                        selected: engineTab == e,
                        onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { engineTab = e } }
                    )
                }
            }
            engineLifecycle
            // The OpenAI (cloud transcription) engine needs your OpenAI key — it lives HERE, with the
            // engine that uses it, not in AI rewriting. (Same key is reused if you also pick OpenAI there.)
            if engineTab == .openAI {
                apiKeyField(L("OpenAI API key"), "sk-…", $openAIKey) { Keychain.openAIKey = $0 }
                Text(L("Used for OpenAI cloud transcription. Saved in your macOS Keychain."))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }

        card(L("Microphone"),
             footer: L("Verba uses your default system microphone. Pick the input device in System Settings ▸ Sound.")) {
            permissionRow("mic.fill", L("Microphone access"), L("Record your voice."), granted: micGranted) {
                AVCaptureDevice.requestAccess(for: .audio) { _ in }
                openPane("Privacy_Microphone")
            }
        }

        card(L("Language")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Primary language")).font(.system(size: 13))
                    Text(L("Your everyday language. Output defaults to it when the spoken language is ambiguous; a clearly-spoken other language is always kept."))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Picker("", selection: $settings.mainLanguage) {
                    Text(L("Auto-detect")).tag("")
                    Divider()
                    ForEach(translateLanguages, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden().fixedSize()
            }
            labeledField(L("Spoken language"), $settings.language, prompt: L("ISO code, blank = auto"))
            toggleRow(L("Single-language output"), $settings.languageGuard,
                      help: settings.languageGuard ? L("If the engine mixes two languages mid-sentence, Verba rewrites the result fully in its dominant language. Applies to every mode, including Raw.") : nil)
        }

        card(L("Voice commands")) {
            toggleRow(L("Voice commands"), $settings.voiceCommands,
                      help: settings.voiceCommands ? L("Say “new line / new paragraph”, “comma / period / question mark”, “bullet point”, or “scratch that” and Verba turns them into real formatting (any mode, incl. Flow). EN + FR.") : nil)
        }
    }

    private func engineSubtitle(_ e: TranscriptionEngine) -> String {
        switch e {
        case .openAI:   return L("Remote, no download. Uses your OpenAI key.")
        case .whisper:  return L("On-device WhisperKit. Fully offline & free.")
        case .parakeet: return L("On-device NVIDIA Parakeet, multilingual. Offline & free.")
        }
    }

    // MARK: - 3 · AI rewriting

    @ViewBuilder private var rewritingDetail: some View {
        card(L("Reprompting")) {
            toggleRow(L("Restructure transcript with Claude"), $settings.repromptEnabled)
        }

        card(L("Backend")) {
            VStack(spacing: 9) {
                ForEach(RepromptBackend.allCases) { b in
                    selectCard(
                        icon: backendIcon(b),
                        title: b.label,
                        subtitle: backendSubtitle(b),
                        selected: settings.repromptBackend == b,
                        onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { settings.repromptBackend = b } }
                    )
                }
            }
            backendStatus
        }

        // Per-backend model
        if settings.repromptBackend == .openRouter {
            card(L("OpenRouter model"),
                 footer: L("Any model on openrouter.ai (openai/gpt-4o, google/gemini-2.0-flash…). Add your key below.")) {
                labeledField(L("Model id"), $settings.openRouterModel, prompt: "anthropic/claude-3.7-sonnet", width: 360)
            }
        } else if settings.repromptBackend == .localLLM {
            card(L("Local model (Ollama)")) { localModelBlock }
        } else if settings.repromptBackend == .apiKey {
            card(L("Provider")) {
                chips(ApiKeyProvider.allCases, selected: settings.apiKeyProvider,
                      label: { $0.label }, onPick: { settings.apiKeyProvider = $0 })
            }
            apiKeyProviderModelCard
        } else {
            card(L("Claude model")) {
                chips(claudeModels.map { IdString($0) }, selected: IdString(settings.claudeModel),
                      label: { $0.id }, onPick: { settings.claudeModel = $0.id })
            }
        }

        card(L("Context")) {
            toggleRow(L("Auto-pick profile from the active app"), $settings.autoDetectProfile)
            toggleRow(L("Use selected text as context"), $settings.useSelectionContext,
                      help: settings.useSelectionContext ? L("If text is selected when you dictate, your words become an instruction on that selection, and the result replaces it.") : nil)
        }

        // Only the reprompting key the CHOSEN backend actually uses (transcription's OpenAI key
        // lives in Dictation ▸ engine, not here).
        repromptKeyCard
    }

    /// The one API-key field the current reprompting backend needs — nothing more. Backends that
    /// need no key (Verba managed, Claude subscription, Fully local) show no key card at all.
    @ViewBuilder private var repromptKeyCard: some View {
        let b = settings.repromptBackend
        let footer = L("Saved automatically as you type, in your macOS Keychain.")
        if b == .openRouter || (b == .apiKey && settings.apiKeyProvider == .openRouter) {
            card(L("API key"), footer: footer) {
                apiKeyField(L("OpenRouter"), "sk-or-…", $openRouterKey) { Keychain.openRouterKey = $0 }
            }
        } else if b == .apiKey && settings.apiKeyProvider == .openAI {
            card(L("API key"), footer: footer) {
                apiKeyField(L("OpenAI"), "sk-…", $openAIKey) { Keychain.openAIKey = $0 }
                Text(L("Same OpenAI key as Dictation ▸ cloud transcription."))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        } else if b == .apiKey || b == .auto {
            // .apiKey→Anthropic, and .auto uses your Anthropic key as one of its fallbacks.
            card(L("API key"), footer: footer) {
                apiKeyField(L("Anthropic (Claude)"), "sk-ant-…", $anthropicKey) { Keychain.anthropicKey = $0 }
            }
        }
    }

    /// The model field for whichever provider is picked under the "My API key" backend.
    @ViewBuilder private var apiKeyProviderModelCard: some View {
        switch settings.apiKeyProvider {
        case .anthropic:
            card(L("Claude model")) {
                chips(claudeModels.map { IdString($0) }, selected: IdString(settings.claudeModel),
                      label: { $0.id }, onPick: { settings.claudeModel = $0.id })
            }
        case .openAI:
            card(L("OpenAI model"),
                 footer: L("Any OpenAI chat model (gpt-4o, gpt-4.1, o3…). Add your key below.")) {
                labeledField(L("Model id"), $settings.openAIModel, prompt: "gpt-4o", width: 280)
            }
        case .openRouter:
            card(L("OpenRouter model"),
                 footer: L("Any model on openrouter.ai (openai/gpt-4o, google/gemini-2.0-flash…). Add your key below.")) {
                labeledField(L("Model id"), $settings.openRouterModel, prompt: "anthropic/claude-3.7-sonnet", width: 360)
            }
        }
    }

    private func apiKeyField(_ label: String, _ prompt: String, _ binding: Binding<String>,
                             store: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            SecureField(prompt, text: binding)
                .textFieldStyle(.plain)
                .padding(.horizontal, 11).padding(.vertical, 8)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: binding.wrappedValue) { _, v in
                    store(v.trimmingCharacters(in: .whitespacesAndNewlines))
                }
        }
    }

    private func backendIcon(_ b: RepromptBackend) -> String {
        switch b {
        case .auto:       return "wand.and.stars"
        case .verba:      return "checkmark.seal"
        case .claudeCode: return "terminal"
        case .apiKey:     return "key"
        case .openRouter: return "arrow.triangle.branch"
        case .localLLM:   return "cpu"
        }
    }
    private func backendSubtitle(_ b: RepromptBackend) -> String {
        switch b {
        case .auto:       return L("Claude Code if present, else Verba's included engine.")
        case .verba:      return L("Included, no key. Runs on Verba's servers.")
        case .claudeCode: return L("Runs on your Claude Max/Pro plan via the local CLI.")
        case .apiKey:     return L("Pay-per-token with your own OpenAI, Anthropic, or OpenRouter key.")
        case .openRouter: return L("Any model on openrouter.ai with your key.")
        case .localLLM:   return L("Fully offline on your Mac via Ollama.")
        }
    }

    /// Whether the Keychain slot for the given "My API key" provider is filled (reads the live
    /// @State text, which mirrors Keychain via apiKeyField's onChange).
    private func hasApiKey(for provider: ApiKeyProvider) -> Bool {
        switch provider {
        case .anthropic:  return !anthropicKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .openAI:     return !openAIKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .openRouter: return !openRouterKey.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    @ViewBuilder private var backendStatus: some View {
        switch settings.repromptBackend {
        case .auto:
            statusLabel(ClaudeCode.isAvailable
                        ? L("Using Claude Code (runs on your Claude plan, no key).")
                        : L("Using Verba's included rewriting (no key, no setup)."),
                        system: "wand.and.stars", tint: .secondary)
        case .verba:
            if settings.proEmail.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    statusLabel(L("Sign in to use the included rewriting, no API key needed."),
                                system: "exclamationmark.triangle.fill", tint: .orange)
                    Spacer()
                    Button { startSignIn() } label: { Text(signingIn ? L("Signing in…") : L("Sign in")) }
                        .glassButton().controlSize(.small).disabled(signingIn)
                }
            } else {
                statusLabel(L("Included with Verba, no API key needed. Runs on Verba's servers."),
                            system: "checkmark.seal.fill", tint: .green)
            }
        case .claudeCode:
            statusLabel(ClaudeCode.isAvailable
                        ? L("Claude Code detected, uses your Claude plan, no API key.")
                        : L("Claude Code not found. Install it and run `claude` once to sign in."),
                        system: ClaudeCode.isAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tint: ClaudeCode.isAvailable ? .green : .orange)
        case .apiKey:
            if hasApiKey(for: settings.apiKeyProvider) {
                statusLabel(String(format: L("Using your %@ key."), settings.apiKeyProvider.label),
                            system: "checkmark.seal.fill", tint: .green)
            } else {
                statusLabel(String(format: L("Add your %@ key in the API keys section below."), settings.apiKeyProvider.label),
                            system: "exclamationmark.triangle.fill", tint: .orange)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - 4 · Output & feedback

    @ViewBuilder private var outputDetail: some View {
        card(L("Paste & formatting"),
             footer: L("Formatting pastes as real bold/headings/lists in apps that support it; plain fields get clean text.")) {
            toggleRow(L("Auto-paste into the active field"), $settings.autoPaste)
            toggleRow(L("Copy to clipboard"), $settings.copyToClipboard)
            toggleRow(L("Paste with formatting (render Markdown)"), $settings.richTextPaste)
            toggleRow(L("Review / edit before sending"), $settings.reviewBeforeSend)
            if !Output.accessibilityTrusted {
                HStack {
                    statusLabel(L("Auto-paste needs Accessibility access"), system: "exclamationmark.triangle.fill", tint: .orange)
                    Spacer()
                    Button(L("Enable…")) { Output.promptAccessibility() }.glassButton().controlSize(.small)
                }
            }
        }

        card(L("Recording indicator")) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Overlay style")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(OverlayStyle.allCases, selected: settings.overlayStyle,
                      label: { $0.label }, onPick: { settings.overlayStyle = $0 })
            }
            if settings.overlayStyle == .minimal {
                Text(L("No floating window. The menu-bar icon turns red and pulses while recording."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Recording style")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(RecordStyle.allCases, selected: settings.recordStyle,
                      label: { $0.label }, onPick: { settings.recordStyle = $0 })
            }
            Text(settings.recordStyle.help).font(.caption).foregroundStyle(.secondary)
        }

        card(L("Sounds"),
             footer: L("Cues for recording start, paste, and errors. Only your custom mp3s play (no macOS system beeps). Drop more in the Sounds folder.")) {
            toggleRow(L("Sound effects"), $settings.soundsEnabled)
            if settings.soundsEnabled {
                HStack {
                    Text(L("Volume")).font(.system(size: 13))
                    Slider(value: $settings.soundVolume, in: 0...1)
                    Text("\(Int(settings.soundVolume * 100))%").monospacedDigit()
                        .foregroundStyle(.secondary).frame(width: 42, alignment: .trailing)
                }
            }
        }

        card(L("Loading jokes"),
             footer: settings.quipTone == .off
             ? "\(L("While Claude works, Verba shows a neutral")) “\(Quips.neutral)”."
             : L("While Claude works, Verba shows a short AI-generated joke in this style, never the same twice in a day.")) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Joke style")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(QuipTone.allCases, selected: settings.quipTone,
                      label: { $0.label }, onPick: { settings.quipTone = $0 })
            }
        }

        card(L("App presence"), footer: L("Dock off = menu-bar only. The dictation hotkeys work either way. If you hide BOTH, reopen Verba from Applications to get back here.")) {
            toggleRow(L("Show in Dock (full window app)"), $settings.showInDock)
            toggleRow(L("Show the menu-bar icon"), $settings.showMenuBarIcon)
        }

        card(L("Fn key behaviour"), footer: L("By default Verba takes over the globe (Fn) key so macOS doesn't pop the emoji/Fn HUD or switch your keyboard layout. Turn these off to get the standard macOS behaviour back.")) {
            toggleRow(L("Stop the macOS Fn / emoji popup"), $settings.suppressFnPopup)
            toggleRow(L("Disable the keyboard / input-source switcher"), $settings.disableInputSwitcher)
        }

        labsCard
        sidebarCard
    }

    @ViewBuilder private var labsCard: some View {
        card(L("Labs")) {
            toggleRow(L("Notes tab (long-form voice notes)"), $settings.notesTabEnabled,
                      help: L("A Notes tab to record long voice memos (up to an hour) and reorganize them into a clean document."))
            toggleRow(L("Task Manager tab (tasks by project)"), $settings.todosTabEnabled,
                      help: L("Capture tasks and sub-tasks by voice, sorted into projects. Ask the agent to build a whole list from a spoken request."))
            toggleRow(L("To-do reminders (30 min before a deadline)"), $settings.todoReminders,
                      help: L("Posts a local notification 30 minutes before a to-do's deadline. Needs notification permission."))
            toggleRow(L("Smart formatting per app"), $settings.smartFormatting,
                      help: L("Rich text/markdown in apps that render it (Mail, Notion, Notes…), plain text in code editors and terminals."))
            toggleRow(L("Redo last dictation in another mode"), $settings.redoEnabled,
                      help: L("Adds “Redo last in…” to the menu, re-runs your last recording through any mode without speaking again."))
            toggleRow(L("Auto-learn dictionary from your edits"), $settings.autoLearnDictionary,
                      help: L("When you fix a word, Verba spots the correction on your next dictation and applies it automatically. Learned terms appear in Dictionary."))
            toggleRow(L("Match my tone per app"), $settings.toneMatch,
                      help: L("Verba learns how you write in each app and matches that tone automatically."))
            toggleRow(L("Edit last result by voice"), $settings.voiceEditLast,
                      help: L("Adds “Edit last by voice…” to the menu, speak a change (“make it shorter”, “more formal”…) and Verba rewrites your last result."))
            toggleRow(L("Agentic actions in Context mode"), $settings.agenticActions,
                      help: L("In Context mode, turn spoken commands into Calendar events, Reminders, or email drafts — it always asks you to confirm first."))
            Text(L("Tip: hold Fn + X anytime for Action mode — speak a command (run a Shortcut, open an app, play music, message someone) and Verba confirms before it acts. No toggle needed."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var sidebarCard: some View {
        card(L("Sidebar menu"), footer: L("Choose which sections show in the main window's sidebar. Home, Modes and Settings always stay.")) {
            ForEach(Self.sidebarItems) { item in
                toggleRow(item.title, sidebarBinding(item))
            }
        }
    }

    // MARK: - 5 · Shortcuts

    @ViewBuilder private var shortcutsDetail: some View {
        let fnOn = settings.useFnAsPrimary

        // SELECTION — the transform picker hotkey (Option + key).
        card(L("Transform selection"),
             footer: L("Select text in any app and press this to pick a transform to run on it. Option is always held; choose the key. Default is X (it's right under your fingers, unlike slash).")) {
            HStack(spacing: 10) {
                Text(L("Transform picker")).font(.system(size: 13))
                Spacer()
                Text("⌥ \(keyName(UInt32(settings.transformHotkeyCode)))")
                    .font(.system(size: 13, weight: .semibold)).monospaced()
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                ShortcutRecorder(label: L("Change")) { code, _ in
                    settings.transformHotkeyCode = Int(code)
                }
            }
        }

        // DICTATION — how you start, pause and cancel a dictation.
        card(L("Dictation")) {
            toggleRow(L("Use the Fn (🌐 globe) key as the trigger"), $settings.useFnAsPrimary)
            if fnOn {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("When you press Fn")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    chips(TriggerStyle.allCases, selected: settings.triggerStyle,
                          label: { $0.label }, onPick: { settings.triggerStyle = $0 })
                }
                chordRow(settings.triggerStyle == .hold
                         ? L("Hold to talk, release to send") : L("Tap to start, tap again to send"),
                         caps: ["Fn"])
            } else {
                chordRecorderRow(L("Start / stop dictation"),
                                 has: settings.primaryHasShortcut,
                                 code: settings.primaryKeyCode, mods: settings.primaryMods,
                                 target: .primary)
            }
            chordRow(L("Pause / resume while recording"), caps: ["⌃"])
            chordRecorderRow(L("Custom pause / resume shortcut"),
                             has: settings.pauseToggleHasShortcut,
                             code: settings.pauseToggleKeyCode, mods: settings.pauseToggleMods,
                             target: .pauseToggle)
            chordRow(L("Cancel recording or processing"), caps: ["⎋"])
            chordRecorderRow(L("Custom cancel shortcut"),
                             has: settings.cancelHasShortcut,
                             code: settings.cancelKeyCode, mods: settings.cancelMods,
                             target: .cancel)
            cardCaption(fnOn
                ? L("Your trigger is everything: tap or hold to dictate, then ⌃ to pause and ⎋ to cancel. You can add your own pause/cancel shortcut above — the defaults keep working.")
                : L("Pick the keystroke that starts and stops a dictation. ⌃ pauses, ⎋ cancels — and you can rebind any of them above."))
        }

        // MODES — choosing which rewriting mode the dictation runs through.
        if fnOn {
            card(L("Modes")) {
                toggleRow(L("Change-mode jumps straight to the next mode (no list)"), $settings.modeGestureCycles)
                toggleRow(L("Remember the last mode you used"), $settings.rememberLastMode,
                          help: L("After each dictation, the mode you just used becomes the default for the next one."))
                chordRow(L("Next mode  (add ⇧ for previous)"), caps: ["Fn", "⇥"])
                chordRow(L("Pick a mode by number"), caps: ["Fn", "1–9"])
                chordRow(L("Next mode hands-free while recording"), caps: ["⌥"])
                chordRecorderRow(L("Custom change-mode shortcut"),
                                 has: settings.modePickerHasShortcut,
                                 code: settings.modePickerKeyCode, mods: settings.modePickerMods,
                                 target: .modePicker)
                cardCaption(settings.modeGestureCycles
                    ? L("Fn + Tab cycles to the next mode even mid-dictation; turn the toggle off to open a numbered picker instead.")
                    : L("Fn + Tab opens a numbered picker; turn the toggle on to cycle straight to the next mode instead."))
            }
        }

        // STYLES — the tone/format layer on top of the active mode.
        if fnOn {
            card(L("Styles")) {
                chordRow(L("Next style"), caps: ["Fn", "]"])
                chordRecorderRow(L("Custom next-style shortcut"),
                                 has: settings.styleNextHasShortcut,
                                 code: settings.styleNextKeyCode, mods: settings.styleNextMods,
                                 target: .styleNext)
                chordRow(L("Previous style"), caps: ["Fn", "["])
                chordRecorderRow(L("Custom previous-style shortcut"),
                                 has: settings.stylePrevHasShortcut,
                                 code: settings.stylePrevKeyCode, mods: settings.stylePrevMods,
                                 target: .stylePrev)
                cardCaption(L("Styles tweak the tone or format on top of whatever mode you're in — flick between them without leaving your dictation."))
            }
        }

        // CAPTURE — voice notes, to-dos and the Mac-controlling Action mode.
        if fnOn {
            card(L("Capture")) {
                chordRow(L("Add a to-do by voice"), caps: FnTap.todoChordLabel.components(separatedBy: " + "))
                chordRecorderRow(L("Custom add-to-do shortcut"),
                                 has: settings.todoCaptureHasShortcut,
                                 code: settings.todoCaptureKeyCode, mods: settings.todoCaptureMods,
                                 target: .todoCapture)
                chordRow(L("Capture a note by voice"), caps: ["Fn", "Z"])
                chordRecorderRow(L("Custom record-note shortcut"),
                                 has: settings.noteRecordHasShortcut,
                                 code: settings.noteRecordKeyCode, mods: settings.noteRecordMods,
                                 target: .noteRecord)
                chordRow(L("Action mode — speak a command to control your Mac"), caps: ["Fn", "X"])
                chordRecorderRow(L("Custom Action-mode shortcut"),
                                 has: settings.actionModeHasShortcut,
                                 code: settings.actionModeKeyCode, mods: settings.actionModeMods,
                                 target: .actionMode)
                chordRow(L("Stop an in-progress note / to-do capture"), caps: ["Fn"])
                Divider().opacity(0.4)
                toggleRow(L("Show today's to-dos on ⌥ + Fn"), $settings.todoGlanceEnabled,
                          help: L("Press ⌥ (Option) + Fn for a compact glance of today's tasks. Press it again or ⎋ to dismiss."))
                chordRow(L("Today's to-dos  (quick glance)"), caps: ["⌥", "Fn"])
                chordRecorderRow(L("Custom to-do glance shortcut"),
                                 has: settings.todoGlanceHasShortcut,
                                 code: settings.todoGlanceKeyCode, mods: settings.todoGlanceMods,
                                 target: .todoGlance)
                cardCaption(L("Capture things hands-free: a note files into Notes, a to-do files into your projects, and Action mode turns speech into a command that runs on your Mac."))
            }
        }

        // EDITING — fixing or re-running the last dictation. Menu-bar actions (no chord).
        if fnOn {
            card(L("Editing")) {
                menuActionRow(L("Edit the last result by voice"),
                              L("Say a change (\u{201C}shorter\u{201D}, \u{201C}more formal\u{201D}\u{2026}) to rewrite what you just dictated."))
                menuActionRow(L("Redo the last recording in another mode"),
                              L("Re-run your last recording through a different mode \u{2014} no need to speak again."))
                cardCaption(L("Both live in Verba's menu-bar icon, under your recent result."))
            }
        }
    }

    /// A single keycap: monospace glyph in a soft-filled rounded rect with a subtle border.
    private func keycap(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, label.count > 1 ? 7 : 6).padding(.vertical, 3)
            .frame(minWidth: 22)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.hairlineTint, lineWidth: 1))
    }

    /// A row of individual keycaps (e.g. ⌥ ⌘ T as separate caps).
    private func keycaps(_ caps: [String]) -> some View {
        HStack(spacing: 4) { ForEach(Array(caps.enumerated()), id: \.offset) { keycap($0.element) } }
    }

    /// Description on the left, the chord rendered as individual keycaps on the right.
    private func chordRow(_ desc: String, caps: [String]) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(desc).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            keycaps(caps)
        }
    }

    /// A chord row whose binding is user-configurable — keeps the recorder control on the right.
    private func chordRecorderRow(_ desc: String, has: Bool, code: UInt32, mods: UInt32, target: ShortcutTarget) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(desc).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            ShortcutRecorder(
                label: has ? shortcutLabel(keyCode: code, modifiers: mods) : "",
                onCapture: { c, m in settings.assignShortcut(keyCode: c, modifiers: m, to: target) },
                onClear: { settings.clearShortcut(target) }
            )
        }
    }

    /// A menu-bar action (no keyboard chord): description + sub-line, tagged "Menu".
    private func menuActionRow(_ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Label(L("Menu"), systemImage: "menubar.arrow.up.rectangle")
                .labelStyle(.titleAndIcon)
                .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .fixedSize()
        }
    }

    /// A one-line caption under a Shortcuts group.
    private func cardCaption(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 6 · Privacy & history

    @ViewBuilder private var privacyDetail: some View {
        card(L("Dictation history")) {
            toggleRow(L("Save dictation history"), $settings.saveHistory,
                      help: settings.saveHistory ? nil : L("Off: new dictations are pasted and forgotten — nothing is written to disk, no audio is kept, nothing is synced. Existing history stays until you delete it below."))
            if settings.saveHistory {
                toggleRow(L("Keep recorded audio"), $settings.keepAudio,
                          help: settings.keepAudio ? L("Audio is saved with each entry so you can replay it. Turn off to keep only the text and save disk space.")
                                                   : L("Off: your text history is still saved, but no audio is stored. Frees disk if you never replay recordings."))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Keep history for")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(retentionOptions, selected: retentionOption(settings.historyRetentionDays),
                      label: { $0.label }, onPick: {
                          settings.historyRetentionDays = $0.days
                          History.shared.pruneExpired()
                          cacheBytes = History.shared.audioCacheBytes()
                      })
            }
        }

        card(L("Disk & cloud"),
             footer: L("Retention deletes dictations older than the chosen window (text + audio, locally and in your account's cloud sync). Clear audio cache frees disk while keeping your text history.")) {
            HStack {
                Label(L("Saved audio & buffers"), systemImage: "internaldrive").font(.system(size: 13))
                Spacer()
                Text(byteString(cacheBytes)).monospacedDigit().foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                History.shared.clearAudioCache(); cacheBytes = History.shared.audioCacheBytes()
            } label: { Label(L("Clear audio cache (keep history text)"), systemImage: "trash") }
                .glassButton().controlSize(.small)
            Button(role: .destructive) {
                History.shared.clear(); cacheBytes = History.shared.audioCacheBytes()
            } label: { Label(L("Delete all history (text + audio)"), systemImage: "trash.fill") }
                .glassButton().controlSize(.small)
            if !settings.proEmail.isEmpty {
                HStack(spacing: 8) {
                    Button(role: .destructive) { confirmCloudWipe = true } label: {
                        HStack(spacing: 6) {
                            if cloudWiping { ProgressView().controlSize(.small) }
                            Label(cloudWiped ? L("Cloud data deleted ✓")
                                  : (cloudWiping ? L("Deleting…") : L("Delete all my cloud data")),
                                  systemImage: "icloud.slash")
                        }
                    }
                    .glassButton().controlSize(.small)
                    .disabled(cloudWiping)
                    .confirmationDialog(L("Delete all your cloud data?"), isPresented: $confirmCloudWipe, titleVisibility: .visible) {
                        Button(L("Delete cloud data"), role: .destructive) { wipeCloudData() }
                        Button(L("Cancel"), role: .cancel) { }
                    } message: {
                        Text(L("Removes your synced history, notes, stats and leaderboard score from Verba's servers (with tombstones, so other Macs won't re-upload them). Local data on this Mac is untouched."))
                    }
                    if cloudWipeError {
                        statusLabel(L("Couldn't reach the server — cloud data may not have been deleted. Try again."),
                                    system: "exclamationmark.triangle.fill", tint: .orange)
                    }
                }
            }
        }

        card(L("Screen recording"),
             footer: L("Only used in Context mode to read on-screen text you point at. It's entirely optional.")) {
            permissionRow("camera.viewfinder", L("Screen Recording"), L("Context mode only (optional)."), granted: screenGranted) {
                ScreenCapture.requestPermission()
                ScreenCapture.openPrivacySettings()
            }
        }

        card(L("Core permissions")) {
            permissionRow("mic.fill", L("Microphone"), L("Record your voice."), granted: micGranted) {
                AVCaptureDevice.requestAccess(for: .audio) { _ in }; openPane("Privacy_Microphone")
            }
            permissionRow("hand.point.up.left.fill", L("Accessibility"), L("Paste into the active app."), granted: axGranted) {
                Output.promptAccessibility(); openPane("Privacy_Accessibility")
            }
            permissionRow("keyboard", L("Input Monitoring"), L("Use the Fn key as your trigger."), granted: imGranted) {
                _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent); openPane("Privacy_ListenEvent")
            }
            if micGranted && axGranted && imGranted {
                statusLabel(L("All set. Verba has everything it needs to work."), system: "checkmark.seal.fill", tint: .green)
            } else {
                statusLabel(L("Some permissions are off. Verba can't fully work until the three core ones are on."), system: "exclamationmark.triangle.fill", tint: .orange)
            }
        }

        card(L("What goes where")) {
            explainerRow(L("Audio & transcripts"), L("Stay on this Mac. Synced to your account only if history is on."))
            explainerRow(L("Cloud sync"), L("Encrypted in transit. Delete anytime with “Delete all my cloud data”."))
            explainerRow(L("Local engines"), L("Whisper / Parakeet / Ollama run 100% offline — nothing leaves your Mac."))
            explainerRow(L("Cloud engines"), L("OpenAI transcription and remote rewriting send your text to that provider."))
        }
    }

    private func explainerRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.secondary).padding(.top, 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12.5, weight: .semibold))
                Text(body).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 7 · Updates & about

    @ViewBuilder private var updatesDetail: some View {
        card(L("Automatic updates"),
             footer: L("Verba updates itself in the background via signed releases. Turn off automatic checks to update only when you press “Check now”.")) {
            toggleRow(L("Automatically check for updates"),
                      Binding(get: { autoCheck }, set: { autoCheck = $0; updater.autoCheck = $0 }))
            toggleRow(L("Automatically download & install updates"),
                      Binding(get: { autoDownload }, set: { autoDownload = $0; updater.autoDownload = $0 }))
        }

        card(L("Version")) {
            HStack {
                Label(L("Current version"), systemImage: "app.badge").font(.system(size: 13))
                Spacer()
                Text("v\(Updater.currentVersion)").monospacedDigit().foregroundStyle(.secondary)
            }
            if updater.updateAvailable, let v = updater.latestVersion {
                statusLabel("\(L("Update available:")) v\(v)", system: "arrow.down.circle.fill", tint: .blue)
            }
            if let when = updater.lastChecked {
                HStack {
                    Text(L("Last checked")).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(when.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Button { Updater.shared.checkForUpdates() } label: {
                Label(L("Check now"), systemImage: "arrow.triangle.2.circlepath")
            }
            .glassButton().controlSize(.small)
        }

        card(L("About")) {
            HStack {
                VerbaMark(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Verba").font(.system(size: 15, weight: .bold))
                    Text(L("Voice to clean text, on your terms.")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            explainerRow(L("JARVIS & connected apps"), L("Action mode is powered by JARVIS, Verba's voice agent, with 1,000+ third-party app connections — connect your apps in the sidebar under Library ▸ Connected apps, and act on them by voice."))
            explainerRow(L("Acknowledgements"), L("WhisperKit, NVIDIA Parakeet, Ollama, Sparkle, and the SwiftUI community. Thank you."))
        }
    }

    // MARK: - Changelog (the full release story, mirrored from verba.run/changelog)

    @ViewBuilder private var changelogDetail: some View {
        card {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").font(.system(size: 15)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(L("You're on")) v\(Updater.currentVersion)").font(.system(size: 13, weight: .semibold))
                    Text(L("Everything Verba has shipped since launch — newest first.")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        ForEach(Changelog.days) { day in changelogDayView(day) }
    }

    @ViewBuilder private func changelogDayView(_ day: ChangelogDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(day.date).font(.system(size: 15, weight: .bold))
                if let tag = day.tag {
                    Text(tag).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                if let w = day.window {
                    Text(w).font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Text(day.summary).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(day.entries) { entry in changelogEntryCard(entry) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func changelogEntryCard(_ entry: ChangelogEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(entry.badge)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.1)))
                    .foregroundStyle(.primary)
                Text(entry.title).font(.system(size: 13.5, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if let t = entry.time {
                    Spacer(minLength: 4)
                    Text(t).font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
                }
            }
            ForEach(entry.items, id: \.self) { item in
                HStack(alignment: .top, spacing: 9) {
                    Circle().fill(Color.primary.opacity(0.4)).frame(width: 5, height: 5).padding(.top, 6)
                    Text(item).font(.system(size: 12.5)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    // MARK: - Engine lifecycle (local engines: install / use / uninstall)

    @ViewBuilder private var engineLifecycle: some View {
        let _ = engineRefresh
        let active = settings.engine == engineTab
        if engineTab == .openAI {
            if active {
                // "Active & ready" lied when no key was set — every dictation then failed. Show the gap.
                if (Keychain.openAIKey ?? "").isEmpty {
                    Label(L("Add your OpenAI key below to use this engine"), systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                } else { activeLabel }
            } else {
                Button(L("Use OpenAI")) { settings.engine = .openAI }.glassProminentButton().controlSize(.small)
            }
        } else {
            if engineTab == .whisper {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("Whisper model")).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    chips(localModels.map { IdString($0) }, selected: IdString(settings.localModel),
                          label: { $0.id }, onPick: { settings.localModel = $0.id; engineRefresh += 1 })
                }
            }
            if installing {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: installProgress).progressViewStyle(.linear)
                    Text("\(installMsg) \(Int(installProgress * 100))%").font(.caption).foregroundStyle(.secondary)
                }
            } else if EngineManager.isInstalled(engineTab) {
                let _ = engineRefresh
                let ready = EngineManager.isReady(engineTab, model: settings.localModel)
                HStack {
                    Label("\(L("Downloaded ·")) \(EngineManager.sizeGB(engineTab)) \(L("on disk"))", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                    Spacer()
                    if activating && active {
                        ProgressView().controlSize(.small); Text(L("Activating…")).font(.caption).foregroundStyle(.secondary)
                    } else if active && ready {
                        activeLabel
                        Button(L("Reload")) { activate(engineTab) }.glassButton().controlSize(.small)
                    } else {
                        Button(active ? L("Activate") : L("Use this model")) { activate(engineTab) }.glassProminentButton().controlSize(.small)
                    }
                    Button(L("Reinstall")) { installEngine(engineTab) }.glassButton().controlSize(.small)
                        .help(L("Re-download this model, e.g. if it's corrupted or only partly downloaded."))
                    Button(L("Uninstall"), role: .destructive) { confirmUninstall = true }.glassButton().controlSize(.small)
                        .confirmationDialog(L("Uninstall this model?"), isPresented: $confirmUninstall, titleVisibility: .visible) {
                            Button(L("Uninstall"), role: .destructive) { uninstallEngine(engineTab) }
                            Button(L("Cancel"), role: .cancel) { }
                        } message: {
                            Text("\(L("Deletes the")) \(EngineManager.sizeGB(engineTab)) \(L("model from this Mac. You can re-download it anytime."))")
                        }
                }
                if active && !ready && !activating, let err = EngineManager.lastInstallError {
                    statusLabel("\(L("Couldn't load this model:")) \(err). \(L("Tap Activate to retry, or Uninstall + redownload."))",
                                system: "exclamationmark.triangle.fill", tint: .orange)
                }
            } else {
                HStack {
                    Text("\(L("Not installed · download")) \(EngineManager.sizeGB(engineTab))").font(.system(size: 13)).foregroundStyle(.secondary)
                    Spacer()
                    Button(L("Download & install")) { installEngine(engineTab) }.glassProminentButton().controlSize(.small)
                }
            }
            Text(L("Runs fully offline & free once installed, no API key needed."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var activeLabel: some View {
        Label(L("Active & ready"), systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
    }

    // MARK: - Local LLM (Ollama)

    @ViewBuilder private var localModelBlock: some View {
        labeledField(L("Model"), $settings.localLLMModel, prompt: "qwen3:8b", width: 280)
        if engineInstalling {
            HStack { ProgressView().controlSize(.small); Text(L("Setting up the local engine…")).font(.caption).foregroundStyle(.secondary) }
        } else if !ollamaUp {
            HStack {
                Text(L("Local engine not running.")).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(L("Set up & start")) { setupEngine() }.glassProminentButton().controlSize(.small)
            }
        } else if pulling {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: pullProgress).progressViewStyle(.linear)
                Text("\(L("Downloading")) \(settings.localLLMModel)… \(Int(pullProgress * 100))%").font(.caption).foregroundStyle(.secondary)
            }
        } else if ollamaHasModel {
            statusLabel("\(settings.localLLMModel) \(L("ready, runs 100% offline."))", system: "checkmark.seal.fill", tint: .green)
        } else {
            HStack {
                Text(L("Engine ready. Model not downloaded yet.")).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(L("Download model")) { pullModel() }.glassProminentButton().controlSize(.small)
            }
        }
        Text(L("Reformulation runs entirely on your Mac. Tap Set up to install the local engine (~30 MB) the first time. Qwen 2.5 7B recommended (~4.7 GB)."))
            .font(.caption).foregroundStyle(.secondary)
            // Probe state non-intrusively. If the engine is already installed we start it,
            // but we never auto-DOWNLOAD the binary — that stays behind the explicit Set up button.
            .onAppear { probeEngine() }
    }

    /// Reflect the local-engine state without installing anything. The binary download
    /// is gated behind the explicit "Set up & start" button (see setupEngine()).
    private func probeEngine() {
        LocalLLM.isRunning { up in
            if up {
                ollamaUp = true
                LocalLLM.hasModel(settings.localLLMModel) { ollamaHasModel = $0 }
            } else if LocalLLM.locateBinary() != nil {
                // Installed but not running yet — bring it up (no download involved).
                setupEngine()
            }
        }
    }

    private func setupEngine() {
        engineInstalling = true
        LocalLLM.ensureServer { up in
            if up {
                engineInstalling = false; ollamaUp = true
                LocalLLM.hasModel(settings.localLLMModel) { ollamaHasModel = $0 }
            } else {
                LocalLLM.installBinary { ok in
                    engineInstalling = false; ollamaUp = ok
                    if ok { LocalLLM.hasModel(settings.localLLMModel) { ollamaHasModel = $0 } }
                }
            }
        }
    }
    private func pullModel() {
        pulling = true; pullProgress = 0
        LocalLLM.pull(settings.localLLMModel, progress: { pullProgress = $0 }) { ok in
            pulling = false; ollamaHasModel = ok
        }
    }
    private func wipeCloudData() {
        guard !cloudWiping else { return }
        cloudWiping = true; cloudWipeError = false; cloudWiped = false
        // Track which attempt this is so a slow/never-returning call can't clobber a newer state,
        // and so the timeout only fires for an attempt that is still in flight.
        let attempt = UUID()
        cloudWipeAttempt = attempt
        ConvexClient.call("mutation", "account:wipe", ConvexClient.authedArgs()) { data in
            DispatchQueue.main.async {
                guard cloudWipeAttempt == attempt, cloudWiping else { return }
                cloudWiping = false
                // Convex success is an explicit {"status":"success"} envelope; nil data (network
                // error / unreachable) or any non-success status is a failed wipe, surfaced explicitly.
                let ok = data
                    .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                    .map { ($0["status"] as? String) == "success" } ?? false
                if ok {
                    cloudWipeError = false
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) { cloudWiped = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        guard cloudWipeAttempt == attempt else { return }
                        withAnimation(.easeOut(duration: 0.2)) { cloudWiped = false }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { cloudWipeError = true }
                }
            }
        }
        // Safety net: if the completion never fires (server hang / dropped connection), don't leave the
        // user stuck on an indistinguishable 'Deleting…' forever — surface an explicit failure.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            guard cloudWipeAttempt == attempt, cloudWiping else { return }
            cloudWiping = false
            withAnimation(.easeOut(duration: 0.2)) { cloudWipeError = true }
        }
    }

    private func activate(_ e: TranscriptionEngine) {
        settings.engine = e
        activating = true
        EngineManager.lastInstallError = nil
        Task {
            let ok = await EngineManager.load(e)
            await MainActor.run {
                activating = false
                engineRefresh += 1
                if !ok { verifyMsg = "" }
            }
        }
    }
    private func installEngine(_ e: TranscriptionEngine) {
        installing = true; installProgress = 0
        installMsg = "\(L("Downloading")) \(EngineManager.sizeGB(e))…"
        Task {
            let ok = await EngineManager.install(e) { p in installProgress = p }
            await MainActor.run {
                installing = false
                installMsg = ok ? "" : "\(L("Install failed:")) \(EngineManager.lastInstallError ?? L("check your connection."))"
                if ok { settings.engine = e }
                engineRefresh += 1
            }
        }
    }
    private func uninstallEngine(_ e: TranscriptionEngine) {
        Task {
            await EngineManager.uninstall(e)
            await MainActor.run {
                if settings.engine == e { settings.engine = .openAI }
                engineRefresh += 1
            }
        }
    }

    // MARK: - Sign-in

    private func startSignIn() {
        signingIn = true
        AuthSession.shared.signIn { email in
            DispatchQueue.main.async {
                signingIn = false
                guard let email else { return }
                settings.proEmail = email
                Task { _ = await settings.verifyPro() }
            }
        }
    }

    // MARK: - Permission row

    private func permissionRow(_ icon: String, _ title: String, _ desc: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : icon)
                .foregroundStyle(granted ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Label(L("Authorized"), systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
            } else {
                Button(L("Enable"), action: action).glassButton().controlSize(.small)
            }
        }
    }

    private func openPane(_ id: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(id)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Sidebar / retention helpers

    private static let sidebarItems: [NavItem] =
        [.notes, .todos, .insights, .history, .dictionary, .snippets, .style, .transforms, .scratchpad, .files, .leaderboard, .wishlist, .freeMonth]

    private func sidebarBinding(_ item: NavItem) -> Binding<Bool> {
        if item == .notes { return $settings.notesTabEnabled }
        if item == .todos { return $settings.todosTabEnabled }
        return Binding(get: { settings.navVisible(item) }, set: { settings.setNavVisible(item, $0) })
    }

    private var retentionOptions: [RetentionOption] {
        [.init(days: 0, label: L("Forever")), .init(days: 7, label: L("7 days")),
         .init(days: 30, label: L("30 days")), .init(days: 90, label: L("90 days"))]
    }
    private func retentionOption(_ days: Int) -> RetentionOption {
        retentionOptions.first { $0.days == days } ?? retentionOptions[0]
    }

    private func byteString(_ b: Int64) -> String {
        let f = ByteCountFormatter(); f.allowedUnits = [.useMB, .useKB, .useGB]; f.countStyle = .file
        return f.string(fromByteCount: b)
    }
}

// MARK: - Small value types for chip pickers

private struct IdString: Hashable, Identifiable {
    let id: String
    init(_ s: String) { id = s }
}

private struct RetentionOption: Hashable, Identifiable {
    let days: Int
    let label: String
    var id: Int { days }
}

/// Capsule tag chips that wrap onto multiple rows — the exemplar grammar for small enums.
private struct SettingsChips<T: Hashable & Identifiable>: View {
    let options: [T]
    /// Optional so callers (e.g. presets) can express "no chip active" — a custom mix.
    let selectedOptional: T?
    let label: (T) -> String
    var icon: ((T) -> String)? = nil
    /// Optional per-chip tooltip text, so opaque option names can explain themselves.
    var help: ((T) -> String)? = nil
    let onPick: (T) -> Void

    init(options: [T], selected: T, label: @escaping (T) -> String,
         icon: ((T) -> String)? = nil, help: ((T) -> String)? = nil, onPick: @escaping (T) -> Void) {
        self.options = options; self.selectedOptional = selected
        self.label = label; self.icon = icon; self.help = help; self.onPick = onPick
    }
    init(options: [T], selectedOptional: T?, label: @escaping (T) -> String,
         icon: ((T) -> String)? = nil, help: ((T) -> String)? = nil, onPick: @escaping (T) -> Void) {
        self.options = options; self.selectedOptional = selectedOptional
        self.label = label; self.icon = icon; self.help = help; self.onPick = onPick
    }

    var body: some View {
        WrapHStack(spacing: 8, rowSpacing: 8) {
            ForEach(options) { opt in
                let isSel = opt == selectedOptional
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { onPick(opt) }
                } label: {
                    HStack(spacing: 5) {
                        if let icon { Image(systemName: icon(opt)).font(.system(size: 10, weight: .semibold)) }
                        Text(label(opt)).font(.system(size: 12, weight: isSel ? .semibold : .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6.5)
                    .foregroundStyle(isSel ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
                    // Glass chip: soft fill step, ultra-subtle hairline (0.10 max on select).
                    .background(Capsule(style: .continuous)
                        .fill(Color.primary.opacity(isSel ? VGlass.fillSelected : VGlass.fillSecondary)))
                    .overlay(Capsule(style: .continuous)
                        .strokeBorder(Color.primary.opacity(isSel ? VGlass.hairlineSelected : VGlass.hairline), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .ifLet(help?(opt)) { $0.help($1) }
            }
        }
    }
}

private extension View {
    /// Apply a modifier only when an optional value is present (used for per-chip tooltips).
    @ViewBuilder func ifLet<V>(_ value: V?, @ViewBuilder _ transform: (Self, V) -> some View) -> some View {
        if let value { transform(self, value) } else { self }
    }
}

/// Wrapping HStack: chips flow to the next line when they run out of width.
/// Backed by the shared native FlowLayout (ModesView.swift) so the reported height is
/// ALWAYS the true wrapped height — the old GeometryReader+alignmentGuide version reported
/// a single row's height, which let later content overlap multi-row chip groups (the
/// "Lock/Direct over Recording indicator" overlap bug).
private struct WrapHStack<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    @ViewBuilder var content: () -> Content
    var body: some View {
        FlowLayout(spacing: spacing) { content() }
    }
}
