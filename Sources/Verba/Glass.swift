import SwiftUI
import AppKit

/// A translucent window background (NSVisualEffectView) for that frosted-glass Apple feel.
/// Default material follows the user's Customize choice (VAppr.material); pass an explicit
/// material to override (e.g. a specific dialog that always wants one look).
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material? = nil   // nil → user's chosen glass material
    private var resolved: NSVisualEffectView.Material { material ?? VAppr.material.nsMaterial }
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = resolved
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) { v.material = resolved }
}

// Clean, borderless design helpers (modern, no harsh stroke lines).

// MARK: - Refined glass design tokens
//
// Single source of truth for the new refined-glass look. Hierarchy reads through
// ELEVATION + SUBTLE glass, never a heavy black stroke. No stroke above 0.12 opacity
// anywhere; selection is a soft fill step + an ultra-subtle hairline (+ optional shadow).

enum VGlass {
    // Fill steps — depth by translucency, not boxes.
    static let fillRest: Double      = 0.04   // resting card/row fill
    static let fillSecondary: Double = 0.055  // inputs, secondary chips
    static let fillSelected: Double  = 0.10   // selected/active fill step
    static let fillHover: Double     = 0.07   // hover lift

    // Hairlines — always <= 0.10. A whisper, never a border.
    static let hairline: Double         = 0.06  // resting hairline
    static let hairlineSelected: Double = 0.10  // selected hairline (max)

    // Soft elevation shadow for the brought-forward / active element.
    static let shadowColor   = Color.black.opacity(0.10)
    static let shadowRadius: CGFloat = 14
    static let shadowY: CGFloat      = 5

    /// Standard concentric continuous corners.
    static func shape(_ r: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: r, style: .continuous)
    }
}

extension ShapeStyle where Self == Color {
    /// Subtle fill for inputs/cards that adapts to light/dark, no border needed.
    static var softFill: Color { Color.primary.opacity(VGlass.fillSecondary) }
    /// Selection fill step (replaces the old 0.12 selected fill).
    static var selectionFill: Color { Color.primary.opacity(VGlass.fillSelected) }
    /// Ultra-subtle hairline tint (<= 0.10).
    static var hairlineTint: Color { Color.primary.opacity(VGlass.hairline) }
}

extension View {
    /// Borderless text-field look: subtle fill, comfortable padding, no stroke.
    func cleanField() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// Borderless card: soft fill, rounded, generous padding.
    func cleanCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Refined-glass shared helpers

    /// Ultra-subtle hairline overlay (<= 0.10). Use INSTEAD of any visible stroke.
    /// Pass `selected` to bump the resting hairline up to the 0.10 max.
    func hairline(_ cornerRadius: CGFloat = 12, selected: Bool = false) -> some View {
        overlay(
            VGlass.shape(cornerRadius)
                .strokeBorder(Color.primary.opacity(selected ? VGlass.hairlineSelected : VGlass.hairline),
                              lineWidth: 1)
        )
    }

    /// Soft elevation shadow that brings the important/active element forward.
    /// Gate on an `active` flag so secondary elements stay flat (recede).
    func softElevation(_ active: Bool = true) -> some View {
        shadow(color: active ? VGlass.shadowColor : .clear,
               radius: active ? VGlass.shadowRadius : 0,
               y: active ? VGlass.shadowY : 0)
    }

    /// Bring an element forward: soft fill + selected hairline + soft shadow.
    /// The single "this matters" treatment, monochrome by default.
    func bringForward(_ cornerRadius: CGFloat = 12) -> some View {
        background(Color.selectionFill, in: VGlass.shape(cornerRadius))
            .hairline(cornerRadius, selected: true)
            .softElevation(true)
    }

    /// THE replacement for the harsh `strokeBorder(Color.primary.opacity(selected ? 0.4 : 0))`
    /// selected-card pattern. Apply over the existing fill: a soft hairline that bumps on
    /// selection (0.06 → 0.10) plus a soft elevation shadow only when selected.
    ///   `.overlay(RoundedRectangle(...).strokeBorder(...0.4...))` → `.glassSelection(selected)`
    @ViewBuilder
    func glassSelection(_ selected: Bool, cornerRadius: CGFloat = 12) -> some View {
        self
            .hairline(cornerRadius, selected: selected)
            .softElevation(selected)
    }

    /// Full refined-glass card: resting/selected fill step + hairline + elevation-on-select.
    /// Drop-in for the `RoundedRectangle.fill(...selected ? 0.12 : 0.04)` + harsh-stroke pair.
    func glassCard(selected: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        background(
            VGlass.shape(cornerRadius)
                .fill(Color.primary.opacity(selected ? VGlass.fillSelected : VGlass.fillRest))
        )
        .glassSelection(selected, cornerRadius: cornerRadius)
    }
}

