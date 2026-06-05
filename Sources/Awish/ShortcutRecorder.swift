import SwiftUI
import AppKit
import Carbon.HIToolbox

/// A small "click to record a shortcut" control. Captures the next key combo and
/// rebinds the global Carbon hotkey.
struct ShortcutRecorder: View {
    @State private var recording = false
    @State private var label = HotKey.shared.label
    @State private var monitor: Any?

    var body: some View {
        Button {
            recording ? cancel() : begin()
        } label: {
            Text(recording ? "Press a shortcut…  (Esc to cancel)" : label)
                .frame(minWidth: 180)
                .monospacedDigit()
        }
        .glass(interactive: true, in: Capsule())
        .onDisappear { cancel() }
    }

    private func begin() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) { cancel(); return nil }
            let mods = carbonModifiers(from: event.modifierFlags)
            // Require at least one non-shift modifier so the combo is globally safe.
            guard mods & UInt32(cmdKey | optionKey | controlKey) != 0 else { return nil }
            HotKey.shared.rebind(keyCode: UInt32(event.keyCode), modifiers: mods)
            label = HotKey.shared.label
            cancel()
            return nil
        }
    }

    private func cancel() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        recording = false
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.option)  { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        if flags.contains(.shift)   { m |= UInt32(shiftKey) }
        return m
    }
}
