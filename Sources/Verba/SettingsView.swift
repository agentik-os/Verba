import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var verifying = false
    @State private var verifyMsg = ""

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            keys.tabItem { Label("API Keys", systemImage: "key") }
            planTab.tabItem { Label("Plan", systemImage: "sparkles") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: General
    private var general: some View {
        Form {
            Section("Transcription") {
                Picker("Engine", selection: $settings.engine) {
                    ForEach(TranscriptionEngine.allCases) { Text($0.label).tag($0) }
                }
                if settings.engine == .whisper {
                    Picker("Whisper model", selection: $settings.localModel) {
                        ForEach(localModels, id: \.self) { Text($0).tag($0) }
                    }
                }
                if settings.engine.isLocal {
                    Text("On-device & free. First use downloads the model (a few hundred MB), then runs fully offline — no API key needed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                TextField("Language (ISO code, blank = auto)", text: $settings.language)
                    .frame(width: 220)
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
                    Text("Fn is now your trigger (like Wispr Flow). In System Settings ▸ Keyboard, set “Press 🌐 to: Do Nothing” so macOS doesn’t steal it.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    HStack {
                        Text("Primary shortcut")
                        Spacer()
                        ShortcutRecorder(
                            label: shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods),
                            onCapture: { code, mods in settings.primaryKeyCode = code; settings.primaryMods = mods }
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
