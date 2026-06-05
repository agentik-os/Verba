import Foundation
import AVFoundation

/// Records microphone input to a compact .m4a (AAC) file.
/// AAC keeps long dictations small enough for OpenAI's 25 MB upload limit, and
/// WhisperKit reads m4a fine too, one format serves both engines.
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var currentURL: URL?
    var isRecording: Bool { recorder?.isRecording ?? false }

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
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Verba", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("rec-\(Int(Date().timeIntervalSince1970)).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,          // Whisper/parakeet operate at 16 kHz
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        do {
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            guard rec.record() else { return false }
            recorder = rec
            currentURL = url
            return true
        } catch {
            NSLog("Verba: recorder start failed: \(error)")
            return false
        }
    }

    private(set) var isPaused = false

    func pause() { recorder?.pause(); isPaused = true }
    func resume() { if recorder?.record() == true { isPaused = false } }

    /// Stop and return the finished file URL (nil if nothing recorded).
    func stop() -> URL? {
        guard let rec = recorder else { return nil }
        rec.stop()
        recorder = nil
        isPaused = false
        return currentURL
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
