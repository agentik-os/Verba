import AppKit
import Carbon.HIToolbox
import IOKit.hid

/// CGEventTap for the Fn (globe) key when it's the primary trigger. Unlike an
/// NSEvent monitor, a tap can *consume* events, so we swallow the bare globe key
/// (no emoji/keyboard popup) and capture digit/arrow/enter keys for the mode
/// picker without them reaching the focused app. Requires Accessibility trust.
final class FnTap {
    static let shared = FnTap()

    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?
    var onFnControl: (() -> Void)?    // ⌥+Fn → today's to-do glance (Option held at Fn-down, or Option tapped mid-Fn-hold)
    var onModeCycle: ((Int) -> Void)? // Fn + Tab → next mode (+1) / Fn + ⇧ + Tab → previous (-1)
    var onStyleCycle: ((Int) -> Void)? // Fn + ] → next style (+1) / Fn + [ → previous (-1)
    var onNoteRecord: (() -> Void)?   // Fn + Z → record a new note
    var onTodoCapture: (() -> Void)?  // Fn + § → voice "add to-do" capture
    var onActionMode: (() -> Void)?   // Fn + X → Action mode: speech CONTROLS the Mac (confirm → execute)
    var onDigit: ((Int) -> Bool)?     // 1-9 while menuActive; return true to consume
    var onArrow: ((Int) -> Bool)?     // -1 left / +1 right while menuActive
    var onEnter: (() -> Bool)?        // return / enter while menuActive
    var onControl: (() -> Void)?      // plain ⌃ tapped → pause/resume the current recording
    var onOptionTap: (() -> Void)?    // lone ⌥ tapped (no ⌃, no Fn) → switch mode while hands-free recording
    var menuActive = false

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var fnDown = false
    private var optDown = false   // Option held during the current Fn-hold (fires onFnControl → to-do glance)
    private var ctrlPresent = false             // edge-tracking for the plain-Control pause/resume tap
    private var optSeenDuringCtrl = false        // Option co-present during the current Control press → it's a ⌃⌥ chord, NOT a pause tap
    private var lastControlFire: TimeInterval = 0   // debounce so one physical tap fires once
    private var optPresent = false              // edge-tracking for the lone-Option mode-switch tap
    private var optCombo = false                 // Control or Fn co-present during the Option press → NOT a lone-Option tap
    private var lastOptionFire: TimeInterval = 0

