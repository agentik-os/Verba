import AppKit
import Carbon.HIToolbox

/// Global watcher for the ⌃⌥ chord (to show the mode widget), its release
/// (push-to-talk in Direct style), and the Escape key (to cancel a recording).
/// Uses NSEvent monitors, needs Accessibility/Input-Monitoring trust (same grant
/// as auto-paste).
final class ChordMonitor {
    static let shared = ChordMonitor()

    var onChordDown: (() -> Void)?   // ⌃⌥ became held
    var onChordUp: (() -> Void)?     // ⌃⌥ released
    var onEscape: (() -> Void)?      // Esc pressed
    var onFnDown: (() -> Void)?      // Fn (globe) pressed
    var onFnUp: (() -> Void)?        // Fn (globe) released
    var onControl: (() -> Void)?     // plain ⌃ tapped (used to pause/resume while recording)

    private var globalFlags: Any?
    private var localFlags: Any?
    private var globalKeys: Any?
    private var localKeys: Any?
    private var chordHeld = false
    private var fnHeld = false
    private var lastControlFire: TimeInterval = 0   // debounce for the Control pause/resume tap
    private static let fnKeyCode: UInt16 = 63   // the globe / Fn key

    func start() {
        stop()
        let flags: (NSEvent) -> Void = { [weak self] e in self?.handleFlags(e) }
        globalFlags = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: flags)
        localFlags = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in self?.handleFlags(e); return e }

        let keys: (NSEvent) -> Void = { [weak self] e in self?.handleKey(e) }
        globalKeys = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: keys)
        localKeys = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == UInt16(kVK_Escape), self?.onEscape != nil { self?.handleKey(e) }
            return e
        }
    }

    func stop() {
        [globalFlags, localFlags, globalKeys, localKeys].forEach { if let m = $0 { NSEvent.removeMonitor(m) } }
        globalFlags = nil; localFlags = nil; globalKeys = nil; localKeys = nil
        chordHeld = false
    }

    private func handleFlags(_ e: NSEvent) {
        let f = e.modifierFlags
        let both = f.contains(.control) && f.contains(.option)
        if both && !chordHeld {
            chordHeld = true
            DispatchQueue.main.async { self.onChordDown?() }
        } else if !both && chordHeld {
            chordHeld = false
            DispatchQueue.main.async { self.onChordUp?() }
        }

        // Plain Control (no Option) → pause/resume. When the Fn event tap is live it owns this
        // gesture (it sees every flagsChanged at HID head-insert, where the NSEvent global monitor
        // here drops modifier events unpredictably across launches) — so skip to avoid a double
        // trigger. This path remains the fallback when Fn is NOT the primary trigger (tap off).
        // We DON'T track a held/released latch: global NSEvent monitors can drop the Control
        // RELEASE, which used to leave a latch stuck "held". Fire on every Control-present edge
        // with a short time debounce — one physical tap is one down event (the up event has
        // Control absent, ignored), and a missed release can no longer block the next press.
        let ctrlDown = f.contains(.control) && !f.contains(.option)
        if ctrlDown, !FnTap.shared.active {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastControlFire > 0.3 {
                lastControlFire = now
                DispatchQueue.main.async { self.onControl?() }
            }
        }

        // Fn / globe key, isolate by its own keyCode so other keys held with Fn don't fire it.
        if e.keyCode == Self.fnKeyCode {
            let down = f.contains(.function)
            if down && !fnHeld {
                fnHeld = true
                DispatchQueue.main.async { self.onFnDown?() }
            } else if !down && fnHeld {
                fnHeld = false
                DispatchQueue.main.async { self.onFnUp?() }
            }
        }
    }

    private func handleKey(_ e: NSEvent) {
        if e.keyCode == UInt16(kVK_Escape) {
            DispatchQueue.main.async { self.onEscape?() }
        }
    }
}
