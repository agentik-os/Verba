import AppKit
import CoreGraphics
import ScreenCaptureKit

/// Screenshot helper for Context mode. Grabs the screen the pointer is on, downscaled
/// to a vision-friendly size, as PNG. Needs Screen Recording permission.
enum ScreenCapture {
    /// True once the user has granted Screen Recording for Verba.
    static func hasPermission() -> Bool { CGPreflightScreenCaptureAccess() }

    /// Ask the system for Screen Recording (shows the prompt the first time, then it's a
    /// no-op that just opens the toggle in System Settings). Returns the current state.
    @discardableResult
    static func requestPermission() -> Bool { CGRequestScreenCaptureAccess() }

    static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Capture the display the mouse is currently on, downscaled so its longest side is at
    /// most `maxDim` (Claude vision sweet spot ≈ 1568px), returned as PNG. nil on failure.
    /// Uses ScreenCaptureKit: CGDisplayCreateImage was OBSOLETED in macOS 15 and returns nil
    /// there, which silently broke Context mode (the screen was never actually captured).
    static func capturePNG(maxDim: CGFloat = 1568) async -> Data? {
        let wantID = displayUnderCursor()
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first(where: { $0.displayID == wantID }) ?? content.displays.first else { return nil }
            // Exclude Verba's OWN windows (the floating pill / overlays) so the model never sees our
            // processing pill on top of the screen it's meant to act on.
            let myPID = ProcessInfo.processInfo.processIdentifier
            let mine = content.windows.filter { $0.owningApplication?.processID == myPID }
            let filter = SCContentFilter(display: display, excludingWindows: mine)
            let cfg = SCStreamConfiguration()
            cfg.width = display.width
            cfg.height = display.height
            cfg.showsCursor = false
            let cg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
            let scaled = downscale(cg, maxDim: maxDim)
            let rep = NSBitmapImageRep(cgImage: scaled)
            return rep.representation(using: .png, properties: [:])
        } catch {
            return nil
        }
    }

    // MARK: - internals
    private static func displayUnderCursor() -> CGDirectDisplayID {
        let loc = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if screen.frame.contains(loc),
               let n = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                return n
            }
        }
        return CGMainDisplayID()
    }

    private static func downscale(_ image: CGImage, maxDim: CGFloat) -> CGImage {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        let longest = max(w, h)
        guard longest > maxDim else { return image }
        let scale = maxDim / longest
        let nw = Int(w * scale), nh = Int(h * scale)
        guard let ctx = CGContext(data: nil, width: nw, height: nh, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: nw, height: nh))
        return ctx.makeImage() ?? image
    }
}
