import SwiftUI
import AppKit
import AVFoundation
import IOKit.hid

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var axGranted = Output.accessibilityTrusted
    @State private var imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    @State private var screenGranted = ScreenCapture.hasPermission()
    private let permPoll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var openRouterKey = Keychain.openRouterKey ?? ""
    @State private var verifying = false
    @State private var verifyMsg = ""
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

    private let claudeModels = ["claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8"]
    private let localModels = ["base", "small", "large-v3-v20240930_turbo", "large-v3"]

    var body: some View {
        Form {
            referralSection
            generalSections
            permissionsSection
            storageSection
            keySections
            planSections
        }
        .formStyle(.grouped)
        .frame(minWidth: 540, maxWidth: .infinity, minHeight: 460, maxHeight: .infinity)
        .tint(.primary)   // B&W accents
        .onReceive(permPoll) { _ in
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            axGranted = Output.accessibilityTrusted
            imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
            screenGranted = ScreenCapture.hasPermission()
        }
    }

    // MARK: Permissions (live status; re-launch the grant if a permission is off)
    @ViewBuilder private var permissionsSection: some View {
        Section {
            permissionRow("mic.fill", "Microphone", "Record your voice.", granted: micGranted) {
                AVCaptureDevice.requestAccess(for: .audio) { _ in }
                openPane("Privacy_Microphone")
            }
            permissionRow("hand.point.up.left.fill", "Accessibility", "Paste into the active app.", granted: axGranted) {
                Output.promptAccessibility()
                openPane("Privacy_Accessibility")
            }
            permissionRow("keyboard", "Input Monitoring", "Use the Fn key as your trigger.", granted: imGranted) {
                _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
                openPane("Privacy_ListenEvent")
            }
            permissionRow("camera.viewfinder", "Screen Recording", "Context mode only (optional).", granted: screenGranted) {
                ScreenCapture.requestPermission()
                ScreenCapture.openPrivacySettings()
            }
        } header: { Text("Permissions") } footer: {
            if micGranted && axGranted && imGranted {
                Label("All set. Verba has everything it needs to work.", systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.green)
            } else {
                Label("Some permissions are off. Verba can't fully work until the three core ones are on. Screen Recording is optional (Context mode).", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func permissionRow(_ icon: String, _ title: String, _ desc: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : icon)
                .foregroundStyle(granted ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Label("Authorized", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
            } else {
                Button("Enable", action: action)
            }
        }
    }

    private func openPane(_ id: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(id)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: General (ordered: Account → Transcription → AI → Recording → Output → Loading → App)
    @ViewBuilder private var generalSections: some View {
        Group {
            Section {
                HStack {
                    TextField("Alias", text: $settings.username).frame(width: 220)
                    Button { settings.username = Settings.randomAlias() } label: { Image(systemName: "shuffle") }
                        .buttonStyle(.borderless).help("Shuffle a new alias")
                }
                Toggle("Show me on the public leaderboard", isOn: $settings.showOnLeaderboard)
            } header: { Text("Alias & leaderboard") } footer: {
                Text("Your alias is PUBLIC on the leaderboard, so pick a nickname, never your real name or email. Turn the toggle off to keep your profile off the leaderboard entirely.")
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
                Toggle("Single-language output", isOn: $settings.languageGuard)
                if settings.languageGuard {
                    Text("If the engine mixes two languages mid-sentence (e.g. English words in French speech), Verba rewrites the result fully in its dominant language. Applies to every mode, including Flow.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } header: { Text("Transcription") }

            Section {
                Toggle("Restructure transcript with Claude", isOn: $settings.repromptEnabled)
                Picker("Run via", selection: $settings.repromptBackend) {
                    ForEach(RepromptBackend.allCases) { Text($0.label).tag($0) }
                }
                if settings.repromptBackend == .auto {
                    Label(ClaudeCode.isAvailable
                          ? "Using Claude Code (runs on your Claude plan, no key)."
                          : "Using Verba's included rewriting (no key, no setup).",
                          systemImage: "wand.and.stars")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if settings.repromptBackend == .verba {
                    Label(settings.proEmail.isEmpty ? "Sign in (account section) to use the included rewriting, no API key needed."
                                                     : "Included with Verba, no API key needed. Runs on Verba's servers.",
                          systemImage: settings.proEmail.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(settings.proEmail.isEmpty ? .orange : .green)
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
                } else if settings.repromptBackend == .localLLM {
                    localModelBlock
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
                if settings.overlayStyle == .minimal {
                    Text("No floating window. The menu-bar icon turns red and pulses while recording.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Picker("Style", selection: $settings.recordStyle) {
                    ForEach(RecordStyle.allCases) { Text($0.label).tag($0) }
                }
                Text(settings.recordStyle.help).font(.caption).foregroundStyle(.secondary)
                Toggle("Use the Fn (🌐 globe) key", isOn: $settings.useFnAsPrimary)
                if settings.useFnAsPrimary {
                    Text("Tap = record the active mode (tap again to send) · hold = push-to-talk · Fn + 1-9 = dictate in a specific mode · Fn + Tab = next mode (even mid-dictation) · ⌃ pauses · Esc cancels.")
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
                Toggle("Change-mode jumps to the next mode (no list)", isOn: $settings.modeGestureCycles)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Remember last used mode", isOn: $settings.rememberLastMode)
                    Text("After each dictation, the mode you used becomes the default for the next one.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Change-mode shortcut")
                    Spacer()
                    Text("Fn + Tab").foregroundStyle(.secondary)   // the built-in gesture
                }
                HStack {
                    Text("Custom change-mode shortcut")
                    Spacer()
                    ShortcutRecorder(
                        label: settings.modePickerHasShortcut ? shortcutLabel(keyCode: settings.modePickerKeyCode, modifiers: settings.modePickerMods) : "",
                        onCapture: { code, mods in settings.assignShortcut(keyCode: code, modifiers: mods, to: .modePicker) },
                        onClear: { settings.clearShortcut(.modePicker) }
                    )
                }
                Text(settings.modeGestureCycles
                     ? "Fn + Tab jumps straight to the next mode — even mid-dictation; Fn + 1-9 picks a specific mode. Set your own key above. Turn this off to open a numbered picker instead. Per-mode shortcuts are in Modes."
                     : "Fn + Tab opens the mode picker; Fn + 1-9 picks a specific mode. Set your own key above. Turn the toggle on to cycle straight to the next mode instead. Per-mode shortcuts are in Modes.")
                    .font(.caption).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Today's to-do glance")
                        Spacer()
                        Text("⌥ + Fn").foregroundStyle(.secondary)   // quick glance popup
                    }
                    Toggle("Enable the ⌥ + Fn task glance", isOn: $settings.todoGlanceEnabled)
                    Text("Press ⌥ (Option) + Fn to pop up a compact glance of today's tasks — what's due today plus anything overdue, each checkable. Press it again or Esc to dismiss.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Record a note")
                    Spacer()
                    Text("Fn + Z").foregroundStyle(.secondary)   // built-in note gesture
                }
                HStack {
                    Text("Add a to-do")
                    Spacer()
                    Text("Fn + §").foregroundStyle(.secondary)   // built-in voice to-do capture
                }
                HStack {
                    Text("Custom record-note shortcut")
                    Spacer()
                    ShortcutRecorder(
                        label: settings.noteRecordHasShortcut ? shortcutLabel(keyCode: settings.noteRecordKeyCode, modifiers: settings.noteRecordMods) : "",
                        onCapture: { code, mods in settings.assignShortcut(keyCode: code, modifiers: mods, to: .noteRecord) },
                        onClear: { settings.clearShortcut(.noteRecord) }
                    )
                }
                Text("Fn + Z opens the Notes tab and starts recording a new note instantly (notes auto-save as you go — no Save button). Fn + § instead captures a spoken to-do and files it into your projects. Set your own note key above.")
                    .font(.caption).foregroundStyle(.secondary)
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
                Toggle("Show the menu-bar icon", isOn: $settings.showMenuBarIcon)
            } header: { Text("App") } footer: {
                Text("Dock off = menu-bar only. The dictation hotkeys work either way. If you hide BOTH the Dock and the menu-bar icon, reopen Verba from Applications to get back here.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Toggle("Notes tab (long-form voice notes)", isOn: $settings.notesTabEnabled)
                Text("A Notes tab to record long voice memos (up to an hour) and reorganize them into a clean document with a chosen format.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Task Manager tab (tasks by project)", isOn: $settings.todosTabEnabled)
                Text("A Task Manager tab to capture tasks and sub-tasks by voice, sorted into projects (accordion panels). Ask the agent to build a whole list from a spoken request.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("To-do reminders (30 min before a deadline)", isOn: $settings.todoReminders)
                Text("Posts a local notification 30 minutes before a to-do task's deadline. Needs notification permission (macOS asks once). Clearing the deadline, completing, or deleting the task cancels its reminder.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Smart formatting per app", isOn: $settings.smartFormatting)
                Text("Rich text/markdown in apps that render it (Mail, Notion, Notes…), plain text in code editors and terminals.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Redo last dictation in another mode", isOn: $settings.redoEnabled)
                Text("Adds “Redo last in…” to the menu-bar menu, re-runs your last recording through any mode without speaking again.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Auto-learn dictionary from your edits", isOn: $settings.autoLearnDictionary)
                Text("When you fix a word — in the review screen, or by hand in the app right after pasting — Verba spots the correction on your next dictation and applies it automatically from then on. Learned terms appear in Dictionary.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Match my tone per app", isOn: $settings.toneMatch)
                Text("Verba learns how you write in each app (from your recent messages there) and matches that tone automatically.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Edit last result by voice", isOn: $settings.voiceEditLast)
                Text("Adds “Edit last by voice…” to the menu, speak a change (“make it shorter”, “more formal”, “translate to English”) and Verba rewrites your last result.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Agentic actions (Context mode)", isOn: $settings.agenticActionsEnabled)
                Text("In Context mode, voice requests like “create an event tomorrow 3pm”, “remind me to…”, or “draft a reply to this” create a Calendar event / Reminder / email draft. Verba always asks you to confirm first.")
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text("Labs") }

            Section {
                Toggle("Sound effects", isOn: $settings.soundsEnabled)
                if settings.soundsEnabled {
                    HStack {
                        Text("Volume")
                        Slider(value: $settings.soundVolume, in: 0...1)
                        Text("\(Int(settings.soundVolume * 100))%").foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
                    }
                }
            } header: { Text("Sounds") } footer: {
                Text("Cues for recording start, paste, and errors. Only your custom mp3s play (no macOS system beeps). Drop more in the Sounds folder to add stop / pause / resume / cancel / mode cues.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Toggle("Stop the macOS Fn / emoji popup", isOn: $settings.suppressFnPopup)
                Toggle("Disable the keyboard / input-source switcher", isOn: $settings.disableInputSwitcher)
            } header: { Text("Fn key behaviour") } footer: {
                Text("By default Verba takes over the globe (Fn) key so macOS doesn't pop the emoji/Fn HUD or switch your keyboard layout. Turn these off to get the standard macOS behaviour back (the Fn trigger may then show the system popup).")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                ForEach(Self.sidebarItems) { item in
                    Toggle(item.title, isOn: sidebarBinding(item))
                }
            } header: { Text("Sidebar menu") } footer: {
                Text("Choose which sections show in the main window's sidebar. Home, Modes and Settings always stay.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    /// Sidebar sections the user can hide (Home / Modes / Settings are pinned).
    private static let sidebarItems: [NavItem] =
        [.notes, .todos, .insights, .history, .dictionary, .snippets, .style, .transforms, .scratchpad, .files, .leaderboard, .wishlist, .freeMonth]

    private func sidebarBinding(_ item: NavItem) -> Binding<Bool> {
        if item == .notes { return $settings.notesTabEnabled }   // Notes has its own feature flag
        if item == .todos { return $settings.todosTabEnabled }   // To-dos has its own feature flag
        return Binding(get: { settings.navVisible(item) }, set: { settings.setNavVisible(item, $0) })
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
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: installProgress).progressViewStyle(.linear)
                    Text("\(installMsg) \(Int(installProgress * 100))%").font(.caption).foregroundStyle(.secondary)
                }
            } else if EngineManager.isInstalled(engineTab) {
                let _ = engineRefresh
                let ready = EngineManager.isReady(engineTab, model: settings.localModel)
                HStack {
                    Label("Downloaded", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Spacer()
                    if activating && active {
                        ProgressView().controlSize(.small); Text("Activating…").font(.caption).foregroundStyle(.secondary)
                    } else if active && ready {
                        activeLabel
                        Button("Reload") { activate(engineTab) }.buttonStyle(.bordered).controlSize(.small)
                    } else {
                        Button(active ? "Activate" : "Use this model") { activate(engineTab) }.buttonStyle(.borderedProminent)
                    }
                    Button("Uninstall", role: .destructive) { uninstallEngine(engineTab) }
                }
                if active && !ready && !activating, let err = EngineManager.lastInstallError {
                    Label("Couldn't load this model: \(err). Tap Activate to retry, or Uninstall + redownload.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
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
        Label("Active & ready", systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
    }

    // MARK: Local LLM (Ollama) — auto start / install + model download, fully offline
    @ViewBuilder private var localModelBlock: some View {
        TextField("Model (e.g. qwen2.5:7b)", text: $settings.localLLMModel)
        if engineInstalling {
            HStack { ProgressView().controlSize(.small); Text("Setting up the local engine…").font(.caption).foregroundStyle(.secondary) }
        } else if !ollamaUp {
            HStack {
                Text("Local engine not running.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Set up & start") { setupEngine() }.buttonStyle(.borderedProminent)
            }
        } else if pulling {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: pullProgress).progressViewStyle(.linear)
                Text("Downloading \(settings.localLLMModel)… \(Int(pullProgress * 100))%").font(.caption).foregroundStyle(.secondary)
            }
        } else if ollamaHasModel {
            Label("\(settings.localLLMModel) ready, runs 100% offline.", systemImage: "checkmark.seal.fill")
                .font(.caption).foregroundStyle(.green)
        } else {
            HStack {
                Text("Engine ready. Model not downloaded yet.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Download model") { pullModel() }.buttonStyle(.borderedProminent)
            }
        }
        Text("Reformulation runs entirely on your Mac. We start the local engine for you (and download it if needed). Qwen 2.5 7B recommended (~4.7 GB).")
            .font(.caption).foregroundStyle(.secondary)
            .onAppear { setupEngine() }
    }
    private func setupEngine() {
        engineInstalling = true
        LocalLLM.ensureServer { up in
            if up {
                engineInstalling = false; ollamaUp = true
                LocalLLM.hasModel(settings.localLLMModel) { ollamaHasModel = $0 }
            } else {
                // No engine binary found → download it, then it auto-starts.
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
    /// Select an engine AND actually load its model, with verified feedback. This is the fix
    /// for "downloaded but doesn't work": activation now confirms the model is loaded & ready.
    private func activate(_ e: TranscriptionEngine) {
        settings.engine = e
        activating = true
        EngineManager.lastInstallError = nil
        Task {
            let ok = await EngineManager.load(e)
            await MainActor.run {
                activating = false
                engineRefresh += 1
                if !ok { verifyMsg = "" }   // error surfaces via EngineManager.lastInstallError in the row
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
                if ok { settings.engine = e }   // auto-activate only once fully downloaded
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
                // Restore / re-check, merged in. When already Pro we don't push "Verify",
                // it's just there to re-check if needed.
                TextField("Email used at checkout", text: $settings.proEmail)
                HStack {
                    Button {
                        verifying = true; verifyMsg = ""
                        Task {
                            let ok = await settings.verifyPro()
                            verifying = false
                            verifyMsg = ok ? "Pro unlocked ✓" : "No active subscription for this email."
                        }
                    } label: { Text(verifying ? "Checking…" : (settings.isPro ? "Re-check" : "Verify / restore")) }
                        .disabled(verifying || settings.proEmail.isEmpty)
                    if !verifyMsg.isEmpty { Text(verifyMsg).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    if let u = URL(string: Entitlement.accountURL) {
                        Link("Manage", destination: u).font(.caption)
                    }
                }
            } header: { Text("Your plan") } footer: {
                Text(settings.isPro
                     ? "Thanks! Unlimited dictation, editable mode prompts and custom modes. Your subscription is active for this email."
                     : "Free is a full-Pro trial of \(Entitlement.freeTrialDictations) dictations. Pro ($9.99/mo) unlocks unlimited dictation, editable system prompts and custom modes. Already subscribed? Enter your checkout email and Verify to restore.")
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
            // Plan + restore are merged into one "Your plan" section below.
        }
    }

    // MARK: Referral — pinned to the very top, it's important to us.
    @ViewBuilder private var referralSection: some View {
        Section {
            HStack {
                Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                Spacer()
                Button("Copy") {
                    let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string)
                }
            }
        } header: { Text("Refer friends, give a month, get a month") } footer: {
            Text("Every friend who subscribes through your link and dictates 15,000+ words earns you a free month, unlimited, no cap.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Memory & space — let users reclaim disk without losing their text history.
    @ViewBuilder private var storageSection: some View {
        Section {
            HStack {
                Label("Saved audio & buffers", systemImage: "internaldrive")
                Spacer()
                Text(byteString(cacheBytes)).foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                History.shared.clearAudioCache()
                cacheBytes = History.shared.audioCacheBytes()
            } label: { Label("Clear audio cache (keep history text)", systemImage: "trash") }
            Button(role: .destructive) {
                History.shared.clear()
                cacheBytes = History.shared.audioCacheBytes()
            } label: { Label("Delete all history (text + audio)", systemImage: "trash.fill") }
        } header: { Text("Memory & space") } footer: {
            Text("Audio recordings pile up over time. Clear audio cache frees the disk by deleting saved recordings and temporary buffers while keeping your dictation history (the text). Delete all history removes everything.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onAppear { cacheBytes = History.shared.audioCacheBytes() }
    }

    private func byteString(_ b: Int64) -> String {
        let f = ByteCountFormatter(); f.allowedUnits = [.useMB, .useKB, .useGB]; f.countStyle = .file
        return f.string(fromByteCount: b)
    }

}
