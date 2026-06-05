import Foundation
import Carbon.HIToolbox
import AppKit

/// A single global hotkey via Carbon RegisterEventHotKey (no dependencies, works
/// system-wide without Accessibility). Fires `onPress` on the main thread.
/// Default: ⌃⌥Space (avoids clashing with LiquidPad's ⌥Space).
final class HotKey {
    static let shared = HotKey()

    var onPress: (() -> Void)?
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?

    // Stored as keyCode + Carbon modifier mask in UserDefaults so the user can rebind it.
    private(set) var keyCode: UInt32
    private(set) var modifiers: UInt32

    private init() {
        let d = UserDefaults.standard
        keyCode = UInt32(d.object(forKey: "hotkeyCode") as? Int ?? kVK_Space)
        modifiers = UInt32(d.object(forKey: "hotkeyMods") as? Int ?? (controlKey | optionKey))
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData = userData else { return noErr }
            let me = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { me.onPress?() }
            return noErr
        }, 1, &eventType, selfPtr, &handler)

        let hotKeyID = EventHotKeyID(signature: OSType(0x41575348 /* 'AWSH' */), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref); self.ref = nil }
        if let handler { RemoveEventHandler(handler); self.handler = nil }
    }

    func rebind(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "hotkeyMods")
        register()
    }

    /// Human-readable label like "⌃⌥Space".
    var label: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        s += Self.keyName(keyCode)
        return s
    }

    static func keyName(_ code: UInt32) -> String {
        switch Int(code) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_ANSI_Grave: return "`"
        default:
            // Best-effort letter mapping for common ANSI keys.
            let map: [Int: String] = [
                kVK_ANSI_A: "A", kVK_ANSI_S: "S", kVK_ANSI_D: "D", kVK_ANSI_W: "W",
                kVK_ANSI_R: "R", kVK_ANSI_V: "V", kVK_ANSI_Q: "Q", kVK_ANSI_E: "E",
            ]
            return map[Int(code)] ?? "key\(code)"
        }
    }
}
