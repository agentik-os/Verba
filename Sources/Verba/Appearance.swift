import SwiftUI
import AppKit
import Combine

// MARK: - Verba appearance / personalization store
//
// A direct port of LiquidPad's `Appr` (Sources/LiquidPad/AppearanceStore.swift),
// renamed to `VAppr` and given an ObservableObject front (`VerbaAppearance`) so
// SwiftUI views re-render the instant a preference changes.
//
// Two NAMESPACES live here, never crossed:
//   • APP   — keys prefixed "verba.appr.*"  → UserDefaults.standard (the menu-bar app)
//   • WIDGET— keys prefixed "widget.appr.*" → the shared App-Group suite
//             "group.975755H4ZC.verba" (see WidgetBridge.swift) so the WidgetKit
//             extension process can read them.
//
// MONOCHROME BY DEFAULT: `accent` defaults to `.monochrome`, which maps to the
// SwiftUI `Color.primary` (dynamic black/white). Color is opt-in — existing
// users are never forced into a tint.

// MARK: - VAppr (the raw, UserDefaults-backed store)

enum VAppr {
    private static let app = UserDefaults.standard

    /// The shared App-Group suite the widget extension reads. Mirrors the suite
    /// name in WidgetBridge.swift. Falls back to .standard if the App-Group
    /// entitlement isn't provisioned yet (the widget then uses its defaults —
    /// graceful degradation, identical to the data bridge).
    static let appGroup = "group.975755H4ZC.verba"
    static var widget: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    // =========================================================================
    // MARK: Glass material
    // =========================================================================

    /// Maps to NSVisualEffectView.Material. Order is persisted by rawValue —
    /// only APPEND new cases, never reorder.
    enum Material: Int, CaseIterable, Identifiable {
        var id: Int { rawValue }
        case frosted = 0, soft, sidebar, hud, crystal, ultra
        var label: String { ["Frosted", "Soft", "Sidebar", "HUD", "Crystal", "Ultra"][rawValue] }
        var nsMaterial: NSVisualEffectView.Material {
            switch self {
            case .frosted: return .menu
            case .soft:    return .popover
            case .sidebar: return .sidebar
            case .hud:     return .hudWindow
            // The deep, very-translucent materials macOS uses for Notification
            // Center / the widgets popover — the "beautiful glass" look.
            case .crystal: return .underWindowBackground
            case .ultra:   return .fullScreenUI
            }
        }
    }

    // =========================================================================
    // MARK: Accent
    // =========================================================================

    enum Accent: Int, CaseIterable, Identifiable {
        var id: Int { rawValue }
        case monochrome = 0, indigo, blue, teal, green, orange, pink, purple, custom
        var label: String {
            ["Mono", "Indigo", "Blue", "Teal", "Green", "Orange", "Pink", "Purple", "Custom"][rawValue]
        }
        /// nil = monochrome (dynamic black/white); otherwise a fixed sRGB color.
        var nsColor: NSColor? {
            switch self {
            case .monochrome: return nil
            case .indigo: return NSColor(srgbRed: 0.40, green: 0.36, blue: 0.95, alpha: 1)
            case .blue:   return NSColor(srgbRed: 0.20, green: 0.52, blue: 1.00, alpha: 1)
            case .teal:   return NSColor(srgbRed: 0.13, green: 0.70, blue: 0.74, alpha: 1)
            case .green:  return NSColor(srgbRed: 0.18, green: 0.72, blue: 0.40, alpha: 1)
            case .orange: return NSColor(srgbRed: 1.00, green: 0.52, blue: 0.13, alpha: 1)
            case .pink:   return NSColor(srgbRed: 0.95, green: 0.30, blue: 0.55, alpha: 1)
            case .purple: return NSColor(srgbRed: 0.66, green: 0.34, blue: 0.92, alpha: 1)
            case .custom: return nil   // resolved against the stored hex by the store
            }
        }
    }

    // =========================================================================
    // MARK: Color mode
    // =========================================================================

    enum ColorMode: Int, CaseIterable, Identifiable {
        var id: Int { rawValue }
        case auto = 0, light, dark
        var label: String { ["Auto", "Light", "Dark"][rawValue] }
        /// nil = follow the system; otherwise force this NSAppearance at the root.
        var nsAppearance: NSAppearance? {
            switch self {
            case .auto:  return nil
            case .light: return NSAppearance(named: .aqua)
            case .dark:  return NSAppearance(named: .darkAqua)
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .auto:  return nil
            case .light: return .light
            case .dark:  return .dark
            }
        }
    }

