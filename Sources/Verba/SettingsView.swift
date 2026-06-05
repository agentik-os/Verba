import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var selectedProfileID: UUID?
    @State private var verifying = false
    @State private var verifyMsg = ""

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            keys.tabItem { Label("API Keys", systemImage: "key") }
            profilesTab.tabItem { Label("Modes", systemImage: "wand.and.stars") }
            planTab.tabItem { Label("Plan", systemImage: "sparkles") }
        }
        .frame(width: 560, height: 480)
        .onAppear { selectedProfileID = settings.activeProfileID }
    }

    // MARK: General
    private var general: some View {
        Form {
            Section("Transcription") {
                Picker("Engine", selection: $settings.engine) {
                    ForEach(TranscriptionEngine.allCases) { Text($0.label).tag($0) }
                }
                if settings.engine == .local {
                    Picker("Local model", selection: $settings.localModel) {
                        ForEach(localModels, id: \.self) { Text($0).tag($0) }
                    }
                    Text("First use downloads the model (~runs fully offline after).")
                        .font(.caption).foregroundStyle(.secondary)
                }
                TextField("Language (ISO code, blank = auto)", text: $settings.language)
                    .frame(width: 220)
            }
            Section("Reprompting (Claude)") {
                Toggle("Restructure transcript with Claude", isOn: $settings.repromptEnabled)
                Picker("Claude model", selection: $settings.claudeModel) {
                    ForEach(claudeModels, id: \.self) { Text($0).tag($0) }
                }
                Toggle("Auto-pick profile from the active app", isOn: $settings.autoDetectProfile)
            }
            Section("Trigger") {
                Picker("How to start", selection: $settings.triggerMode) {
                    ForEach(TriggerMode.allCases) { Text($0.label).tag($0) }
                }
                if settings.triggerMode == .hotkey {
                    HStack {
                        Text("Primary shortcut")
                        Spacer()
                        ShortcutRecorder(
                            label: shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods),
                            onCapture: { code, mods in settings.primaryKeyCode = code; settings.primaryMods = mods }
                        )
                    }
                    Text("Each profile can also have its own shortcut (Profiles tab) to dictate straight into that mode.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Verba watches the Fn (globe) key. macOS may ask for Input Monitoring / Accessibility access the first time. Per-profile shortcuts (Profiles tab) still work.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Output") {
                Toggle("Auto-paste into the active field", isOn: $settings.autoPaste)
                Toggle("Copy to clipboard", isOn: $settings.copyToClipboard)
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

    // MARK: Modes
    private var profilesTab: some View {
        HSplitView {
            List(selection: $selectedProfileID) {
                ForEach(settings.profiles) { p in
                    HStack {
                        Text(p.name)
                        if p.id == settings.activeProfileID {
                            Spacer(); Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        }
                    }.tag(p.id)
                }
            }
            .frame(minWidth: 160)
            .toolbar {
                Button { addProfile() } label: { Image(systemName: "plus") }
                    .disabled(!settings.isPro)
                    .help(settings.isPro ? "New mode" : "Custom modes are a Pro feature")
                Button {
                    settings.resetProfilesToDefaults()
                    selectedProfileID = settings.activeProfileID
                } label: { Image(systemName: "arrow.counterclockwise") }
                    .help("Restore the built-in modes")
            }

            if let id = selectedProfileID, settings.profiles.contains(where: { $0.id == id }) {
                profileEditor(id: id)
            } else {
                Text("Select a mode").foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }

    /// Index of a profile by id, resolved fresh on every binding access so a
    /// mutating array (delete / reset / reseed) can never crash on a stale index.
    private func index(of id: UUID) -> Int? { settings.profiles.firstIndex { $0.id == id } }

    private func profileEditor(id: UUID) -> some View {
        let nameB = Binding(
            get: { settings.profiles.first { $0.id == id }?.name ?? "" },
            set: { v in if let i = index(of: id) { settings.profiles[i].name = v } })
        let promptB = Binding(
            get: { settings.profiles.first { $0.id == id }?.systemPrompt ?? "" },
            set: { v in if let i = index(of: id) { settings.profiles[i].systemPrompt = v } })
        let bundlesB = Binding(
            get: { settings.profiles.first { $0.id == id }?.matchBundleIDs.joined(separator: ", ") ?? "" },
            set: { v in if let i = index(of: id) {
                settings.profiles[i].matchBundleIDs = v.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } })
        let p = settings.profiles.first { $0.id == id }
        let isBuiltin = p?.builtin ?? true
        let shortcut: String = {
            guard let p, let c = p.hotkeyCode, let m = p.hotkeyMods else { return "" }
            return shortcutLabel(keyCode: c, modifiers: m)
        }()

        return Form {
            TextField("Name", text: nameB)
            Section {
                TextEditor(text: promptB)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 160)
                    .disabled(!settings.isPro)
                    .opacity(settings.isPro ? 1 : 0.55)
            } header: {
                HStack {
                    Text("System prompt (how Claude reinterprets your audio)")
                    if !settings.isPro {
                        Spacer()
                        Label("Pro", systemImage: "lock.fill").font(.caption).foregroundStyle(.tint)
                    }
                }
            } footer: {
                if !settings.isPro {
                    Text("Editing modes is a Pro feature. Free includes the built-in modes as-is.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Dedicated shortcut") {
                HStack {
                    Text("Dictate straight into this mode")
                    Spacer()
                    ShortcutRecorder(
                        label: shortcut,
                        onCapture: { code, mods in
                            if let i = index(of: id) { settings.profiles[i].hotkeyCode = code; settings.profiles[i].hotkeyMods = mods }
                        },
                        onClear: {
                            if let i = index(of: id) { settings.profiles[i].hotkeyCode = nil; settings.profiles[i].hotkeyMods = nil }
                        }
                    )
                }
            }
            Section("Auto-match app bundle IDs (comma-separated)") {
                TextField("com.apple.dt.Xcode, …", text: bundlesB)
            }
            HStack {
                Button("Make active") { settings.activeProfileID = id }
                Spacer()
                if !isBuiltin {
                    Button("Delete", role: .destructive) {
                        selectedProfileID = nil   // detach the editor before mutating the array
                        settings.profiles.removeAll { $0.id == id }
                        if settings.activeProfileID == id {
                            settings.activeProfileID = settings.profiles.first?.id ?? id
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 320)
    }

    private func addProfile() {
        let p = Profile(name: "New mode", systemPrompt: Profile.custom.systemPrompt)
        settings.profiles.append(p)
        selectedProfileID = p.id
    }
}