// Liquid Glass shim (mirrors kaset's approach): use Apple's real `.glassEffect`
// on macOS 26+ (Tahoe), fall back to `.ultraThinMaterial` on macOS 14/15.

extension View {
    @ViewBuilder
    func glass(interactive: Bool = false, in shape: some Shape = RoundedRectangle(cornerRadius: 12, style: .continuous)) -> some View {
        if #available(macOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func glassProminentButton() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func glassButton() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

/// A copy-to-clipboard button with clear tactile feedback: the icon flips to a green
/// checkmark and pops briefly so you SEE the click registered.
struct CopyButton: View {
    let text: String
    var title: String? = nil    // nil = icon-only; set for a labeled button
    @State private var copied = false

    var body: some View {
        Button {
            Output.copyToClipboard(text)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeOut(duration: 0.2)) { copied = false }
            }
        } label: {
            if let title {
                Label(copied ? "Copied" : title, systemImage: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(.primary)   // stay black, no color
            } else {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(copied ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    .scaleEffect(copied ? 1.25 : 1)
            }
        }
        .buttonStyle(.plain)
        .help("Copy")
    }
}

/// Solid black button with white text, matches Verba's minimalist B&W design.
struct DarkButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .background(Color.black, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(Capsule())
    }
}

// MARK: - Liquid Glass dialog system

/// One floating Liquid Glass dialog card: tinted icon squircle + title + subtitle,
/// a content slot, and a trailing button row. Use for every confirmation/sheet.
struct GlassDialog<Content: View, Buttons: View>: View {
    var icon: String
    var tint: Color = .primary
    var title: String
    var subtitle: String? = nil
    var width: CGFloat = 460
    /// false when the hosting window already provides the glass backdrop edge-to-edge.
    var drawsCard: Bool = true
    @ViewBuilder var content: () -> Content
    @ViewBuilder var buttons: () -> Buttons

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.13),
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.title3.weight(.semibold))
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            content()
            HStack(spacing: 10) { buttons() }   // caller adds Spacer() for trailing alignment
        }
        .padding(22)
        .frame(width: width)
        .modifier(GlassCardIf(enabled: drawsCard))
        .scaleEffect(appeared ? 1 : 0.98, anchor: .center)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

private struct GlassCardIf: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content
                .glass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.13), radius: 26, y: 10)
        } else { content }
    }
}

extension View {
    /// Primary dialog action: glassProminent on 26, large tinted borderedProminent below.
    func dialogPrimary(tint: Color = .primary) -> some View {
        self.glassProminentButton().tint(tint).controlSize(.large)
    }
    /// Secondary dialog action: interactive glass capsule on 26, large bordered below.
    func dialogSecondary() -> some View {
        self.glassButton().controlSize(.large)
    }
}

/// Caption label floating above a value/control — the dialog field treatment.
struct GlassLabeledValue<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Subtle spring appear (scale 0.98→1 + fade) for sheets/popovers not using GlassDialog.
struct DialogAppear: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.scaleEffect(on ? 1 : 0.98).opacity(on ? 1 : 0)
            .onAppear { withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { on = true } }
    }
}
extension View { func dialogAppear() -> some View { modifier(DialogAppear()) } }

/// Drop-in NSAlert replacement: present via makeWindow(glass: true) + presentFocused.
struct GlassAlertView: View {
    struct AlertButton: Identifiable {
        let id = UUID()
        var title: String
        var role: ButtonRole? = nil          // .cancel → Escape; .destructive → red tint
        var isDefault: Bool = false          // ↩ default action
        var action: () -> Void
    }
    var icon: String = "exclamationmark.circle"
    var tint: Color = .primary
    var title: String
    var message: String? = nil
    var buttons: [AlertButton]

    var body: some View {
        GlassDialog(icon: icon, tint: tint, title: title, subtitle: message,
                    width: 400, drawsCard: false) {
            EmptyView()
        } buttons: {
            Spacer()
            ForEach(buttons) { b in
                if b.isDefault {
                    Button(b.title, role: b.role, action: b.action)
                        .dialogPrimary(tint: b.role == .destructive ? .red : tint)
                        .keyboardShortcut(.defaultAction)
                } else if b.role == .cancel {
                    Button(b.title, role: b.role, action: b.action)
                        .dialogSecondary()
                        .keyboardShortcut(.cancelAction)
                } else {
                    Button(b.title, role: b.role, action: b.action)
                        .dialogSecondary()
                }
            }
        }
    }
}

/// Wraps content in a GlassEffectContainer on macOS 26+ so multiple glass shapes
/// blend together; passthrough otherwise.
struct GlassContainer<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content
    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
    }
}
