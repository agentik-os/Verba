import AppKit
import SwiftUI
import Combine
import IOKit.hid

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let recorder = AudioRecorder()
    private let overlay = OverlayController()
    private var levelTimer: Timer?
    private var quipTimer: Timer?
    private var statusPulseTimer: Timer?
    private var fnHoldTimer: Timer?
    private var fnActionTaken = false
    private var lastFnDown: Date?
    private var fnPressAt: Date?        // when the current hold started (push-to-talk)
    private var fnToggleStopArmed = false   // tap-toggle: a Fn tap landed mid-recording; release decides stop vs. switch-mode
    private var fnToggleSwitched = false    // a long Fn hold already cycled the mode this press → release must not stop
    private let fnSwitchThreshold = 0.6     // tap-toggle: hold Fn ≥ this (mid-recording) → switch mode & keep listening; a quick stop tap (well under this) → stop & send. Widened from 0.4 so stop-vs-switch has a humanly-distinguishable dead-band.
    private let fnHoldThreshold = 0.8   // hold longer than this → release auto-finishes; a
                                        // deliberate "tap" (≤0.8s) latches for hands-free listening
    // Each in-flight Session runs its own concurrent processing Task, keyed by Session id, so
    // several dictations can transcribe/reprompt in parallel (the recorder is free the instant a
    // recording stops). Esc cancels them all. The old single-session `processingTask` is gone.
    private var sessionTasks: [UUID: Task<Void, Never>] = [:]
    private let processingTimeout: Double = 180   // hard ceiling on transcribe+reprompt so a hung backend can't spin forever
    private var cancellables = Set<AnyCancellable>()
    private var tapPermissionNagged = false   // show the "grant Fn permission" alert at most once
    private var lastAudioURL: URL?            // #8: last recording, to redo in another mode
    private var lastResultText: String?       // #2: last delivered text, to edit by voice
    private var editLastInstruction = false   // #2: next dictation edits lastResultText
    private var lastDelivered: String?        // auto-learn: text just pasted, to diff vs manual edits
    private var lastDeliveredBundle: String?  // app it was pasted into

    private enum State { case idle, recording, processing }
    // `state` is the DISPLAY state of the overlay/menu-bar icon (idle / recording / processing).
    // It no longer gates the recorder: a new recording can begin while older Sessions process.
    // The recorder is busy only while `state == .recording`; processing lives in concurrent
    // Sessions (see sessionTasks / SessionStore), so handing a recording off frees the recorder.
    private var state: State = .idle { didSet { refreshUI() } }

    /// Everything one record→process→deliver run needs, snapshotted when the recording stops so
    /// the Session's concurrent Task is self-contained and never reads a field a newer recording
    /// has since overwritten. Mirrors the instance fields the old single-session finish() used.
    private struct SessionContext {
        let session: Session
        let audioURL: URL
        let capturedTarget: PasteTarget?
        let capturedBundleID: String?
        let recordStartedAt: Date?
        let countStats: Bool
        var actionMode: Bool = false   // Fn+X Action mode: route through the agentic-action (confirm→execute) path
    }
    private var statusLine = ""
    private var capturedBundleID: String?
    private var capturedTarget: PasteTarget?  // app + focused field captured at record start, so auto-paste can restore focus across Space/app switches
    private var capturedSelection: String?  // text selected in the active app when recording started
    private var forcedProfile: Profile?     // set when a profile-specific shortcut started the dictation
    private var actionModeRecording = false  // Fn+X Action mode: this recording's request CONTROLS the Mac (confirm → execute)

    private var todoCaptureRecording = false   // a voice "add to-do" capture is recording
    private var todoCaptureTask: Task<Void, Never>?
    private var noteLevelTimer: Timer?         // drives the shared overlay's waveform while a note records (NotesView owns the recorder)
    // Set when stopTodoCapture() runs from the bare-Fn half of a Fn+§ stop chord; swallows the
    // §-keyDown's startTodoCapture() that follows on the same chord so it doesn't restart capture.
    private var todoCaptureJustStopped = false

    private var settingsWC: NSWindowController?
    private var historyWC: NSWindowController?
    private var sessionsWC: NSWindowController?
    private var onboardingWC: NSWindowController?
    private var mainWC: NSWindowController?
    private var reviewWindow: NSWindow?
    private var actionWindow: NSWindow?
    private var recordStartedAt: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyDockPolicy()
        installMainMenu()   // menu-bar apps have no main menu → no ⌘C/⌘V in text fields without this
        Quips.refillIfLow(tone: Settings.shared.quipTone)  // pre-warm the AI-generated loading lines
        EngineManager.seedBundledModels()   // copy the app-bundled Parakeet model into cache (first run, offline-instant)
        preloadEngine()   // load the local transcription model now so the first dictation is instant
        // Re-check the real subscription on launch so Pro reflects Stripe, not just sign-in.
        if !Settings.shared.proEmail.isEmpty {
            Task { _ = await Settings.shared.verifyPro() }
            Task { await Username.reconcileOnSignIn() }  // adopt the Clerk username so the handle syncs across Macs
            History.shared.syncFromCloud()   // pull dictation history from the user's other Macs
            Stats.shared.syncFromCloud()     // restore Insights / Total Words for the account
            NotesStore.shared.syncFromCloud()// pull long-form notes for the account
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()

        ChordMonitor.shared.onChordDown = { [weak self] in self?.chordDown() }
        ChordMonitor.shared.onChordUp = { [weak self] in self?.chordUp() }
        ChordMonitor.shared.onEscape = { [weak self] in self?.escapePressed() }
        ChordMonitor.shared.onControl = { [weak self] in InputCoach.shared.note(.control); self?.togglePause() }   // ⌃ pauses/resumes
        FnTap.shared.onFnDown = { [weak self] in self?.fnDown() }
        FnTap.shared.onFnUp = { [weak self] in self?.fnUp() }
        FnTap.shared.onFnControl = { [weak self] in self?.fnControlPressed() }   // ⌥+Fn → today's to-do glance
        FnTap.shared.onModeCycle = { [weak self] dir in self?.modeCycleGesture(dir) }   // Fn+Tab → next/prev mode
        FnTap.shared.onStyleCycle = { [weak self] dir in self?.styleCycleGesture(dir) } // Fn+[ / Fn+] → prev/next style
        FnTap.shared.onNoteRecord = { [weak self] in self?.startNoteRecording() }   // Fn+Z → record a note
        FnTap.shared.onTodoCapture = { [weak self] in self?.startTodoCapture() }    // Fn+§ → add a to-do
        FnTap.shared.onActionMode = { [weak self] in self?.startActionMode() }      // Fn+X → Action mode (speech controls the Mac)
        FnTap.shared.onDigit = { [weak self] n in self?.fnDigit(n) ?? false }
        FnTap.shared.onArrow = { [weak self] d in self?.fnArrow(d) ?? false }
        FnTap.shared.onEnter = { [weak self] in self?.fnEnter() ?? false }
        FnTap.shared.onControl = { [weak self] in InputCoach.shared.note(.control); self?.togglePause() }   // ⌃ pauses/resumes (reliable HID-tap path when Fn is primary)
        FnTap.shared.onOptionTap = { [weak self] in self?.optionTapped() }   // lone ⌥ tap while hands-free recording → next mode
        overlay.model.onCancel = { [weak self] in self?.cancelEverything() }
        overlay.model.onPauseToggle = { [weak self] in self?.togglePause() }
        overlay.prepare()   // warm the floating panel so it appears instantly
        ChordMonitor.shared.start()
        // Don't request any permission before the user reaches the onboarding permissions
        // slide. Until onboarded we only suppress the globe/emoji HUD (no prompt); the Fn
        // event tap (which would request Input Monitoring) starts once onboarding is done.
        if Settings.shared.onboarded {
            applyTriggers()
            recorder.prewarm()   // pre-arm the mic so the first Fn-press captures from the first word
        } else {
            FnSystemPref.suppress()
        }
        _ = Updater.shared   // start Sparkle (scheduled background update checks)
        // Silent check shortly after launch so the menu/icon reflect availability without a popup.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { Updater.shared.checkInBackground() }
        // When Sparkle's delegate flips update availability, rebuild the menu + re-badge the icon.
        Updater.shared.$updateAvailable
            .removeDuplicates().receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshUI() }
            .store(in: &cancellables)
        TodoReminders.shared.start()   // schedule "30 min before deadline" to-do reminders, keep them in sync
        WidgetBridge.shared.start()    // keep the WidgetKit "Today" snapshot in sync with the TodoStore

        // Re-apply hotkeys when the primary shortcut, profiles, or Fn option change.
        Publishers.MergeMany(
            Settings.shared.$primaryKeyCode.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$primaryMods.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$modePickerKeyCode.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$modePickerMods.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$profiles.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$useFnAsPrimary.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst()
        .receive(on: RunLoop.main)
        .sink { [weak self] in self?.applyTriggers() }
        .store(in: &cancellables)

        // Show/hide the menu-bar icon live when toggled in Settings.
        Settings.shared.$showMenuBarIcon
            .dropFirst().receive(on: RunLoop.main)
            .sink { [weak self] show in self?.statusItem.isVisible = show }
            .store(in: &cancellables)

        // "Capture by voice" button (or a future shortcut) → start/stop a voice to-do capture.
        TodoCaptureController.shared.$captureSignal
            .dropFirst().receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.startTodoCapture() }
            .store(in: &cancellables)

        // A note records in the Notes window via its own recorder, but it shows the SAME floating
        // pill as dictation (labelled "Note"). Drive that overlay from the shared controller so the
        // pill, Control-pause and the × all work for note recording too.
        NotesController.shared.$isRecording
            .removeDuplicates().receive(on: RunLoop.main)
            .sink { [weak self] rec in rec ? self?.showNoteOverlay() : self?.hideNoteOverlay() }
            .store(in: &cancellables)
        // Mirror NotesView's paused state onto the pill.
        NotesController.shared.$paused
            .removeDuplicates().receive(on: RunLoop.main)
            .sink { [weak self] p in guard let self, NotesController.shared.isRecording else { return }
                self.overlay.model.paused = p
                self.overlay.model.title = p ? "Paused" : CaptureContext.note.label }
            .store(in: &cancellables)

        // Keep the menu-bar dropdown's "Default mode" list in sync when modes are added,
        // removed, or the default changes anywhere (the menu is rebuilt in refreshUI).
        Publishers.MergeMany(
            Settings.shared.$profiles.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$activeProfileID.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$triggerStyle.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst().receive(on: RunLoop.main)
        .sink { [weak self] in self?.refreshUI() }
        .store(in: &cancellables)

        // Propagate an alias change to the shared leaderboard (debounced while typing) so the
        // new username shows everywhere, for everyone.
        Settings.shared.$username
            .dropFirst()
            .debounce(for: .seconds(0.9), scheduler: RunLoop.main)
            .sink { name in
                Leaderboard.submit()
                // Push the new public handle to Clerk so it syncs to the web + other Macs.
                let email = Settings.shared.proEmail
                if !email.isEmpty { Task { await Username.push(name, email: email) } }
            }
            .store(in: &cancellables)

        // Signing in after launch: verify Pro, push anything dictated while signed out, pull history.
        Settings.shared.$proEmail
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { email in
                guard !email.isEmpty else { return }
                Task { _ = await Settings.shared.verifyPro() }
                Task { await Username.reconcileOnSignIn() }  // pull the account's Clerk username (or seed it)
                History.shared.pushAll()
                History.shared.syncFromCloud()
                Stats.shared.pushAll()        // push stats accrued while signed out
                Stats.shared.syncFromCloud()  // merge in stats from the account's other Macs
                NotesStore.shared.pushAll()
                NotesStore.shared.syncFromCloud()
            }
            .store(in: &cancellables)

        let statusRelay: (String) -> Void = { [weak self] s in
            DispatchQueue.main.async { guard !s.isEmpty else { return }; self?.statusLine = s; self?.refreshUI() }   // jokes own the overlay title during processing
        }
        LocalTranscriber.shared.onStatus = statusRelay
        ParakeetTranscriber.shared.onStatus = statusRelay

        // React to the Dock toggle live.
        Settings.shared.$showInDock
            .dropFirst().receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyDockPolicy() }
            .store(in: &cancellables)

        // Preload the model when the user switches engine / model so it's warm next time.
        Publishers.MergeMany(
            Settings.shared.$engine.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$localModel.map { _ in () }.eraseToAnyPublisher(),
            Settings.shared.$repromptBackend.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst().debounce(for: .seconds(0.4), scheduler: RunLoop.main)
        .sink { [weak self] in self?.preloadEngine() }
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

    /// Re-check the subscription whenever the app regains focus (e.g. right after the
    /// user upgrades in the browser), so Pro unlocks without a relaunch.
    func applicationDidBecomeActive(_ notification: Notification) {
        if !Settings.shared.proEmail.isEmpty {
            Task { _ = await Settings.shared.verifyPro() }
        }
        // Self-heal the Fn suppression: if something (e.g. System Settings) reset "Press 🌐 to"
        // back to Change Input Source / Emoji, re-force it whenever Verba regains focus.
        if Settings.shared.useFnAsPrimary { FnSystemPref.reapplyIfDrifted() }
        // Apply any task check-offs the user made from the widget while we were inactive.
        WidgetBridge.shared.syncFromWidget()
    }

    private func applyDockPolicy() {
        NSApp.setActivationPolicy(Settings.shared.showInDock ? .regular : .accessory)
    }

    /// Load the active local model into memory ahead of time so the first dictation doesn't
    /// pay the multi-second cold-load. Runs in the background; no-op for cloud engines.
    private func preloadEngine() {
        let s = Settings.shared
        if s.engine.isLocal {
            // Auto-download the on-device model if it isn't there yet, then warm + mark it ready.
            // Routed through EngineManager.load so the "Active & ready" state stays truthful.
            Task.detached(priority: .utility) {
                if !EngineManager.isInstalled(s.engine) {
                    _ = await EngineManager.install(s.engine)
                }
                _ = await EngineManager.load(s.engine)
            }
        }
        if s.repromptBackend == .localLLM { LocalLLM.ensureServer { _ in } }   // warm the local LLM server
        // Warm the Claude Code path lookup off the reprompt path (its login-shell probe is slow).
        Task.detached(priority: .utility) { _ = ClaudeCode.isAvailable }
    }

    // Reopen the main window when the user clicks the Dock icon.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { openMain() }
        return true
    }

    /// When Fn is the primary trigger, pressing Fn instantly starts a dictation (push-to-talk).
    /// So a Fn+Z / Fn+§ chord arrives a beat AFTER that dictation already latched to `.recording`.
    /// This discards that just-auto-started dictation (no send) so the chord can run the note/to-do
    /// flow instead. Returns true when it tore one down. `fnPressAt != nil` proves the in-flight
    /// recording belongs to the current bare-Fn hold (and isn't an unrelated, deliberate dictation).
    @discardableResult
    private func abortPhantomFnDictation() -> Bool {
        guard state == .recording, fnPressAt != nil else { return false }
        fnPressAt = nil; lastFnDown = nil
        cancelRecording()   // stop + discard the nascent dictation, back to idle (no transcription)
        return true
    }

    /// Fn + Z (or a custom shortcut): open the Notes tab and immediately start a new note recording.
    @objc func startNoteRecording() {
        guard Settings.shared.onboarded else { openOnboarding(); return }
        cancelToggleHold()   // Fn+Z is a chord → don't let the Fn release stop/switch a tap-toggle recording
        // Fn+Z chord: the bare Fn already auto-started a dictation — discard it and record a note.
        abortPhantomFnDictation()
        // Any OTHER in-flight dictation (a deliberate one, no Fn hold) must not collide with a note.
        if state == .recording { return }
        // A voice to-do capture holds the shared mic while it records (state stays .idle): a note
        // recorder couldn't grab the input and the user would loop on "Couldn't start". Drop the Fn+Z.
        if todoCaptureRecording { return }
        // Free the pre-armed mic: the main recorder stays prepared (holding the audio input) while
        // idle, which made the Notes window's separate recorder fail to start ("Couldn't start
        // recording") and the user retry in a loop. Release it so the note can grab the mic.
        recorder.releaseArmed()
        // A note records in the Notes window (its recorder card shows a "Note" context badge),
        // not on the floating pill — so no overlay.show()/context here.
        NotesController.shared.pendingRecord = true
        openMain()
        DispatchQueue.main.async { NotesController.shared.navSignal &+= 1 }
    }

    /// Fn + X — Action mode: record a spoken COMMAND that controls the Mac (run a Shortcut, open an
    /// app, play music, send a message, create an event/reminder/email…). It records exactly like a
    /// dictation (same floating pill, here badged "Action"), but the result is routed through the
    /// agentic-action vision path: screenshot → vision model → structured action → CONFIRM → execute.
    /// Nothing happens to the Mac without the confirmation sheet (showActionConfirm). It works
    /// regardless of the active mode or the Labs "Agentic actions" toggle.
    @objc func startActionMode() {
        guard Settings.shared.onboarded else { openOnboarding(); return }
        cancelToggleHold()   // Fn+X is a chord → don't let the Fn release stop/switch a tap-toggle recording
        // Fn+X chord: the bare Fn already auto-started a dictation — discard it and record an action.
        abortPhantomFnDictation()
        // Don't collide with any OTHER in-flight capture (deliberate dictation / note / to-do).
        if state == .recording || todoCaptureRecording || NotesController.shared.isRecording { return }
        actionModeRecording = true
        startRecording(forced: nil)
        // Badge the pill as "Action" once recording is actually live (startRecording sets it to
        // .dictation on the async permission callback, so re-stamp it on the next runloop hop).
        DispatchQueue.main.async { [weak self] in
            guard let self, self.state == .recording, self.actionModeRecording else { return }
            self.overlay.model.context = .action
            self.overlay.model.modeName = ""
            self.overlay.model.profiles = []   // Action mode isn't a reprompt mode → no live switcher
            self.overlay.model.title = "Listening · Action"
        }
    }

    /// Show the shared floating pill for an in-progress NOTE recording (labelled "Note"), with a
    /// working pause/resume and ×. The note's audio lives in NotesView's own recorder, so the
    /// waveform is fed from the level NotesView publishes on the shared controller.
    private func showNoteOverlay() {
        // Don't fight a real dictation/to-do capture for the pill.
        guard state == .idle, !todoCaptureRecording else { return }
        overlay.model.menu = false
        overlay.model.done = false
        overlay.model.error = false
        overlay.model.info = false
        overlay.model.modeHint = false
        overlay.model.profiles = []          // a note isn't a dictation mode → no live switcher
        overlay.model.paused = NotesController.shared.paused
        overlay.model.context = .note
        overlay.model.modeName = ""
        overlay.model.recording = true
        overlay.model.title = NotesController.shared.paused ? "Paused" : CaptureContext.note.label
        overlay.model.level = 0
        overlay.show()
        noteLevelTimer?.invalidate()
        let t = Timer(timeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self, NotesController.shared.isRecording else { return }
            let lvl = NotesController.shared.paused ? 0 : NotesController.shared.level
            self.overlay.model.level = lvl
            self.overlay.model.phase += 0.025 + 0.18 * Double(lvl)
        }
        RunLoop.main.add(t, forMode: .common)
        noteLevelTimer = t
    }

    /// Tear the note pill down when the note recording stops (NotesView handles transcription UI).
    private func hideNoteOverlay() {
        noteLevelTimer?.invalidate(); noteLevelTimer = nil
        // Only clear the pill if it's still showing the note (don't stomp a dictation that started).
        guard overlay.model.context == .note else { return }
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.context = .dictation
        overlay.model.title = ""
        if state == .idle { overlay.hide() }
    }

    /// Voice "add to-do" capture: record a short request, transcribe it with the current
    /// engine, then hand it to the routing agent which understands the project▸task▸subtask
    /// model and places the tasks into TodoStore (existing project match or a new one).
    /// First call starts recording; a second call (or pressing the button again) stops & processes.
    @objc func startTodoCapture() {
        guard Settings.shared.onboarded else { openOnboarding(); return }
        cancelToggleHold()   // Fn+§ is a chord → don't let the Fn release stop/switch a tap-toggle recording
        // A bare-Fn tap already stopped this capture (Fn+§ stop chord): swallow the trailing
        // §-keyDown so it doesn't immediately restart a new capture.
        if todoCaptureJustStopped { todoCaptureJustStopped = false; return }
        // Fn+§ chord: the bare Fn already auto-started a dictation — discard it and capture a to-do.
        // (No-op for the toggle's second press, where nothing is recording on the pill.)
        abortPhantomFnDictation()
        // Don't collide with any OTHER in-flight dictation.
        guard state == .idle else { return }

        if todoCaptureRecording {                       // second press → stop & process
            stopTodoCapture()
            return
        }

        recorder.requestPermission { [weak self] ok in
            guard let self else { return }
            guard ok else { self.finishTodoCapture(error: "Microphone access denied."); return }
            // Fresh cold start: the shared recorder was re-armed by the phantom-Fn abort; reusing
            // that hastily-prepared recorder captured silence, so build a clean one.
            self.recorder.releaseArmed()
            guard self.recorder.start() else { self.finishTodoCapture(error: "Couldn't start recording."); return }
            self.todoCaptureRecording = true
            TodoCaptureController.shared.lastError = nil
            TodoCaptureController.shared.capturing = true
            self.overlay.model.menu = false
            self.overlay.model.done = false
            self.overlay.model.error = false
            self.overlay.model.info = false
            self.overlay.model.modeHint = false
            self.overlay.model.paused = false
            self.overlay.model.context = .todo
            self.overlay.model.modeName = ""   // a to-do capture isn't reprompted through a mode
            self.overlay.model.recording = true
            self.overlay.model.title = "Listening · To-do"
            self.overlay.model.level = 0
            self.overlay.show()
            // Drive the live meter ourselves (the focused app owns the run loop) so the user sees
            // it actually listening — the same timer the dictation flow uses.
            let t = Timer(timeInterval: 0.04, repeats: true) { [weak self] _ in
                guard let self else { return }
                let lvl = self.recorder.level()
                self.overlay.model.level = lvl
                self.overlay.model.phase += 0.025 + 0.18 * Double(lvl)
            }
            RunLoop.main.add(t, forMode: .common)
            self.levelTimer = t
        }
    }

    /// Stop an in-progress voice to-do capture and hand it off for transcription/routing.
    /// Used by the Fn+§ toggle's second press AND by a bare-Fn tap (so the user needn't
    /// re-press the chord to finish).
    private func stopTodoCapture() {
        guard todoCaptureRecording else { return }
        todoCaptureRecording = false
        // The §-keyDown of a Fn+§ stop chord fires right after this bare-Fn half; latch a one-shot
        // guard so its startTodoCapture() swallows itself instead of starting a fresh capture.
        todoCaptureJustStopped = true
        DispatchQueue.main.async { [weak self] in self?.todoCaptureJustStopped = false }
        levelTimer?.invalidate(); levelTimer = nil
        let url = recorder.stop()
        overlay.model.recording = false
        if let url { processTodoCapture(url) }
        else { finishTodoCapture(error: "Couldn't capture audio.") }
    }

    /// Transcribe the captured audio, then route it through TodoAgent into TodoStore.
    private func processTodoCapture(_ url: URL) {
        overlay.model.recording = false
        overlay.model.title = "Adding to your tasks…"
        overlay.show()
        todoCaptureTask?.cancel()
        todoCaptureTask = Task { [weak self] in
            do {
                let s = Settings.shared
                let transcriber: Transcriber
                switch s.engine {
                case .openAI:   transcriber = OpenAITranscriber()
                case .whisper:  transcriber = LocalTranscriber.shared
                case .parakeet: transcriber = ParakeetTranscriber.shared
                }
                let readable = try await AudioInput.readable(url)
                defer { AudioInput.cleanup(readable, original: url) }
                var text = try await transcriber.transcribe(fileURL: readable,
                    language: s.language.isEmpty ? nil : s.language, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                if Task.isCancelled { return }
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    await MainActor.run { self?.finishTodoCapture(error: "Didn't catch that — try again.") }
                    return
                }

                let plan = try await TodoAgent.route(transcript: text, projects: TodoStore.shared.projects)
                if Task.isCancelled { return }
                await MainActor.run {
                    let store = TodoStore.shared
                    // Check off any existing items the user reported as done.
                    let completed = plan.completions.count
                    for c in plan.completions {
                        if let sid = c.subtaskID { store.markSubtaskDone(subtaskID: sid) }
                        else { store.markDone(taskID: c.taskID) }
                    }
                    // Apply EVERY project operation: append to an existing project or create a
                    // new one. A single spoken request can touch several projects at once.
                    var touchedProjects = 0
                    for op in plan.projectOps where !op.tasks.isEmpty {
                        if let pid = op.existingProjectID {
                            store.appendTasks(pid, op.tasks)
                        } else {
                            store.addGenerated(name: op.newProjectName ?? "New project", tasks: op.tasks)
                        }
                        touchedProjects += 1
                    }
                    // Overlay feedback reflects what actually happened: pure-complete vs
                    // pure-add vs both, and how many projects were touched. (A no-match completion
                    // falls back to an Inbox add in route(), so nothing is ever silently dropped.)
                    let message: String
                    if touchedProjects > 0 && completed > 0 {
                        message = "Updated your tasks"
                    } else if completed > 0 {
                        message = completed == 1 ? "Marked done" : "Marked \(completed) done"
                    } else if touchedProjects > 1 {
                        message = "Added to \(touchedProjects) projects"
                    } else {
                        message = "Added to your tasks"
                    }
                    self?.finishTodoCapture(error: nil, success: message)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { self?.finishTodoCapture(error: error.localizedDescription) }
            }
        }
    }

    /// Tear down a capture: flash done/error on the overlay and reset state.
    /// `success` is the done-flash message when there's no error (e.g. "Marked done").
    private func finishTodoCapture(error: String?, success: String = "Added to your tasks") {
        todoCaptureRecording = false
        levelTimer?.invalidate(); levelTimer = nil
        todoCaptureTask = nil
        TodoCaptureController.shared.capturing = false
        TodoCaptureController.shared.lastError = error
        overlay.model.recording = false
        overlay.model.paused = false
        if let error {
            overlay.model.error = true
            overlay.model.title = error
        } else {
            overlay.model.done = true
            overlay.model.title = success
        }
        overlay.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + (error == nil ? 1.3 : 2.0)) { [weak self] in
            guard let self, !self.todoCaptureRecording else { return }
            self.overlay.model.done = false
            self.overlay.model.error = false
            self.overlay.model.title = ""
            self.overlay.model.context = .dictation   // back to the default context
            if self.state == .idle { self.overlay.hide() }
        }
    }

    @objc private func openMain() {
        // The app stays locked behind onboarding: never open the main window until it's done.
        guard Settings.shared.onboarded else { openOnboarding(); return }
        if mainWC == nil {
            // Clear any stale saved frame so the window always opens centered.
            UserDefaults.standard.removeObject(forKey: "NSWindow Frame VerbaMain")
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 860),
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
            win.contentMinSize = NSSize(width: 900, height: 600)
            win.setContentSize(NSSize(width: 1040, height: 860))
            win.center()
            mainWC = NSWindowController(window: win)
        }
        present(mainWC)
    }

    /// A minimal main menu so standard text-editing shortcuts (⌘C/⌘V/⌘X/⌘A/⌘Z)
    /// work in our windows, accessory apps don't get one for free.
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
        // Global "open mode picker" shortcut. (Mode switching also lives on Fn+Tab and Fn+1-9;
        // ⌥+Fn now pops the to-do glance, not the picker.)
        if s.modePickerHasShortcut {
            HotKeys.shared.register(id: 2, keyCode: s.modePickerKeyCode, modifiers: s.modePickerMods) { [weak self] in
                self?.changeMode()
            }
        }
        // Global "record a new note" shortcut (in addition to Fn + Z).
        if s.noteRecordHasShortcut {
            HotKeys.shared.register(id: 3, keyCode: s.noteRecordKeyCode, modifiers: s.noteRecordMods) { [weak self] in
                self?.startNoteRecording()
            }
        }
        // Per-profile dedicated shortcuts (⌃⌥1-6).
        for (i, p) in s.profiles.enumerated() {
            guard let code = p.hotkeyCode, let mods = p.hotkeyMods else { continue }
            let pid = p.id
            HotKeys.shared.register(id: UInt32(100 + i), keyCode: code, modifiers: mods) { [weak self] in
                self?.trigger(forced: Settings.shared.profiles.first { $0.id == pid })
            }
        }
        // Fn-as-primary needs an event tap (to consume the globe key + digit picks).
        if s.useFnAsPrimary {
            // If the tap can't be created, Accessibility/Input-Monitoring was revoked
            // (common after a rebuild/re-sign). Surface it instead of silently doing nothing.
            if !FnTap.shared.start() { promptTapPermissions() }
        } else {
            FnTap.shared.stop()
        }
        // Rebuild the menu (incl. the Keyboard Shortcuts cheat-sheet) so it reflects the new
        // trigger setting immediately, not only on the next state change.
        refreshUI()
    }

    /// The Fn event tap failed to start → permissions are missing. Tell the user and open
    /// the relevant System Settings panes (this is why "nothing happens when I press Fn").
    private func promptTapPermissions() {
        // Never nag during onboarding (the permissions slide handles it), and only once per session.
        if tapPermissionNagged || !Settings.shared.onboarded || onboardingWC?.window?.isVisible == true { return }
        tapPermissionNagged = true
        let alert = NSAlert()
        alert.messageText = "Verba needs permission to use the Fn key"
        alert.informativeText = "Grant Verba under Accessibility and Input Monitoring in System Settings ▸ Privacy & Security, then the Fn key and the recording overlay will work again."
        alert.addButton(withTitle: "Open Accessibility")
        alert.addButton(withTitle: "Open Input Monitoring")
        alert.addButton(withTitle: "Later")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            Output.promptAccessibility()
        case .alertSecondButtonReturn:
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        default: break
        }
    }

    // MARK: - Trigger handlers

    private func trigger(forced: Profile?) {
        switch state {
        // `.processing` no longer blocks the recorder — start a new dictation over an in-flight
        // Session (it keeps processing in the background) exactly as from idle.
        case .idle, .processing: startRecording(forced: forced)
        case .recording: stopAndProcess()   // re-press = send (Lock); Direct stops on key release
        }
    }

    /// ⌃⌥ held with nothing recording → show the numbered mode picker.
    private func chordDown() {
        guard state == .idle else { return }
        // Menu bar only mode has no overlay; the picker is the menu-bar dropdown instead.
        if Settings.shared.overlayStyle == .minimal { return }
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
        // Forceful, state-independent teardown so the × (and Esc) ALWAYS dismisses the overlay,
        // whatever is happening (recording, transcribing, model-downloading, picker open).
        // The glance is a .nonactivatingPanel that may not own key focus, so its own local Esc
        // monitor can't be relied on — dismiss it here via the GLOBAL Esc path too.
        TodoGlanceController.shared.hide()
        // A note recording lives in NotesView's own recorder; ask it to discard (the pill is then
        // torn down by the isRecording→false observer).
        if NotesController.shared.isRecording {
            NotesController.shared.cancelRecord &+= 1
            noteLevelTimer?.invalidate(); noteLevelTimer = nil
        }
        // Cancel every in-flight Session's processing Task (Esc aborts whatever is happening) and
        // drop them from the store so none lands in the completed list.
        for (_, task) in sessionTasks { task.cancel() }
        sessionTasks.removeAll()
        for session in SessionStore.shared.inflight {
            session.status = .cancelled
            SessionStore.shared.complete(session)   // .cancelled is dropped, not listed
        }
        todoCaptureTask?.cancel(); todoCaptureTask = nil
        if todoCaptureRecording { todoCaptureRecording = false }
        TodoCaptureController.shared.capturing = false
        levelTimer?.invalidate(); levelTimer = nil
        fnHoldTimer?.invalidate(); fnHoldTimer = nil
        fnToggleStopArmed = false; fnToggleSwitched = false; lastFnDown = nil; fnPressAt = nil
        stopQuips()
        _ = recorder.stop()
        forcedProfile = nil
        actionModeRecording = false
        editLastInstruction = false
        FnTap.shared.menuActive = false
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = false
        overlay.model.info = false
        overlay.model.error = false
        overlay.model.modeHint = false
        overlay.model.title = ""
        overlay.model.context = .dictation   // reset to the default capture context
        overlay.model.modeName = ""
        // A review-before-send window awaiting confirmation is a pending delivery: global Esc must
        // discard it too, otherwise it would still paste after everything else was torn down.
        reviewWindow?.close(); reviewWindow = nil
        overlay.hide()
        SoundFX.cancel()
        state = .idle
    }

    // Fn (globe) as the primary trigger, Wispr-Flow style:
    //   • tap (idle) → start recording the ACTIVE mode, latched (tap again to send)
    //   • press & HOLD, then release → push-to-talk: the release sends automatically
    //   • ⌥ + Fn (hold Option, tap Fn) → today's to-do glance popup (see fnControlPressed)
    private func fnDown() {
        guard Settings.shared.useFnAsPrimary else { return }
        // `.processing` no longer blocks a new dictation: an in-flight Session keeps processing in
        // the background while this Fn tap starts a fresh recording (handled by the idle branch
        // below, since the recorder — busy only while .recording — is free).
        // A voice to-do capture is in flight (state stays .idle while it records): a bare Fn tap
        // now STOPS & finishes it — the user needn't re-press the Fn+§ chord. This also covers the
        // Fn+§ toggle-stop chord's bare-Fn half (don't spin up a phantom dictation on the shared
        // `recorder`); the §-keyDown's startTodoCapture() stop path then becomes a no-op.
        if todoCaptureRecording { stopTodoCapture(); return }
        // A note is recording in the Notes window (its own recorder). A bare Fn tap stops & finishes
        // it via the shared controller — and must NOT also start a stray dictation here.
        if NotesController.shared.isRecording { NotesController.shared.stopRecord &+= 1; return }

        if state == .recording {
            fnPressAt = nil
            // Hold-to-talk: a tap while recording sends immediately (legacy behaviour).
            // Tap-to-toggle: DON'T decide yet — a quick tap (< fnSwitchThreshold) stops & sends,
            // but a longer hold cycles to the next mode and KEEPS recording (hands-free). The
            // release (fnUp) makes the call from the down→up duration; an in-flight timer fires the
            // mode switch the moment the threshold passes so the user gets immediate feedback.
            if Settings.shared.triggerStyle == .toggle {
                lastFnDown = Date()
                fnToggleStopArmed = true
                fnToggleSwitched = false
                fnHoldTimer?.invalidate()
                let t = Timer(timeInterval: fnSwitchThreshold, repeats: false) { [weak self] _ in
                    guard let self, self.state == .recording, self.fnToggleStopArmed else { return }
                    self.fnToggleSwitched = true   // held long enough → switch mode, keep listening
                    self.cycleMode(1)              // cycleMode plays SoundFX.mode() + sets "Listening · X"
                    self.flashModeSwitch()         // unambiguous switch feedback: distinct title flash so the user knows this was a SWITCH, not a stop
                }
                RunLoop.main.add(t, forMode: .common)
                fnHoldTimer = t
            } else {
                lastFnDown = nil
                stopAndProcess()
            }
            return
        }
        if overlay.model.menu { dismissMenu(); lastFnDown = nil; return }

        // Idle → record instantly with the active mode. Remember the press so a
        // sustained hold-then-release can auto-finish (push-to-talk).
        lastFnDown = Date()
        fnPressAt = Date()
        InputCoach.shared.note(.singleFn)
        startRecording(forced: Settings.shared.activeProfile)
    }

    /// Option + Fn → pop up a quick glance of today's to-dos (toggles off on ⌥+Fn again / Esc).
    /// Mode switching now lives on Fn + Tab and Fn + 1-9 only; this no longer changes mode.
    private func fnControlPressed() {
        guard Settings.shared.useFnAsPrimary else { return }
        cancelToggleHold()   // ⌥+Fn is a chord → don't let the pending toggle-switch timer cycle the mode on release
        // Don't pop the glance over a live capture: if ⌥ is tapped mid-Fn-hold while a dictation,
        // note, or to-do voice capture is recording, leave the recording untouched.
        if state == .recording || todoCaptureRecording || NotesController.shared.isRecording { return }
        showTodoGlance()
    }

    /// ⌥ + Fn → toggle the floating "Today" to-do glance (gated by its Settings toggle).
    private func showTodoGlance() {
        guard Settings.shared.todoGlanceEnabled else { return }
        TodoGlanceController.shared.toggle()
    }

    /// A Fn+<key> chord fired during this Fn hold → this press is a chord, not a bare tap. Cancel
    /// any armed tap-toggle stop/switch so releasing Fn doesn't ALSO stop the recording or cycle
    /// the mode a second time. Safe to call from every Fn-chord handler.
    private func cancelToggleHold() {
        guard fnToggleStopArmed else { return }
        fnHoldTimer?.invalidate(); fnHoldTimer = nil
        fnToggleStopArmed = false
        fnToggleSwitched = false
        lastFnDown = nil
    }

    /// Toggle-style mode SWITCH feedback: when the in-flight toggle timer cycles the mode mid-
    /// recording, flash a distinct "Switched · X" title for ~1s so the user unambiguously knows a
    /// switch (not a stop) happened, then settle back to the steady "Listening · X". Recording
    /// keeps running throughout. SoundFX.mode() is already played by cycleMode().
    private func flashModeSwitch() {
        guard state == .recording else { return }
        let name = (forcedProfile ?? Settings.shared.activeProfile).name
        overlay.model.title = "Switched · \(name)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.state == .recording else { return }
            // Only revert if nothing else changed the title since (still our switch flash).
            if self.overlay.model.title == "Switched · \(name)" {
                self.overlay.model.title = "Listening · \(name)"
            }
        }
    }

    /// Fn + Tab (next) / Fn + ⇧ + Tab (previous) → cycle the active mode, live while recording.
    private func modeCycleGesture(_ dir: Int) {
        cancelToggleHold()
        if state == .processing { return }
        InputCoach.shared.note(.doubleFn)   // mark the mode-switch gesture as learned
        cycleMode(dir)
    }

    /// A lone ⌥ (Option) tap WHILE hands-free recording cycles to the next mode and keeps listening.
    /// In toggle style the keyboard is free (Fn is already released), so a bare Option tap is the
    /// cleanest mid-recording switch — no long-press ambiguity. Only acts during an active recording;
    /// FnTap already guarantees this never fires for ⌃⌥ (picker) or ⌥+Fn (to-do glance).
    private func optionTapped() {
        guard Settings.shared.useFnAsPrimary, state == .recording else { return }
        modeCycleGesture(1)
    }

    /// Fn + ] (next) / Fn + [ (previous) → cycle the active style (the tone/format layer applied
    /// on top of the mode when reprompting). Shows a brief overlay flash of the new style name.
    private func styleCycleGesture(_ dir: Int) {
        cancelToggleHold()
        if state == .processing { return }
        let style = Settings.shared.cycleStyle(dir)
        SoundFX.mode()
        if state == .idle {
            flashMode("Style · \(style.name)")
        } else {
            refreshUI()   // recording: keep listening; menu-bar checkmark updates on next open
        }
    }

    /// The change-mode action shared by the Fn gesture and the configurable global shortcut.
    /// Cycles straight to the next mode (no list) when `modeGestureCycles` is on — works live
    /// while recording — otherwise opens the numbered picker.
    private func changeMode() {
        if state == .processing { return }
        if Settings.shared.modeGestureCycles {
            cycleMode(1)
        } else {
            if Settings.shared.overlayStyle == .minimal { return }
            if state == .recording { cancelRecording() }
            showModeMenu()
        }
    }

    /// Advance the active mode by `delta` (default = next). While recording it switches THIS
    /// dictation's mode live (no interruption); from idle it sets the default and shows a brief hint.
    private func cycleMode(_ delta: Int = 1) {
        let profiles = Settings.shared.profiles
        guard !profiles.isEmpty else { return }
        func step(from id: UUID?) -> Profile {
            let cur = profiles.firstIndex { $0.id == id } ?? 0
            return profiles[((cur + delta) % profiles.count + profiles.count) % profiles.count]
        }
        switch state {
        case .processing:
            return
        case .recording:
            let p = step(from: forcedProfile?.id ?? overlay.model.selectedID ?? Settings.shared.activeProfileID)
            forcedProfile = p
            overlay.model.selectedID = p.id
            overlay.model.title = "Listening · \(p.name)"
            overlay.model.modeName = p.name
            SoundFX.mode()
        case .idle:
            let p = step(from: Settings.shared.activeProfileID)
            Settings.shared.activeProfileID = p.id
            SoundFX.mode()
            flashMode("Mode · \(p.name)")
        }
    }

    /// Brief, discreet mode-change flash (slider icon + "Mode · X"), auto-dismissing. Used when
    /// cycling modes from idle so you can see which mode is now active without opening a list.
    private func flashMode(_ message: String) {
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = false
        overlay.model.error = false
        overlay.model.info = false
        overlay.model.modeHint = true
        overlay.model.title = message
        state = .idle
        overlay.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self, self.state == .idle, self.overlay.model.modeHint else { return }
            self.overlay.model.modeHint = false
            self.overlay.model.title = ""
            self.overlay.hide()
        }
    }

    private func fnUp() {
        guard Settings.shared.useFnAsPrimary else { return }
        // Tap-to-toggle, mid-recording Fn press released: a quick tap stops & sends, a longer hold
        // already switched the mode (via the fnHoldTimer) and keeps listening. Decide from the
        // down→up duration; cancel the pending switch timer either way.
        if fnToggleStopArmed {
            fnHoldTimer?.invalidate(); fnHoldTimer = nil
            fnToggleStopArmed = false
            let held = lastFnDown.map { Date().timeIntervalSince($0) } ?? 0
            lastFnDown = nil
            // The timer already cycled the mode → keep recording, do nothing on release.
            if fnToggleSwitched { fnToggleSwitched = false; return }
            // Quick tap (released before the threshold) → stop & send.
            if held < fnSwitchThreshold, state == .recording {
                InputCoach.shared.note(.holdFn)
                stopAndProcess()
            }
            return
        }
        guard state == .recording, let pressed = fnPressAt else { return }
        fnPressAt = nil
        // Hold-to-talk: ANY release sends immediately (push-to-talk).
        // Tap-to-toggle: release never sends; the next Fn tap sends (handled in fnDown). For an
        // accidental long hold in toggle mode we still send on a clearly deliberate hold so the
        // recording isn't orphaned, matching the prior auto-detect behaviour.
        let send = Settings.shared.triggerStyle == .hold
            || Date().timeIntervalSince(pressed) >= fnHoldThreshold
        if send {
            InputCoach.shared.note(.holdFn)
            lastFnDown = nil
            stopAndProcess()
        }
    }

    private func fnDigit(_ n: Int) -> Bool {
        guard Settings.shared.useFnAsPrimary else { return false }
        cancelToggleHold()   // Fn+number is a chord, not a bare tap → don't let the release stop/switch
        let profiles = Settings.shared.profiles
        guard n >= 1, n <= profiles.count else { return false }
        let p = profiles[n - 1]
        InputCoach.shared.note(.doubleFn)   // onboarding: "mode picker learned"
        switch state {
        case .recording:
            // Fn + number while recording → switch THIS dictation's mode live.
            forcedProfile = p
            overlay.model.selectedID = p.id
            overlay.model.title = "Listening · \(p.name)"
            overlay.model.modeName = p.name
        case .idle, .processing:
            // Fn + number from idle (or while a background Session processes) → record in that mode.
            if overlay.model.menu { Settings.shared.activeProfileID = p.id; dismissMenu() }
            startRecording(forced: p)
        }
        return true
    }
    /// Arrows move the highlight in the OPEN mode picker (consumed only while it's up, so no
    /// global conflict). Enter confirms the highlighted mode.
    private func fnArrow(_ delta: Int) -> Bool {
        guard overlay.model.menu, !overlay.model.profiles.isEmpty else { return false }
        let profiles = overlay.model.profiles
        let cur = profiles.firstIndex(where: { $0.id == overlay.model.activeID }) ?? 0
        let next = ((cur + delta) % profiles.count + profiles.count) % profiles.count
        overlay.model.activeID = profiles[next].id
        Settings.shared.activeProfileID = profiles[next].id   // commit, so recording uses the arrow-picked mode
        return true
    }
    private func fnEnter() -> Bool {
        guard overlay.model.menu else { return false }
        let picked = overlay.model.profiles.first { $0.id == overlay.model.activeID } ?? Settings.shared.activeProfile
        Settings.shared.activeProfileID = picked.id
        dismissMenu()
        trigger(forced: picked)
        return true
    }
    private func togglePause() {
        // A note recording owns its own recorder in NotesView; route the toggle there.
        if state == .idle, NotesController.shared.isRecording {
            NotesController.shared.pauseToggleSignal &+= 1
            return
        }
        guard state == .recording else { return }
        if recorder.isPaused {
            if recorder.resume() { overlay.model.paused = false; SoundFX.resume() }   // only un-pause the UI if audio actually resumed
        } else {
            recorder.pause(); overlay.model.paused = true; SoundFX.pause()
        }
    }

    private func dismissMenu() {
        fnHoldTimer?.invalidate(); fnHoldTimer = nil
        lastFnDown = nil
        overlay.model.menu = false
        FnTap.shared.menuActive = false
    }

    /// Auto-learn from manual edits: if the user hand-corrected the text we last pasted (same app,
    /// field still readable), diff the field's current value against what we pasted and learn the
    /// word swaps. Runs once per delivered paste, right before the next recording.
    private func learnFromManualEdits() {
        guard Settings.shared.autoLearnDictionary,
              let pasted = lastDelivered, let bundle = lastDeliveredBundle,
              bundle == capturedBundleID,                       // same app we pasted into
              let current = Output.focusedValue() else { lastDelivered = nil; return }
        DictionaryStore.shared.learnFromEdit(pasted: pasted, current: current)
        lastDelivered = nil; lastDeliveredBundle = nil          // consume; learn at most once per paste
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
        SoundFX.mode()
        overlay.show()
    }

    private func cancelRecording() {
        levelTimer?.invalidate(); levelTimer = nil
        fnHoldTimer?.invalidate(); fnHoldTimer = nil
        fnToggleStopArmed = false; fnToggleSwitched = false; lastFnDown = nil
        _ = recorder.stop()
        todoCaptureRecording = false   // tearing down the shared recorder voids any to-do capture too
        actionModeRecording = false    // and any in-progress Fn+X Action recording
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
        // A voice to-do capture owns the shared `recorder` while it records (state stays .idle,
        // so every state==.idle caller — global shortcut, edit-last, etc. — would otherwise hijack
        // its mic and orphan the capture). Refuse to start a dictation over an in-flight capture.
        if todoCaptureRecording { return }
        // Free Pro-trial: block new dictations once the trial allowance is spent.
        if Entitlement.freeLimitReached() { showPaywall(); return }
        recorder.requestPermission { [weak self] ok in
            guard let self else { return }
            guard ok else { self.flashError("Microphone access denied"); return }
            // Start capturing FIRST (the recorder is pre-armed, so record() is instant) so the
            // first spoken word is never clipped, THEN do the slower frontmost-app / selection
            // captures and overlay work while audio is already flowing.
            guard self.recorder.start() else { self.flashError("Couldn't start recording"); return }
            self.recordStartedAt = Date()
            self.state = .recording
            SoundFX.start()
            self.forcedProfile = forced
            self.capturedTarget = Output.captureTarget()   // app + focused field, for cross-Space auto-paste restore
            self.capturedBundleID = self.capturedTarget?.bundleID ?? Output.frontmostBundleID()
            self.learnFromManualEdits()   // before recording: did the user fix our last paste by hand?
            self.capturedSelection = Settings.shared.useSelectionContext ? Output.selectedText() : nil

            // Populate the live mode switcher in the overlay.
            let s = Settings.shared
            let initial = forced ?? s.profile(forBundleID: self.capturedBundleID)
            self.overlay.model.profiles = s.repromptEnabled ? s.profiles : []
            self.overlay.model.selectedID = initial.id
            self.overlay.model.onSelect = { [weak self] p in
                self?.forcedProfile = p
                self?.overlay.model.title = "Listening · \(p.name)"
                self?.overlay.model.modeName = p.name
            }
            self.overlay.model.menu = false   // hide the numbers once recording starts
            self.overlay.model.paused = false
            self.overlay.model.modeHint = false
            self.overlay.model.info = false
            self.overlay.model.context = .dictation
            self.overlay.model.modeName = s.repromptEnabled ? initial.name : ""
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
                // loud/fast speech → a bit faster, but kept gentle so it stays readable.
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

        // Snapshot this recording's whole context, then free the recorder immediately so the user
        // can start a NEW dictation while this one processes. The capture overwrites nothing the
        // newer recording sets because everything lives in the SessionContext from here on.
        let bundleID = capturedBundleID
        let forced = forcedProfile
        // #2 Edit-last: treat this dictation as an instruction applied to the last result
        // (reuses selection mode: transcript = instruction, lastResultText = the text to edit).
        let editingLast = editLastInstruction
        let selection = editingLast ? lastResultText : capturedSelection
        // Fn+X Action mode: this recording's spoken request CONTROLS the Mac (confirm → execute).
        let isActionMode = actionModeRecording
        let modeName = isActionMode ? "Action"
            : (forced ?? Settings.shared.profile(forBundleID: bundleID)).name
        let ctx = SessionContext(session: Session(modeName: modeName),
                                 audioURL: url,
                                 capturedTarget: capturedTarget,
                                 capturedBundleID: bundleID,
                                 recordStartedAt: recordStartedAt,
                                 countStats: true,
                                 actionMode: isActionMode)
        editLastInstruction = false
        forcedProfile = nil
        capturedSelection = nil
        capturedTarget = nil
        actionModeRecording = false

        // The recorder is now free. Show the processing pill for this latest Session.
        state = .processing
        statusLine = isActionMode ? "On it…" : "Transcribing…"
        overlay.model.recording = false
        overlay.model.paused = false
        showProcessingOverlay()

        runSession(ctx, forcedProfile: forced, selection: selection, editLast: editingLast)
    }

    /// Spawn the concurrent processing Task for a Session. Several of these can run at once; each is
    /// tracked by Session id so Esc can cancel them all. On success it delivers (or, if the user has
    /// since moved to an unrelated app, lands in the Sessions list with Copy); on failure it records
    /// the error on the Session and surfaces it without blocking the recorder.
    private func runSession(_ ctx: SessionContext, forcedProfile forced: Profile?, selection: String?, editLast: Bool = false) {
        let session = ctx.session
        SessionStore.shared.start(session)
        let url = ctx.audioURL
        let bundleID = ctx.capturedBundleID
        sessionTasks[session.id] = Task {
            do {
                // Hard ceiling so a hung transcription/reprompt backend can't spin forever.
                let result = try await withTimeout(seconds: self.processingTimeout) {
                    try await Pipeline.run(audioURL: url, frontmostBundleID: bundleID, forcedProfile: forced, selection: selection, editLast: editLast, actionMode: ctx.actionMode) { [weak self] s in
                        DispatchQueue.main.async {
                            guard let self else { return }
                            session.status = s.lowercased().contains("transcrib") ? .transcribing : .processing
                            // The processing pill follows the LATEST Session's status line.
                            if self.isLatestInflight(session) { self.statusLine = s; self.refreshUI() }
                        }
                    }
                }
                if Task.isCancelled { return }
                await MainActor.run {
                    // Close the TOCTOU window: cancelEverything() clears sessionTasks (and marks the
                    // session .cancelled) on the main thread. If an Esc landed between the check above
                    // and this hop, the session is no longer tracked → drop it (no paste, no listing).
                    guard self.sessionTasks[session.id] != nil else { return }
                    self.sessionTasks[session.id] = nil
                    self.finish(ctx: ctx, result: result)
                }
            } catch is CancellationError {
                // user cancelled, handled by cancelEverything()
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard self.sessionTasks[session.id] != nil else { return }
                    self.sessionTasks[session.id] = nil
                    self.failSession(session, error: error, latestShowsOverlay: true)
                }
            }
        }
    }

    /// Mark a Session failed and surface it. The latest Session shows the overlay flash/info (so the
    /// single-session happy path is byte-identical); an older background Session lands quietly in the
    /// Sessions list as failed without hijacking the overlay the user is now using.
    @MainActor
    private func failSession(_ session: Session, error: Error, latestShowsOverlay: Bool) {
        // Don't let a background session's failure reset overlay state while the user is recording a
        // NEW dictation: the new recording isn't tracked in SessionStore.inflight yet, so the failed
        // old session can still look "latest". Gating on state != .recording keeps a background
        // failure quiet (list refresh only) and never orphans the live recording.
        let wasLatest = latestShowsOverlay && isLatestInflight(session) && state != .recording
        let msg = error.localizedDescription.lowercased()
        let tooShort = msg.contains("at least 300ms") || msg.contains("invalid audio") || msg.contains("too short")
        let benign: Bool
        if case TranscribeError.empty = error { benign = true } else { benign = tooShort }

        if benign {
            session.status = .cancelled   // a silent/too-short capture is a non-event: don't list it
        } else {
            session.status = .failed
            session.error = (error is TimeoutError) ? "Timed out" : "Transcription failed"
        }
        SessionStore.shared.complete(session)

        guard wasLatest else { refreshUI(); return }   // background failure: just refresh the list
        stopQuipsIfNoInflight()
        overlay.model.recording = false
        if benign {
            flashInfo("Didn't catch that")
        } else if error is TimeoutError {
            flashError("Timed out — try again")
        } else {
            flashError("Transcription failed, try again")
        }
        // Older Sessions still processing behind this failed one → restore the processing pill.
        if SessionStore.shared.hasInflight {
            state = .processing; statusLine = "Transcribing…"; showProcessingOverlay()
        }
    }

    /// True when `session` is the most recently started in-flight Session — the one whose status the
    /// shared processing overlay reflects.
    private func isLatestInflight(_ session: Session) -> Bool {
        SessionStore.shared.inflight.last?.id == session.id
    }

    /// Show the shared processing pill (quips + spinner). Used when a recording hands off and when
    /// the latest recording finished but older Sessions are still processing.
    private func showProcessingOverlay() {
        startQuips()
        refreshUI()
    }

    /// Stop the rotating quips only once NO Session is still processing, so the pill keeps rotating
    /// jokes while any background Session runs.
    private func stopQuipsIfNoInflight() {
        if !SessionStore.shared.hasInflight { stopQuips() }
    }

    /// Rotate a fresh joke (or the neutral word when off) every few seconds while processing,
    /// so the loading screen is lively during transcription AND reprompt, locally too.
    private func startQuips() {
        quipTimer?.invalidate()
        overlay.model.title = Quips.current()
        let t = Timer(timeInterval: 3.5, repeats: true) { [weak self] _ in
            // Keep rotating jokes while ANY Session is still processing (and the overlay isn't
            // showing a live recording), not just while the latest one is.
            guard let self, SessionStore.shared.hasInflight, !self.overlay.model.recording else { return }
            self.overlay.model.title = Quips.current()
        }
        RunLoop.main.add(t, forMode: .common)
        quipTimer = t
    }
    private func stopQuips() { quipTimer?.invalidate(); quipTimer = nil }

    @MainActor
    private func finish(ctx: SessionContext, result: PipelineResult) {
        let session = ctx.session
        // A session Esc-cancelled in the TOCTOU window is already marked .cancelled (and dropped from
        // the store) by cancelEverything(); never auto-paste or list it.
        guard session.status != .cancelled else { return }
        session.original = result.original
        let wasLatest = isLatestInflight(session)
        lastAudioURL = ctx.audioURL   // #8: keep the last recording so it can be redone in another mode
        // Remember last used mode: the mode actually applied to this dictation (a mid-dictation
        // override or auto-detected match included) becomes the default for the next one.
        if Settings.shared.rememberLastMode, let usedID = result.profileID,
           Settings.shared.profiles.contains(where: { $0.id == usedID }),
           Settings.shared.activeProfileID != usedID {
            Settings.shared.activeProfileID = usedID
        }

        // Whether it's safe to auto-paste into the ORIGINAL target right now. A background Session
        // completing while the user has moved on to an unrelated app must NOT steal focus / paste
        // there (task 18): only auto-paste when the captured app is still frontmost. Otherwise the
        // result lands in the Sessions list with Copy. The single-session happy path (the user is
        // still where they dictated, OR there's no captured app) always auto-pastes as before.
        let safeToAutoPaste: Bool = {
            guard let captured = ctx.capturedTarget, let pid = captured.pid else { return true }
            return NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
        }()

        // Side-effect result (e.g. "add to dictionary" on a selection): there is nothing to paste —
        // the dictation performed an action. Finalize the session and flash a brief confirmation
        // WITHOUT replacing the user's selection. (Checked before action/text delivery.)
        if let notice = result.notice {
            session.status = .done
            SessionStore.shared.endInflight(session)
            SessionStore.shared.complete(session)
            stopQuipsIfNoInflight()
            if SessionStore.shared.hasInflight {
                state = .processing; statusLine = "Transcribing…"; overlay.model.recording = false; showProcessingOverlay()
            } else {
                flashInfo(notice)
            }
            return
        }

        // Context mode + Labs "Agentic actions": the result is a structured action, not text. Never
        // auto-paste — take it out of in-flight and present a confirmation sheet. On Confirm, execute
        // it; on Cancel, discard. Plain Context/other modes (action == nil) fall through unchanged.
        if let action = result.action {
            session.original = result.original
            session.status = .done
            SessionStore.shared.endInflight(session)
            SessionStore.shared.complete(session)
            stopQuipsIfNoInflight()
            if SessionStore.shared.hasInflight {
                state = .processing; statusLine = "Transcribing…"; overlay.model.recording = false; showProcessingOverlay()
            } else {
                overlay.hide(); state = .idle
            }
            showActionConfirm(action)
            return
        }

        // Action mode (Fn+X) but the request wasn't an actionable command (the model returned text):
        // never paste that text into the user's app — Action mode controls the Mac, it doesn't type.
        // Finalize the session and flash what we understood, then stop. (Normal Context/dictation
        // modes fall through and paste as usual.)
        if ctx.actionMode {
            session.status = .done
            SessionStore.shared.endInflight(session)
            SessionStore.shared.complete(session)
            stopQuipsIfNoInflight()
            let note = result.reprompted.trimmingCharacters(in: .whitespacesAndNewlines)
            if SessionStore.shared.hasInflight {
                state = .processing; statusLine = "Transcribing…"; overlay.model.recording = false; showProcessingOverlay()
            } else {
                flashInfo(note.isEmpty ? "No action recognized" : "Not an action: \(note)")
            }
            return
        }

        let deliver: (String) -> Void = { [weak self] text in
            guard let self else { return }
            session.resultText = text
            session.status = .done
            // #7 smart formatting: pick rich/plain based on the target app (toggle in Labs).
            let rich = Output.willPasteRich(ctx.capturedBundleID)
            session.rich = rich   // persist so the Sessions list Copy preserves the same formatting
            if Settings.shared.autoPaste && safeToAutoPaste {
                if Output.paste(text, rich: rich, target: ctx.capturedTarget) {
                    session.autoPasted = true
                    // Auto-learn: remember what we pasted so the NEXT dictation can diff it against
                    // any manual fix the user made in this field and learn the correction.
                    self.lastDelivered = text
                    self.lastDeliveredBundle = ctx.capturedBundleID
                } else {
                    Output.copyToClipboard(text, rich: rich)
                    Output.promptAccessibility()
                    self.notify("Copied to clipboard", "Grant Accessibility to enable auto-paste.")
                }
            } else if Settings.shared.autoPaste {
                // Auto-paste is on but the user is in a different app now — copy to the clipboard
                // (no focus hijack) and leave it in the Sessions list to paste when ready.
                Output.copyToClipboard(text, rich: rich)
            } else if Settings.shared.copyToClipboard {
                Output.copyToClipboard(text, rich: rich)
            }
            History.shared.add(original: result.original, reprompted: result.reprompted,
                               profileName: result.profileName, engine: result.engine, audioURL: ctx.audioURL)
            self.lastResultText = text   // #2: remember for "edit last by voice"
            if Settings.shared.toneMatch { ToneStore.record(bundleID: ctx.capturedBundleID, text: text) }
            if ctx.countStats {
                let dur = ctx.recordStartedAt.map { Date().timeIntervalSince($0) } ?? 0
                Stats.shared.record(words: wordCount(text), seconds: dur)
                Leaderboard.submit()   // keep the public leaderboard up to date
            }
            // Surface the finished Session: list it (with Copy) and notify without stealing focus.
            SessionStore.shared.complete(session)
            self.notifySessionDone(session, wasLatest: wasLatest)
        }

        // Review-before-send only applies to the FOREGROUND (latest) Session — a background Session
        // can't pop a modal review over the user's current work; it auto-delivers/lands in the list.
        if Settings.shared.reviewBeforeSend && wasLatest && safeToAutoPaste {
            // Processing is done; take it out of in-flight (it lands in the list on confirm via
            // deliver→complete). Stop the pill only when no OTHER Session is still processing.
            SessionStore.shared.endInflight(session)
            stopQuipsIfNoInflight()
            if SessionStore.shared.hasInflight {
                state = .processing; statusLine = "Transcribing…"; overlay.model.recording = false; showProcessingOverlay()
            } else {
                overlay.hide(); state = .idle
            }
            showReview(original: result.original, text: result.reprompted, onConfirm: deliver)
        } else {
            deliver(result.reprompted)
        }
    }

    /// Surface a freshly-completed Session. The foreground (latest) Session gets the familiar
    /// "✓ Done" overlay flash; a background Session that finished while the user worked elsewhere
    /// gets a quiet, non-focus-stealing toast and sits in the Sessions list with Copy. Either way,
    /// the rotating jokes stop only once no Session is left processing.
    @MainActor
    private func notifySessionDone(_ session: Session, wasLatest: Bool) {
        if wasLatest {
            flashDone()   // identical single-session happy-path flash; sets state = .idle
            // If older Sessions are still processing behind this one, keep the pill alive for them.
            if SessionStore.shared.hasInflight {
                statusLine = "Transcribing…"
                state = .processing
                overlay.model.done = false
                overlay.model.recording = false
                showProcessingOverlay()
            }
        } else {
            // Background completion: never hijack the overlay the user may be using. If nothing else
            // is happening, a brief, silent toast; otherwise stay quiet (the Sessions list shows it).
            SoundFX.done()
            if state == .idle && !SessionStore.shared.hasInflight && !overlay.model.recording {
                flashSessionToast(session)
            }
            refreshUI()   // rebuild the menu so the new result shows in "Recent results"
        }
        stopQuipsIfNoInflight()
    }

    /// A brief, non-focus-stealing "✓ <mode> ready" toast for a background Session completion, with
    /// the result already on the clipboard / in the Sessions list. Mirrors flashInfo's lifecycle.
    @MainActor
    private func flashSessionToast(_ session: Session) {
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = true
        overlay.model.error = false
        overlay.model.info = false
        overlay.model.title = session.autoPasted ? "Done · \(session.modeName)" : "Ready · \(session.modeName)"
        overlay.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, self.state == .idle, self.overlay.model.done,
                  !SessionStore.shared.hasInflight, !self.overlay.model.recording else { return }
            self.overlay.model.done = false
            self.overlay.model.title = ""
            self.overlay.hide()
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

    /// A quiet, auto-dismissing overlay hint (no sound, no red modal) for benign outcomes
    /// like silent audio. Subtle on purpose: it should feel like nothing happened.
    private func flashInfo(_ message: String) {
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = false
        overlay.model.error = false
        overlay.model.modeHint = false
        overlay.model.info = true
        overlay.model.title = message
        state = .idle
        overlay.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self, self.state == .idle else { return }
            self.overlay.model.info = false
            self.overlay.model.title = ""
            self.overlay.hide()
        }
    }

    /// A non-blocking RED error flash in the overlay (same place as the jokes) + error sound.
    /// Replaces the annoying "click OK" modal alerts for transcription/rewrite failures.
    private func flashError(_ message: String) {
        overlay.model.recording = false
        overlay.model.paused = false
        overlay.model.menu = false
        overlay.model.done = false
        overlay.model.info = false
        overlay.model.modeHint = false
        overlay.model.error = true
        overlay.model.title = message
        state = .idle
        SoundFX.error()
        overlay.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, self.state == .idle else { return }
            self.overlay.model.error = false
            self.overlay.model.title = ""
            self.overlay.hide()
        }
    }

    // MARK: - Status item / menu

    private func refreshUI() {
        guard let button = statusItem.button else { return }
        // Distinct glyph per state so "Menu bar only" mode reads at a glance:
        //   idle = mic, recording = filled REC dot (red + pulsing), processing = waveform.
        let symbol: String
        switch state {
        case .idle:       symbol = "mic"
        case .recording:  symbol = "record.circle.fill"
        case .processing: symbol = "waveform"
        }
        statusItem.isVisible = Settings.shared.showMenuBarIcon
        // A template status image is auto-tinted by the system (black on a light menu bar)
        // and ignores contentTintColor. To force the color we BAKE it in: draw the symbol,
        // then fill it with our color using .sourceAtop. ALWAYS white; recording is shown by
        // the glyph change + the blinking pulse (no red).
        let color: NSColor = .white
        let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        let updateReady = Updater.shared.updateAvailable
        // Subtle "background work happening" indicator: a small dot (or count when >1) when Sessions
        // are still processing — so the user knows dictations are landing in Recent results.
        let inflightCount = SessionStore.shared.inflight.count
        if let base = NSImage(systemSymbolName: symbol, accessibilityDescription: "Verba")?.withSymbolConfiguration(cfg) {
            let tinted = NSImage(size: base.size, flipped: false) { rect in
                base.draw(in: rect)
                color.set()
                rect.fill(using: .sourceAtop)
                // Availability badge: a small dot in the top-right corner when an update is ready.
                if updateReady {
                    let d: CGFloat = 5
                    let dot = NSRect(x: rect.maxX - d, y: rect.maxY - d, width: d, height: d)
                    NSColor.systemBlue.setFill()
                    NSBezierPath(ovalIn: dot).fill()
                } else if inflightCount > 0 {
                    // Processing badge in the top-right: a count when several Sessions run, else a dot.
                    if inflightCount > 1 {
                        let n = NSAttributedString(string: "\(inflightCount)", attributes: [
                            .font: NSFont.systemFont(ofSize: 7, weight: .bold),
                            .foregroundColor: NSColor.white,
                        ])
                        let sz = n.size()
                        let pad: CGFloat = 1.5
                        let w = max(sz.width + pad * 2, sz.height + pad)
                        let badge = NSRect(x: rect.maxX - w, y: rect.maxY - (sz.height + pad),
                                           width: w, height: sz.height + pad)
                        NSColor.systemBlue.setFill()
                        NSBezierPath(roundedRect: badge, xRadius: badge.height / 2, yRadius: badge.height / 2).fill()
                        n.draw(at: NSPoint(x: badge.midX - sz.width / 2, y: badge.minY))
                    } else {
                        let d: CGFloat = 5
                        let dot = NSRect(x: rect.maxX - d, y: rect.maxY - d, width: d, height: d)
                        NSColor.systemBlue.setFill()
                        NSBezierPath(ovalIn: dot).fill()
                    }
                }
                return true
            }
            tinted.isTemplate = false
            button.image = tinted
        }
        button.toolTip = updateReady
            ? "Verba update ready" + (Updater.shared.latestVersion.map { " (v\($0))" } ?? "")
            : (inflightCount > 0 ? "Verba — \(inflightCount) dictation\(inflightCount == 1 ? "" : "s") processing" : nil)
        button.contentTintColor = nil
        updateStatusPulse()
        statusItem.menu = buildMenu()
    }

    /// Pulse the menu-bar icon while recording/processing so it's a clear indicator (this is the
    /// whole UI in "Minimal" overlay mode).
    private func updateStatusPulse() {
        statusPulseTimer?.invalidate(); statusPulseTimer = nil
        guard let button = statusItem.button else { return }
        guard state != .idle else { button.alphaValue = 1; return }
        var dim = false
        let t = Timer(timeInterval: 0.6, repeats: true) { _ in
            dim.toggle()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.55
                button.animator().alphaValue = dim ? 0.35 : 1
            }
        }
        RunLoop.main.add(t, forMode: .common)
        statusPulseTimer = t
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        // A cheat-sheet of every shortcut, first in the menu, so the reminder is always right there.
        let scParent = NSMenuItem(title: "Keyboard Shortcuts", action: nil, keyEquivalent: "")
        scParent.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard Shortcuts")
        scParent.submenu = buildShortcutsMenu()
        menu.addItem(scParent)
        menu.addItem(.separator())

        // Prominent "an update is ready" item at the very top when Sparkle found a newer version.
        if Updater.shared.updateAvailable {
            let v = Updater.shared.latestVersion.map { " (v\($0))" } ?? ""
            let upd = NSMenuItem(title: "Install update\(v) — relaunch", action: #selector(installUpdate), keyEquivalent: "")
            upd.target = self
            upd.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: "Install update")
            let font = NSFont.menuFont(ofSize: 0)
            upd.attributedTitle = NSAttributedString(string: upd.title,
                attributes: [.font: NSFont.boldSystemFont(ofSize: font.pointSize)])
            menu.addItem(upd)
            menu.addItem(.separator())
        }

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

        // Default mode picker, right at the top: pick the mode dictation uses by default.
        // This is the way to choose your mode in "Menu bar only" (no overlay) mode.
        menu.addItem(.separator())
        let modeHeader = NSMenuItem(title: "Default mode", action: nil, keyEquivalent: "")
        modeHeader.isEnabled = false
        menu.addItem(modeHeader)
        for p in s.profiles {
            let mi = NSMenuItem(title: p.name, action: #selector(pickDefaultMode(_:)), keyEquivalent: "")
            mi.target = self
            mi.state = (p.id == s.activeProfileID) ? .on : .off
            mi.representedObject = p.id.uuidString
            menu.addItem(mi)
        }

        // Style picker: a tone/format layer applied on top of the active mode (Fn + [ / Fn + ]).
        menu.addItem(.separator())
        let styleHeader = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        styleHeader.isEnabled = false
        menu.addItem(styleHeader)
        for st in s.styles {
            let mi = NSMenuItem(title: st.name, action: #selector(pickDefaultStyle(_:)), keyEquivalent: "")
            mi.target = self
            mi.state = (st.id == s.activeStyleID) ? .on : .off
            mi.representedObject = st.id.uuidString
            menu.addItem(mi)
        }

        // #2: edit the last result by voice ("make it shorter", "more formal", "translate"…).
        if s.voiceEditLast, lastResultText != nil, state == .idle {
            menu.addItem(.separator())
            add(menu, "Edit last by voice…", #selector(editLastByVoice), "")
        }

        // #8: redo the last recording in another mode (if there is one + the feature is on).
        if s.redoEnabled, lastAudioURL != nil, state == .idle {
            menu.addItem(.separator())
            let redoParent = NSMenuItem(title: "Redo last in…", action: nil, keyEquivalent: "")
            let redoSub = NSMenu()
            for p in s.profiles {
                let mi = NSMenuItem(title: p.name, action: #selector(redoLastMode(_:)), keyEquivalent: "")
                mi.target = self; mi.representedObject = p.id.uuidString
                redoSub.addItem(mi)
            }
            redoParent.submenu = redoSub
            menu.addItem(redoParent)
        }

        // Sessions: in-flight (still processing in the background) Sessions plus completed ones
        // (newest first), each with its mode + a Copy action, so a background result the user ran
        // while busy elsewhere is never lost — they can paste it later. The "Recent results…" item
        // opens the live floating Sessions panel. Surfaced whenever there's anything to show.
        let recent = SessionStore.shared.completed
        let inflight = SessionStore.shared.inflight
        if !recent.isEmpty || !inflight.isEmpty {
            menu.addItem(.separator())
            // Live "N processing…" header while background Sessions run, so the user knows work is
            // happening and where to find it; otherwise the plain "Recent results" header.
            if !inflight.isEmpty {
                let n = inflight.count
                let proc = NSMenuItem(title: "\(n) dictation\(n == 1 ? "" : "s") processing…",
                                      action: #selector(openSessions), keyEquivalent: "")
                proc.target = self
                proc.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Processing")
                menu.addItem(proc)
            } else {
                let header = NSMenuItem(title: "Recent results", action: nil, keyEquivalent: "")
                header.isEnabled = false
                menu.addItem(header)
            }
            for sess in recent.prefix(6) {
                let title = sess.status == .failed
                    ? "\(sess.modeName) · \(sess.error ?? "Failed")"
                    : "\(sess.modeName) · \(Self.preview(sess.resultText))"
                let mi = NSMenuItem(title: title, action: #selector(copySessionResult(_:)), keyEquivalent: "")
                mi.target = self
                mi.representedObject = sess.id.uuidString
                mi.image = NSImage(systemSymbolName: sess.status == .failed ? "exclamationmark.triangle" : "doc.on.doc",
                                   accessibilityDescription: nil)
                mi.isEnabled = sess.status != .failed
                menu.addItem(mi)
            }
            add(menu, "Recent results…", #selector(openSessions), "")
            if !recent.isEmpty {
                add(menu, "Clear recent results", #selector(clearSessions), "")
            }
        }

        menu.addItem(.separator())
        let engineItem = NSMenuItem(title: "Engine: \(Settings.shared.engine.label)", action: nil, keyEquivalent: "")
        engineItem.isEnabled = false
        menu.addItem(engineItem)

        // Microphone source picker, right in the menu: System default + every input device.
        let devices = MicDevices.inputs()
        let micName: String = s.micUID.isEmpty
            ? "System default"
            : (MicDevices.name(forUID: s.micUID) ?? "Unavailable")
        let micParent = NSMenuItem(title: "Microphone: \(micName)", action: nil, keyEquivalent: "")
        micParent.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Microphone")
        let micSub = NSMenu()
        let defItem = NSMenuItem(title: "System default", action: #selector(pickMic(_:)), keyEquivalent: "")
        defItem.target = self
        defItem.state = s.micUID.isEmpty ? .on : .off
        defItem.representedObject = ""
        micSub.addItem(defItem)
        if !devices.isEmpty { micSub.addItem(.separator()) }
        for dev in devices {
            let mi = NSMenuItem(title: dev.name, action: #selector(pickMic(_:)), keyEquivalent: "")
            mi.target = self
            mi.state = (dev.uid == s.micUID) ? .on : .off
            mi.representedObject = dev.uid
            micSub.addItem(mi)
        }
        micParent.submenu = micSub
        menu.addItem(micParent)

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

    /// A one-line preview of a result for menu labels (first line, clipped).
    static func preview(_ text: String, max: Int = 48) -> String {
        let line = text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).first.map(String.init) ?? text
        let t = line.trimmingCharacters(in: .whitespaces)
        return t.count > max ? String(t.prefix(max)) + "…" : t
    }

    /// Copy a completed Session's result back to the clipboard (the "paste it later" path for a
    /// background result the user couldn't auto-paste because they'd moved to another app).
    @objc private func copySessionResult(_ sender: NSMenuItem) {
        guard let idStr = sender.representedObject as? String, let id = UUID(uuidString: idStr),
              let sess = SessionStore.shared.completed.first(where: { $0.id == id }),
              !sess.resultText.isEmpty else { return }
        Output.copyToClipboard(sess.resultText, rich: false)
        flashInfo("Copied · \(sess.modeName)")
    }

    @objc private func clearSessions() { SessionStore.shared.clearCompleted(); refreshUI() }

    /// A read-only cheat-sheet of every keyboard shortcut, shown as a submenu off the menu-bar
    /// icon so the user always has a reminder of what's available. Items are non-actionable
    /// (autoenablesItems = false keeps them full-colour and readable, not greyed); section
    /// headers stay disabled/greyed to separate groups. Reflects the current trigger mode.
    private func buildShortcutsMenu() -> NSMenu {
        let m = NSMenu()
        m.autoenablesItems = false
        let s = Settings.shared

        func ref(_ keys: String, _ desc: String) {
            let i = NSMenuItem(title: "\(keys)  —  \(desc)", action: nil, keyEquivalent: "")
            i.isEnabled = true
            m.addItem(i)
        }
        func header(_ t: String) {
            let i = NSMenuItem(title: t, action: nil, keyEquivalent: "")
            i.isEnabled = false
            m.addItem(i)
        }

        let primary = s.useFnAsPrimary ? "Fn"
            : (s.primaryHasShortcut ? shortcutLabel(keyCode: s.primaryKeyCode, modifiers: s.primaryMods) : "⌃⌥ + number")

        header("Dictation")
        if s.useFnAsPrimary {
            ref(primary, s.triggerStyle == .hold
                ? "Hold to talk, release to send"
                : "Tap to start, tap again to send")
        } else {
            ref(primary, "Start / stop dictation")
        }
        ref("Esc", "Cancel recording or processing")
        ref("Control", "Pause / resume while recording")

        // The Fn-combinations only exist when Fn is the primary trigger (the Fn event tap is live).
        if s.useFnAsPrimary {
            let maxN = min(max(s.profiles.count, 1), 9)
            m.addItem(.separator())
            header("Modes  (while holding Fn)")
            ref("Fn + Tab", "Next mode  (add ⇧ for previous)")
            ref(maxN == 1 ? "Fn + 1" : "Fn + 1…\(maxN)", "Pick a mode by number")
            ref("⌥ (tap)", "Next mode while recording hands-free")
            ref("Fn + ]", "Next style  (Fn + [ for previous)")

            m.addItem(.separator())
            header("Capture  (while holding Fn)")
            ref("Fn + §", "Add a to-do by voice")
            ref("Fn + Z", "Capture a note by voice")
            ref("Fn + X", "Action mode — speak a command to control your Mac")
            ref("Fn", "Stop an in-progress note / to-do capture")
            ref("⌥ + Fn", "Today's to-dos  (quick glance)")
        }
        return m
    }

    @objc private func menuToggle() { trigger(forced: nil) }
    @objc private func enableAccessibility() { Output.promptAccessibility() }

    @objc private func pickDefaultMode(_ sender: NSMenuItem) {
        guard let idStr = sender.representedObject as? String, let id = UUID(uuidString: idStr) else { return }
        Settings.shared.activeProfileID = id
        refreshUI()   // rebuild the menu so the checkmark moves to the new default
    }

    @objc private func pickDefaultStyle(_ sender: NSMenuItem) {
        guard let idStr = sender.representedObject as? String, let id = UUID(uuidString: idStr) else { return }
        Settings.shared.activeStyleID = id
        refreshUI()   // rebuild the menu so the checkmark moves to the new style
    }

    /// Choose the microphone Verba records from ("" = follow the system default).
    @objc private func pickMic(_ sender: NSMenuItem) {
        Settings.shared.micUID = (sender.representedObject as? String) ?? ""
        refreshUI()   // rebuild the menu so the checkmark + label update
    }

    // #2: record a spoken instruction that edits the last result ("shorter", "more formal"…).
    @objc private func editLastByVoice() {
        guard state == .idle, lastResultText != nil else { return }
        editLastInstruction = true
        startRecording(forced: Settings.shared.activeProfile)
        overlay.model.title = "Editing last · say your change"
    }

    // #8: re-run the LAST recording through a different mode, no need to speak again.
    @objc private func redoLastMode(_ sender: NSMenuItem) {
        // Allowed whenever the recorder is free (idle OR while a background Session processes).
        guard state != .recording, let url = lastAudioURL,
              let idStr = sender.representedObject as? String, let id = UUID(uuidString: idStr),
              let profile = Settings.shared.profiles.first(where: { $0.id == id }) else { return }
        // Redo runs as its own concurrent Session, just like a fresh dictation — it reuses the last
        // recording's audio + captured target. countStats is false (it's a re-run, not new speech).
        let ctx = SessionContext(session: Session(modeName: profile.name),
                                 audioURL: url,
                                 capturedTarget: capturedTarget,
                                 capturedBundleID: capturedBundleID,
                                 recordStartedAt: recordStartedAt,
                                 countStats: false)
        state = .processing
        statusLine = "Redoing in \(profile.name)…"
        overlay.model.recording = false; overlay.model.menu = false
        showProcessingOverlay()
        runSession(ctx, forcedProfile: profile, selection: nil)
    }
    @objc private func checkUpdates() { Updater.shared.checkForUpdates() }
    @objc private func installUpdate() { Updater.shared.installUpdate() }
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

    @objc private func openSessions() {
        if sessionsWC == nil {
            sessionsWC = makeWindow(title: "Recent Results",
                                    view: SessionsView(store: SessionStore.shared),
                                    size: NSSize(width: 460, height: 420), glass: true)
        }
        present(sessionsWC)
    }

    private func openOnboarding() {
        if let wc = onboardingWC { present(wc); return }   // already open → just focus it
        let view = OnboardingView { [weak self] in
            self?.onboardingWC?.close(); self?.onboardingWC = nil
            self?.applyTriggers()   // now onboarded + permissions granted → start the Fn tap
            self?.recorder.prewarm()   // pre-arm so the first dictation captures from the first word
        }
        onboardingWC = makeWindow(title: "Welcome to Verba", view: view, size: NSSize(width: 620, height: 720), glass: true)
        present(onboardingWC)
    }

    private func showReview(original: String, text: String, onConfirm: @escaping (String) -> Void) {
        let close: () -> Void = { [weak self] in
            self?.reviewWindow?.close(); self?.reviewWindow = nil
        }
        let view = ReviewView(original: original, text: text,
                              onConfirm: { t in
                                  if Settings.shared.autoLearnDictionary { DictionaryStore.shared.learn(from: text, edited: t) }
                                  onConfirm(t); close()
                              },
                              onCancel: { close() })
        let wc = makeWindow(title: "Review dictation", view: view, size: NSSize(width: 520, height: 420), glass: true, resizable: false)
        reviewWindow = wc.window
        present(wc)
    }

    /// Present the agentic-action confirmation sheet (Context mode + Labs). On Confirm, run the
    /// action via ActionExecutor and flash success/error; on Cancel, just close and discard.
    private func showActionConfirm(_ action: VerbaAction) {
        let close: () -> Void = { [weak self] in
            self?.actionWindow?.close(); self?.actionWindow = nil
        }
        let view = ActionConfirmView(
            action: action,
            onConfirm: { [weak self] in
                close()
                guard let self else { return }
                Task { @MainActor in
                    do {
                        let message = try await ActionExecutor().perform(action)
                        self.flashInfo(message)
                    } catch {
                        self.flashError(error.localizedDescription)
                    }
                }
            },
            onCancel: { close() })
        let wc = makeWindow(title: "Confirm action", view: view, size: NSSize(width: 460, height: 320),
                            glass: true, resizable: false)
        actionWindow = wc.window
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
        a.messageText = "Your free trial is used up"
        a.informativeText = "You've used your \(Entitlement.freeTrialDictations) free Pro dictations. Upgrade to Verba Pro for unlimited dictation, $9.99/month."
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
