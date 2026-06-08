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
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Verba", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("rec-\(Int(Date().timeIntervalSince1970 * 1000)).m4a")
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
            NSLog("Verba: recorder prewarm failed: \(error)")
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
    private func chosenMicToApply() -> AudioDeviceID? {
        let uid = Settings.shared.micUID
        guard !uid.isEmpty, let chosen = MicDevices.id(forUID: uid) else { return nil }
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

    @discardableResult
    func start() -> Bool {
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
            NSLog("Verba: recorder start failed: \(error)")
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

    /// Current input level 0...1 for the meter, boosted so quiet speech still moves.
    func level() -> Float {
        guard let rec = recorder, rec.isRecording else { return 0 }
        rec.updateMeters()
        let db = rec.averagePower(forChannel: 0)        // ~ -160 ... 0
        let norm = max(0, min(1, (db + 52) / 52))       // tighter floor = more sensitive
        return powf(norm, 0.55)                          // lift low end for a livelier meter
    }
}
