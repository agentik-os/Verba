import AppKit
import Carbon.HIToolbox

/// CGEventTap for the Fn (globe) key when it's the primary trigger. Unlike an
/// NSEvent monitor, a tap can *consume* events — so we swallow the bare globe key
/// (no emoji/keyboard popup) and capture digit/arrow/enter keys for the mode
/// picker without them reaching the focused app. Requires Accessibility trust.
final class FnTap {
    static let shared = FnTap()

    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?
    var onDigit: ((Int) -> Bool)?     // 1–9 while menuActive; return true to consume
    var onArrow: ((Int) -> Bool)?     // -1 left / +1 right while menuActive
    var onEnter: (() -> Bool)?        // return / enter while menuActive
    var menuActive = false

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var fnDown = false

    func start() {
        guard tap == nil else { return }
        FnSystemPref.suppress()   // also set "Press 🌐 to: Do Nothing" so macOS shows no HUD
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let me = Unmanaged.passUnretained(self).toOpaque()
        // HID-level tap: sees the globe key before HIToolbox, so consuming it kills
        // the input-source / emoji HUD. Falls back to session level if unavailable.
        let tapped = CGEvent.tapCreate(
            tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                Unmanaged<FnTap>.fromOpaque(refcon!).takeUnretainedValue().handle(type, event)
            }, userInfo: me)
        guard let t = tapped ?? CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                Unmanaged<FnTap>.fromOpaque(refcon!).takeUnretainedValue().handle(type, event)
            }, userInfo: me) else { return }
        tap = t
        source = CFMachPortCreateRunLoopSource(nil, t, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
    }

    func stop() {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false) }
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), s, .commonModes) }
        tap = nil; source = nil; fnDown = false; menuActive = false
        FnSystemPref.restore()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
            return Unmanaged.passUnretained(event)

        case .flagsChanged:
            let fn = event.flags.contains(.maskSecondaryFn)
            let bareFn = event.flags.subtracting([.maskSecondaryFn, .maskNonCoalesced]).isEmpty
            if fn && !fnDown { fnDown = true; onFnDown?() }
            else if !fn && fnDown { fnDown = false; onFnUp?() }
            return bareFn ? nil : Unmanaged.passUnretained(event)

        case .keyDown:
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            if code == 63 { return nil }                          // bare globe key
            if menuActive {
                if let n = Self.digit(code), onDigit?(n) == true { return nil }
                if code == kVK_LeftArrow,  onArrow?(-1) == true { return nil }
                if code == kVK_RightArrow, onArrow?(1) == true { return nil }
                if (code == kVK_Return || code == kVK_ANSI_KeypadEnter), onEnter?() == true { return nil }
            }
            return Unmanaged.passUnretained(event)

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private static func digit(_ code: Int) -> Int? {
        switch code {
        case kVK_ANSI_1: return 1; case kVK_ANSI_2: return 2; case kVK_ANSI_3: return 3
        case kVK_ANSI_4: return 4; case kVK_ANSI_5: return 5; case kVK_ANSI_6: return 6
        case kVK_ANSI_7: return 7; case kVK_ANSI_8: return 8; case kVK_ANSI_9: return 9
        default: return nil
        }
    }
}

/// Sets the system "Press 🌐 to:" action to "Do Nothing" while Verba owns the Fn
/// key, then restores it. This is how dictation apps stop macOS from popping the
/// input-source / emoji HUD on Fn.
enum FnSystemPref {
    private static let key = "AppleFnUsageType"
    private static let domain = ".GlobalPreferences"
    private static var saved: Int??

    static func suppress() {
        let d = UserDefaults(suiteName: domain)
        if saved == nil { saved = .some(d?.object(forKey: key) as? Int) }  // remember once
        d?.set(0, forKey: key)   // 0 = Do Nothing
    }
    static func restore() {
        guard let saved else { return }
        let d = UserDefaults(suiteName: domain)
        if let v = saved { d?.set(v, forKey: key) } else { d?.removeObject(forKey: key) }
        Self.saved = nil
    }
}
