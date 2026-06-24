import AppKit
import Carbon.HIToolbox
import ApplicationServices

/// A snapshot of the field that was focused when recording STARTED, so auto-paste can
/// deliver the text back into the *original* field even after the user switched Space/app
/// while the dictation was processing. Captures the app (bundle id + pid) and, when
/// Accessibility is granted, the exact focused AX element so we can write to it directly
/// (often without a visible Space switch).
struct PasteTarget {
    let bundleID: String?
    let pid: pid_t?
    let element: AXUIElement?   // the AX focused element at record start (may be stale by paste time)
}

enum Output {
    /// Bundle id of the app that was frontmost (captured before we showed any UI).
    static func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    /// Snapshot the frontmost app + its focused field at record start. Used so auto-paste
    /// can restore focus to the ORIGINAL target later, even across Space/app switches.
    static func captureTarget() -> PasteTarget {
        let app = NSWorkspace.shared.frontmostApplication
        var element: AXUIElement?
        if accessibilityTrusted, let pid = app?.processIdentifier {
            // Ask the target app directly (not the system-wide element) for its focused
            // UI element, so the reference survives the user moving focus elsewhere.
            let appEl = AXUIElementCreateApplication(pid)
            var focused: AnyObject?
            if AXUIElementCopyAttributeValue(appEl, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
               let focused {
                element = (focused as! AXUIElement)
            }
        }
        return PasteTarget(bundleID: app?.bundleIdentifier, pid: app?.processIdentifier, element: element)
    }

    // Smart formatting (#7): rich text/markdown for apps that render it, plain for code/terminals.
    private static let plainTextApps: Set<String> = [
        "com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable",
        "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92" /* Cursor */, "com.apple.dt.Xcode",
        "com.sublimetext.4", "com.jetbrains.intellij", "com.github.atom", "org.alacritty",
    ]
    private static let richTextApps: Set<String> = [
        "com.apple.mail", "com.microsoft.Outlook", "com.readdle.smartemail-Mac", "notion.id",
        "com.apple.TextEdit", "com.apple.iWork.Pages", "net.shinyfrog.bear", "md.obsidian",
        "com.apple.Notes", "com.microsoft.Word",
    ]
    // Multi-line editors where a trailing newline is content, not an accidental submit: code
    // editors/terminals and long-form writing apps never auto-send on a trailing \n. For these we
    // preserve a SINGLE trailing newline so intentional multi-paragraph dictation isn't mangled,
    // unlike chat/search/single-line fields (Slack, iMessage, browser URL bars) where a trailing
    // newline submits — there we still strip it. Editors are the union of the code-plain set and
    // the long-form rich-text writing apps.
    private static let multiLineEditorApps: Set<String> =
        plainTextApps.union([
            "notion.id", "com.apple.TextEdit", "com.apple.iWork.Pages", "net.shinyfrog.bear",
            "md.obsidian", "com.apple.Notes", "com.microsoft.Word",
        ])

    /// Whether the target app is a multi-line editor where a single trailing newline is meaningful
    /// (paragraph break) rather than an accidental message submit. Drives whether we preserve one
    /// trailing newline on paste. Unknown apps → false (keep the safe strip-everything behaviour).
    static func prefersTrailingNewline(_ bundleID: String?) -> Bool {
        guard let b = bundleID else { return false }
        return multiLineEditorApps.contains(b)
    }
    /// Decide rich vs plain for the target app. Known plain apps → plain; known rich apps →
    /// rich; otherwise fall back to the user's default.
    static func prefersRichText(_ bundleID: String?) -> Bool {
        guard let b = bundleID else { return Settings.shared.richTextPaste }
        if plainTextApps.contains(b) { return false }
        if richTextApps.contains(b) { return true }
        return Settings.shared.richTextPaste
    }

    /// Whether this delivery will be pasted as RICH text (Markdown rendered to styled
    /// rich text) for the given target app. Single source of truth shared by the paste
    /// path (AppDelegate) and the generation path (Pipeline), so when we render Markdown
    /// we also ask the model to PRODUCE Markdown structure. Mirrors the rich/plain
    /// decision exactly: Smart Formatting → per-app; otherwise the global toggle.
    static func willPasteRich(_ bundleID: String?) -> Bool {
        Settings.shared.smartFormatting ? prefersRichText(bundleID) : Settings.shared.richTextPaste
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

    /// Full text of the currently focused field (the whole value, not just the selection).
    /// Used by auto-learn to see how the user manually edited what we pasted.
    static func focusedValue() -> String? {
        guard accessibilityTrusted else { return nil }
        let system = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused else { return nil }
        let element = focused as! AXUIElement
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success,
              let text = value as? String, !text.isEmpty else { return nil }
        return text
    }

    /// `rich` writes a styled (RTF) representation from Markdown alongside clean
    /// plain text, so formatting apps render bold/headings/lists and plain fields
    /// get the de-marked text.
    static func copyToClipboard(_ text: String, rich: Bool = false, keepTrailingNewline: Bool = false) {
        // For multi-line editors (keepTrailingNewline) we preserve ONE trailing newline so
        // intentional paragraph dictation survives; everywhere else we strip all trailing
        // whitespace so auto-paste never lands a stray Return in a chat/search/single-line field.
        let text = keepTrailingNewline
            ? trimTrailingWhitespacePreservingOneNewline(text)
            : trimTrailingNewlines(text)
        let pb = NSPasteboard.general
        pb.clearContents()
        if rich {
            // HTML→NSAttributedString leaves a trailing newline that would submit in
            // single-line fields, strip any trailing whitespace from the rich text too.
            let m = NSMutableAttributedString(attributedString: Markdown.attributed(text))
            while let last = m.string.last, last == "\n" || last == "\r" || last == " " || last == "\t" {
                m.deleteCharacters(in: NSRange(location: m.length - 1, length: 1))
            }
            // Re-append the single paragraph newline for editors (the Markdown render dropped it).
            if keepTrailingNewline, text.last == "\n" {
                m.append(NSAttributedString(string: "\n"))
            }
            pb.writeObjects([m])
        } else {
            pb.setString(text, forType: .string)
        }
    }

    /// Strip trailing newlines/whitespace so auto-paste never lands a stray Return, /// a trailing newline submits the message in Slack/iMessage/search fields. We never
    /// synthesize Enter; this also kills any newline the transcript/Markdown left behind.
    static func trimTrailingNewlines(_ text: String) -> String {
        var t = Substring(text)
        while let last = t.last, last == "\n" || last == "\r" || last == " " || last == "\t" { t = t.dropLast() }
        return String(t)
    }

    /// Strip trailing whitespace but keep a SINGLE trailing newline when the original ended in one
    /// — for multi-line editors where a paragraph break is intentional content. Collapses runs of
    /// trailing newlines/spaces/tabs to exactly one "\n" (never more, so we still can't auto-submit
    /// a multi-line field by piling on blank lines).
    static func trimTrailingNewlinesPreservingOne(_ text: String) -> String {
        trimTrailingWhitespacePreservingOneNewline(text)
    }

    private static func trimTrailingWhitespacePreservingOneNewline(_ text: String) -> String {
        let hadNewline = { () -> Bool in
            var t = Substring(text)
            while let last = t.last, last == " " || last == "\t" { t = t.dropLast() }
            return t.last == "\n" || t.last == "\r"
        }()
        let stripped = trimTrailingNewlines(text)
        return hadNewline ? stripped + "\n" : stripped
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
    static func paste(_ text: String, rich: Bool = false, keepTrailingNewline: Bool = false) -> Bool {
        copyToClipboard(text, rich: rich, keepTrailingNewline: keepTrailingNewline)   // trims trailing newlines (keeping one for editors)
        guard accessibilityTrusted else { return false }
        postPasteShortcut(after: 0.05)
        return true
    }

    /// Synthesize ⌘V after a small delay (so the target app is ready to receive it).
    private static func postPasteShortcut(after delay: TimeInterval) {
        let src = CGEventSource(stateID: .combinedSessionState)
        let v = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: false)
        up?.flags = .maskCommand
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    /// Whether an AX element still looks usable as a paste destination (its app is alive
    /// and the element exposes a role). A torn-down element returns errors here.
    private static func elementIsAlive(_ el: AXUIElement) -> Bool {
        var role: AnyObject?
        let err = AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &role)
        return err == .success && role != nil
    }

    /// Auto-paste into the field that was focused when recording STARTED — even if the user
    /// switched Space/app while the dictation was processing. We re-activate the captured app
    /// (bringing its window/Space forward as needed), restore focus to the captured AX element
    /// when it's still alive, then synthesize ⌘V. Falls back to the plain frontmost paste if the
    /// original target is gone, so we never paste into the wrong app silently.
    /// Returns false only when Accessibility isn't granted (caller falls back to clipboard-only).
    @discardableResult
    static func paste(_ text: String, rich: Bool = false, target: PasteTarget?) -> Bool {
        // VER-24: auto-paste delivers text via the clipboard (⌘V), but it must not silently
        // overwrite whatever the user had copied. Unless they opted into keeping dictations on the
        // clipboard (Settings ▸ Copy to clipboard), snapshot the current clipboard now and put it
        // back once ⌘V has landed.
        let preserveClipboard = !Settings.shared.copyToClipboard
        let savedClipboard = preserveClipboard ? snapshotPasteboard() : []
        let scheduleRestore: () -> Void = {
            guard preserveClipboard else { return }
            // Well after ⌘V is delivered & consumed (the paste fires at +0.05–0.20s below).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { restorePasteboard(savedClipboard) }
        }

        // Preserve a single trailing newline only for multi-line editors (code/long-form), where a
        // paragraph break is intentional; chat/search/single-line targets still get a full strip so
        // we never auto-submit. The decision keys off the captured target's bundle id.
        copyToClipboard(text, rich: rich, keepTrailingNewline: prefersTrailingNewline(target?.bundleID))
        // No Accessibility → we couldn't paste; leave the text on the clipboard as the fallback
        // (don't restore), matching the caller's "Copied to clipboard" prompt.
        guard accessibilityTrusted else { return false }

        // No captured target (or capture failed) → behave exactly like the legacy paste.
        guard let target, let pid = target.pid,
              let app = NSRunningApplication(processIdentifier: pid),
              !app.isTerminated else {
            postPasteShortcut(after: 0.05)
            scheduleRestore()
            return true
        }

        // Already frontmost? No need to re-activate — paste straight away.
        let alreadyFront = NSWorkspace.shared.frontmostApplication?.processIdentifier == pid

        // Restore focus to the original element (best effort) so ⌘V lands in the right field.
        let restoreFocus: () -> Void = {
            if let el = target.element, elementIsAlive(el) {
                // Raise the element's window, then make it the focused UI element. This puts the
                // caret back in the exact field the user dictated into.
                var window: AnyObject?
                if AXUIElementCopyAttributeValue(el, kAXWindowAttribute as CFString, &window) == .success,
                   let window {
                    AXUIElementPerformAction((window as! AXUIElement), kAXRaiseAction as CFString)
                }
                AXUIElementSetAttributeValue(el, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            }
        }

        if alreadyFront {
            restoreFocus()
            postPasteShortcut(after: 0.05)
        } else {
            // Bring the captured app forward (this switches Space if it lives on another one —
            // acceptable per spec), wait for it to actually become active, then focus + paste.
            app.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                restoreFocus()
                postPasteShortcut(after: 0.05)
            }
        }
        scheduleRestore()
        return true
    }

    // MARK: clipboard preservation (VER-24)

    /// Deep-copy the current general pasteboard into detached items so it can be restored after
    /// an auto-paste. Reads each item's data for every advertised type (text, RTF, images, …).
    private static func snapshotPasteboard() -> [NSPasteboardItem] {
        let pb = NSPasteboard.general
        return (pb.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
    }

    /// Put a snapshotted clipboard back. A no-op for an empty snapshot leaves the dictated text in
    /// place rather than blanking the clipboard (safer than clearing it).
    private static func restorePasteboard(_ items: [NSPasteboardItem]) {
        guard !items.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(items)
    }
}
