import AppKit

/// Subtle audio cues so you know recording started/stopped without looking at the menu bar.
enum SoundFX {
    private static func play(_ name: String) {
        NSSound(named: name)?.play()
    }
    static func start() { play("Pop") }
    static func stop()  { play("Tink") }
    static func done()  { play("Glass") }
}