    // =========================================================================
    // MARK: Presets — one click sets a whole coherent look (APP scope).
    // =========================================================================

    enum Preset: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case frosted = "Frosted", crystal = "Crystal", midnight = "Midnight",
             minimal = "Minimal", vibrant = "Vibrant"

        /// Each preset is (material, accent, colorMode, cornerScale, shadow, blur).
        var combo: (Material, Accent, ColorMode, Double, Bool, Double) {
            switch self {
            case .frosted:  return (.frosted, .monochrome, .auto,  1.0, true,  0)
            case .crystal:  return (.crystal, .indigo,     .auto,  1.1, true,  18)
            case .midnight: return (.ultra,   .indigo,     .dark,  0.9, true,  12)
            case .minimal:  return (.soft,    .monochrome, .light, 0.7, false, 0)
            case .vibrant:  return (.sidebar, .purple,     .auto,  1.2, true,  8)
            }
        }

        /// True when this preset's combo matches the given appearance tuple.
        /// Blur/cornerScale compared with a small epsilon (slider drift tolerant).
        func matches(material: Material, accent: Accent, colorMode: ColorMode,
                     cornerScale: Double, shadow: Bool, blur: Double) -> Bool {
            let (m, a, c, corner, sh, bl) = combo
            return m == material && a == accent && c == colorMode && sh == shadow
                && abs(corner - cornerScale) < 0.001 && abs(bl - blur) < 0.001
        }
    }

    // =========================================================================
    // MARK: Bounds (shared by app + widget)
    // =========================================================================

    static let blurRange: ClosedRange<Double>   = 0...40
    static let cornerScaleRange: ClosedRange<Double> = 0.7...1.4

    // Base corner radii the cornerScale multiplies (matches Glass.swift's 12/16/…).
    static func corner(_ base: CGFloat, scale: Double) -> CGFloat {
        CGFloat(min(cornerScaleRange.upperBound, max(cornerScaleRange.lowerBound, scale))) * base
    }

    // =========================================================================
    // MARK: Raw getters/setters — APP namespace ("verba.appr.*")
    // =========================================================================

    static var material: Material {
        get { Material(rawValue: app.integer(forKey: "verba.appr.material")) ?? .frosted }
        set { app.set(newValue.rawValue, forKey: "verba.appr.material") }
    }
    static var blur: Double {
        get { clamp(app.object(forKey: "verba.appr.blur") as? Double ?? 0, blurRange) }
        set { app.set(clamp(newValue, blurRange), forKey: "verba.appr.blur") }
    }
    static var cornerScale: Double {
        get { clamp(app.object(forKey: "verba.appr.cornerscale") as? Double ?? 1.0, cornerScaleRange) }
        set { app.set(clamp(newValue, cornerScaleRange), forKey: "verba.appr.cornerscale") }
    }
    static var shadow: Bool {
        get { app.object(forKey: "verba.appr.shadow") as? Bool ?? true }
        set { app.set(newValue, forKey: "verba.appr.shadow") }
    }
    static var accent: Accent {
        get { Accent(rawValue: app.integer(forKey: "verba.appr.accent")) ?? .monochrome }
        set { app.set(newValue.rawValue, forKey: "verba.appr.accent") }
    }
    static var accentHex: String {
        get { app.string(forKey: "verba.appr.accenthex") ?? "5b5bd6" }
        set { app.set(newValue, forKey: "verba.appr.accenthex") }
    }
    static var colorMode: ColorMode {
        get { ColorMode(rawValue: app.integer(forKey: "verba.appr.colormode")) ?? .auto }
        set { app.set(newValue.rawValue, forKey: "verba.appr.colormode") }
    }
    static var reduceMotion: Bool {
        get {
            if app.object(forKey: "verba.appr.reducemotion") as? Bool == true { return true }
            return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        set { app.set(newValue, forKey: "verba.appr.reducemotion") }
    }

    // =========================================================================
    // MARK: Raw getters/setters — WIDGET namespace ("widget.appr.*", App Group)
    // =========================================================================
    //
    // Independent of the app appearance so the widget can be styled separately.
    // Stored in the shared suite so the extension process reads the same values.

    static var widgetMaterial: Material {
        get { Material(rawValue: widget.integer(forKey: "widget.appr.material")) ?? .frosted }
        set { widget.set(newValue.rawValue, forKey: "widget.appr.material") }
    }
    static var widgetBlur: Double {
        get { clamp(widget.object(forKey: "widget.appr.blur") as? Double ?? 0, blurRange) }
        set { widget.set(clamp(newValue, blurRange), forKey: "widget.appr.blur") }
    }
    static var widgetCornerScale: Double {
        get { clamp(widget.object(forKey: "widget.appr.cornerscale") as? Double ?? 1.0, cornerScaleRange) }
        set { widget.set(clamp(newValue, cornerScaleRange), forKey: "widget.appr.cornerscale") }
    }
    static var widgetShadow: Bool {
        get { widget.object(forKey: "widget.appr.shadow") as? Bool ?? true }
        set { widget.set(newValue, forKey: "widget.appr.shadow") }
    }
    static var widgetAccent: Accent {
        get { Accent(rawValue: widget.integer(forKey: "widget.appr.accent")) ?? .monochrome }
        set { widget.set(newValue.rawValue, forKey: "widget.appr.accent") }
    }
    static var widgetAccentHex: String {
        get { widget.string(forKey: "widget.appr.accenthex") ?? "5b5bd6" }
        set { widget.set(newValue, forKey: "widget.appr.accenthex") }
    }
    static var widgetColorMode: ColorMode {
        get { ColorMode(rawValue: widget.integer(forKey: "widget.appr.colormode")) ?? .auto }
        set { widget.set(newValue.rawValue, forKey: "widget.appr.colormode") }
    }

    // =========================================================================
    // MARK: Resolved colors
    // =========================================================================

    /// The accent for a given Accent + hex, as NSColor. nil = monochrome.
    static func resolved(_ a: Accent, hex: String) -> NSColor? {
        if a == .custom { return NSColor(vHex: hex) }
        return a.nsColor
    }

    private static func clamp(_ v: Double, _ r: ClosedRange<Double>) -> Double {
        min(r.upperBound, max(r.lowerBound, v))
    }
}

