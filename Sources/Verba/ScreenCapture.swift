import AppKit
import CoreGraphics

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
    static func capturePNG(maxDim: CGFloat = 1568) -> Data? {
        let displayID = displayUnderCursor()
        guard let cg = CGDisplayCreateImage(displayID) else { return nil }
        let scaled = downscale(cg, maxDim: maxDim)
        let rep = NSBitmapImageRep(cgImage: scaled)
        return rep.representation(using: .png, properties: [:])
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
