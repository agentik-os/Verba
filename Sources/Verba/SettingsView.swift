import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var verifying = false
    @State private var verifyMsg = ""
    @State private var engineTab: TranscriptionEngine = Settings.shared.engine
    @State private var installing = false
    @State private var installMsg = ""
    @State private var engineRefresh = 0

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            keys.tabItem { Label("API Keys", systemImage: "key") }
            planTab.tabItem { Label("Plan", systemImage: "sparkles") }
        }
        .frame(minWidth: 540, maxWidth: .infinity, minHeight: 460, maxHeight: .infinity)
    }

    // MARK: General
    private var general: some View {
        Form {
            Section("Engine") {
                Picker("Engine", selection: $engineTab) {
                    ForEach(TranscriptionEngine.allCases) { Text($0.label).tag($0) }
                }
                engineLifecycle
            }
            Section("Transcription") {
                TextField("Language (ISO code, blank = auto)", text: $settings.language)
                    .frame(width: 220)
                Toggle("Voice commands", isOn: $settings.voiceCommands)
                if settings.voiceCommands {
                    Text("Say “new line / new paragraph”, “comma / period / question mark”, “bullet point”, or “scratch that” and Verba turns them into real formatting (works in any mode, incl. Flow). EN + FR.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Reprompting (Claude)") {
                Toggle("Restructure transcript with Claude", isOn: $settings.repromptEnabled)
                Picker("Run via", selection: $settings.repromptBackend) {
                    ForEach(RepromptBackend.allCases) { Text($0.label).tag($0) }
                }
                if settings.repromptBackend == .claudeCode {
                    Label(ClaudeCode.isAvailable ? "Claude Code detected — uses your Max/Pro plan, no API key."
                                                  : "Claude Code not found. Install it and run `claude` once to sign in.",
                          systemImage: ClaudeCode.isAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(ClaudeCode.isAvailable ? .green : .orange)
                }
                Picker("Claude model", selection: $settings.claudeModel) {
                    ForEach(claudeModels, id: \.self) { Text($0).tag($0) }
                }
                Toggle("Auto-pick profile from the active app", isOn: $settings.autoDetectProfile)
                Toggle("Use selected text as context", isOn: $settings.useSelectionContext)
                if settings.useSelectionContext {
                    Text("If you have text selected when you dictate, your words are treated as an instruction on that selection — the result replaces it.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Recording") {
                Picker("Style", selection: $settings.recordStyle) {
                    ForEach(RecordStyle.allCases) { Text($0.label).tag($0) }
                }
                Text(settings.recordStyle.help).font(.caption).foregroundStyle(.secondary)

                Toggle("Use the Fn (🌐 globe) key", isOn: $settings.useFnAsPrimary)
                if settings.useFnAsPrimary {
                    Text("Fn is your trigger (like Wispr Flow): quick tap = record · hold >1s = mode picker, then press 1–9 to choose. Verba swallows the globe key so it won’t switch keyboards. If it still does, set System Settings ▸ Keyboard ▸ “Press 🌐 to: Do Nothing”.")
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
                Text("Hold ⌃⌥ to pop the mode picker; press 1–6 to dictate straight into a mode. Esc cancels a recording.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("App") {
                Toggle("Show in Dock (full window app)", isOn: $settings.showInDock)
                Text("Off = menu-bar only. The dictation hotkeys work either way.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Output") {
                Toggle("Auto-paste into the active field", isOn: $settings.autoPaste)
                Toggle("Copy to clipboard", isOn: $settings.copyToClipboard)
                Toggle("Paste with formatting (render Markdown)", isOn: $settings.richTextPaste)
                if settings.richTextPaste {
                    Text("Bold, headings and lists paste as real formatting in apps that support it (Notes, Mail, Slack…); plain-text fields get clean text without the * and #.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle("Review / edit before sending", isOn: $settings.reviewBeforeSend)
                if !Output.accessibilityTrusted {
                    HStack {
                        Text("Auto-paste needs Accessibility access")
                        Spacer()
                        Button("Enable…") { Output.promptAccessibility() }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Engine lifecycle (local engines: install / use / uninstall)
    @ViewBuilder private var engineLifecycle: some View {
        let _ = engineRefresh
        let active = settings.engine == engineTab
        if engineTab == .openAI {
            Text("Remote — no download. Uses your OpenAI key.")
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
            Text("Runs fully offline & free once installed — no API key needed.")
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
                installMsg = ok ? "" : "Download failed — check your connection."
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
    private var keys: some View {
        Form {
            Section("OpenAI (cloud transcription)") {
                SecureField("sk-…", text: $openAIKey)
                Text("Used for gpt-4o-transcribe. Stored in your macOS Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Anthropic (Claude reprompting)") {
                SecureField("sk-ant-…", text: $anthropicKey)
                Text("Used for restructuring. Stored in your macOS Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("Save keys") {
                    Keychain.openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Plan
    private var planTab: some View {
        Form {
            Section {
                HStack {
                    Label(settings.isPro ? "Pro" : "Free", systemImage: settings.isPro ? "sparkles" : "circle")
                        .foregroundStyle(settings.isPro ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    Spacer()
                    if !settings.isPro, let u = URL(string: Entitlement.pricingURL) {
                        Link("Upgrade — 14-day trial", destination: u)
                    }
                }
            } header: { Text("Your plan") } footer: {
                Text(settings.isPro
                     ? "Thanks! You can edit every mode's system prompt and create custom modes."
                     : "Free includes the built-in Coding / Pro / Perso modes. Pro unlocks editing the system prompts (full control over how Verba reinterprets your audio) and creating your own modes.")
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
        .formStyle(.grouped)
    }

}
