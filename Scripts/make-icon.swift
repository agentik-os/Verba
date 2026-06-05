// Renders Verba's app icon to a 1024px PNG. Run: swift Scripts/make-icon.swift
import AppKit

let size = 1024.0
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Black squircle background — clean monochrome, no gradient.
let inset = size * 0.06
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)
NSColor.black.setFill()
path.fill()

// White microphone glyph (SF Symbol) centered.
let cfg = NSImage.SymbolConfiguration(pointSize: size * 0.46, weight: .regular)
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

let out = URL(fileURLWithPath: "/tmp/verba-1024.png")
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
