import AppKit
import Carbon.HIToolbox
import ApplicationServices

enum Output {
    /// Bundle id of the app that was frontmost (captured before we showed any UI).
    static func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    /// The text currently selected in the frontmost app's focused field, via the
    /// Accessibility API. Returns nil if nothing is selected or AX isn't granted.
    static func selectedText() -> String? {
        guard accessibilityTrusted else { return nil }
        let system = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused else { return nil }
        let element = focused as! AXUIElement
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success,
              let text = value as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    static func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// Whether we're trusted for Accessibility (needed to synthesize ⌘V into other apps).
    static var accessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func promptAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    /// Put text on the clipboard and paste it into the frontmost app via ⌘V.
    /// Returns false if Accessibility isn't granted (caller can fall back to clipboard only).
    @discardableResult
    static func paste(_ text: String) -> Bool {
        copyToClipboard(text)
        guard accessibilityTrusted else { return false }

        let src = CGEventSource(stateID: .combinedSessionState)
        let v = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: false)
        up?.flags = .maskCommand
        // Small delay so the previously-focused app is ready to receive the paste.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
        return true
    }
}
