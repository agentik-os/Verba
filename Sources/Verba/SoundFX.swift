import AppKit

/// Subtle audio cues so you know recording started/stopped without looking.
enum SoundFX {
    private static func play(_ name: String, _ volume: Float) {
        guard let s = NSSound(named: name) else { return }
        s.volume = volume
        s.play()
    }
    static func start() { play("Tink", 0.35) }     // soft tick
    static func stop()  { play("Tink", 0.25) }
    static func done()  { play("Pop", 0.55) }       // soft, cute "plop" when the text lands
}
