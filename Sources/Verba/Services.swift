import AppKit

/// macOS Services integration (VER-19, point 1): make Transforms triggerable WITHOUT voice.
///
/// macOS Services are static menu items declared in Info.plist, each mapped to ONE selector on
/// the app's `servicesProvider`. Transforms are user-defined at runtime, so we can't emit a
/// distinct, pre-declared selector per transform. Instead we register a SINGLE service —
/// "Transform with Verba…" — that appears under Services ▸ (and the right-click "Services"
/// submenu) whenever text is selected in ANY app. Choosing it pops a quick picker of the user's
/// ENABLED transforms; picking one runs that transform's instruction on the selection (through the
/// exact same transform-on-selection pipeline the verbal shortcut uses) and replaces the selection.
///
/// The provider must be Obj-C visible (`@objc` selector with the standard NSServices signature) and
/// registered via `NSApp.servicesProvider`. The Info.plist NSServices array (written by bundle.sh)
/// maps the menu title to `transformWithVerba:userData:error:`.
final class VerbaServiceProvider: NSObject {
    static let shared = VerbaServiceProvider()

    /// Install this provider so the system routes the declared service to us. Called once at launch.
    static func register() {
        NSApp.servicesProvider = shared
        // Force a re-scan so the Services menu reflects our just-registered provider on first run.
        NSUpdateDynamicServices()
    }

    /// NSServices entry point. macOS hands us the selection on the pasteboard; we run a transform on
    /// it and write the replacement back to the SAME pasteboard, which the system splices into the
    /// app's selection (the service is declared with NSReturnTypes so the selection is replaced).
    @objc func transformWithVerba(_ pboard: NSPasteboard,
                                  userData: String?,
                                  error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        guard let selection = pboard.string(forType: .string),
              !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error?.pointee = "Select some text first, then choose Transform with Verba." as NSString
            return
        }

        // Only the user's REAL rewrite transforms are offered here — the "Add to dictionary"
        // shortcut is a voice-only side-effect (no selection to replace), so it's filtered out.
        let transforms = TransformsStore.shared.items.filter { !TransformsStore.isAddToDictionary($0) }
        guard !transforms.isEmpty else {
            error?.pointee = "No transforms yet. Add one in Verba ▸ Transforms." as NSString
            return
        }

        // Pick the transform on the main thread (modal popup), then run it. The service call is
        // synchronous from the system's perspective: we must block until the replacement (or an
        // abort) is ready, so we drive the async transform with a semaphore while keeping the UI
        // interaction on the main run loop.
        let chosen = pickTransform(from: transforms)
        guard let transform = chosen else { return }   // user cancelled → leave the selection untouched

        switch TransformsStore.runOnSelectionSync(transform, selection: selection) {
        case .success(let replacement):
            pboard.clearContents()
            pboard.setString(replacement, forType: .string)
        case .failure(let message):
            error?.pointee = message as NSString
        }
    }

    /// A small modal picker listing the enabled transforms. Returns the chosen transform, or nil if
    /// the user cancelled. Runs on the main thread (services are delivered on the main thread).
    private func pickTransform(from transforms: [Transform]) -> Transform? {
        // Single transform → no need to ask, run it directly.
        if transforms.count == 1 { return transforms[0] }

        let alert = NSAlert()
        alert.messageText = "Transform with Verba"
        alert.informativeText = "Choose a transform to run on the selected text."
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 260, height: 26))
        popup.addItems(withTitles: transforms.map { $0.name.isEmpty ? "(unnamed)" : $0.name })
        alert.accessoryView = popup
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        // Bring our (accessory) app forward so the modal is interactive and key.
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return nil }
        let idx = popup.indexOfSelectedItem
        guard idx >= 0 && idx < transforms.count else { return nil }
        return transforms[idx]
    }
}