// MARK: - VerbaAppearance (ObservableObject front)

/// Observable wrapper so SwiftUI views re-render on any change. Reads/writes go
/// through `VAppr`; each setter publishes `objectWillChange` and posts a
/// Notification so non-SwiftUI consumers (MainWindow root tint, the live glass
/// helpers) can re-apply. One shared instance.
final class VerbaAppearance: ObservableObject {
    static let shared = VerbaAppearance()

    /// Posted after any app-appearance change (root tint / color mode / glass).
    static let didChange = Notification.Name("verba.appearance.didChange")
    /// Posted after any widget-appearance change (so the bridge reloads timelines).
    static let widgetDidChange = Notification.Name("verba.appearance.widgetDidChange")

    private init() {}

    private func changed() {
        objectWillChange.send()
        NotificationCenter.default.post(name: VerbaAppearance.didChange, object: nil)
    }
    private func widgetChanged() {
        objectWillChange.send()
        NotificationCenter.default.post(name: VerbaAppearance.widgetDidChange, object: nil)
    }

    // MARK: APP appearance (published surface)

    var material: VAppr.Material {
        get { VAppr.material }
        set { VAppr.material = newValue; changed() }
    }
    var blur: Double {
        get { VAppr.blur }
        set { VAppr.blur = newValue; changed() }
    }
    var cornerScale: Double {
        get { VAppr.cornerScale }
        set { VAppr.cornerScale = newValue; changed() }
    }
    var shadow: Bool {
        get { VAppr.shadow }
        set { VAppr.shadow = newValue; changed() }
    }
    var accent: VAppr.Accent {
        get { VAppr.accent }
        set { VAppr.accent = newValue; changed() }
    }
    var accentHex: String {
        get { VAppr.accentHex }
        set { VAppr.accentHex = newValue; if VAppr.accent == .custom { changed() } }
    }
    var colorMode: VAppr.ColorMode {
        get { VAppr.colorMode }
        set { VAppr.colorMode = newValue; changed() }
    }
    var reduceMotion: Bool {
        get { VAppr.reduceMotion }
        set { VAppr.reduceMotion = newValue; changed() }
    }

    /// Set a custom accent from a SwiftUI Color (selects `.custom`).
    func setCustomAccent(_ color: Color) {
        let ns = NSColor(color)
        accentHex = ns.vHexString
        accent = .custom
    }

    // MARK: WIDGET appearance (published surface)

