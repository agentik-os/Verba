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
    var escapeShouldCancel: (() -> Bool)?  // true only while something is in flight to cancel
    var onFnDown: (() -> Void)?      // Fn (globe) pressed
    var onFnUp: (() -> Void)?        // Fn (globe) released
    var onControl: (() -> Void)?     // plain ⌃ tapped (used to pause/resume while recording)

    private var globalFlags: Any?
    private var localFlags: Any?
    private var globalKeys: Any?
    private var localKeys: Any?
    private var chordHeld = false
    private var fnHeld = false
    private var ctrlPresent = false                 // edge-tracking for the plain-Control pause/resume tap
    private var optSeenDuringCtrl = false            // Option co-present during the Control press → ⌃⌥ chord, not a pause tap
    // Pause/resume debounce is the SHARED FnTap.claimControlFire() gate, so this NSEvent fallback
    // and the HID tap can never double-fire during the tap (re)start window.
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
        chordHeld = false; ctrlPresent = false; optSeenDuringCtrl = false
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
        //
        // Fire on the Control-UP edge, not the down edge: a ⌃⌥ chord begins with a lone
        // Control-down, so firing on down emitted a phantom pause/resume. Latch whether Option was
        // ever co-present during the press; a lone ⌃ tap pauses, a ⌃⌥ chord does not. Global
        // NSEvent monitors can drop the Control RELEASE, so we also clear the latch whenever
        // Control is fully absent — a missed release can't block the next press.
        if !FnTap.shared.active {
            let ctrlHeld = f.contains(.control)
            let optHeld = f.contains(.option)
            if ctrlHeld {
                if !ctrlPresent { ctrlPresent = true; optSeenDuringCtrl = optHeld }
                if optHeld { optSeenDuringCtrl = true }
            } else if ctrlPresent {
                let wasChord = optSeenDuringCtrl
                ctrlPresent = false
                optSeenDuringCtrl = false
                if !wasChord, FnTap.claimControlFire() {
                    DispatchQueue.main.async { self.onControl?() }
                }
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
            // When the Fn event tap is live it owns the Esc-cancel gesture (gated behind its own
            // escapeShouldCancel), so skip here to avoid running cancelEverything() twice during a
            // recording — mirrors the onControl gate above.
            if FnTap.shared.active { return }
            // Otherwise gate on the same "is anything in flight" predicate FnTap uses, so a global
            // Esc pressed to dismiss a dialog in another app doesn't run the full idle-teardown.
            if escapeShouldCancel?() != true { return }
            DispatchQueue.main.async { self.onEscape?() }
            return
        }
    }
}
