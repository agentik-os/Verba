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

    private var settingsWC: NSWindowController?
    private var historyWC: NSWindowController?
    private var onboardingWC: NSWindowController?
    private var reviewWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()

        HotKey.shared.onPress = { [weak self] in self?.toggleDictation() }
        FnMonitor.shared.onDown = { [weak self] in self?.fnDown() }
        FnMonitor.shared.onUp = { [weak self] in self?.fnUp() }
        applyTriggerMode()

        // Re-apply the trigger whenever the user changes it in Settings.
        Settings.shared.$triggerMode
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyTriggerMode() }
            .store(in: &cancellables)

        LocalTranscriber.shared.onStatus = { [weak self] s in
            DispatchQueue.main.async { guard !s.isEmpty else { return }; self?.statusLine = s; self?.overlay.model.title = s; self?.refreshUI() }
        }

        if !Settings.shared.onboarded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.openOnboarding() }
        }
    }

    private func applyTriggerMode() {
        switch Settings.shared.triggerMode {
        case .hotkey:
            FnMonitor.shared.stop()
            HotKey.shared.register()
        case .fnHold, .fnToggle:
            HotKey.shared.unregister()
            FnMonitor.shared.start()
        }
    }

    // MARK: - Trigger handlers

    private func toggleDictation() {
        switch state {
        case .idle: startRecording()
        case .recording: stopAndProcess()
        case .processing: break
        }
    }
    private func fnDown() {
        switch Settings.shared.triggerMode {
        case .fnHold: if state == .idle { startRecording() }
        case .fnToggle: toggleDictation()
        case .hotkey: break
        }
    }
    private func fnUp() {
        if Settings.shared.triggerMode == .fnHold, state == .recording { stopAndProcess() }
    }

    // MARK: - Dictation flow

    private func startRecording() {
        recorder.requestPermission { [weak self] ok in
            guard let self else { return }
            guard ok else { self.notify("Microphone access denied", "Enable it in System Settings ▸ Privacy & Security ▸ Microphone."); return }
            self.capturedBundleID = Output.frontmostBundleID()
            guard self.recorder.start() else { self.notify("Couldn't start recording", ""); return }
            self.state = .recording
            SoundFX.start()
            self.overlay.model.recording = true
            self.overlay.model.title = "Listening…"
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
        Task {
            do {
                let result = try await Pipeline.run(audioURL: url, frontmostBundleID: bundleID) { [weak self] s in
                    DispatchQueue.main.async { self?.statusLine = s; self?.overlay.model.title = s; self?.refreshUI() }
                }
                await MainActor.run { self.finish(result: result, audioURL: url) }
            } catch {
                await MainActor.run {
                    self.overlay.hide()
                    self.state = .idle
                    self.notify("Awish failed", error.localizedDescription)
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
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Awish")
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
        let trigger = Settings.shared.triggerMode == .hotkey ? HotKey.shared.label : Settings.shared.triggerMode.label
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
        add(menu, "Settings…", #selector(openSettings), ",")
        add(menu, "History…", #selector(openHistory), "y")
        if !Output.accessibilityTrusted {
            add(menu, "Enable auto-paste…", #selector(enableAccessibility), "")
        }
        menu.addItem(.separator())
        add(menu, "Quit Awish", #selector(quit), "q")
        return menu
    }

    private func add(_ menu: NSMenu, _ title: String, _ sel: Selector, _ key: String) {
        let i = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        i.target = self
        menu.addItem(i)
    }

    @objc private func menuToggle() { toggleDictation() }
    @objc private func enableAccessibility() { Output.promptAccessibility() }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Windows

    @objc private func openSettings() {
        if settingsWC == nil { settingsWC = makeWindow(title: "Awish Settings", view: SettingsView(), size: NSSize(width: 560, height: 480)) }
        present(settingsWC)
    }

    @objc private func openHistory() {
        if historyWC == nil { historyWC = makeWindow(title: "Awish History", view: HistoryView(), size: NSSize(width: 780, height: 500)) }
        present(historyWC)
    }

    private func openOnboarding() {
        let view = OnboardingView { [weak self] in
            self?.onboardingWC?.close(); self?.onboardingWC = nil
        }
        onboardingWC = makeWindow(title: "Welcome to Awish", view: view, size: NSSize(width: 560, height: 640))
        present(onboardingWC)
    }

    private func showReview(original: String, text: String, onConfirm: @escaping (String) -> Void) {
        let close: () -> Void = { [weak self] in
            self?.reviewWindow?.close(); self?.reviewWindow = nil
        }
        let view = ReviewView(original: original, text: text,
                              onConfirm: { t in onConfirm(t); close() },
                              onCancel: { close() })
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
                           styleMask: [.titled, .closable], backing: .buffered, defer: false)
        win.title = "Review dictation"
        win.contentViewController = NSHostingController(rootView: view)
        win.center()
        win.isReleasedWhenClosed = false
        reviewWindow = win
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    private func makeWindow<V: View>(title: String, view: V, size: NSSize) -> NSWindowController {
        let win = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        win.title = title
        win.contentViewController = NSHostingController(rootView: view)
        win.center()
        win.isReleasedWhenClosed = false
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
