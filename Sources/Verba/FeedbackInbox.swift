import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Lets a screenshot dropped onto the sidebar "Feedback" row attach itself and open Feedback.
/// The drop parses the image to PNG, parks it here, and bumps `openSignal`; MainWindow navigates
/// to Feedback on that signal, and FeedbackView consumes `pending` on appear.
final class FeedbackInbox: ObservableObject {
    static let shared = FeedbackInbox()

    @Published private(set) var pending: Data?     // PNG bytes waiting to be attached
    @Published var openSignal = 0                  // bumped to ask MainWindow to open Feedback

    /// Parse a dropped item into PNG bytes; on success, park it and ask to open Feedback.
    /// Returns true if the drop advertised an image we'll handle.
    @discardableResult
    func ingest(_ providers: [NSItemProvider]) -> Bool {
        FeedbackInbox.loadImage(from: providers) { [weak self] img in
            guard let self, let img, let png = FeedbackInbox.png(from: img) else { return }
            DispatchQueue.main.async {
                self.pending = png
                self.openSignal &+= 1
            }
        }
    }

    /// Pop the pending screenshot (FeedbackView calls this when it appears).
    func take() -> Data? {
        let p = pending
        pending = nil
        return p
    }

    // MARK: shared drop parsing (also used by FeedbackView's in-editor drop)

    /// PNG bytes from an NSImage, or nil.
    static func png(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]), !png.isEmpty else { return nil }
        return png
    }

    /// The best image UTI the provider advertises (png/jpeg/tiff/heic/generic image).
    static func imageTypeIdentifier(for provider: NSItemProvider) -> String? {
        let preferred: [UTType] = [.png, .jpeg, .tiff, .heic, .image]
        for t in preferred where provider.hasItemConformingToTypeIdentifier(t.identifier) {
            return t.identifier
        }
        return nil
    }

    /// True if the provider advertises any image payload (image UTI or an image file URL).
    static func isImageDrop(_ provider: NSItemProvider) -> Bool {
        imageTypeIdentifier(for: provider) != nil
            || provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
            || provider.canLoadObject(ofClass: NSImage.self)
    }

    /// Resolve a dropped provider to an NSImage (bytes-by-type, then file URL, then in-memory image).
    /// Returns true if a handleable image was advertised; `onImage` is called async with the result.
    @discardableResult
    static func loadImage(from providers: [NSItemProvider], onImage: @escaping (NSImage?) -> Void) -> Bool {
        guard let provider = providers.first(where: { isImageDrop($0) }) else { return false }

        if let typeID = imageTypeIdentifier(for: provider) {
            _ = provider.loadDataRepresentation(forTypeIdentifier: typeID) { data, _ in
                if let data, let img = NSImage(data: data) { onImage(img) }
                else { loadFromFileURL(provider, onImage: onImage) }
            }
            return true
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            loadFromFileURL(provider, onImage: onImage)
            return true
        }
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { obj, _ in onImage(obj as? NSImage) }
            return true
        }
        return false
    }

    private static func loadFromFileURL(_ provider: NSItemProvider, onImage: @escaping (NSImage?) -> Void) {
        _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
            guard let data, let s = String(data: data, encoding: .utf8),
                  let url = URL(string: s) ?? URL(fileURLWithPath: s) as URL? else { onImage(nil); return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            onImage(NSImage(contentsOf: url))
        }
    }
}
