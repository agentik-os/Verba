import SwiftUI
import AppKit

/// A translucent window background (NSVisualEffectView) for that frosted-glass Apple feel.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) { v.material = material }
}

// Clean, borderless design helpers (modern, no harsh stroke lines).

extension ShapeStyle where Self == Color {
    /// Subtle fill for inputs/cards that adapts to light/dark, no border needed.
    static var softFill: Color { Color.primary.opacity(0.055) }
}

extension View {
    /// Borderless text-field look: subtle fill, comfortable padding, no stroke.
    func cleanField() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    /// Borderless card: soft fill, rounded, generous padding.
    func cleanCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

/// Solid black button with white text — matches Verba's minimalist B&W design.
struct DarkButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Body(configuration: configuration) }
    private struct Body: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var enabled
        var body: some View {
            configuration.label
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(Color.black, in: Capsule())
                .opacity(!enabled ? 0.35 : (configuration.isPressed ? 0.85 : 1))
                .contentShape(Capsule())
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
