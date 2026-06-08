import AppKit

/// Audio cues. Each cue plays a custom file bundled at Resources/Sounds/<cue>.mp3 if present,
/// otherwise a soft macOS system sound. Drop an mp3 named after the cue to customize it.
enum SoundFX {
    enum Cue: String, CaseIterable {
        case start, stop, done, pause, resume, cancel, mode, error
        var gain: Float {   // per-cue base level (scaled by the user's volume setting)
            switch self {
            case .done:  return 1.0
            case .start: return 0.8
            case .error: return 0.85
            default:     return 0.7
            }
        }
    }

    private static var cache: [String: NSSound?] = [:]

    static func play(_ cue: Cue) {
        guard Settings.shared.soundsEnabled else { return }
        // ONLY play a bundled custom sound. No macOS system fallback, so cues without a file
        // (stop, pause, resume, cancel, mode by default) stay silent, no parasitic system beep.
        guard let s = sound(for: cue) else { return }
        s.volume = cue.gain * Float(max(0, min(1, Settings.shared.soundVolume)))
        s.stop()       // restart cleanly if it's already playing
        s.play()
    }

    private static func sound(for cue: Cue) -> NSSound? {
        if let cached = cache[cue.rawValue] { return cached }   // may be nil (no file) → cached as "no sound"
        let s: NSSound? = {
            guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "mp3", subdirectory: "Sounds") else { return nil }
            return NSSound(contentsOf: url, byReference: true)
        }()
        cache[cue.rawValue] = s
        return s
    }

    // Convenience wrappers used across the app.
    static func start()  { play(.start) }
    static func stop()   { play(.stop) }
    static func done()   { play(.done) }
    static func pause()  { play(.pause) }
    static func resume() { play(.resume) }
    static func cancel() { play(.cancel) }
    static func mode()   { play(.mode) }
    static func error()  { play(.error) }
}
