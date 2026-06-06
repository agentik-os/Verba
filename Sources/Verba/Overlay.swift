import SwiftUI
import AppKit
import Combine

final class OverlayModel: ObservableObject {
    @Published var level: Float = 0      // 0...1 mic level
    @Published var phase: Double = 0     // advanced by our own timer → animation never stalls
    @Published var title: String = ""    // "Listening…" / "Transcribing…" / etc.
    @Published var recording = false
    @Published var paused = false        // dictation paused
    @Published var done = false          // brief success flash
    var onPauseToggle: (() -> Void)?
    @Published var menu = false          // pre-record: show numbered modes to pick
    @Published var profiles: [Profile] = []
    @Published var selectedID: UUID?
    @Published var activeID: UUID?       // the default mode (highlighted in the picker)
    var onSelect: ((Profile) -> Void)?   // user switched mode mid-recording
    var onStart: ((Profile) -> Void)?    // user picked a mode from the menu → start recording
    var onCancel: (() -> Void)?          // discard / abort whatever is happening
    @Published var style: OverlayStyle = .floating
}

/// The recording indicator. Three looks (set in Settings ▸ Recording):
///   • floating, glass pill at the bottom (default)
///   • island, dark pill at the top of the screen (Dynamic-Island style)
///   • minimal, tiny top bar, just the moving waveform (for power users)
struct OverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        Group {
            switch model.style {
            case .floating: floating
            case .island:   island
            case .minimal:  minimal
            }
        }
        .tint(.primary)
    }

    // MARK: Floating glass (full)
    private var floating: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                leading(big: true)
                if model.recording {
                    Button { model.onPauseToggle?() } label: {
                        Image(systemName: model.paused ? "play.fill" : "pause.fill").font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }.buttonStyle(.plain).help(model.paused ? "Resume" : "Pause")
                    Waveform(level: model.paused ? 0 : model.level, phase: model.phase).frame(width: 64, height: 24)
                }
                label(size: 13)
                if !model.menu && !model.done {
                    Button { model.onCancel?() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain).help("Cancel (Esc)")
                }
            }
            picker(font: 11)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .glass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .fixedSize()
    }

    // MARK: Top island — Dynamic-Island style pill
    private var island: some View {
        VStack(spacing: 9) {
            HStack(spacing: 11) {
                leading(big: false)
                if model.recording {
                    Waveform(level: model.paused ? 0 : model.level, phase: model.phase).frame(width: 78, height: 18)
                } else if !model.menu && !model.done {
                    ProgressView().controlSize(.small).scaleEffect(0.7)
                }
                label(size: 12.5)
            }
            picker(font: 11)
        }
        .padding(.horizontal, 18).padding(.vertical, 11)
        .background(
            ZStack {
                Capsule(style: .continuous).fill(.black)
                // soft inner highlight at the top for depth, like the real island
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.10), .clear],
                                         startPoint: .top, endPoint: .center))
            }
        )
        .overlay(Capsule(style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.55), radius: 22, y: 10)
        // subtle live glow while recording
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.red.opacity(model.recording && !model.paused ? 0.35 + Double(model.level) * 0.4 : 0), lineWidth: 1.5)
                .blur(radius: 4)
        )
        .environment(\.colorScheme, .dark)
        .fixedSize()
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: model.menu)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: model.recording)
        .transition(.scale(scale: 0.6, anchor: .top).combined(with: .opacity))
    }

    // MARK: Minimal top bar
    private var minimal: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                leading(big: false)
                Waveform(level: model.paused ? 0 : model.level, phase: model.phase).frame(width: 54, height: 14)
                if !model.title.isEmpty { Text(model.title).font(.system(size: 11, weight: .medium)).lineLimit(1) }
            }
            if model.menu { picker(font: 10) }   // only surfaces when picking a mode
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.black.opacity(0.9), in: Capsule(style: .continuous))
        .environment(\.colorScheme, .dark)
        .fixedSize()
    }

    // MARK: Shared pieces
    @ViewBuilder private func leading(big: Bool) -> some View {
        if model.done {
            Image(systemName: "checkmark.circle.fill").font(.system(size: big ? 14 : 12)).foregroundStyle(.green)
        } else if model.menu {
            Image(systemName: "mic").font(.system(size: big ? 13 : 12)).foregroundStyle(.secondary)
        } else if model.recording {
            Circle()
                .fill(model.paused ? Color.orange : Color.red)
                .frame(width: big ? 10 : 8, height: big ? 10 : 8)
                .opacity(model.paused ? 1 : 0.6 + Double(model.level) * 0.4)
        } else {
            ProgressView().controlSize(.small).scaleEffect(big ? 0.8 : 0.6)
        }
    }

    @ViewBuilder private func label(size: CGFloat) -> some View {
        if model.done {
            Text(model.title.isEmpty ? "Done" : model.title).font(.system(size: size, weight: .medium)).lineLimit(1)
        } else if model.menu {
            Text("Choose a mode").font(.system(size: size, weight: .medium)).lineLimit(1)
        } else {
            Text(model.paused ? "Paused" : model.title).font(.system(size: size, weight: .medium)).lineLimit(1)
        }
    }

    @ViewBuilder private func picker(font: CGFloat) -> some View {
        if (model.menu || (model.recording && model.style == .floating)) && !model.profiles.isEmpty {
            HStack(spacing: 6) {
                ForEach(model.profiles) { p in
                    let isActive = model.menu && p.id == model.activeID
                    let isSwitch = !model.menu && p.id == model.selectedID
                    let hot = isActive || isSwitch
                    Button {
                        if model.menu { model.onStart?(p) }
                        else { model.selectedID = p.id; model.onSelect?(p) }
                    } label: {
                        Text(p.name).font(.system(size: font, weight: hot ? .semibold : .regular))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(hot ? Color.primary.opacity(0.95) : Color.primary.opacity(0.1)))
                            .foregroundStyle(hot ? (model.style == .floating ? Color.white : Color.black) : Color.primary.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
            }
            if model.menu {
                Text("← → · 1-9 · click, sets your default mode & dictates")
                    .font(.system(size: max(9, font - 1))).foregroundStyle(.secondary)
            }
        }
    }
}

/// Lively meter. Motion is driven by `phase` (advanced by our own recording timer),
/// so it never stalls, unlike TimelineView, which pauses while another app is active.
private struct Waveform: View {
    let level: Float
    let phase: Double
    private let bars = 11
    private let maxH: CGFloat = 24

    var body: some View {
        let lvl = CGFloat(max(0.05, min(1, level)))
        HStack(spacing: 2.5) {
            ForEach(0..<bars, id: \.self) { i in
                // two detuned sines per bar → organic motion; amplitude follows the level
                let w = (sin(phase * 3.4 + Double(i) * 0.9) + sin(phase * 5.1 + Double(i) * 1.7)) / 2.0
                let wobble = CGFloat((w + 1) / 2)                  // 0…1
                let center = 1 - abs(CGFloat(i) - CGFloat(bars - 1) / 2) / CGFloat(bars)  // taller in middle
                let h = max(0.10, min(1, lvl * (0.35 + 0.95 * wobble) * (0.6 + 0.6 * center)))
                Capsule()
                    .fill(.primary.opacity(0.55 + 0.4 * Double(h)))
                    .frame(width: 3, height: h * maxH)
            }
        }
        .frame(height: maxH, alignment: .center)
        .animation(.linear(duration: 0.05), value: phase)
    }
}

/// Owns the borderless floating panel.
final class OverlayController {
    let model = OverlayModel()
    private var panel: NSPanel?
    private var sizeObserver: AnyCancellable?
    private var lastSize: NSSize = .zero

    /// Build the panel ahead of time so the first show() is instant.
    func prepare() {
        guard panel == nil else { return }
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 260, height: 80),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.ignoresMouseEvents = false   // chips must be clickable
        p.contentViewController = NSHostingController(rootView: OverlayView(model: model))
        p.alphaValue = 1
        panel = p
        p.layoutIfNeeded()             // warm the SwiftUI render
        // Keep the pill centered when its content size changes (recording → transcribing →
        // done all have different widths, which otherwise leaves it visibly off-center).
        sizeObserver = model.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.recenterIfSizeChanged() }
        }
    }

    private func recenterIfSizeChanged() {
        guard let panel, panel.isVisible else { return }
        panel.layoutIfNeeded()
        guard let size = panel.contentView?.fittingSize, size != lastSize else { return }
        lastSize = size
        reposition()
    }

    func show() {
        prepare()
        model.style = Settings.shared.overlayStyle
        reposition()
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    func reposition() {
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 260, height: 80)
        lastSize = size
        panel.setContentSize(size)
        let vf = screen.visibleFrame
        let x = vf.midX - size.width / 2
        let y: CGFloat
        switch model.style {
        case .floating: y = vf.minY + 90                  // bottom center
        case .island:   y = vf.maxY - size.height - 6     // just below the menu bar
        case .minimal:  y = vf.maxY - size.height - 4
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
