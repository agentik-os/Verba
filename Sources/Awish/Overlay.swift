import SwiftUI
import AppKit

final class OverlayModel: ObservableObject {
    @Published var level: Float = 0      // 0...1 mic level
    @Published var title: String = ""    // "Listening…" / "Transcribing…" / etc.
    @Published var recording = false
}

/// The floating glass pill shown while recording / processing.
struct OverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.recording ? Color.red : Color.accentColor)
                    .frame(width: 10, height: 10)
                    .opacity(model.recording ? 0.6 + Double(model.level) * 0.4 : 1)
            }
            if model.recording {
                Waveform(level: model.level)
                    .frame(width: 72, height: 22)
            } else {
                ProgressView().controlSize(.small).scaleEffect(0.8)
            }
            Text(model.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glass(in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
        .fixedSize()
    }
}

/// Simple animated level bars.
private struct Waveform: View {
    let level: Float
    private let bars = 9
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<bars, id: \.self) { i in
                let phase = Float(i) / Float(bars)
                let h = max(0.12, min(1, level * (0.5 + 0.9 * sinf((phase + level) * .pi))))
                Capsule()
                    .fill(.primary.opacity(0.85))
                    .frame(width: 4, height: CGFloat(h) * 22)
            }
        }
        .animation(.easeOut(duration: 0.08), value: level)
        .frame(maxHeight: 22, alignment: .center)
    }
}

/// Owns the borderless floating panel.
final class OverlayController {
    let model = OverlayModel()
    private var panel: NSPanel?

    func show() {
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 220, height: 48),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
            p.isFloatingPanel = true
            p.level = .statusBar
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.ignoresMouseEvents = true
            p.contentViewController = NSHostingController(rootView: OverlayView(model: model))
            panel = p
        }
        reposition()
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    private func reposition() {
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 220, height: 48)
        panel.setContentSize(size)
        let vf = screen.visibleFrame
        let x = vf.midX - size.width / 2
        let y = vf.minY + 90   // floats above the Dock area
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
