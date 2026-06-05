import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let recorder = AudioRecorder()
    private let overlay = OverlayController()
    private var levelTimer: Timer?
    private var fnHoldTimer: Timer?
    private var fnActionTaken = false
    private var lastFnDown: Date?
    private var fnPressAt: Date?        // when the current hold started (push-to-talk)
    private let fnHoldThreshold = 0.5   // hold longer than this → release auto-finishes
    private var processingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private enum State { case idle, recording, processing }
    private var state: State = .idle { didSet { refreshUI() } }
    private var statusLine = ""
    private var capturedBundleID: String?
    private var capturedSelection: String?  // text selected in the active app when recording started
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
        Quips.refillIfLow(tone: Settings.shared.quipTone)  // pre-warm the AI-generated loading lines

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()

        ChordMonitor.shared.onChordDown = { [weak self] in self?.chordDown() }
        ChordMonitor.shared.onChordUp = { [weak self] in self?.chordUp() }
        ChordMonitor.shared.onEscape = { [weak self] in self?.escapePressed() }
        ChordMonitor.shared.onControl = { [weak self] in self?.togglePause() }   // ⌃ pauses/resumes
        FnTap.shared.onFnDown = { [weak self] in self?.fnDown() }
        FnTap.shared.onFnUp = { [weak self] in self?.fnUp() }
        FnTap.shared.onDigit = { [weak self] n in self?.fnDigit(n) ?? false }
        FnTap.shared.onArrow = { [weak self] d in self?.fnArrow(d) ?? false }
        FnTap.shared.onEnter = { [weak self] in self?.fnEnter() ?? false }
        overlay.model.onCancel = { [weak self] in self?.cancelEverything() }
        overlay.model.onPauseToggle = { [weak self] in self?.togglePause() }
        overlay.prepare()   // warm the floating panel so it appears instantly
        ChordMonitor.shared.start()
        applyTriggers()
        _ = Updater.shared   // start Sparkle (scheduled background update checks)

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

    func applicationWillTerminate(_ notification: Notification) {
        FnTap.shared.stop()   // restores the system "Press 🌐 to:" setting
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
            win.isOpaque = true
            win.backgroundColor = .windowBackgroundColor   // solid white, no desktop bleed
            let host = NSHostingController(rootView: MainWindow())
            host.sizingOptions = []   // don't let SwiftUI content shrink the window
            win.contentViewController = host
            win.isReleasedWhenClosed = false
            win.contentMinSize = NSSize(width: 900, height: 560)
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
        if !s.useFnAsPrimary, s.primaryHasShortcut {
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
        // Fn-as-primary needs an event tap (to consume the globe key + digit picks).
        if s.useFnAsPrimary { FnTap.shared.start() } else { FnTap.shared.stop() }
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

    private func escapePressed() { cancelEverything() }

    /// Esc / the × in the overlay: discard a recording, abort processing, or dismiss the picker.
    private func cancelEverything() {
        switch state {
        case .recording:
            cancelRecording()
        case .processing:
            processingTask?.cancel(); processingTask = nil
            overlay.model.recording = false; overlay.model.menu = false
            overlay.hide(); SoundFX.stop(); state = .idle
        case .idle:
            if overlay.model.menu { overlay.model.menu = false; overlay.hide(); FnTap.shared.menuActive = false }
        }
    }

    // Fn (globe) as the primary trigger — Wispr-Flow style:
    //   • quick tap (idle) → start recording the ACTIVE mode, latched (tap again to send)
    //   • press & HOLD, then release → push-to-talk: the release sends automatically
    //   • double-tap (a 2nd quick tap right after) → open the mode picker instead
    private func fnDown() {
        guard Settings.shared.useFnAsPrimary else { return }
        if state == .processing { return }
        let now = Date()
        let quick = lastFnDown.map { now.timeIntervalSince($0) < 0.35 } ?? false

        if state == .recording {
            if quick {                       // 2nd tap right after starting → it was a double-tap
                lastFnDown = nil; fnPressAt = nil
                cancelRecording()
                showModeMenu()
            } else {                         // normal tap after speaking → stop & send
                lastFnDown = nil; fnPressAt = nil
                stopAndProcess()
            }
            return
        }
        if overlay.model.menu { dismissMenu(); lastFnDown = nil; return }

        // Idle → record instantly with the active mode. Remember the press so a
        // sustained hold-then-release can auto-finish (push-to-talk).
        lastFnDown = now
        fnPressAt = now
        startRecording(forced: Settings.shared.activeProfile)
    }

    private func fnUp() {
        guard Settings.shared.useFnAsPrimary, state == .recording, let pressed = fnPressAt else { return }
        fnPressAt = nil
        // Held long enough to be a deliberate push-to-talk → release sends.
        // A quick tap leaves it latched (stop on the next tap).
        if Date().timeIntervalSince(pressed) >= fnHoldThreshold {
            lastFnDown = nil
            stopAndProcess()
        }
    }

    private func fnDigit(_ n: Int) -> Bool {
        guard Settings.shared.useFnAsPrimary, overlay.model.menu else { return false }
        let profiles = Settings.shared.profiles
        guard n >= 1, n <= profiles.count else { return false }
        Settings.shared.activeProfileID = profiles[n - 1].id   // picking sets the default too
        dismissMenu()
        trigger(forced: profiles[n - 1])
        return true
    }
    private func fnArrow(_ delta: Int) -> Bool {
        guard overlay.model.menu else { return false }
        let s = Settings.shared
        guard let i = s.profiles.firstIndex(where: { $0.id == s.activeProfileID }), !s.profiles.isEmpty else { return false }
        let next = ((i + delta) % s.profiles.count + s.profiles.count) % s.profiles.count
        s.activeProfileID = s.profiles[next].id            // live-change the default
        overlay.model.activeID = s.activeProfileID
        return true
    }
    private func fnEnter() -> Bool {
        guard overlay.model.menu else { return false }
        dismissMenu()
        trigger(forced: Settings.shared.activeProfile)
        return true
    }
    private func togglePause() {
        guard state == .recording else { return }
        if recorder.isPaused {
            recorder.resume(); overlay.model.paused = false
        } else {
            recorder.pause(); overlay.model.paused = true
        }
    }

    private func dismissMenu() {
        fnHoldTimer?.invalidate(); fnHoldTimer = nil
        lastFnDown = nil
        overlay.model.menu = false
        FnTap.shared.menuActive = false
    }

    private func showModeMenu() {
        let s = Settings.shared
        overlay.model.menu = true
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.profiles = s.profiles
        overlay.model.activeID = s.activeProfileID
        overlay.model.onStart = { [weak self] p in
            Settings.shared.activeProfileID = p.id   // picking sets the default too
            self?.dismissMenu(); self?.trigger(forced: p)
        }
        FnTap.shared.menuActive = true
        overlay.show()
    }

    private func cancelRecording() {
        levelTimer?.invalidate(); levelTimer = nil
        _ = recorder.stop()
        forcedProfile = nil
        overlay.model.menu = false
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.hide()
        SoundFX.stop()
        state = .idle
    }

    // MARK: - Dictation flow

    private func startRecording(forced: Profile?) {
        // The tool is locked until onboarding is finished (no using it from the onboarding).
        if !Settings.shared.onboarded { openOnboarding(); return }
        // Free-tier word limit: block new dictations once the monthly quota is spent.
        if Entitlement.freeLimitReached() { showPaywall(); return }
        recorder.requestPermission { [weak self] ok in
            guard let self else { return }
            guard ok else { self.notify("Microphone access denied", "Enable it in System Settings ▸ Privacy & Security ▸ Microphone."); return }
            self.forcedProfile = forced
            self.capturedBundleID = Output.frontmostBundleID()
            self.capturedSelection = Settings.shared.useSelectionContext ? Output.selectedText() : nil
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
            self.overlay.model.paused = false
            self.overlay.model.recording = true
            self.overlay.model.title = "Listening · \(initial.name)"
            self.overlay.model.level = 0
            self.overlay.show()
            // Minimal style: show the mode name briefly, then leave just the moving bar.
            if Settings.shared.overlayStyle == .minimal {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    guard let self, self.state == .recording else { return }
                    self.overlay.model.title = ""
                    self.overlay.reposition()
                }
            }
            // Drive both the level and the animation phase ourselves so the meter keeps
            // moving even though the focused app (not Verba) owns the run loop.
            let t = Timer(timeInterval: 0.04, repeats: true) { [weak self] _ in
                guard let self else { return }
                let lvl = self.recorder.level()
                self.overlay.model.level = lvl
                // Animation speed follows how energetically you're speaking: quiet → slow,
                // loud/fast speech → a bit faster — but kept gentle so it stays readable.
                self.overlay.model.phase += 0.025 + 0.18 * Double(lvl)
            }
            RunLoop.main.add(t, forMode: .common)
            self.levelTimer = t
        }
    }

    private func stopAndProcess() {
        levelTimer?.invalidate(); levelTimer = nil
        guard let url = recorder.stop() else { state = .idle; overlay.hide(); return }
        SoundFX.stop()
        state = .processing
        statusLine = "Transcribing…"
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.title = "Transcribing…"
        refreshUI()

        let bundleID = capturedBundleID
        let forced = forcedProfile
        let selection = capturedSelection
        forcedProfile = nil
        capturedSelection = nil
        processingTask = Task {
            do {
                let result = try await Pipeline.run(audioURL: url, frontmostBundleID: bundleID, forcedProfile: forced, selection: selection) { [weak self] s in
                    DispatchQueue.main.async { self?.statusLine = s; self?.overlay.model.title = s; self?.refreshUI() }
                }
                if Task.isCancelled { return }
                await MainActor.run { self.processingTask = nil; self.finish(result: result, audioURL: url) }
            } catch is CancellationError {
                // user cancelled — handled by cancelEverything()
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.processingTask = nil
                    self.overlay.hide(); self.overlay.model.recording = false
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
            let rich = Settings.shared.richTextPaste
            if Settings.shared.autoPaste {
                if !Output.paste(text, rich: rich) {
                    Output.copyToClipboard(text, rich: rich)
                    Output.promptAccessibility()
                    self.notify("Copied to clipboard", "Grant Accessibility to enable auto-paste.")
                }
            } else if Settings.shared.copyToClipboard {
                Output.copyToClipboard(text, rich: rich)
            }
            History.shared.add(original: result.original, reprompted: result.reprompted,
                               profileName: result.profileName, engine: result.engine, audioURL: audioURL)
            let dur = self.recordStartedAt.map { Date().timeIntervalSince($0) } ?? 0
            Stats.shared.record(words: wordCount(text), seconds: dur)
            self.flashDone()
        }

        if Settings.shared.reviewBeforeSend {
            overlay.hide()
            state = .idle
            showReview(original: result.original, text: result.reprompted, onConfirm: deliver)
        } else {
            deliver(result.reprompted)
        }
    }

    /// A brief, soft "✓ Done" flash in the overlay instead of an abrupt disappearance.
    private func flashDone() {
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = true
        overlay.model.title = "Done"
        overlay.show()
        SoundFX.done()
        state = .idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { [weak self] in
            guard let self, self.state == .idle else { return }
            self.overlay.model.done = false
            self.overlay.hide()
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
        let s = Settings.shared
        let trigger: String = s.useFnAsPrimary ? "Fn"
            : (s.primaryHasShortcut ? shortcutLabel(keyCode: s.primaryKeyCode, modifiers: s.primaryMods) : "⌃⌥+number")
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
        add(menu, "Check for Updates…", #selector(checkUpdates), "")
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
    @objc private func checkUpdates() { Updater.shared.checkForUpdates() }
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
        if let wc = onboardingWC { present(wc); return }   // already open → just focus it
        let view = OnboardingView { [weak self] in
            self?.onboardingWC?.close(); self?.onboardingWC = nil
        }
        onboardingWC = makeWindow(title: "Welcome to Verba", view: view, size: NSSize(width: 620, height: 720), glass: true)
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
            let host = NSHostingController(rootView: root)
            host.sizingOptions = []
            win.contentViewController = host
        } else {
            let host = NSHostingController(rootView: view)
            host.sizingOptions = []
            win.contentViewController = host
        }
        win.contentMinSize = NSSize(width: min(size.width, 480), height: min(size.height, 360))
        win.setContentSize(size)
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

    /// Shown when a free user hits the monthly word limit.
    private func showPaywall() {
        state = .idle
        overlay.hide()
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "You've reached your free monthly limit"
        a.informativeText = "Free includes \(Entitlement.freeMonthlyWords.formatted()) dictated words per month. Upgrade to Verba Pro for unlimited dictation — $9.99/month."
        a.addButton(withTitle: "Upgrade to Pro")
        a.addButton(withTitle: "I already subscribed")
        a.addButton(withTitle: "Later")
        switch a.runModal() {
        case .alertFirstButtonReturn:
            if let u = URL(string: Entitlement.pricingURL) { NSWorkspace.shared.open(u) }
        case .alertSecondButtonReturn:
            openMain()   // Settings ▸ Plan to restore via email
        default: break
        }
    }
}
