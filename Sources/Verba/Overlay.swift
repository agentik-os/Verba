import SwiftUI
import AppKit

final class OverlayModel: ObservableObject {
    @Published var level: Float = 0      // 0...1 mic level
    @Published var title: String = ""    // "Listening…" / "Transcribing…" / etc.
    @Published var recording = false
    @Published var done = false          // brief success flash
    @Published var menu = false          // pre-record: show numbered modes to pick
    @Published var profiles: [Profile] = []
    @Published var selectedID: UUID?
    @Published var activeID: UUID?       // the default mode (highlighted in the picker)
    var onSelect: ((Profile) -> Void)?   // user switched mode mid-recording
    var onStart: ((Profile) -> Void)?    // user picked a mode from the menu → start recording
    var onCancel: (() -> Void)?          // discard / abort whatever is happening
}

/// The floating glass pill shown while recording / processing, with a live mode
/// switcher so you can pick the reprompting style on the fly.
struct OverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if model.done {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(.green)
                    Text(model.title.isEmpty ? "Done" : model.title).font(.system(size: 13, weight: .medium))
                } else if model.menu {
                    Image(systemName: "mic").font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("Choose a mode").font(.system(size: 13, weight: .medium))
                } else {
                    Circle()
                        .fill(model.recording ? Color.red : Color.primary)
                        .frame(width: 10, height: 10)
                        .opacity(model.recording ? 0.6 + Double(model.level) * 0.4 : 1)
                    if model.recording {
                        Waveform(level: model.level).frame(width: 72, height: 22)
                    } else {
                        ProgressView().controlSize(.small).scaleEffect(0.8)
                    }
                    Text(model.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                }
                // Cancel (×) — discard recording or abort processing.
                if !model.menu && !model.done {
                    Button { model.onCancel?() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).help("Cancel (Esc)")
                }
            }

            if (model.menu || model.recording) && !model.profiles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(model.profiles.enumerated()), id: \.element.id) { i, p in
                        let isActive = model.menu && p.id == model.activeID         // default in picker
                        let isSwitch = !model.menu && p.id == model.selectedID       // current while recording
                        let hot = isActive || isSwitch
                        Button {
                            if model.menu { model.onStart?(p) }
                            else { model.selectedID = p.id; model.onSelect?(p) }
                        } label: {
                            HStack(spacing: 4) {
                                if model.menu {
                                    Text("\(i + 1)").font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(hot ? Color.white.opacity(0.9) : .secondary)
                                }
                                Text(p.name).font(.system(size: 11, weight: hot ? .semibold : .regular))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(
                                isActive ? Color.accentColor.opacity(0.95)
                                         : isSwitch ? Color.primary.opacity(0.9)
                                         : Color.primary.opacity(0.08)))
                            .foregroundStyle(hot ? Color.white : Color.primary.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if model.menu {
                    Text("← → change default · 1–9 or click to dictate")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .fixedSize()
    }
}

private struct Waveform: View {
    let level: Float
    private let bars = 9
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<bars, id: \.self) { i in
                let phase = Float(i) / Float(bars)
                let h = max(0.12, min(1, level * (0.5 + 0.9 * sinf((phase + level) * .pi))))
                Capsule().fill(.primary.opacity(0.85)).frame(width: 4, height: CGFloat(h) * 22)
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
            panel = p
        }
        reposition()
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    private func reposition() {
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 260, height: 80)
        panel.setContentSize(size)
        let vf = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: vf.midX - size.width / 2, y: vf.minY + 90))
    }
}
