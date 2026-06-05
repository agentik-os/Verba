import AppKit

/// Watches the Fn (globe) key globally via flagsChanged events. The Fn key can't
/// be registered as a Carbon hotkey, so we monitor modifier-flag changes instead.
/// Needs Accessibility/Input-Monitoring trust (same grant used for auto-paste).
final class FnMonitor {
    static let shared = FnMonitor()

    var onDown: (() -> Void)?
    var onUp: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var fnDown = false
    private static let fnKeyCode: UInt16 = 63   // the globe/Fn key

    func start() {
        stop()
        let handler: (NSEvent) -> Void = { [weak self] event in self?.handle(event) }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event); return event
        }
    }

    func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor { NSEvent.removeMonitor(l); localMonitor = nil }
        fnDown = false
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == Self.fnKeyCode else { return }
        let isDown = event.modifierFlags.contains(.function)
        if isDown && !fnDown {
            fnDown = true
            DispatchQueue.main.async { self.onDown?() }
        } else if !isDown && fnDown {
            fnDown = false
            DispatchQueue.main.async { self.onUp?() }
        }
    }
}
