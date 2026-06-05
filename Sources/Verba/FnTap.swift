import AppKit
import Carbon.HIToolbox

/// A CGEventTap for the Fn (globe) key when it's the primary trigger. Unlike an
/// NSEvent monitor, a tap can *consume* events — so we can swallow the bare globe
/// key (no emoji/keyboard-switch popup) and capture digit keys for the mode picker
/// without them typing into the focused app. Requires Accessibility trust.
final class FnTap {
    static let shared = FnTap()

    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?
    /// Called for digit keys while `consumeDigits` is true; return true to consume.
    var onDigit: ((Int) -> Bool)?
    var consumeDigits = false

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var fnDown = false

    func start() {
        guard tap == nil else { return }
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let me = Unmanaged.passUnretained(self).toOpaque()
        guard let t = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                let tap = Unmanaged<FnTap>.fromOpaque(refcon!).takeUnretainedValue()
                return tap.handle(type, event)
            }, userInfo: me) else { return }
        tap = t
        source = CFMachPortCreateRunLoopSource(nil, t, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
    }

    func stop() {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false) }
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), s, .commonModes) }
        tap = nil; source = nil; fnDown = false; consumeDigits = false
    }

    // Runs on the main run loop (we add the source to the current/main loop).
    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
            return Unmanaged.passUnretained(event)

        case .flagsChanged:
            let fn = event.flags.contains(.maskSecondaryFn)
            if fn && !fnDown { fnDown = true; onFnDown?() }
            else if !fn && fnDown { fnDown = false; onFnUp?() }
            return Unmanaged.passUnretained(event)

        case .keyDown:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            if code == 63 { return nil }   // swallow the bare globe key (kill the popup/switch)
            if consumeDigits, let n = Self.digit(forKeyCode: Int(code)), onDigit?(n) == true {
                return nil
            }
            return Unmanaged.passUnretained(event)

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private static func digit(forKeyCode code: Int) -> Int? {
        switch code {
        case kVK_ANSI_1: return 1; case kVK_ANSI_2: return 2; case kVK_ANSI_3: return 3
        case kVK_ANSI_4: return 4; case kVK_ANSI_5: return 5; case kVK_ANSI_6: return 6
        case kVK_ANSI_7: return 7; case kVK_ANSI_8: return 8; case kVK_ANSI_9: return 9
        default: return nil
        }
    }
}
