import SwiftUI
import AppKit
import Carbon.HIToolbox

/// "Click to record a shortcut" control. Captures the next key combo and reports
/// it back via `onCapture(keyCode, carbonModifiers)`. Generic so it drives both
/// the primary trigger and each profile's dedicated shortcut.
struct ShortcutRecorder: View {
    let label: String
    var onCapture: (UInt32, UInt32) -> Void
    var onClear: (() -> Void)? = nil

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button {
                recording ? cancel() : begin()
            } label: {
                Text(recording ? L("Hold ⌘ / ⌥ / ⌃ + a key…  (Esc)") : (label.isEmpty ? L("None") : label))
                    .frame(minWidth: 110)
                    .monospacedDigit()
            }
            .glass(interactive: true, in: Capsule())

            if let onClear, !label.isEmpty, !recording {
                Button { onClear() } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear { cancel() }
    }

    private func begin() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) { cancel(); return nil }
            let mods = carbonModifiers(from: event.modifierFlags)
            // Require a non-shift modifier so the global shortcut is safe.
            guard mods & UInt32(cmdKey | optionKey | controlKey) != 0 else { return nil }
            onCapture(UInt32(event.keyCode), mods)
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
