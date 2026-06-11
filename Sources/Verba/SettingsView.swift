import SwiftUI
import AppKit
import AVFoundation
import IOKit.hid

// MARK: - Settings sections (the custom left rail)

private enum SettingsSection: String, CaseIterable, Identifiable {
    case account, dictation, rewriting, output, customize, shortcuts, privacy, updates
    var id: String { rawValue }
    var title: String {
        switch self {
        case .account:   return "Account & Plan"
        case .dictation: return "Dictation"
        case .rewriting: return "AI rewriting"
        case .output:    return "Output & feedback"
        case .customize: return "Customize"
        case .shortcuts: return "Shortcuts"
        case .privacy:   return "Privacy & history"
        case .updates:   return "Updates & about"
        }
    }
    var icon: String {
        switch self {
        case .account:   return "person.crop.circle"
        case .dictation: return "waveform"
        case .rewriting: return "wand.and.stars"
        case .output:    return "arrow.down.doc"
        case .customize: return "paintpalette"
        case .shortcuts: return "keyboard"
        case .privacy:   return "lock.shield"
        case .updates:   return "arrow.triangle.2.circlepath"
        }
    }
    var subtitle: String {
        switch self {
        case .account:   return "Sign-in, plan, referrals"
        case .dictation: return "Engine, mic, language"
        case .rewriting: return "Backend, model, API keys"
        case .output:    return "Paste, overlay, sounds"
        case .customize: return "Glass, accent, widget"
        case .shortcuts: return "Triggers & chords"
        case .privacy:   return "History, permissions"
        case .updates:   return "Version & releases"
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

    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var openRouterKey = Keychain.openRouterKey ?? ""
    @State private var keysSaved = false
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
            Text("Settings").font(.system(size: 17, weight: .bold))
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

    @ViewBuilder private var detail: some View {
        switch section {
        case .account:   accountDetail
        case .dictation: dictationDetail
        case .rewriting: rewritingDetail
        case .output:    outputDetail
        case .customize: customizeDetail
        case .shortcuts: shortcutsDetail
        case .privacy:   privacyDetail
        case .updates:   updatesDetail
        }
    }

    // MARK: - Shared building blocks

    /// A titled grouping card: caption header + a glass-fill card body.
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
        case .frosted: return "Frosted — the most opaque, menu-like glass."
        case .soft:    return "Soft — a light popover-style frost."
        case .sidebar: return "Sidebar — the translucency macOS uses for sidebars."
        case .hud:     return "HUD — a darker heads-up-display glass."
        case .crystal: return "Crystal — deep, very translucent (Notification Center look)."
        case .ultra:   return "Ultra — the most translucent, full-screen-style glass."
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
        card("Interface", footer: "Make the app yours. Defaults are monochrome and macOS-native; everything here is optional.") {
            apprLabel("Presets")
            presetChips(selected: appearance.activePreset) { appearance.applyPreset($0) }
            // Live preview — re-renders with the current material + blur + corner + accent.
            previewTile(material: appearance.material, blur: appearance.blur,
                        cornerScale: appearance.cornerScale, accent: appearance.accentColor,
                        colorMode: appearance.colorMode, shadow: appearance.shadow, label: "App preview")
            apprLabel("Appearance")
            chips(VAppr.ColorMode.allCases, selected: appearance.colorMode, label: { $0.label }) { appearance.colorMode = $0 }
            apprLabel("Glass material")
            chips(VAppr.Material.allCases, selected: appearance.material, label: { $0.label },
                  help: materialHelp) { appearance.material = $0 }
            apprLabel("Accent")
            accentSwatches(selected: appearance.accent,
                           customHex: appearance.accentHex,
                           onPick: { appearance.accent = $0 },
                           onCustom: { appearance.setCustomAccent($0) })
            sliderRow("Glass blur", value: $appearance.blur, range: 0...40, suffix: "pt")
            sliderRow("Corner radius", value: $appearance.cornerScale, range: 0.7...1.4, suffix: "×")
            toggleRow("Shadow on panels", $appearance.shadow)
            toggleRow("Reduce motion", $appearance.reduceMotion)
        }

        // MENUS — the glass behind popovers, dialogs and confirmations.
        card("Menus & popovers", footer: "Style the glass behind menus, dialogs and confirmations, independently of the main window.") {
            apprLabel("Menu glass material")
            chips(VAppr.Material.allCases, selected: appearance.menuMaterial, label: { $0.label },
                  help: materialHelp) { appearance.menuMaterial = $0 }
            sliderRow("Menu glass blur", value: $appearance.menuBlur, range: 0...40, suffix: "pt")
        }

        // WIDGET
        card("Widget", footer: "Style the macOS Task Manager widget independently from the app.") {
            apprLabel("Presets")
            presetChips(selected: appearance.activeWidgetPreset) { appearance.applyWidgetPreset($0) }
            previewTile(material: appearance.widgetMaterial, blur: appearance.widgetBlur,
                        cornerScale: appearance.widgetCornerScale, accent: appearance.widgetAccentColor,
                        colorMode: appearance.widgetColorMode, shadow: appearance.widgetShadow, label: "Widget preview")
            apprLabel("Appearance")
            chips(VAppr.ColorMode.allCases, selected: appearance.widgetColorMode, label: { $0.label }) { appearance.widgetColorMode = $0 }
            apprLabel("Glass material")
            chips(VAppr.Material.allCases, selected: appearance.widgetMaterial, label: { $0.label },
                  help: materialHelp) { appearance.widgetMaterial = $0 }
            apprLabel("Accent")
            accentSwatches(selected: appearance.widgetAccent,
                           customHex: appearance.widgetAccentHex,
                           onPick: { appearance.widgetAccent = $0 },
                           onCustom: { appearance.setWidgetCustomAccent($0) })
            sliderRow("Blur", value: $appearance.widgetBlur, range: 0...40, suffix: "pt")
            sliderRow("Corner radius", value: $appearance.widgetCornerScale, range: 0.7...1.4, suffix: "×")
            toggleRow("Shadow", $appearance.widgetShadow)
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
                      ? "Mono — no tint, follows light/dark automatically (the default)."
                      : "\(a.label) — tints buttons, selections and the recording dot.")
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
            .help("Custom color")
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
        card("Account") {
            if settings.proEmail.isEmpty {
                HStack {
                    Label("Not signed in", systemImage: "person.crop.circle.badge.questionmark")
                        .foregroundStyle(.secondary).font(.system(size: 13))
                    Spacer()
                    Button { startSignIn() } label: { Text(signingIn ? "Signing in…" : "Sign in") }
                        .glassProminentButton().controlSize(.regular).disabled(signingIn)
                }
                Text("Sign in to sync your plan, use the included AI rewriting (no key needed), and earn referral rewards.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else {
                HStack {
                    Label(settings.proEmail, systemImage: "person.crop.circle.fill")
                        .font(.system(size: 13)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button(role: .destructive) { confirmSignOut = true } label: { Text("Sign out") }
                        .glassButton().controlSize(.regular)
                        .confirmationDialog("Sign out of Verba?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                            Button("Sign out", role: .destructive) { AuthSession.shared.signOut() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("This detaches your account from this Mac. Your local notes, transcripts and to-dos stay on this device, you can sign back in anytime.")
                        }
                }
                if settings.needsReauth {
                    HStack(alignment: .top, spacing: 10) {
                        statusLabel("Please sign in again to keep Pro and sync secure.",
                                    system: "exclamationmark.triangle.fill", tint: .orange)
                        Spacer()
                        Button { startSignIn() } label: { Text(signingIn ? "Signing in…" : "Sign in again") }
                            .glassButton().controlSize(.small).disabled(signingIn)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.orange.opacity(0.1)))
                }
                Text("Signed in. Signing out keeps everything stored locally on this Mac, it only disconnects this device from your account.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }

        // Restore / verify checkout email
        card("Restore a subscription",
             footer: settings.isPro
             ? "Thanks! Unlimited dictation, editable mode prompts and custom modes. Your subscription is active for this email."
             : "Already subscribed? Enter your checkout email and Verify to restore.") {
            labeledField("Email used at checkout", $restoreEmail, prompt: "you@example.com")
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
                        verifyMsg = ok ? "Pro unlocked ✓" : "No active subscription for this email."
                    }
                } label: { Text(verifying ? "Checking…" : (settings.isPro ? "Re-check" : "Verify / restore")) }
                    .glassButton().controlSize(.regular)
                    .disabled(verifying || restoreEmail.isEmpty)
                if !verifyMsg.isEmpty {
                    Text(verifyMsg).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let u = URL(string: Entitlement.accountURL) {
                    Link("Manage", destination: u).font(.caption)
                }
            }
        }

        // Free trial usage bar
        if !settings.isPro {
            let used = Stats.shared.totalCount
            let limit = Entitlement.freeTrialDictations
            let exhausted = used >= limit
            card("Free trial",
                 footer: "Free is a full-Pro trial of \(limit) dictations. Pro ($9.99/mo) unlocks unlimited dictation, editable system prompts and custom modes.") {
                if exhausted {
                    // Trial used up: a clear upgrade state instead of a silently pinned bar.
                    HStack(spacing: 10) {
                        statusLabel("Free trial used up. Upgrade for unlimited dictation.",
                                    system: "checkmark.circle.fill", tint: .secondary)
                        Spacer()
                        if let u = URL(string: Entitlement.pricingURL) {
                            Link("Upgrade", destination: u).glassProminentButton().controlSize(.small)
                        }
                    }
                } else {
                    HStack {
                        Text("\(used) / \(limit) dictations").font(.callout).monospacedDigit()
                        Spacer()
                        Text("\(limit - used) left").font(.callout).monospacedDigit().foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(used), total: Double(limit))
                }
            }
        }

        // Username + leaderboard visibility
        card("Public alias",
             footer: "Your username is PUBLIC on the leaderboard and synced to your account, so pick a nickname, never your real name or email.") {
            HStack(spacing: 8) {
                TextField("Username", text: $settings.username)
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
                .buttonStyle(.plain).help("Shuffle a new username")
                Spacer()
            }
            toggleRow("Show me on the public leaderboard", $settings.showOnLeaderboard)
        }

        // Referral
        card("Refer friends — give a month, get a month",
             footer: "Every friend who subscribes through your link and dictates 15,000+ words earns you a free month, unlimited, no cap.") {
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
                    Label(copiedReferral ? "Copied" : "Copy", systemImage: copiedReferral ? "checkmark" : "doc.on.doc")
                }
                .glassButton().controlSize(.small)
                // Same Share affordance as the Free Month tab, so the referral surfaces match.
                Button { shareReferral() } label: { Label("Share…", systemImage: "square.and.arrow.up") }
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
                Text(settings.isPro ? "Verba Pro" : "Free plan").font(.system(size: 17, weight: .bold))
                Text(settings.isPro ? "Unlimited dictation, custom modes, editable prompts."
                                    : "A full-Pro trial. Upgrade for unlimited dictation.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if !settings.isPro, let u = URL(string: Entitlement.pricingURL) {
                Link(destination: u) { Text("Upgrade · 7-day trial") }
                    .glassProminentButton().controlSize(.large)
            } else if settings.isPro {
                Label("Active", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .softElevation(!settings.isPro)
    }

    // MARK: - 2 · Dictation

    @ViewBuilder private var dictationDetail: some View {
        card("Transcription engine") {
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
        }

        card("Microphone",
             footer: "Verba uses your default system microphone. Pick the input device in System Settings ▸ Sound.") {
            permissionRow("mic.fill", "Microphone access", "Record your voice.", granted: micGranted) {
                AVCaptureDevice.requestAccess(for: .audio) { _ in }
                openPane("Privacy_Microphone")
            }
        }

        card("Language") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Primary language").font(.system(size: 13))
                    Text("Your everyday language. Output defaults to it when the spoken language is ambiguous; a clearly-spoken other language is always kept.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Picker("", selection: $settings.mainLanguage) {
                    Text("Auto-detect").tag("")
                    Divider()
                    ForEach(translateLanguages, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden().fixedSize()
            }
            labeledField("Spoken language", $settings.language, prompt: "ISO code, blank = auto")
            toggleRow("Single-language output", $settings.languageGuard,
                      help: settings.languageGuard ? "If the engine mixes two languages mid-sentence, Verba rewrites the result fully in its dominant language. Applies to every mode, including Flow." : nil)
        }

        card("Voice commands") {
            toggleRow("Voice commands", $settings.voiceCommands,
                      help: settings.voiceCommands ? "Say “new line / new paragraph”, “comma / period / question mark”, “bullet point”, or “scratch that” and Verba turns them into real formatting (any mode, incl. Flow). EN + FR." : nil)
        }
    }

    private func engineSubtitle(_ e: TranscriptionEngine) -> String {
        switch e {
        case .openAI:   return "Remote, no download. Uses your OpenAI key."
        case .whisper:  return "On-device WhisperKit. Fully offline & free."
        case .parakeet: return "On-device NVIDIA Parakeet, multilingual. Offline & free."
        }
    }

    // MARK: - 3 · AI rewriting

    @ViewBuilder private var rewritingDetail: some View {
        card("Reprompting") {
            toggleRow("Restructure transcript with Claude", $settings.repromptEnabled)
        }

        card("Backend") {
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
            card("OpenRouter model",
                 footer: "Any model on openrouter.ai (openai/gpt-4o, google/gemini-2.0-flash…). Add your key below.") {
                labeledField("Model id", $settings.openRouterModel, prompt: "anthropic/claude-3.7-sonnet", width: 360)
            }
        } else if settings.repromptBackend == .localLLM {
            card("Local model (Ollama)") { localModelBlock }
        } else {
            card("Claude model") {
                chips(claudeModels.map { IdString($0) }, selected: IdString(settings.claudeModel),
                      label: { $0.id }, onPick: { settings.claudeModel = $0.id })
            }
        }

        card("Context") {
            toggleRow("Auto-pick profile from the active app", $settings.autoDetectProfile)
            toggleRow("Use selected text as context", $settings.useSelectionContext,
                      help: settings.useSelectionContext ? "If text is selected when you dictate, your words become an instruction on that selection, and the result replaces it." : nil)
        }

        card("Action mode",
             footer: "Action mode (Fn+X) turns speech into a confirmed action. Calendar events and reminders go to your macOS DEFAULT Calendar / Reminders list (set the default in Calendar.app / Reminders.app, e.g. a Google or Notion-synced calendar). Web search targets below let you say “search … on Google / ChatGPT / Claude”; {q} is replaced by what you said.") {
            ForEach($settings.searchTargets) { $t in
                HStack(spacing: 8) {
                    TextField("Name", text: $t.name).frame(width: 110).textFieldStyle(.roundedBorder)
                    TextField("https://…/search?q={q}", text: $t.urlTemplate).textFieldStyle(.roundedBorder)
                    Button { settings.searchTargets.removeAll { $0.id == t.id } } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.borderless).help("Remove")
                }
            }
            HStack {
                Button { settings.searchTargets.append(SearchTarget(name: "New", urlTemplate: "https://example.com/search?q={q}")) } label: {
                    Label("Add search target", systemImage: "plus")
                }.buttonStyle(.borderless)
                Spacer()
                Button("Reset to defaults") { settings.searchTargets = SearchTarget.defaults }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
            }
        }

        // API keys (instant-save)
        card("API keys",
             footer: "Keys save automatically as you type, stored in your macOS Keychain.") {
            apiKeyField("OpenAI (cloud transcription)", "sk-…", $openAIKey) { Keychain.openAIKey = $0 }
            apiKeyField("Anthropic (Claude reprompting)", "sk-ant-…", $anthropicKey) { Keychain.anthropicKey = $0 }
            apiKeyField("OpenRouter (any writing model)", "sk-or-…", $openRouterKey) { Keychain.openRouterKey = $0 }
            HStack {
                Button("Save keys") {
                    Keychain.openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    Keychain.openRouterKey = openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    withAnimation { keysSaved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { keysSaved = false } }
                }
                .glassButton().controlSize(.small)
                if keysSaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green).transition(.opacity)
                }
                Spacer()
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
        case .auto:       return "Claude Code if present, else Verba's included engine."
        case .verba:      return "Included, no key. Runs on Verba's servers."
        case .claudeCode: return "Runs on your Claude Max/Pro plan via the local CLI."
        case .apiKey:     return "Pay-per-token with your Anthropic API key."
        case .openRouter: return "Any model on openrouter.ai with your key."
        case .localLLM:   return "Fully offline on your Mac via Ollama."
        }
    }

    @ViewBuilder private var backendStatus: some View {
        switch settings.repromptBackend {
        case .auto:
            statusLabel(ClaudeCode.isAvailable
                        ? "Using Claude Code (runs on your Claude plan, no key)."
                        : "Using Verba's included rewriting (no key, no setup).",
                        system: "wand.and.stars", tint: .secondary)
        case .verba:
            if settings.proEmail.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    statusLabel("Sign in to use the included rewriting, no API key needed.",
                                system: "exclamationmark.triangle.fill", tint: .orange)
                    Spacer()
                    Button { startSignIn() } label: { Text(signingIn ? "Signing in…" : "Sign in") }
                        .glassButton().controlSize(.small).disabled(signingIn)
                }
            } else {
                statusLabel("Included with Verba, no API key needed. Runs on Verba's servers.",
                            system: "checkmark.seal.fill", tint: .green)
            }
        case .claudeCode:
            statusLabel(ClaudeCode.isAvailable
                        ? "Claude Code detected, uses your Claude plan, no API key."
                        : "Claude Code not found. Install it and run `claude` once to sign in.",
                        system: ClaudeCode.isAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tint: ClaudeCode.isAvailable ? .green : .orange)
        default:
            EmptyView()
        }
    }

    // MARK: - 4 · Output & feedback

    @ViewBuilder private var outputDetail: some View {
        card("Paste & formatting",
             footer: "Formatting pastes as real bold/headings/lists in apps that support it; plain fields get clean text.") {
            toggleRow("Auto-paste into the active field", $settings.autoPaste)
            toggleRow("Copy to clipboard", $settings.copyToClipboard)
            toggleRow("Paste with formatting (render Markdown)", $settings.richTextPaste)
            toggleRow("Review / edit before sending", $settings.reviewBeforeSend)
            if !Output.accessibilityTrusted {
                HStack {
                    statusLabel("Auto-paste needs Accessibility access", system: "exclamationmark.triangle.fill", tint: .orange)
                    Spacer()
                    Button("Enable…") { Output.promptAccessibility() }.glassButton().controlSize(.small)
                }
            }
        }

        card("Recording indicator") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Overlay style").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(OverlayStyle.allCases, selected: settings.overlayStyle,
                      label: { $0.label }, onPick: { settings.overlayStyle = $0 })
            }
            if settings.overlayStyle == .minimal {
                Text("No floating window. The menu-bar icon turns red and pulses while recording.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Recording style").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(RecordStyle.allCases, selected: settings.recordStyle,
                      label: { $0.label }, onPick: { settings.recordStyle = $0 })
            }
            Text(settings.recordStyle.help).font(.caption).foregroundStyle(.secondary)
        }

        card("Sounds",
             footer: "Cues for recording start, paste, and errors. Only your custom mp3s play (no macOS system beeps). Drop more in the Sounds folder.") {
            toggleRow("Sound effects", $settings.soundsEnabled)
            if settings.soundsEnabled {
                HStack {
                    Text("Volume").font(.system(size: 13))
                    Slider(value: $settings.soundVolume, in: 0...1)
                    Text("\(Int(settings.soundVolume * 100))%").monospacedDigit()
                        .foregroundStyle(.secondary).frame(width: 42, alignment: .trailing)
                }
            }
        }

        card("Loading jokes",
             footer: settings.quipTone == .off
             ? "While Claude works, Verba shows a neutral “\(Quips.neutral)”."
             : "While Claude works, Verba shows a short AI-generated joke in this style, never the same twice in a day.") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Joke style").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(QuipTone.allCases, selected: settings.quipTone,
                      label: { $0.label }, onPick: { settings.quipTone = $0 })
            }
        }

        card("App presence", footer: "Dock off = menu-bar only. The dictation hotkeys work either way. If you hide BOTH, reopen Verba from Applications to get back here.") {
            toggleRow("Show in Dock (full window app)", $settings.showInDock)
            toggleRow("Show the menu-bar icon", $settings.showMenuBarIcon)
        }

        card("Fn key behaviour", footer: "By default Verba takes over the globe (Fn) key so macOS doesn't pop the emoji/Fn HUD or switch your keyboard layout. Turn these off to get the standard macOS behaviour back.") {
            toggleRow("Stop the macOS Fn / emoji popup", $settings.suppressFnPopup)
            toggleRow("Disable the keyboard / input-source switcher", $settings.disableInputSwitcher)
        }

        labsCard
        sidebarCard
    }

    @ViewBuilder private var labsCard: some View {
        card("Labs") {
            toggleRow("Notes tab (long-form voice notes)", $settings.notesTabEnabled,
                      help: "A Notes tab to record long voice memos (up to an hour) and reorganize them into a clean document.")
            toggleRow("Task Manager tab (tasks by project)", $settings.todosTabEnabled,
                      help: "Capture tasks and sub-tasks by voice, sorted into projects. Ask the agent to build a whole list from a spoken request.")
            toggleRow("To-do reminders (30 min before a deadline)", $settings.todoReminders,
                      help: "Posts a local notification 30 minutes before a to-do's deadline. Needs notification permission.")
            toggleRow("Smart formatting per app", $settings.smartFormatting,
                      help: "Rich text/markdown in apps that render it (Mail, Notion, Notes…), plain text in code editors and terminals.")
            toggleRow("Redo last dictation in another mode", $settings.redoEnabled,
                      help: "Adds “Redo last in…” to the menu, re-runs your last recording through any mode without speaking again.")
            toggleRow("Auto-learn dictionary from your edits", $settings.autoLearnDictionary,
                      help: "When you fix a word, Verba spots the correction on your next dictation and applies it automatically. Learned terms appear in Dictionary.")
            toggleRow("Match my tone per app", $settings.toneMatch,
                      help: "Verba learns how you write in each app and matches that tone automatically.")
            toggleRow("Edit last result by voice", $settings.voiceEditLast,
                      help: "Adds “Edit last by voice…” to the menu, speak a change (“make it shorter”, “more formal”…) and Verba rewrites your last result.")
            toggleRow("Agentic actions in Context mode", $settings.agenticActions,
                      help: "In Context mode, turn spoken commands into Calendar events, Reminders, or email drafts — it always asks you to confirm first.")
            Text("Tip: hold Fn + X anytime for Action mode — speak a command (run a Shortcut, open an app, play music, message someone) and Verba confirms before it acts. No toggle needed.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var sidebarCard: some View {
        card("Sidebar menu", footer: "Choose which sections show in the main window's sidebar. Home, Modes and Settings always stay.") {
            ForEach(Self.sidebarItems) { item in
                toggleRow(item.title, sidebarBinding(item))
            }
        }
    }

    // MARK: - 5 · Shortcuts

    @ViewBuilder private var shortcutsDetail: some View {
        let fnOn = settings.useFnAsPrimary

        // SELECTION — the transform picker hotkey (Option + key).
        card("Transform selection",
             footer: "Select text in any app and press this to pick a transform to run on it. Option is always held; choose the key. Default is X (it's right under your fingers, unlike slash).") {
            HStack(spacing: 10) {
                Text("Transform picker").font(.system(size: 13))
                Spacer()
                Text("⌥ \(keyName(UInt32(settings.transformHotkeyCode)))")
                    .font(.system(size: 13, weight: .semibold)).monospaced()
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                ShortcutRecorder(label: "Change") { code, _ in
                    settings.transformHotkeyCode = Int(code)
                }
            }
        }

        // DICTATION — how you start, pause and cancel a dictation.
        card("Dictation") {
            toggleRow("Use the Fn (🌐 globe) key as the trigger", $settings.useFnAsPrimary)
            if fnOn {
                VStack(alignment: .leading, spacing: 6) {
                    Text("When you press Fn").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    chips(TriggerStyle.allCases, selected: settings.triggerStyle,
                          label: { $0.label }, onPick: { settings.triggerStyle = $0 })
                }
                chordRow(settings.triggerStyle == .hold
                         ? "Hold to talk, release to send" : "Tap to start, tap again to send",
                         caps: ["Fn"])
            } else {
                chordRecorderRow("Start / stop dictation",
                                 has: settings.primaryHasShortcut,
                                 code: settings.primaryKeyCode, mods: settings.primaryMods,
                                 target: .primary)
            }
            chordRow("Pause / resume while recording", caps: ["⌃"])
            chordRow("Cancel recording or processing", caps: ["⎋"])
            cardCaption(fnOn
                ? "Your trigger is everything: tap or hold to dictate, then ⌃ to pause and ⎋ to cancel."
                : "Pick the keystroke that starts and stops a dictation. ⌃ pauses, ⎋ cancels.")
        }

        // MODES — choosing which rewriting mode the dictation runs through.
        if fnOn {
            card("Modes") {
                toggleRow("Change-mode jumps straight to the next mode (no list)", $settings.modeGestureCycles)
                toggleRow("Remember the last mode you used", $settings.rememberLastMode,
                          help: "After each dictation, the mode you just used becomes the default for the next one.")
                chordRow("Next mode  (add ⇧ for previous)", caps: ["Fn", "⇥"])
                chordRow("Pick a mode by number", caps: ["Fn", "1–9"])
                chordRow("Next mode hands-free while recording", caps: ["⌥"])
                chordRecorderRow("Custom change-mode shortcut",
                                 has: settings.modePickerHasShortcut,
                                 code: settings.modePickerKeyCode, mods: settings.modePickerMods,
                                 target: .modePicker)
                cardCaption(settings.modeGestureCycles
                    ? "Fn + Tab cycles to the next mode even mid-dictation; turn the toggle off to open a numbered picker instead."
                    : "Fn + Tab opens a numbered picker; turn the toggle on to cycle straight to the next mode instead.")
            }
        }

        // STYLES — the tone/format layer on top of the active mode.
        if fnOn {
            card("Styles") {
                chordRow("Next style", caps: ["Fn", "]"])
                chordRecorderRow("Custom next-style shortcut",
                                 has: settings.styleNextHasShortcut,
                                 code: settings.styleNextKeyCode, mods: settings.styleNextMods,
                                 target: .styleNext)
                chordRow("Previous style", caps: ["Fn", "["])
                chordRecorderRow("Custom previous-style shortcut",
                                 has: settings.stylePrevHasShortcut,
                                 code: settings.stylePrevKeyCode, mods: settings.stylePrevMods,
                                 target: .stylePrev)
                cardCaption("Styles tweak the tone or format on top of whatever mode you're in — flick between them without leaving your dictation.")
            }
        }

        // CAPTURE — voice notes, to-dos and the Mac-controlling Action mode.
        if fnOn {
            card("Capture") {
                chordRow("Add a to-do by voice", caps: FnTap.todoChordLabel.components(separatedBy: " + "))
                chordRecorderRow("Custom add-to-do shortcut",
                                 has: settings.todoCaptureHasShortcut,
                                 code: settings.todoCaptureKeyCode, mods: settings.todoCaptureMods,
                                 target: .todoCapture)
                chordRow("Capture a note by voice", caps: ["Fn", "Z"])
                chordRecorderRow("Custom record-note shortcut",
                                 has: settings.noteRecordHasShortcut,
                                 code: settings.noteRecordKeyCode, mods: settings.noteRecordMods,
                                 target: .noteRecord)
                chordRow("Action mode — speak a command to control your Mac", caps: ["Fn", "X"])
                chordRecorderRow("Custom Action-mode shortcut",
                                 has: settings.actionModeHasShortcut,
                                 code: settings.actionModeKeyCode, mods: settings.actionModeMods,
                                 target: .actionMode)
                chordRow("Stop an in-progress note / to-do capture", caps: ["Fn"])
                Divider().opacity(0.4)
                toggleRow("Show today's to-dos on ⌥ + Fn", $settings.todoGlanceEnabled,
                          help: "Press ⌥ (Option) + Fn for a compact glance of today's tasks. Press it again or ⎋ to dismiss.")
                chordRow("Today's to-dos  (quick glance)", caps: ["⌥", "Fn"])
                chordRecorderRow("Custom to-do glance shortcut",
                                 has: settings.todoGlanceHasShortcut,
                                 code: settings.todoGlanceKeyCode, mods: settings.todoGlanceMods,
                                 target: .todoGlance)
                cardCaption("Capture things hands-free: a note files into Notes, a to-do files into your projects, and Action mode turns speech into a command that runs on your Mac.")
            }
        }

        // EDITING — fixing or re-running the last dictation. Menu-bar actions (no chord).
        if fnOn {
            card("Editing") {
                menuActionRow("Edit the last result by voice",
                              "Say a change (\u{201C}shorter\u{201D}, \u{201C}more formal\u{201D}\u{2026}) to rewrite what you just dictated.")
                menuActionRow("Redo the last recording in another mode",
                              "Re-run your last recording through a different mode \u{2014} no need to speak again.")
                cardCaption("Both live in Verba's menu-bar icon, under your recent result.")
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
            Label("Menu", systemImage: "menubar.arrow.up.rectangle")
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
        card("Dictation history") {
            toggleRow("Save dictation history", $settings.saveHistory,
                      help: settings.saveHistory ? nil : "Off: new dictations are pasted and forgotten — nothing is written to disk, no audio is kept, nothing is synced. Existing history stays until you delete it below.")
            VStack(alignment: .leading, spacing: 6) {
                Text("Keep history for").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                chips(retentionOptions, selected: retentionOption(settings.historyRetentionDays),
                      label: { $0.label }, onPick: {
                          settings.historyRetentionDays = $0.days
                          History.shared.pruneExpired()
                          cacheBytes = History.shared.audioCacheBytes()
                      })
            }
        }

        card("Disk & cloud",
             footer: "Retention deletes dictations older than the chosen window (text + audio, locally and in your account's cloud sync). Clear audio cache frees disk while keeping your text history.") {
            HStack {
                Label("Saved audio & buffers", systemImage: "internaldrive").font(.system(size: 13))
                Spacer()
                Text(byteString(cacheBytes)).monospacedDigit().foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                History.shared.clearAudioCache(); cacheBytes = History.shared.audioCacheBytes()
            } label: { Label("Clear audio cache (keep history text)", systemImage: "trash") }
                .glassButton().controlSize(.small)
            Button(role: .destructive) {
                History.shared.clear(); cacheBytes = History.shared.audioCacheBytes()
            } label: { Label("Delete all history (text + audio)", systemImage: "trash.fill") }
                .glassButton().controlSize(.small)
            if !settings.proEmail.isEmpty {
                HStack(spacing: 8) {
                    Button(role: .destructive) { confirmCloudWipe = true } label: {
                        HStack(spacing: 6) {
                            if cloudWiping { ProgressView().controlSize(.small) }
                            Label(cloudWiped ? "Cloud data deleted ✓"
                                  : (cloudWiping ? "Deleting…" : "Delete all my cloud data"),
                                  systemImage: "icloud.slash")
                        }
                    }
                    .glassButton().controlSize(.small)
                    .disabled(cloudWiping)
                    .confirmationDialog("Delete all your cloud data?", isPresented: $confirmCloudWipe, titleVisibility: .visible) {
                        Button("Delete cloud data", role: .destructive) { wipeCloudData() }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Removes your synced history, notes, stats and leaderboard score from Verba's servers (with tombstones, so other Macs won't re-upload them). Local data on this Mac is untouched.")
                    }
                    if cloudWipeError {
                        statusLabel("Couldn't reach the server — cloud data may not have been deleted. Try again.",
                                    system: "exclamationmark.triangle.fill", tint: .orange)
                    }
                }
            }
        }

        card("Screen recording",
             footer: "Only used in Context mode to read on-screen text you point at. It's entirely optional.") {
            permissionRow("camera.viewfinder", "Screen Recording", "Context mode only (optional).", granted: screenGranted) {
                ScreenCapture.requestPermission()
                ScreenCapture.openPrivacySettings()
            }
        }

        card("Core permissions") {
            permissionRow("mic.fill", "Microphone", "Record your voice.", granted: micGranted) {
                AVCaptureDevice.requestAccess(for: .audio) { _ in }; openPane("Privacy_Microphone")
            }
            permissionRow("hand.point.up.left.fill", "Accessibility", "Paste into the active app.", granted: axGranted) {
                Output.promptAccessibility(); openPane("Privacy_Accessibility")
            }
            permissionRow("keyboard", "Input Monitoring", "Use the Fn key as your trigger.", granted: imGranted) {
                _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent); openPane("Privacy_ListenEvent")
            }
            if micGranted && axGranted && imGranted {
                statusLabel("All set. Verba has everything it needs to work.", system: "checkmark.seal.fill", tint: .green)
            } else {
                statusLabel("Some permissions are off. Verba can't fully work until the three core ones are on.", system: "exclamationmark.triangle.fill", tint: .orange)
            }
        }

        card("What goes where") {
            explainerRow("Audio & transcripts", "Stay on this Mac. Synced to your account only if history is on.")
            explainerRow("Cloud sync", "Encrypted in transit. Delete anytime with “Delete all my cloud data”.")
            explainerRow("Local engines", "Whisper / Parakeet / Ollama run 100% offline — nothing leaves your Mac.")
            explainerRow("Cloud engines", "OpenAI transcription and remote rewriting send your text to that provider.")
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
        card("Automatic updates",
             footer: "Verba updates itself in the background via signed releases. Turn off automatic checks to update only when you press “Check now”.") {
            toggleRow("Automatically check for updates",
                      Binding(get: { autoCheck }, set: { autoCheck = $0; updater.autoCheck = $0 }))
            toggleRow("Automatically download & install updates",
                      Binding(get: { autoDownload }, set: { autoDownload = $0; updater.autoDownload = $0 }))
        }

        card("Version") {
            HStack {
                Label("Current version", systemImage: "app.badge").font(.system(size: 13))
                Spacer()
                Text("v\(Updater.currentVersion)").monospacedDigit().foregroundStyle(.secondary)
            }
            if updater.updateAvailable, let v = updater.latestVersion {
                statusLabel("Update available: v\(v)", system: "arrow.down.circle.fill", tint: .blue)
            }
            if let when = updater.lastChecked {
                HStack {
                    Text("Last checked").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(when.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Button { Updater.shared.checkForUpdates() } label: {
                Label("Check now", systemImage: "arrow.triangle.2.circlepath")
            }
            .glassButton().controlSize(.small)
        }

        card("About") {
            HStack {
                VerbaMark(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Verba").font(.system(size: 15, weight: .bold))
                    Text("Voice to clean text, on your terms.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            explainerRow("Acknowledgements", "WhisperKit, NVIDIA Parakeet, Ollama, Sparkle, and the SwiftUI community. Thank you.")
        }
    }

    // MARK: - Engine lifecycle (local engines: install / use / uninstall)

    @ViewBuilder private var engineLifecycle: some View {
        let _ = engineRefresh
        let active = settings.engine == engineTab
        if engineTab == .openAI {
            if active { activeLabel } else {
                Button("Use OpenAI") { settings.engine = .openAI }.glassProminentButton().controlSize(.small)
            }
        } else {
            if engineTab == .whisper {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Whisper model").font(.caption.weight(.medium)).foregroundStyle(.secondary)
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
                    Label("Downloaded · \(EngineManager.sizeGB(engineTab)) on disk", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                    Spacer()
                    if activating && active {
                        ProgressView().controlSize(.small); Text("Activating…").font(.caption).foregroundStyle(.secondary)
                    } else if active && ready {
                        activeLabel
                        Button("Reload") { activate(engineTab) }.glassButton().controlSize(.small)
                    } else {
                        Button(active ? "Activate" : "Use this model") { activate(engineTab) }.glassProminentButton().controlSize(.small)
                    }
                    Button("Uninstall", role: .destructive) { confirmUninstall = true }.glassButton().controlSize(.small)
                        .confirmationDialog("Uninstall this model?", isPresented: $confirmUninstall, titleVisibility: .visible) {
                            Button("Uninstall", role: .destructive) { uninstallEngine(engineTab) }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Deletes the \(EngineManager.sizeGB(engineTab)) model from this Mac. You can re-download it anytime.")
                        }
                }
                if active && !ready && !activating, let err = EngineManager.lastInstallError {
                    statusLabel("Couldn't load this model: \(err). Tap Activate to retry, or Uninstall + redownload.",
                                system: "exclamationmark.triangle.fill", tint: .orange)
                }
            } else {
                HStack {
                    Text("Not installed · download \(EngineManager.sizeGB(engineTab))").font(.system(size: 13)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Download & install") { installEngine(engineTab) }.glassProminentButton().controlSize(.small)
                }
            }
            Text("Runs fully offline & free once installed, no API key needed.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var activeLabel: some View {
        Label("Active & ready", systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
    }

    // MARK: - Local LLM (Ollama)

    @ViewBuilder private var localModelBlock: some View {
        labeledField("Model", $settings.localLLMModel, prompt: "qwen2.5:7b", width: 280)
        if engineInstalling {
            HStack { ProgressView().controlSize(.small); Text("Setting up the local engine…").font(.caption).foregroundStyle(.secondary) }
        } else if !ollamaUp {
            HStack {
                Text("Local engine not running.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Set up & start") { setupEngine() }.glassProminentButton().controlSize(.small)
            }
        } else if pulling {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: pullProgress).progressViewStyle(.linear)
                Text("Downloading \(settings.localLLMModel)… \(Int(pullProgress * 100))%").font(.caption).foregroundStyle(.secondary)
            }
        } else if ollamaHasModel {
            statusLabel("\(settings.localLLMModel) ready, runs 100% offline.", system: "checkmark.seal.fill", tint: .green)
        } else {
            HStack {
                Text("Engine ready. Model not downloaded yet.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Download model") { pullModel() }.glassProminentButton().controlSize(.small)
            }
        }
        Text("Reformulation runs entirely on your Mac. Tap Set up to install the local engine (~30 MB) the first time. Qwen 2.5 7B recommended (~4.7 GB).")
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
        installMsg = "Downloading \(EngineManager.sizeGB(e))…"
        Task {
            let ok = await EngineManager.install(e) { p in installProgress = p }
            await MainActor.run {
                installing = false
                installMsg = ok ? "" : "Install failed: \(EngineManager.lastInstallError ?? "check your connection.")"
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
                Label("Authorized", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
            } else {
                Button("Enable", action: action).glassButton().controlSize(.small)
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
        [.init(days: 0, label: "Forever"), .init(days: 7, label: "7 days"),
         .init(days: 30, label: "30 days"), .init(days: 90, label: "90 days")]
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