    var widgetMaterial: VAppr.Material {
        get { VAppr.widgetMaterial }
        set { VAppr.widgetMaterial = newValue; widgetChanged() }
    }
    var widgetBlur: Double {
        get { VAppr.widgetBlur }
        set { VAppr.widgetBlur = newValue; widgetChanged() }
    }
    var widgetCornerScale: Double {
        get { VAppr.widgetCornerScale }
        set { VAppr.widgetCornerScale = newValue; widgetChanged() }
    }
    var widgetShadow: Bool {
        get { VAppr.widgetShadow }
        set { VAppr.widgetShadow = newValue; widgetChanged() }
    }
    var widgetAccent: VAppr.Accent {
        get { VAppr.widgetAccent }
        set { VAppr.widgetAccent = newValue; widgetChanged() }
    }
    var widgetAccentHex: String {
        get { VAppr.widgetAccentHex }
        set { VAppr.widgetAccentHex = newValue; if VAppr.widgetAccent == .custom { widgetChanged() } }
    }
    var widgetColorMode: VAppr.ColorMode {
        get { VAppr.widgetColorMode }
        set { VAppr.widgetColorMode = newValue; widgetChanged() }
    }

    func setWidgetCustomAccent(_ color: Color) {
        let ns = NSColor(color)
        widgetAccentHex = ns.vHexString
        widgetAccent = .custom
    }

    // MARK: Presets

    /// Apply a preset to the APP appearance and notify once.
    func applyPreset(_ p: VAppr.Preset) {
        let (mat, acc, mode, corner, sh, bl) = p.combo
        VAppr.material = mat
        VAppr.accent = acc
        VAppr.colorMode = mode
        VAppr.cornerScale = corner
        VAppr.shadow = sh
        VAppr.blur = bl
        changed()
    }

    /// The preset whose combo currently matches the APP appearance, or nil for a
    /// custom mix. Lets the Presets chips reflect the real active state instead of a
    /// hard-coded default.
    var activePreset: VAppr.Preset? {
        VAppr.Preset.allCases.first { $0.matches(
            material: material, accent: accent, colorMode: colorMode,
            cornerScale: cornerScale, shadow: shadow, blur: blur) }
    }

    /// The preset currently matching the WIDGET appearance, or nil for a custom mix.
    var activeWidgetPreset: VAppr.Preset? {
        VAppr.Preset.allCases.first { $0.matches(
            material: widgetMaterial, accent: widgetAccent, colorMode: widgetColorMode,
            cornerScale: widgetCornerScale, shadow: widgetShadow, blur: widgetBlur) }
    }

    /// Apply a preset to the WIDGET appearance and notify once.
    func applyWidgetPreset(_ p: VAppr.Preset) {
        let (mat, acc, _, corner, sh, bl) = p.combo
        VAppr.widgetMaterial = mat
        VAppr.widgetAccent = acc
        VAppr.widgetColorMode = p.combo.2
        VAppr.widgetCornerScale = corner
        VAppr.widgetShadow = sh
        VAppr.widgetBlur = bl
        widgetChanged()
    }

    // MARK: Resolved SwiftUI colors (for views)

    /// The app accent as a SwiftUI Color. Monochrome → `.primary` (the
    /// default — never forces a color on existing users).
    var accentColor: Color {
        if let ns = VAppr.resolved(accent, hex: accentHex) { return Color(nsColor: ns) }
        return .primary
    }

    /// The widget accent as a SwiftUI Color. Monochrome → `.primary`.
    var widgetAccentColor: Color {
        if let ns = VAppr.resolved(widgetAccent, hex: widgetAccentHex) { return Color(nsColor: ns) }
        return .primary
    }

    /// SwiftUI `.tint` to apply at the app root: monochrome stays `.primary`.
    var tint: Color { accentColor }
}

// MARK: - Hex <-> NSColor (sRGB)

extension NSColor {
    /// Parse a "RRGGBB" / "#RRGGBB" hex string into an sRGB NSColor.
    convenience init?(vHex hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                  green: CGFloat((v >> 8) & 0xff) / 255,
                  blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
    /// "RRGGBB" sRGB hex string (no leading #). Falls back to indigo.
    var vHexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "5b5bd6" }
        return String(format: "%02x%02x%02x",
                      Int(round(c.redComponent * 255)),
                      Int(round(c.greenComponent * 255)),
                      Int(round(c.blueComponent * 255)))
    }
}
