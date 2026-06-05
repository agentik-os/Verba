// Renders Awish's app icon to a 1024px PNG. Run: swift Scripts/make-icon.swift
import AppKit

let size = 1024.0
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Rounded-rect background with a vibrant gradient.
let inset = size * 0.06
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.40, green: 0.32, blue: 0.95, alpha: 1),   // indigo
    NSColor(calibratedRed: 0.20, green: 0.70, blue: 0.85, alpha: 1),   // teal
])!
grad.draw(in: path, angle: -60)

// Soft top highlight for a glassy feel.
NSColor.white.withAlphaComponent(0.18).setFill()
let hi = NSBezierPath(roundedRect: NSRect(x: inset, y: size * 0.52, width: size - inset * 2, height: size * 0.42),
                      xRadius: size * 0.2, yRadius: size * 0.2)
path.addClip()
hi.fill()
NSGraphicsContext.current?.cgContext.resetClip()

// White microphone glyph (SF Symbol) centered.
let cfg = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .semibold)
if let sym = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {
    let tinted = NSImage(size: sym.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: sym.size)
    sym.draw(in: r)
    r.fill(using: .sourceAtop)
    tinted.unlockFocus()
    let w = sym.size.width, h = sym.size.height
    tinted.draw(in: NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h))
}

NSGraphicsContext.restoreGraphicsState()

let out = URL(fileURLWithPath: "/tmp/awish-1024.png")
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
