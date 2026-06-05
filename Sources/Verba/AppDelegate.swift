import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let recorder = AudioRecorder()
    private let overlay = OverlayController()
    private var levelTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private enum State { case idle, recording, processing }
    private var state: State = .idle { didSet { refreshUI() } }
    private var statusLine = ""
    private var capturedBundleID: String?
    private var forcedProfile: Profile?     // set when a profile-specific shortcut started the dictation

    private var settingsWC: NSWindowController?
    private var historyWC: NSWindowController?
    private var onboardingWC: NSWindowController?
    private var mainWC: NSWindowController?
    private var reviewWindow: NSWindow?
    private var recordStartedAt: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyDockPolicy()
        installMainMenu()   // menu-bar apps have no main menu → no ⌘C/⌘V in text fields without this

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()

        ChordMonitor.shared.onChordDown = { [weak self] in self?.chordDown() }
        ChordMonitor.shared.onChordUp = { [weak self] in self?.chordUp() }
        ChordMonitor.shared.onEscape = { [weak self] in self?.escapePressed() }
        ChordMonitor.shared.onFnDown = { [weak self] in self?.fnPressed() }
        ChordMonitor.shared.onFnUp = { [weak self] in self?.fnReleased() }
        ChordMonitor.shared.start()
        applyTriggers()

        // Re-apply hotkeys when the primary shortcut, profiles, or Fn option change.
        Publishers.MergeMany(
            Settings.shared.$primaryKeyCode.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$primaryMods.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$profiles.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$useFnAsPrimary.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst()
        .receive(on: RunLoop.main)
        .sink { [weak self] in self?.applyTriggers() }
        .store(in: &cancellables)

        let statusRelay: (String) -> Void = { [weak self] s in
            DispatchQueue.main.async { guard !s.isEmpty else { return }; self?.statusLine = s; self?.overlay.model.title = s; self?.refreshUI() }
        }
        LocalTranscriber.shared.onStatus = statusRelay
        ParakeetTranscriber.shared.onStatus = statusRelay

        // React to the Dock toggle live.
        Settings.shared.$showInDock
            .dropFirst().receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyDockPolicy() }
            .store(in: &cancellables)

        if !Settings.shared.onboarded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.openOnboarding() }
        } else if Settings.shared.showInDock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.openMain() }
        }
    }

    private func applyDockPolicy() {
        NSApp.setActivationPolicy(Settings.shared.showInDock ? .regular : .accessory)
    }

    // Reopen the main window when the user clicks the Dock icon.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { openMain() }
        return true
    }

    @objc private func openMain() {
        if mainWC == nil {
            // Clear any stale saved frame so the window always opens centered.
            UserDefaults.standard.removeObject(forKey: "NSWindow Frame VerbaMain")
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680),
                               styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                               backing: .buffered, defer: false)
            win.title = "Verba"
            win.titlebarAppearsTransparent = true
            win.titleVisibility = .hidden
            win.contentViewController = NSHostingController(rootView: MainWindow())
            win.isReleasedWhenClosed = false
            win.contentMinSize = NSSize(width: 900, height: 560)   // stop the layout squishing when resized
            win.setContentSize(NSSize(width: 1040, height: 680))
            win.center()
            mainWC = NSWindowController(window: win)
        }
        present(mainWC)
    }

    /// A minimal main menu so standard text-editing shortcuts (⌘C/⌘V/⌘X/⌘A/⌘Z)
    /// work in our windows — accessory apps don't get one for free.
    private func installMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Hide Verba", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Verba", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        NSApp.mainMenu = main
    }

    private func applyTriggers() {
        HotKeys.shared.unregisterAll()
        let s = Settings.shared
        // Primary trigger (active/auto-detected profile). When Fn is the primary,
        // it's handled by ChordMonitor.onFn* instead of a Carbon hotkey.
        if !s.useFnAsPrimary {
            HotKeys.shared.register(id: 1, keyCode: s.primaryKeyCode, modifiers: s.primaryMods) { [weak self] in
                self?.trigger(forced: nil)
            }
        }
        // Per-profile dedicated shortcuts (⌃⌥1–6).
        for (i, p) in s.profiles.enumerated() {
            guard let code = p.hotkeyCode, let mods = p.hotkeyMods else { continue }
            let pid = p.id
            HotKeys.shared.register(id: UInt32(100 + i), keyCode: code, modifiers: mods) { [weak self] in
                self?.trigger(forced: Settings.shared.profiles.first { $0.id == pid })
            }
        }
    }

    // MARK: - Trigger handlers

    private func trigger(forced: Profile?) {
        switch state {
        case .idle: startRecording(forced: forced)
        case .recording: stopAndProcess()   // re-press = send (Lock); Direct stops on key release
        case .processing: break
        }
    }

    /// ⌃⌥ held with nothing recording → show the numbered mode picker.
    private func chordDown() {
        guard state == .idle else { return }
        showModeMenu()
    }

    /// ⌃⌥ released.
    private func chordUp() {
        if Settings.shared.recordStyle == .direct, state == .recording {
            stopAndProcess()                 // push-to-talk: release = send
        } else if state == .idle, overlay.model.menu {
            overlay.hide(); overlay.model.menu = false   // dismissed the picker without recording
        }
    }

    private func escapePressed() {
        if state == .recording {
            stopAndProcess()                 // Esc = treat as end of recording → transcribe & send
        } else if state == .idle, overlay.model.menu {
            overlay.hide(); overlay.model.menu = false   // just dismiss the mode picker
        }
    }

    // Fn (globe) as the primary trigger — Wispr-Flow style.
    private func fnPressed() {
        guard Settings.shared.useFnAsPrimary else { return }
        switch Settings.shared.recordStyle {
        case .lock:   trigger(forced: nil)                       // tap to start, tap again to send
        case .direct: if state == .idle { startRecording(forced: nil) }   // hold to talk
        }
    }
    private func fnReleased() {
        guard Settings.shared.useFnAsPrimary,
              Settings.shared.recordStyle == .direct, state == .recording else { return }
        stopAndProcess()                                          // release to send
    }

    private func showModeMenu() {
        let s = Settings.shared
        overlay.model.menu = true
        overlay.model.recording = false
        overlay.model.profiles = s.profiles
        overlay.model.onStart = { [weak self] p in self?.trigger(forced: p) }
        overlay.show()
    }

    private func cancelRecording() {
        levelTimer?.invalidate(); levelTimer = nil
        _ = recorder.stop()
        forcedProfile = nil
        overlay.model.menu = false
        overlay.model.recording = false
        overlay.hide()
        SoundFX.stop()
        state = .idle
    }

    // MARK: - Dictation flow

    private func startRecording(forced: Profile?) {
        recorder.requestPermission { [weak self] ok in
            guard let self else { return }
            guard ok else { self.notify("Microphone access denied", "Enable it in System Settings ▸ Privacy & Security ▸ Microphone."); return }
            self.forcedProfile = forced
            self.capturedBundleID = Output.frontmostBundleID()
            guard self.recorder.start() else { self.notify("Couldn't start recording", ""); return }
            self.recordStartedAt = Date()
            self.state = .recording
            SoundFX.start()

            // Populate the live mode switcher in the overlay.
            let s = Settings.shared
            let initial = forced ?? s.profile(forBundleID: self.capturedBundleID)
            self.overlay.model.profiles = s.repromptEnabled ? s.profiles : []
            self.overlay.model.selectedID = initial.id
            self.overlay.model.onSelect = { [weak self] p in
                self?.forcedProfile = p
                self?.overlay.model.title = "Listening · \(p.name)"
            }
            self.overlay.model.menu = false   // hide the numbers once recording starts
            self.overlay.model.recording = true
            self.overlay.model.title = "Listening · \(initial.name)"
            self.overlay.model.level = 0
            self.overlay.show()
            self.levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.overlay.model.level = self?.recorder.level() ?? 0
            }
        }
    }

    private func stopAndProcess() {
        levelTimer?.invalidate(); levelTimer = nil
        guard let url = recorder.stop() else { state = .idle; overlay.hide(); return }
        SoundFX.stop()
        state = .processing
        statusLine = "Transcribing…"
        overlay.model.recording = false
        overlay.model.title = "Transcribing…"
        refreshUI()

        let bundleID = capturedBundleID
        let forced = forcedProfile
        forcedProfile = nil
        Task {
            do {
                let result = try await Pipeline.run(audioURL: url, frontmostBundleID: bundleID, forcedProfile: forced) { [weak self] s in
                    DispatchQueue.main.async { self?.statusLine = s; self?.overlay.model.title = s; self?.refreshUI() }
                }
                await MainActor.run { self.finish(result: result, audioURL: url) }
            } catch {
                await MainActor.run {
                    self.overlay.hide()
                    self.state = .idle
                    self.notify("Verba failed", error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    private func finish(result: PipelineResult, audioURL: URL) {
        let deliver: (String) -> Void = { [weak self] text in
            guard let self else { return }
            if Settings.shared.autoPaste {
                if !Output.paste(text) {
                    Output.copyToClipboard(text)
                    Output.promptAccessibility()
                    self.notify("Copied to clipboard", "Grant Accessibility to enable auto-paste.")
                }
            } else if Settings.shared.copyToClipboard {
                Output.copyToClipboard(text)
            }
            History.shared.add(original: result.original, reprompted: result.reprompted,
                               profileName: result.profileName, engine: result.engine, audioURL: audioURL)
            let dur = self.recordStartedAt.map { Date().timeIntervalSince($0) } ?? 0
            Stats.shared.record(words: wordCount(text), seconds: dur)
            self.overlay.hide()
            self.state = .idle
        }

        if Settings.shared.reviewBeforeSend {
            overlay.hide()
            state = .idle
            showReview(original: result.original, text: result.reprompted, onConfirm: deliver)
        } else {
            SoundFX.done()
            deliver(result.reprompted)
        }
    }

    // MARK: - Status item / menu

    private func refreshUI() {
        guard let button = statusItem.button else { return }
        let symbol: String
        switch state {
        case .idle: symbol = "mic"
        case .recording: symbol = "mic.fill"
        case .processing: symbol = "waveform"
        }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Verba")
        button.image?.isTemplate = true
        button.contentTintColor = (state == .recording) ? .systemRed : nil
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let title: String
        switch state {
        case .idle: title = "Start dictation"
        case .recording: title = "Stop & process"
        case .processing: title = statusLine.isEmpty ? "Working…" : statusLine
        }
        let trigger = shortcutLabel(keyCode: Settings.shared.primaryKeyCode, modifiers: Settings.shared.primaryMods)
        let item = NSMenuItem(title: "\(title)  (\(trigger))", action: #selector(menuToggle), keyEquivalent: "")
        item.target = self
        item.isEnabled = state != .processing
        menu.addItem(item)

        if state == .processing {
            let p = NSMenuItem(title: statusLine, action: nil, keyEquivalent: "")
            p.isEnabled = false
            menu.addItem(p)
        }

        menu.addItem(.separator())
        let engineItem = NSMenuItem(title: "Engine: \(Settings.shared.engine.label)", action: nil, keyEquivalent: "")
        engineItem.isEnabled = false
        menu.addItem(engineItem)

        menu.addItem(.separator())
        add(menu, "Open Verba", #selector(openMain), "o")
        add(menu, "Settings…", #selector(openSettings), ",")
        add(menu, "History…", #selector(openHistory), "y")
        if !Output.accessibilityTrusted {
            add(menu, "Enable auto-paste…", #selector(enableAccessibility), "")
        }
        menu.addItem(.separator())
        add(menu, "Quit Verba", #selector(quit), "q")
        return menu
    }

    private func add(_ menu: NSMenu, _ title: String, _ sel: Selector, _ key: String) {
        let i = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        i.target = self
        menu.addItem(i)
    }

    @objc private func menuToggle() { trigger(forced: nil) }
    @objc private func enableAccessibility() { Output.promptAccessibility() }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Windows

    @objc private func openSettings() {
        if settingsWC == nil { settingsWC = makeWindow(title: "Verba Settings", view: SettingsView(), size: NSSize(width: 560, height: 480)) }
        present(settingsWC)
    }

    @objc private func openHistory() {
        if historyWC == nil { historyWC = makeWindow(title: "Verba History", view: HistoryView(), size: NSSize(width: 780, height: 500)) }
        present(historyWC)
    }

    private func openOnboarding() {
        let view = OnboardingView { [weak self] in
            self?.onboardingWC?.close(); self?.onboardingWC = nil
        }
        onboardingWC = makeWindow(title: "Welcome to Verba", view: view, size: NSSize(width: 560, height: 660), glass: true)
        present(onboardingWC)
    }

    private func showReview(original: String, text: String, onConfirm: @escaping (String) -> Void) {
        let close: () -> Void = { [weak self] in
            self?.reviewWindow?.close(); self?.reviewWindow = nil
        }
        let view = ReviewView(original: original, text: text,
                              onConfirm: { t in onConfirm(t); close() },
                              onCancel: { close() })
        let wc = makeWindow(title: "Review dictation", view: view, size: NSSize(width: 520, height: 420), glass: true, resizable: false)
        reviewWindow = wc.window
        present(wc)
    }

    private func makeWindow<V: View>(title: String, view: V, size: NSSize,
                                     glass: Bool = false, resizable: Bool = true) -> NSWindowController {
        var style: NSWindow.StyleMask = [.titled, .closable]
        if resizable { style.insert(.resizable) }
        if glass { style.insert(.fullSizeContentView) }
        let win = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: style, backing: .buffered, defer: false)
        win.title = title
        win.titlebarAppearsTransparent = true   // unified, less heavy chrome
        win.isReleasedWhenClosed = false
        if glass {
            // Frosted-glass panel: material fills the whole window; SwiftUI content
            // still respects the titlebar safe area automatically.
            win.titleVisibility = .hidden
            win.isOpaque = false
            win.backgroundColor = .clear
            win.isMovableByWindowBackground = true
            let root = view.background(VisualEffectView().ignoresSafeArea())
            win.contentViewController = NSHostingController(rootView: root)
        } else {
            win.contentViewController = NSHostingController(rootView: view)
        }
        win.center()
        return NSWindowController(window: win)
    }

    private func present(_ wc: NSWindowController?) {
        NSApp.activate(ignoringOtherApps: true)
        wc?.showWindow(nil)
        wc?.window?.makeKeyAndOrderFront(nil)
    }

    private func notify(_ title: String, _ body: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = body
        a.runModal()
    }
}
