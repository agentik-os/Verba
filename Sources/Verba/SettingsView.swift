import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var openRouterKey = Keychain.openRouterKey ?? ""
    @State private var verifying = false
    @State private var verifyMsg = ""
    @State private var engineTab: TranscriptionEngine = Settings.shared.engine
    @State private var installing = false
    @State private var installMsg = ""
    @State private var engineRefresh = 0

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        Form {
            generalSections
            keySections
            planSections
        }
        .formStyle(.grouped)
        .frame(minWidth: 540, maxWidth: .infinity, minHeight: 460, maxHeight: .infinity)
        .tint(.primary)   // B&W accents
    }

    // MARK: General (ordered: Account → Transcription → AI → Recording → Output → Loading → App)
    @ViewBuilder private var generalSections: some View {
        Group {
            Section {
                TextField("Username / alias", text: $settings.username).frame(width: 260)
            } header: { Text("Account") } footer: {
                Text("Your public name on the leaderboard, never your real name or email. Change it anytime.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Picker("Engine", selection: $engineTab) {
                    ForEach(TranscriptionEngine.allCases) { Text($0.label).tag($0) }
                }
                engineLifecycle
                TextField("Language (ISO code, blank = auto)", text: $settings.language).frame(width: 220)
                Toggle("Voice commands", isOn: $settings.voiceCommands)
                if settings.voiceCommands {
                    Text("Say “new line / new paragraph”, “comma / period / question mark”, “bullet point”, or “scratch that” and Verba turns them into real formatting (any mode, incl. Flow). EN + FR.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } header: { Text("Transcription") }

            Section {
                Toggle("Restructure transcript with Claude", isOn: $settings.repromptEnabled)
                Picker("Run via", selection: $settings.repromptBackend) {
                    ForEach(RepromptBackend.allCases) { Text($0.label).tag($0) }
                }
                if settings.repromptBackend == .claudeCode {
                    Label(ClaudeCode.isAvailable ? "Claude Code detected, uses your Claude plan, no API key."
                                                  : "Claude Code not found. Install it and run `claude` once to sign in.",
                          systemImage: ClaudeCode.isAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(ClaudeCode.isAvailable ? .green : .orange)
                }
                if settings.repromptBackend == .openRouter {
                    TextField("OpenRouter model (e.g. anthropic/claude-3.7-sonnet)", text: $settings.openRouterModel)
                    Text("Any model on openrouter.ai (openai/gpt-4o, google/gemini-2.0-flash…). Add your key in API Keys below.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Picker("Claude model", selection: $settings.claudeModel) {
                        ForEach(claudeModels, id: \.self) { Text($0).tag($0) }
                    }
                }
                Toggle("Auto-pick profile from the active app", isOn: $settings.autoDetectProfile)
                Toggle("Use selected text as context", isOn: $settings.useSelectionContext)
                if settings.useSelectionContext {
                    Text("If text is selected when you dictate, your words become an instruction on that selection, and the result replaces it.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } header: { Text("AI rewriting") }

            Section {
                Picker("Indicator", selection: $settings.overlayStyle) {
                    ForEach(OverlayStyle.allCases) { Text($0.label).tag($0) }
                }
                Picker("Style", selection: $settings.recordStyle) {
                    ForEach(RecordStyle.allCases) { Text($0.label).tag($0) }
                }
                Text(settings.recordStyle.help).font(.caption).foregroundStyle(.secondary)
                Toggle("Use the Fn (🌐 globe) key", isOn: $settings.useFnAsPrimary)
                if settings.useFnAsPrimary {
                    Text("Quick tap = record the active mode (tap again to send) · hold = push-to-talk · double-tap = mode picker. ⌃ pauses. Esc cancels.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    HStack {
                        Text("Primary shortcut")
                        Spacer()
                        ShortcutRecorder(
                            label: settings.primaryHasShortcut ? shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods) : "",
                            onCapture: { code, mods in settings.assignShortcut(keyCode: code, modifiers: mods, to: .primary) },
                            onClear: { settings.clearShortcut(.primary) }
                        )
                    }
                }
            } header: { Text("Recording & trigger") }

            Section {
                Toggle("Auto-paste into the active field", isOn: $settings.autoPaste)
                Toggle("Copy to clipboard", isOn: $settings.copyToClipboard)
                Toggle("Paste with formatting (render Markdown)", isOn: $settings.richTextPaste)
                Toggle("Review / edit before sending", isOn: $settings.reviewBeforeSend)
                if !Output.accessibilityTrusted {
                    HStack {
                        Text("Auto-paste needs Accessibility access")
                        Spacer()
                        Button("Enable…") { Output.promptAccessibility() }
                    }
                }
            } header: { Text("Output") } footer: {
                Text("Formatting pastes as real bold/headings/lists in apps that support it; plain fields get clean text.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Picker("Joke style", selection: $settings.quipTone) {
                    ForEach(QuipTone.allCases) { Text($0.label).tag($0) }
                }
            } header: { Text("Loading screen") } footer: {
                Text(settings.quipTone == .off
                     ? "While Claude works, Verba shows a neutral “\(Quips.neutral)”."
                     : "While Claude works, Verba shows a short AI-generated joke in this style, never the same twice in a day.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Toggle("Show in Dock (full window app)", isOn: $settings.showInDock)
            } header: { Text("App") } footer: {
                Text("Off = menu-bar only. The dictation hotkeys work either way.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Engine lifecycle (local engines: install / use / uninstall)
    @ViewBuilder private var engineLifecycle: some View {
        let _ = engineRefresh
        let active = settings.engine == engineTab
        if engineTab == .openAI {
            Text("Remote, no download. Uses your OpenAI key.")
                .font(.caption).foregroundStyle(.secondary)
            if active { activeLabel } else { Button("Use OpenAI") { settings.engine = .openAI } }
        } else {
            if engineTab == .whisper {
                Picker("Whisper model", selection: $settings.localModel) {
                    ForEach(localModels, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: settings.localModel) { _, _ in engineRefresh += 1 }
            }
            if installing {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(installMsg.isEmpty ? "Installing…" : installMsg).font(.caption).foregroundStyle(.secondary)
                }
            } else if EngineManager.isInstalled(engineTab) {
                HStack {
                    Label("Installed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Spacer()
                    if active { activeLabel } else {
                        Button("Use") { settings.engine = engineTab }.buttonStyle(.borderedProminent)
                    }
                    Button("Uninstall", role: .destructive) { uninstallEngine(engineTab) }
                }
            } else {
                HStack {
                    Text("Not installed · download \(EngineManager.sizeGB(engineTab))").foregroundStyle(.secondary)
                    Spacer()
                    Button("Download & install") { installEngine(engineTab) }.buttonStyle(.borderedProminent)
                }
            }
            Text("Runs fully offline & free once installed, no API key needed.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var activeLabel: some View {
        Label("Active", systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
    }
    private func installEngine(_ e: TranscriptionEngine) {
        installing = true
        installMsg = "Downloading \(EngineManager.sizeGB(e))… (first run can take a few minutes)"
        Task {
            let ok = await EngineManager.install(e)
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

    // MARK: Keys
    @ViewBuilder private var keySections: some View {
        Group {
            Section("OpenAI (cloud transcription)") {
                SecureField("sk-…", text: $openAIKey)
                Text("Used for gpt-4o-transcribe. Stored in your macOS Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Anthropic (Claude reprompting)") {
                SecureField("sk-ant-…", text: $anthropicKey)
                Text("Used for restructuring with the Anthropic API key backend. Stored in your macOS Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("OpenRouter (any writing model)") {
                SecureField("sk-or-…", text: $openRouterKey)
                Text("Bring your own OpenRouter key to use any model for restructuring. Pick the model in General ▸ Reprompting. Stored in your macOS Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("Save keys") {
                    Keychain.openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    Keychain.openRouterKey = openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }

    // MARK: Plan
    @ViewBuilder private var planSections: some View {
        Group {
            Section {
                HStack {
                    Label(settings.isPro ? "Pro" : "Free", systemImage: settings.isPro ? "sparkles" : "circle")
                        .foregroundStyle(settings.isPro ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    Spacer()
                    if !settings.isPro, let u = URL(string: Entitlement.pricingURL) {
                        Link("Upgrade, 14-day trial", destination: u)
                    }
                }
            } header: { Text("Your plan") } footer: {
                Text(settings.isPro
                     ? "Thanks! Unlimited dictation, editable mode prompts and custom modes."
                     : "Free is a full-Pro trial of \(Entitlement.freeTrialDictations) dictations. Pro ($9.99/mo) unlocks unlimited dictation, editable system prompts and custom modes.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !settings.isPro {
                Section("Free trial") {
                    let used = Stats.shared.totalCount
                    let limit = Entitlement.freeTrialDictations
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(min(used, limit)) / \(limit) dictations")
                            Spacer()
                            Text("\(max(0, limit - used)) left").foregroundStyle(.secondary)
                        }
                        .font(.callout)
                        ProgressView(value: Double(min(used, limit)), total: Double(limit))
                    }
                }
            }
            Section("Refer friends, give a month, get a month") {
                HStack {
                    Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button("Copy") {
                        let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string)
                    }
                }
                Text("Every friend who subscribes through your link and dictates 15,000+ words earns you a free month, unlimited, no cap.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Restore your subscription") {
                TextField("Email used at checkout", text: $settings.proEmail)
                HStack {
                    Button {
                        verifying = true; verifyMsg = ""
                        Task {
                            let ok = await settings.verifyPro()
                            verifying = false
                            verifyMsg = ok ? "Pro unlocked ✓" : "No active subscription for this email."
                        }
                    } label: { Text(verifying ? "Checking…" : "Verify") }
                        .disabled(verifying || settings.proEmail.isEmpty)
                    if !verifyMsg.isEmpty { Text(verifyMsg).font(.caption).foregroundStyle(.secondary) }
                }
                if let u = URL(string: Entitlement.accountURL) {
                    Link("Manage subscription", destination: u).font(.caption)
                }
            }
        }
    }

}
