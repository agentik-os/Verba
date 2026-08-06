import Foundation
import AVFoundation
import CoreAudio

/// Records microphone input to a compact .m4a (AAC) file.
/// AAC keeps long dictations small enough for OpenAI's 25 MB upload limit, and
/// WhisperKit reads m4a fine too, one format serves both engines.
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var currentURL: URL?
    var isRecording: Bool { recorder?.isRecording ?? false }

    /// A recorder created + `prepareToRecord()`-ed ahead of time so that, on the
    /// next `start()`, `record()` fires instantly and we capture from the first
    /// spoken word. The expensive audio-queue / file allocation happens here,
    /// off the Fn-press critical path.
    private var armed: AVAudioRecorder?
    private var armedURL: URL?

    /// True once the input level crossed `signalFloorDB` at any point during the CURRENT capture,
    /// reset by every `start()`. False after a capture means literally nothing reached us: the
    /// selected input device fed no audio at all, which is a different failure from "the user said
    /// nothing" and needs a different answer (see the no-signal alert in AppDelegate).
    private(set) var sawSignal = false

    /// Name of the input device this capture actually recorded from, read once the recorder is
    /// running (so it reflects the chosen-mic switch), and kept after `stop()` has restored the
    /// previous default so the failure path can still name the device.
    private(set) var captureDeviceName: String?

    /// UID of that same device, kept beside the name because the name is what a human reads and the
    /// UID is what identifies the device across reconnects (two "Headset" entries are told apart by
    /// this and nothing else). Neither is personal data: they are hardware identifiers, which is why
    /// both are logged `.public` and stay readable in Console instead of collapsing to <private>.
    private(set) var captureDeviceUID: String?

    /// When `record()` was accepted for the CURRENT capture. Both diagnostics that matter are
    /// measured from here: how long the capture ran, and how long the input took to deliver its
    /// first sample.
    private var captureStartedAt: Date?

    /// Milliseconds between `record()` and the first sample above the floor, nil while none has
    /// arrived. THE number for an input that wakes up slowly: a Bluetooth device sitting in A2DP
    /// output mode advertises a microphone that delivers nothing until SCO/HFP is negotiated, so a
    /// first signal hundreds of milliseconds (or seconds) late is that negotiation, while a built-in
    /// or wired mic lands inside the first sampling tick.
    private(set) var firstSignalMs: Int?

    /// Loudest reading the watcher saw during the current capture, in dBFS. On a capture that never
    /// crosses the floor this single number is the whole diagnosis: a peak pinned at the meter floor
    /// is a device sending literally nothing, while a peak just under the floor is a live device the
    /// user simply spoke too far away from.
    private(set) var peakLevelDB: Float = AudioRecorder.meterFloorDB

    /// When this recorder was built. The app builds its dictation recorder at launch, so a start
    /// logged a few seconds in versus a few minutes in is exactly what separates "dead right after
    /// launch, fine later" from a permanent failure. Approximate on purpose: no launch clock is
    /// plumbed through for it.
    private let createdAt = Date()

    /// Part 2: the device that fed the previous capture NOTHING, while Verba was merely following
    /// the system default. Set only under the conditions in `noteSilentDefault()`, read only by
    /// `builtInRecoveryToApply()`, and cleared the moment any capture hears something.
    private var silentDefaultUID: String?
    private var silentDefaultName: String?

    /// Level floor, in dBFS, above which we call it signal. An input that delivers no samples meters
    /// at -160 dB while even a silent room through a working mic sits far above -60, so the gap is
    /// wide and this test never has to be clever. Deliberately conservative: reading real audio as
    /// "no signal" would blame the user's device for their own silence.
    private static let signalFloorDB: Float = -60

    /// What the meter reads when nothing at all is arriving. Used as the reset value for
    /// `peakLevelDB` so an unstarted capture never reports a peak it did not measure.
    private static let meterFloorDB: Float = -160

    /// A capture has to run at least this long before its silence is allowed to BLAME the device
    /// (Part 2). An accidental brush of the trigger produces a capture too short for the 150 ms
    /// watcher to have taken a meaningful reading, and blaming a healthy microphone for that would
    /// switch the user's input away for no reason.
    private static let minSecondsToBlameDevice: TimeInterval = 1.0

    /// Samples the meter while recording; invalidated as soon as it has an answer.
    private var signalTimer: Timer?

    /// The encoder settings used for every recording (shared by prewarm + start).
    private let recorderSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 16_000,          // Whisper/parakeet operate at 16 kHz
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    private func newRecordingURL() -> URL {
        let dir = Self.recordingsDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("rec-\(Int(Date().timeIntervalSince1970 * 1000)).m4a")
    }

    /// The temp folder every recording buffer lives in.
    static var recordingsDir: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Verba", isDirectory: true)
    }

    /// R12: temp recording buffers used to accumulate forever (72 MB+ observed). Sweep the temp
    /// folder, deleting anything older than `maxAge` (48 h — generously past any redo/processing
    /// lifetime). Called once at launch, off the main thread.
    static func sweepStaleRecordings(olderThan maxAge: TimeInterval = 48 * 3600) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: recordingsDir,
                                                      includingPropertiesForKeys: [.contentModificationDateKey],
                                                      options: [.skipsHiddenFiles]) else { return }
        let cutoff = Date().addingTimeInterval(-maxAge)
        for f in files {
            let mod = (try? f.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            guard mod < cutoff else { continue }
            do { try fm.removeItem(at: f) }
            catch { VerbaLog.audio.error("stale recording sweep failed for \(f.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)") }
        }
    }

    /// Create and `prepareToRecord()` a recorder in advance. Call this on launch
    /// and after each `stop()` so the next dictation starts with zero arm latency.
    /// Cheap to call repeatedly; a no-op while already recording or already armed.
    func prewarm() {
        guard recorder == nil, armed == nil else { return }
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else { return }
        let url = newRecordingURL()
        do {
            let rec = try AVAudioRecorder(url: url, settings: recorderSettings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            rec.prepareToRecord()   // allocates the audio queue + opens the file now
            armed = rec
            armedURL = url
        } catch {
            VerbaLog.audio.error("recorder prewarm failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func discardArmed() {
        armed = nil
        if let url = armedURL { try? FileManager.default.removeItem(at: url) }
        armedURL = nil
    }

    /// Release the pre-armed recorder so the microphone is free for another recorder
    /// (e.g. the Notes window uses its own AudioRecorder). The prepared input held the
    /// audio queue, which made a second recorder's start() fail. Re-arms on the next stop().
    func releaseArmed() { discardArmed() }

    /// When the user picked a specific mic, we point the system default input at it
    /// for the duration of this recording and restore the previous one on stop, so
    /// the proven recording pipeline is untouched and other apps are left as they were.
    private var restoreDefaultInput: AudioDeviceID?

    /// The device the user picked that ISN'T already the default input, or nil if
    /// no switch is needed (no chosen mic, or it's already the default).
    ///
    /// A persisted UID that no longer resolves to a live input — the mic was unplugged, the
    /// Bluetooth headset is off, the settings came from another Mac — is NOT an error and must
    /// never fail the recording: nil here means "record from the system default input", which is
    /// the one device we know exists. The stale UID is left in Settings on purpose so the user's
    /// choice comes back when they plug the device in again; it is only logged, once per start.
    private func chosenMicToApply() -> AudioDeviceID? {
        let uid = Settings.shared.micUID
        guard !uid.isEmpty else { return nil }
        guard let chosen = MicDevices.id(forUID: uid) else {
            VerbaLog.audio.error("chosen mic \(uid, privacy: .public) is not connected — falling back to the system default input")
            return nil
        }
        return chosen != MicDevices.defaultInputID() ? chosen : nil
    }

    /// Route capture to the user's chosen mic (if any) by switching the default input.
    private func applyChosenMic() {
        restoreDefaultInput = nil
        guard let chosen = chosenMicToApply() else { return }
        let current = MicDevices.defaultInputID()
        if MicDevices.setDefaultInput(chosen) { restoreDefaultInput = current }
    }

    /// Restore whatever input device was the default before we recorded.
    private func restoreMic() {
        if let prev = restoreDefaultInput { MicDevices.setDefaultInput(prev) }
        restoreDefaultInput = nil
    }

    /// Watch the input level for the rest of this capture and latch `sawSignal` the first time it
    /// crosses the floor. Started only AFTER `record()` has already returned true, so neither the
    /// fast nor the slow start path waits on it, and it stops itself the moment it has an answer:
    /// a normal dictation pays for a handful of `updateMeters()` calls and nothing more.
    /// A paused recorder is skipped rather than concluded on, so a resume keeps being watched.
    private func beginSignalWatch(_ rec: AVAudioRecorder) {
        endSignalWatch()
        captureDeviceName = MicDevices.defaultInputName()
        captureDeviceUID = MicDevices.defaultInputUID()
        // Read AFTER applyChosenMic() has run, so these name the device the capture is actually
        // bound to rather than the one that was default before the switch.
        captureStartedAt = Date()
        firstSignalMs = nil
        peakLevelDB = Self.meterFloorDB
        let t = Timer(timeInterval: 0.15, repeats: true) { [weak self, weak rec] timer in
            // Nothing left to watch (the owner or the recorder went away): stop the timer rather
            // than let the run loop keep firing it forever.
            guard let self, let rec else { timer.invalidate(); return }
            guard rec.isRecording else { return }   // paused: keep watching for the resume
            rec.updateMeters()
            guard rec.averagePower(forChannel: 0) > Self.signalFloorDB else { self.notePeak(rec); return }
            self.notePeak(rec)
            self.sawSignal = true
            let ms = Int(Date().timeIntervalSince(self.captureStartedAt ?? Date()) * 1000)
            self.firstSignalMs = ms
            VerbaLog.audio.log("capture: first signal after \(ms, privacy: .public) ms device=\(self.captureDeviceName ?? "unknown", privacy: .public) level=\(String(format: "%.1f", self.peakLevelDB), privacy: .public)dBFS")
            timer.invalidate()
            self.signalTimer = nil
        }
        RunLoop.main.add(t, forMode: .common)   // keeps sampling while a menu is tracking
        signalTimer = t
    }

    /// Keep the loudest reading of this capture, including readings BELOW the signal floor: on a
    /// capture that never crosses, the peak is the only quantity that separates a dead input from a
    /// distant voice. The meters have already been updated by the caller, so this is a cached read.
    private func notePeak(_ rec: AVAudioRecorder) {
        let db = rec.averagePower(forChannel: 0)
        if db > peakLevelDB { peakLevelDB = db }
    }

    private func endSignalWatch() {
        signalTimer?.invalidate()
        signalTimer = nil
    }

    /// Ask for mic permission (macOS prompts once). Completion on main thread.
    ///
    /// The status is READ FRESH on every call rather than cached: the user can grant or revoke
    /// microphone access in System Settings while Verba is running, and a cached "denied" would
    /// keep every dictation dead until the next relaunch with no way for the user to tell why.
    func requestPermission(_ done: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            done(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { ok in
                DispatchQueue.main.async { done(ok) }
            }
        default:
            done(false)
        }
    }

    /// True when macOS is REFUSING the microphone (the user denied it, or a profile/parental
    /// restriction blocks it) as opposed to simply not having asked yet. macOS will not prompt
    /// again in this state — `requestAccess` returns false without any UI — so the only way out is
    /// System Settings, and the caller must say so instead of flashing a dead end.
    var permissionRefused: Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted: return true
        default: return false
        }
    }

    @discardableResult
    func start() -> Bool {
        // R1: never overwrite a LIVE recorder — replacing `recorder` while it's still recording
        // would orphan a running AVAudioRecorder (hot mic, lost dictation) with no owner left to
        // stop it. One recording at a time; the caller must stop() the current one first.
        //
        // But `recorder != nil` is NOT the same fact as "a recording is live", and conflating the
        // two is a permanent dead end: AVAudioRecorder stops itself on an encode error, on a route
        // change, and when the capture device it was bound to disappears (unplugged mic, headset
        // powered off, a Handoff/AirPods switch). None of those run our stop(), so `recorder` stays
        // non-nil while `isRecording` is false, and from that moment EVERY start() in EVERY mode —
        // Raw included, since this is below the mode layer — returns false forever. The user sees
        // "Couldn't start recording" (or nothing at all on the paths that don't flash) until they
        // relaunch. Tear the dead one down and take the cold path instead of refusing.
        // The staleness test is `isRecording == false` AND `isPaused == false`, never isRecording
        // alone: a PAUSED recorder also reports isRecording == false, so isRecording by itself
        // cannot tell a recorder that died from one the user deliberately paused, and the teardown
        // below would throw away a dictation they are still holding. Paused is a live recording
        // waiting for resume(), so it refuses exactly like a running one.
        if let live = recorder {
            guard !live.isRecording, !isPaused else {
                VerbaLog.audio.error("AudioRecorder.start() refused: a recording is already live or paused")
                return false
            }
            VerbaLog.audio.error("AudioRecorder.start(): discarding a stale recorder that had already stopped itself")
            live.stop()
            recorder = nil
            isPaused = false
            restoreMic()   // it held a default-input switch we never restored
        }
        // A fresh capture: nothing has been heard yet and no device is bound. Reset BELOW the guard
        // above, never before it, so a start() that refuses because a recording is already live
        // leaves that live recording's signal state intact.
        sawSignal = false
        captureDeviceName = nil
        captureDeviceUID = nil
        endSignalWatch()

        let chosen = chosenMicToApply()
        // Part 2. A recovery switch is a device switch exactly like a chosen mic, so it disqualifies
        // the pre-armed recorder in the same way: that recorder is bound to the device that just
        // produced nothing.
        let recovery = builtInRecoveryToApply()

        // Fast path: a recorder is already armed (prepared) AND either no specific
        // mic is requested or it's already the default. record() fires instantly,
        // so we capture from the first word.
        if let rec = armed, chosen == nil, recovery == nil {
            applyChosenMic()   // no-op switch, but keeps restore bookkeeping consistent
            if rec.record() {
                recorder = rec
                currentURL = armedURL
                armed = nil; armedURL = nil
                beginSignalWatch(rec)
                logCaptureStart(path: "prearmed", started: true)
                return true
            }
            // Prepared recorder refused to start — fall through to a fresh attempt.
            VerbaLog.audio.error("capture: the pre-armed recorder refused record(), retrying from cold")
            discardArmed()
        } else if armed != nil {
            // A different mic was requested; the armed recorder is bound to the old
            // default input, so drop it and build one against the chosen device.
            discardArmed()
        }

        // Slow path (cold start, a custom mic switch, or the built-in-mic recovery).
        applyChosenMic()
        applyBuiltInRecovery(recovery)   // mutually exclusive with the above: recovery needs an empty micUID
        let url = newRecordingURL()
        do {
            let rec = try AVAudioRecorder(url: url, settings: recorderSettings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            rec.prepareToRecord()
            guard rec.record() else {
                logCaptureStart(path: "cold", started: false)
                restoreMic()
                return false
            }
            recorder = rec
            currentURL = url
            beginSignalWatch(rec)
            logCaptureStart(path: "cold", started: true)
            return true
        } catch {
            VerbaLog.audio.error("recorder start failed: \(error.localizedDescription, privacy: .public)")
            restoreMic()
            return false
        }
    }

    /// One grep-able line per start, carrying everything needed to tell WHICH device fed a capture:
    /// the path taken (a normal dictation is `prearmed`; `cold` means the fast path was unavailable
    /// or a device switch was needed), the device actually bound, whether a chosen-mic switch was
    /// applied, and whether `record()` was accepted.
    ///
    /// Logged at DEFAULT level, not `.info`: the unified log keeps info-level messages in memory
    /// only, so an `.info` line is gone by the time a user is asked for a log, which is precisely
    /// the failure this whole pass exists to end. Device names, UIDs and durations are hardware
    /// facts and go out `.public` so the line is readable; no transcript, no file path and nothing
    /// about the user is logged here.
    private func logCaptureStart(path: String, started: Bool) {
        let device = captureDeviceName ?? MicDevices.defaultInputName() ?? "unknown"
        let uid = captureDeviceUID ?? MicDevices.defaultInputUID() ?? "unknown"
        let age = String(format: "%.1f", Date().timeIntervalSince(createdAt))
        VerbaLog.audio.log("capture: start path=\(path, privacy: .public) device=\(device, privacy: .public) uid=\(uid, privacy: .public) chosenMicSwitch=\(self.restoreDefaultInput != nil ? "yes" : "no", privacy: .public) record=\(started ? "true" : "false", privacy: .public) sinceInit=\(age, privacy: .public)s")
    }

    private(set) var isPaused = false

    func pause() { recorder?.pause(); isPaused = true }
    @discardableResult
    func resume() -> Bool {
        guard let rec = recorder else { return false }
        // record() resumes an AVAudioRecorder that was paused; retry once if it reports false.
        let ok = rec.record() || rec.record()
        if ok { isPaused = false }
        return ok
    }

    /// Stop after a short SILENT tail so a word still trailing off when the user releases the trigger
    /// (people routinely stop a beat before the last syllable lands) still makes it into the file. The
    /// mic keeps capturing for `tail` seconds; nothing is shown to the user. Falls back to an immediate
    /// stop when not recording or tail <= 0. The finished URL is delivered on the main thread.
    func stop(afterTail tail: TimeInterval, _ done: @escaping (URL?) -> Void) {
        guard tail > 0, recorder?.isRecording == true else { done(stop()); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + tail) { [weak self] in done(self?.stop()) }
    }

    /// Stop and return the finished file URL (nil if nothing recorded).
    func stop() -> URL? {
        guard let rec = recorder else { restoreMic(); return nil }
        rec.stop()
        // Only the sampler stops here: `sawSignal` and `captureDeviceName` describe the capture that
        // just ended and the caller reads them after this returns.
        endSignalWatch()
        recorder = nil
        isPaused = false
        restoreMic()
        let finished = currentURL
        finishCapture(finished)
        // Re-arm for the next dictation so the following Fn-press starts instantly.
        prewarm()
        return finished
    }

    /// The end-of-capture record: one line with the duration, the bytes written and the signal
    /// verdict, plus an error line naming the device when nothing at all arrived. Together with the
    /// start line and the first-signal line, ONE failing dictation now says which device was used,
    /// whether any audio reached Verba, how long the first sample took and how big the file is.
    ///
    /// Only the SIZE of the file is logged, never its URL: the buffer lives under the user's temp
    /// folder and its path is not ours to publish.
    private func finishCapture(_ url: URL?) {
        let seconds = captureStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let bytes = url.flatMap { (try? $0.resourceValues(forKeys: [.fileSizeKey]))?.fileSize } ?? -1
        let device = captureDeviceName ?? "unknown"
        let elapsed = String(format: "%.2f", seconds)
        let peak = String(format: "%.1f", peakLevelDB)
        VerbaLog.audio.log("capture: stop device=\(device, privacy: .public) uid=\(self.captureDeviceUID ?? "unknown", privacy: .public) seconds=\(elapsed, privacy: .public) bytes=\(bytes, privacy: .public) sawSignal=\(self.sawSignal ? "true" : "false", privacy: .public) firstSignalMs=\(self.firstSignalMs ?? -1, privacy: .public) peakDB=\(peak, privacy: .public)")
        if !sawSignal {
            VerbaLog.audio.error("capture: no signal from \(device, privacy: .public) in \(elapsed, privacy: .public)s, peak \(peak, privacy: .public)dBFS never crossed \(Int(Self.signalFloorDB), privacy: .public)dBFS, \(bytes, privacy: .public) bytes written")
        }
        noteSilentDefault(after: seconds)
    }

    // MARK: - Built-in microphone recovery (Part 2)

    /// Remember, or forget, that the system default input produced nothing.
    ///
    /// Deliberately narrow. Nothing is remembered when the user PICKED their microphone: that
    /// choice is theirs and Verba does not get to overrule it. Nothing is remembered from a capture
    /// too short to have been measured either, because an accidental brush of the trigger would
    /// otherwise blame a perfectly good device. And any capture that hears something clears the
    /// memory outright, so the recovery below lasts exactly as long as the problem does.
    private func noteSilentDefault(after seconds: TimeInterval) {
        if sawSignal { silentDefaultUID = nil; silentDefaultName = nil; return }
        guard Settings.shared.micUID.isEmpty else { return }
        guard seconds >= Self.minSecondsToBlameDevice, let uid = captureDeviceUID else { return }
        silentDefaultUID = uid
        silentDefaultName = captureDeviceName
    }

    /// The built-in microphone to record from for THIS capture, or nil to change nothing.
    ///
    /// Three conditions, all required, each one there to keep this from ever overriding a decision
    /// the user made:
    ///  1. the previous capture saw ZERO signal (`silentDefaultUID` is set, per `noteSilentDefault`);
    ///  2. the user has NOT chosen a microphone, so Verba is only following the system default and
    ///     is free to prefer a device that works;
    ///  3. that same silent device is STILL the default, so if the user already fixed it themselves
    ///     we stay out of the way (and forget, since the fact is no longer about the current input).
    ///
    /// The fallback device is the Mac's own microphone (`MicDevices.builtInInputUID`, the stable
    /// CoreAudio UID "BuiltInMicrophoneDevice"), because it is the one input that is always present,
    /// always wired and never negotiating a Bluetooth profile.
    ///
    /// If the built-in microphone cannot be resolved, nothing changes and we only log: there is no
    /// safer device to fall back to, and moving the user's input somewhere arbitrary would be worse
    /// than the silence. The switch itself is one capture long, exactly like a chosen mic, and
    /// `stop()` restores the previous default.
    private func builtInRecoveryToApply() -> AudioDeviceID? {
        guard let silent = silentDefaultUID, Settings.shared.micUID.isEmpty else { return nil }
        guard MicDevices.defaultInputUID() == silent else { silentDefaultUID = nil; silentDefaultName = nil; return nil }
        guard let builtIn = MicDevices.builtInInput() else {
            VerbaLog.audio.error("capture: \(self.silentDefaultName ?? "the system default input", privacy: .public) produced no signal and this Mac has no built-in microphone to fall back to, recording from the default anyway")
            return nil
        }
        guard builtIn.uid != silent else { return nil }   // the silent device IS the built-in mic: nothing better to switch to
        return builtIn.id
    }

    /// Apply the recovery switch decided above, recording the previous default so `stop()` puts it
    /// back. `restoreDefaultInput` is only written when it is still empty, so a chosen-mic switch
    /// (which cannot coexist with a recovery, since a recovery requires an empty micUID) could never
    /// have its original device overwritten.
    private func applyBuiltInRecovery(_ builtIn: AudioDeviceID?) {
        guard let builtIn else { return }
        let current = MicDevices.defaultInputID()
        guard MicDevices.setDefaultInput(builtIn) else {
            VerbaLog.audio.error("capture: could not switch to the built-in microphone, recording from the system default")
            return
        }
        if restoreDefaultInput == nil { restoreDefaultInput = current }
        VerbaLog.audio.log("capture: recovery, recording from the built-in microphone because \(self.silentDefaultName ?? "the system default input", privacy: .public) sent no audio on the previous capture")
    }

    // MARK: - AVAudioRecorderDelegate

    /// The encoder died mid-capture (disk full, the input device vanished, a codec fault). We were
    /// already the delegate but implemented nothing, so the failure was invisible AND the recorder
    /// object stayed referenced. Log it, and if the casualty is the PRE-ARMED recorder, drop it:
    /// an armed recorder whose encoder has failed will refuse `record()` on every future dictation
    /// while `prewarm()` keeps seeing `armed != nil` and declines to build a healthy replacement.
    /// The live recorder is left for `start()`/`stop()` to reap, which is where the recovery and
    /// the mic restore already live.
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        VerbaLog.audio.error("recorder encode error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
        if recorder === armed { discardArmed() }
    }

    /// Same reasoning for an unsuccessful finish: a failed armed recorder is unusable, and holding
    /// it blocks `prewarm()` from arming a working one.
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard !flag else { return }
        VerbaLog.audio.error("recorder finished unsuccessfully")
        if recorder === armed { discardArmed() }
    }

    /// Current input level 0...1 for the meter, boosted so quiet speech still moves.
    func level() -> Float {
        guard let rec = recorder, rec.isRecording else { return 0 }
        rec.updateMeters()
        let db = rec.averagePower(forChannel: 0)        // ~ -160 ... 0
        let norm = max(0, min(1, (db + 52) / 52))       // tighter floor = more sensitive
        return powf(norm, 0.55)                          // lift low end for a livelier meter
    }
}
