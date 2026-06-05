import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var selectedProfileID: UUID?

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            keys.tabItem { Label("API Keys", systemImage: "key") }
            profilesTab.tabItem { Label("Profiles", systemImage: "person.2") }
        }
        .frame(width: 540, height: 460)
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
                        Text("Shortcut")
                        Spacer()
                        ShortcutRecorder()
                    }
                } else {
                    Text("Verba watches the Fn (globe) key. macOS may ask for Input Monitoring / Accessibility access the first time.")
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

    // MARK: Profiles
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
            }

            if let idx = settings.profiles.firstIndex(where: { $0.id == selectedProfileID }) {
                profileEditor(idx)
            } else {
                Text("Select a profile").foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }

    private func profileEditor(_ idx: Int) -> some View {
        Form {
            TextField("Name", text: $settings.profiles[idx].name)
            Section("System prompt (how Claude restructures)") {
                TextEditor(text: $settings.profiles[idx].systemPrompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 160)
            }
            Section("Auto-match app bundle IDs (comma-separated)") {
                TextField("com.apple.dt.Xcode, …", text: Binding(
                    get: { settings.profiles[idx].matchBundleIDs.joined(separator: ", ") },
                    set: { settings.profiles[idx].matchBundleIDs =
                        $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }
            HStack {
                Button("Make active") { settings.activeProfileID = settings.profiles[idx].id }
                Spacer()
                if !settings.profiles[idx].builtin {
                    Button("Delete", role: .destructive) {
                        let id = settings.profiles[idx].id
                        settings.profiles.removeAll { $0.id == id }
                        if settings.activeProfileID == id { settings.activeProfileID = settings.profiles.first!.id }
                        selectedProfileID = settings.activeProfileID
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 320)
    }

    private func addProfile() {
        let p = Profile(name: "New profile", systemPrompt: "You clean and restructure the transcript. Output only the result.")
        settings.profiles.append(p)
        selectedProfileID = p.id
    }
}
