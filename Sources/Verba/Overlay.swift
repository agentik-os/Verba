import SwiftUI
import AppKit

final class OverlayModel: ObservableObject {
    @Published var level: Float = 0      // 0...1 mic level
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
                        .fill(model.recording ? (model.paused ? Color.orange : Color.red) : Color.primary)
                        .frame(width: 10, height: 10)
                        .opacity(model.recording && !model.paused ? 0.6 + Double(model.level) * 0.4 : 1)
                    if model.recording {
                        Button { model.onPauseToggle?() } label: {
                            Image(systemName: model.paused ? "play.fill" : "pause.fill").font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }.buttonStyle(.plain).help(model.paused ? "Resume" : "Pause")
                        Waveform(level: model.paused ? 0 : model.level).frame(width: 64, height: 22)
                    } else {
                        ProgressView().controlSize(.small).scaleEffect(0.8)
                    }
                    Text(model.paused ? "Paused" : model.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
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
                    ForEach(model.profiles) { p in
                        let isActive = model.menu && p.id == model.activeID         // default in picker
                        let isSwitch = !model.menu && p.id == model.selectedID       // current while recording
                        let hot = isActive || isSwitch
                        Button {
                            if model.menu { model.onStart?(p) }
                            else { model.selectedID = p.id; model.onSelect?(p) }
                        } label: {
                            Text(p.name).font(.system(size: 11, weight: hot ? .semibold : .regular))
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
                    Text("← → · 1–9 · click — sets your default mode & dictates")
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

/// Lively meter: bars wobble continuously and scale with the live mic level.
private struct Waveform: View {
    let level: Float
    private let bars = 11
    private let maxH: CGFloat = 24

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let lvl = CGFloat(max(0.05, min(1, level)))
            HStack(spacing: 2.5) {
                ForEach(0..<bars, id: \.self) { i in
                    // two detuned sines per bar → organic motion; amplitude follows the level
                    let w = (sin(t * 7.5 + Double(i) * 0.9) + sin(t * 11.3 + Double(i) * 1.7)) / 2.0
                    let wobble = CGFloat((w + 1) / 2)                  // 0…1
                    let center = 1 - abs(CGFloat(i) - CGFloat(bars - 1) / 2) / CGFloat(bars)  // taller in middle
                    let h = max(0.10, min(1, lvl * (0.35 + 0.95 * wobble) * (0.6 + 0.6 * center)))
                    Capsule()
                        .fill(.primary.opacity(0.55 + 0.4 * Double(h)))
                        .frame(width: 3, height: h * maxH)
                }
            }
            .frame(height: maxH, alignment: .center)
        }
    }
}

/// Owns the borderless floating panel.
final class OverlayController {
    let model = OverlayModel()
    private var panel: NSPanel?

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
    }

    func show() {
        prepare()
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