    /// True once the event tap is live. False means Accessibility/Input-Monitoring is not
    /// granted (the tap couldn't be created), so the Fn key does nothing until the user grants it.
    private(set) var active = false

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return active }
        // Ask for Input Monitoring so the HID-level tap can actually consume events.
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        FnSystemPref.suppress()   // "Press 🌐 to: Do Nothing" + disable input-source symbolic hotkeys
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
            }, userInfo: me) else { active = false; return false }
        tap = t
        source = CFMachPortCreateRunLoopSource(nil, t, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        active = true
        return true
    }

    func stop() {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false) }
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), s, .commonModes) }
        tap = nil; source = nil; fnDown = false; optDown = false; menuActive = false; active = false
        ctrlPresent = false; optSeenDuringCtrl = false
        optPresent = false; optCombo = false
        FnSystemPref.restore()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
            return Unmanaged.passUnretained(event)

        case .flagsChanged:
            let fn = event.flags.contains(.maskSecondaryFn)
            let opt = event.flags.contains(.maskAlternate)
            let bareFn = event.flags.subtracting([.maskSecondaryFn, .maskNonCoalesced]).isEmpty

            // Plain Control (no Option) → pause/resume the active recording. The HID tap sees
            // EVERY flagsChanged at head-insert, so this is the reliable path (the NSEvent global
            // monitor in ChordMonitor drops modifier events unpredictably across launches). We fire
            // on the Control-UP edge, NOT the down edge: a ⌃⌥ chord (mode picker) and Direct
            // push-to-talk (⌃⌥) both BEGIN with a lone Control-down, so firing on down emitted a
            // phantom pause/resume. By deciding on release and latching whether Option was ever
            // co-present during the press, a lone ⌃ tap pauses while a ⌃⌥ chord does not. Fn may be
            // co-held (hold+Fn dictation) — that's fine, we key off Control alone, ignoring Fn.
            let ctrlHeld = event.flags.contains(.maskControl)
            if ctrlHeld {
                if !ctrlPresent { ctrlPresent = true; optSeenDuringCtrl = opt }
                if opt { optSeenDuringCtrl = true }   // Option arrived during the press → it's a chord
            } else if ctrlPresent {
                // Control released. Fire pause/resume only if this was a lone-Control press.
                let wasChord = optSeenDuringCtrl
                ctrlPresent = false
                optSeenDuringCtrl = false
                if !wasChord {
                    let now = ProcessInfo.processInfo.systemUptime
                    // Short debounce on a per-release edge: a deliberate fast second tap (after a
                    // real release) always registers; this only swallows a duplicate up event.
                    if now - lastControlFire > 0.12 {
                        lastControlFire = now
                        if let cb = onControl { DispatchQueue.main.async(execute: cb) }
                    }
                }
            }
            // Lone ⌥ (Option) tap → switch mode while hands-free recording (AppDelegate gates on
            // state == .recording). Mirror the Control logic: decide on the Option-UP edge and latch
            // whether Control or Fn was EVER co-present during the press, so a ⌃⌥ chord (mode picker)
            // and ⌥+Fn (to-do glance) never fire this. In hold-to-talk, Fn is held → optCombo latches
            // → it correctly does nothing.
            if opt {
                if !optPresent { optPresent = true; optCombo = ctrlHeld || fn }
                if ctrlHeld || fn { optCombo = true }
            } else if optPresent {
                let wasCombo = optCombo
                optPresent = false; optCombo = false
                if !wasCombo {
                    let now = ProcessInfo.processInfo.systemUptime
                    if now - lastOptionFire > 0.12 {
                        lastOptionFire = now
                        if let cb = onOptionTap { DispatchQueue.main.async(execute: cb) }
                    }
                }
            }
            // Plain Fn records. ⌥+Fn (Option held when Fn goes down) pops the today's-to-do glance
            // instead of recording; tapping ⌥ while Fn is already held also triggers the glance.
            if fn && !fnDown {
                fnDown = true; optDown = opt
                if opt { onFnControl?() } else { onFnDown?() }
            } else if !fn && fnDown {
                fnDown = false; optDown = false; onFnUp?()
            } else if fn && fnDown {
                // Fn stayed down; an Option key transition arrived. A fresh Option-press mid-hold
                // fires the ⌥+Fn gesture (today's to-do glance).
                if opt && !optDown { optDown = true; onFnControl?() }
                else if !opt { optDown = false }
            }
            return bareFn ? nil : Unmanaged.passUnretained(event)

        case .keyDown:
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            if code == 63 { return nil }                          // bare globe key
            // Fn + § (ISO section key) → voice "add to-do" capture; Fn + Z → record a new note (anywhere).
            if fnDown, code == kVK_ISO_Section, onTodoCapture != nil { onTodoCapture?(); return nil }
            if fnDown, code == kVK_ANSI_Z, onNoteRecord != nil { onNoteRecord?(); return nil }
            // Fn + X → Action mode: the spoken request is a command that CONTROLS the Mac
            // (run a Shortcut / open an app / play music / send a message / …), confirmed before it runs.
            if fnDown, code == kVK_ANSI_X, onActionMode != nil { onActionMode?(); return nil }
            // Fn + Tab → next mode, Fn + ⇧ + Tab → previous. Works even mid-dictation.
            if fnDown, code == kVK_Tab {
                onModeCycle?(event.flags.contains(.maskShift) ? -1 : 1); return nil
            }
            // Fn + ] → next style, Fn + [ → previous style. A second prompt layer on top of the mode.
            if fnDown, code == kVK_ANSI_RightBracket, onStyleCycle != nil { onStyleCycle?(1); return nil }
            if fnDown, code == kVK_ANSI_LeftBracket, onStyleCycle != nil { onStyleCycle?(-1); return nil }
            // Fn + number selects a mode whenever Fn is held (or the picker menu is open).
            // While Fn is held, ALWAYS consume a mapped digit 1-9 (never leak the literal digit to
            // the focused app) — the handler simply no-ops when the index is out of profile range.
            if menuActive || fnDown {
                if let n = Self.digit(code) {
                    let handled = onDigit?(n) == true
                    if fnDown { return nil }                 // Fn held → consume regardless of range
                    if menuActive, handled { return nil }    // picker open → consume only if it took the digit
                }
            }
            // Arrow navigation + Enter ONLY while the picker is open (no global conflict).
            if menuActive {
                if (code == kVK_LeftArrow || code == kVK_UpArrow), onArrow?(-1) == true { return nil }
                if (code == kVK_RightArrow || code == kVK_DownArrow), onArrow?(1) == true { return nil }
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

/// Owns the system "Press 🌐 to:" action while Verba uses the Fn key. The globe HUD is a
/// HIToolbox/WindowServer behaviour a CGEventTap cannot veto, so the ONLY reliable
/// suppression is AppleFnUsageType = 3 ("Do Nothing") applied live via activateSettings.
/// (Crucial: on macOS 14/15, 0 = "Change Input Source" — that WAS the HUD. 3 = Do Nothing.)
/// The symbolic-hotkey toggles additionally kill the emoji + Ctrl-Space chord switchers.
enum FnSystemPref {
    // The authoritative "Press 🌐 to:" pref lives in com.apple.HIToolbox (NOT .GlobalPreferences,
    // which macOS ignores for this key). It must be set on BOTH the AnyHost and CurrentHost
    // scopes for the WindowServer to honour it. This is what actually kills the globe input
    // switcher / emoji HUD, even with multiple keyboard layouts.
    private static let key = "AppleFnUsageType" as CFString
    private static let appID = "com.apple.HIToolbox" as CFString
    private static var saved: Int??
    private static let kDoNothing = 3                  // 0=Change Input Source, 1=Emoji, 2=Dictation, 3=Do Nothing

    private static func readFn() -> Int? {
        CFPreferencesCopyValue(key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? Int
            ?? CFPreferencesCopyValue(key, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost) as? Int
    }
    private static func writeFn(_ v: Int?) {
        let val = v.map { $0 as CFNumber }
        for host in [kCFPreferencesAnyHost, kCFPreferencesCurrentHost] {
            CFPreferencesSetValue(key, val, appID, kCFPreferencesCurrentUser, host)
            CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, host)
        }
    }

    // Emoji palette (50) + select previous/next input source chords (60/61). NOT the globe key.
    private static let inputSourceHotKeys: [Int32] = [50, 60, 61]
    private static var disabledSHK: [Int32] = []

    // Private SkyLight API (CoreGraphics re-exports the CGS aliases). Resolve SLS first.
    private typealias SetSHK = @convention(c) (Int32, Bool) -> Int32   // CGError, 0 = ok
    private typealias IsSHK  = @convention(c) (Int32) -> Bool          // direct return
    private static let setEnabled: SetSHK? = sym("SLSSetSymbolicHotKeyEnabled") ?? sym("CGSSetSymbolicHotKeyEnabled")
    private static let isEnabled: IsSHK?   = sym("SLSIsSymbolicHotKeyEnabled") ?? sym("CGSIsSymbolicHotKeyEnabled")
    private static func sym<T>(_ name: String) -> T? {
        guard let h = dlopen(nil, RTLD_NOW), let p = dlsym(h, name) else { return nil }
        return unsafeBitCast(p, to: T.self)
    }

    static func suppress() { apply() }

    /// Re-apply when the related settings change (Settings ▸ Fn key).
    static func reapply() { apply() }

    /// Cheap check (CFPreferences read, no subprocess): is "Press 🌐 to" already Do Nothing?
    static var isSuppressedLive: Bool { readFn() == kDoNothing }

    /// Light self-heal for app-focus: only spend the activateSettings subprocess if the value
    /// actually drifted away from Do Nothing.
    static func reapplyIfDrifted() {
        guard Settings.shared.suppressFnPopup, readFn() != kDoNothing else { return }
        apply()
    }

    /// Apply the user's Fn-key preferences:
    ///  • suppressFnPopup → set "Press 🌐 to: Do Nothing" (no emoji/Fn HUD); else restore macOS default.
    ///  • disableInputSwitcher → disable the emoji palette + input-source switch chords; else re-enable.
    private static func apply() {
        if saved == nil { saved = .some(readFn()) }

        if Settings.shared.suppressFnPopup {
            if readFn() != kDoNothing { writeFn(kDoNothing) }
            applySettingsLive()   // ALWAYS refresh the live WindowServer state, even if already 3.
        } else if let saved, readFn() == kDoNothing {
            writeFn(saved)        // restore the user's original Fn behaviour (saved may be nil → remove)
            applySettingsLive()
        }

        if Settings.shared.disableInputSwitcher {
            for id in inputSourceHotKeys where isEnabled?(id) == true {
                if setEnabled?(id, false) == 0, !disabledSHK.contains(id) { disabledSHK.append(id) }
            }
        } else {
            for id in disabledSHK { _ = setEnabled?(id, true) }
            disabledSHK = []
        }
    }

    static func restore() {
        if let saved {
            writeFn(saved)        // saved is the original Int? (nil → remove the override)
            applySettingsLive()
            Self.saved = nil
        }
        for id in disabledSHK { _ = setEnabled?(id, true) }
        disabledSHK = []
    }

    /// Apple's private tool that re-reads keyboard/hotkey pref domains and re-binds them
    /// immediately, the no-logout path System Settings itself uses.
    private static func applySettingsLive() {
        let p = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
        guard FileManager.default.isExecutableFile(atPath: p) else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: p)
        task.arguments = ["-u"]
        try? task.run()
    }
}
