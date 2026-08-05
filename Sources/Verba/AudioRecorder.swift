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
        if let live = recorder {
            guard !live.isRecording else {
                VerbaLog.audio.error("AudioRecorder.start() refused: a recording is already live")
                return false
            }
            VerbaLog.audio.error("AudioRecorder.start(): discarding a stale recorder that had already stopped itself")
            live.stop()
            recorder = nil
            isPaused = false
            restoreMic()   // it held a default-input switch we never restored
        }
        let chosen = chosenMicToApply()

        // Fast path: a recorder is already armed (prepared) AND either no specific
        // mic is requested or it's already the default. record() fires instantly,
        // so we capture from the first word.
        if let rec = armed, chosen == nil {
            applyChosenMic()   // no-op switch, but keeps restore bookkeeping consistent
            if rec.record() {
                recorder = rec
                currentURL = armedURL
                armed = nil; armedURL = nil
                return true
            }
            // Prepared recorder refused to start — fall through to a fresh attempt.
            discardArmed()
        } else if armed != nil {
            // A different mic was requested; the armed recorder is bound to the old
            // default input, so drop it and build one against the chosen device.
            discardArmed()
        }

        // Slow path (cold start, or a custom mic switch is needed).
        applyChosenMic()
        let url = newRecordingURL()
        do {
            let rec = try AVAudioRecorder(url: url, settings: recorderSettings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            rec.prepareToRecord()
            guard rec.record() else { restoreMic(); return false }
            recorder = rec
            currentURL = url
            return true
        } catch {
            VerbaLog.audio.error("recorder start failed: \(error.localizedDescription, privacy: .public)")
            restoreMic()
            return false
        }
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
        recorder = nil
        isPaused = false
        restoreMic()
        let finished = currentURL
        // Re-arm for the next dictation so the following Fn-press starts instantly.
        prewarm()
        return finished
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
