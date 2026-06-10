import SwiftUI
import AppKit
import Combine

/// What the current recording/processing is for — surfaced as a small badge on the pill so the
/// user can always tell a normal dictation apart from a Note (Fn+Z) or a To-do capture (Fn+T, or Fn+§ on ISO).
enum CaptureContext {
    case dictation, note, todo, action

    var label: String {
        switch self {
        case .dictation: return "Dictation"
        case .note:      return "Note"
        case .todo:      return "To-do"
        case .action:    return "Action"
        }
    }

    var symbol: String {
        switch self {
        case .dictation: return "waveform"
        case .note:      return "doc.text"
        case .todo:      return "checklist"
        case .action:    return "bolt.fill"
        }
    }
}

final class OverlayModel: ObservableObject {
    @Published var context: CaptureContext = .dictation   // what this capture is for (badge)
    @Published var modeName: String = ""  // active reprompt mode for the badge ("" = none, e.g. Note/To-do)
    @Published var level: Float = 0      // 0...1 mic level
    @Published var phase: Double = 0     // advanced by our own timer → animation never stalls
    @Published var title: String = ""    // "Listening…" / "Transcribing…" / etc.
    @Published var recording = false
    @Published var paused = false        // dictation paused
    @Published var done = false          // brief success flash
    @Published var info = false          // brief discreet hint (e.g. "Didn't catch that")
    @Published var modeHint = false      // brief mode-change flash (e.g. "Mode · Coding")
    @Published var error = false         // brief red error flash (e.g. "Transcription failed")
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

/// The recording indicator. Two looks (set in Settings ▸ Recording):
///   • floating, glass pill at the bottom (default)
///   • minimal, no overlay at all, the menu-bar icon is the indicator
struct OverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        Group {
            switch model.style {
            case .floating: floating
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
                // The cancel/X is shown whenever something is in flight (recording OR
                // processing) and must ALWAYS be clickable so a hung process can be aborted
                // without quitting. Hidden only on the brief done flash and the mode picker.
                if !model.menu && !model.done {
                    Button { model.onCancel?() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(.secondary)
                            .padding(8).contentShape(Rectangle())   // big, always-hittable target
                    }
                    .buttonStyle(.plain)
                    .help("Cancel (Esc)")
                    .allowsHitTesting(true)   // never let an overlaid ProgressView swallow the click
                }
            }
            picker(font: 11)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(minHeight: 44)   // one stable pill height across idle/recording/processing
        .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .fixedSize()
        // Content swaps (waveform/pause/picker appearing) and the resulting width change
        // animate smoothly instead of snapping → no erratic morph between states.
        .animation(.easeInOut(duration: 0.22), value: model.recording)
        .animation(.easeInOut(duration: 0.22), value: model.menu)
        .animation(.easeInOut(duration: 0.22), value: model.done)
        .animation(.easeInOut(duration: 0.22), value: model.title)
        .animation(.easeInOut(duration: 0.22), value: model.modeName)
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
        if model.error {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: big ? 14 : 12)).foregroundStyle(.red)
        } else if model.done {
            Image(systemName: "checkmark.circle.fill").font(.system(size: big ? 14 : 12)).foregroundStyle(.green)
        } else if model.modeHint {
            Image(systemName: "slider.horizontal.3").font(.system(size: big ? 13 : 12)).foregroundStyle(.secondary)
        } else if model.info {
            Image(systemName: "mic.slash").font(.system(size: big ? 13 : 12)).foregroundStyle(.secondary)
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
        if model.error {
            // The outer pill applies .fixedSize() (both axes), which would otherwise resolve
            // this Text's horizontal ideal to the FULL unwrapped string width — so lineLimit(2)
            // never wraps and a long error stretches the pill past the screen. Cap the width and
            // fix only the vertical axis so the text wraps to ≤2 lines within that bound.
            Text(model.title.isEmpty ? "Error" : model.title)
                .font(.system(size: size, weight: .medium)).foregroundStyle(.red).lineLimit(2)
                .frame(maxWidth: 280, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else if model.done {
            Text(model.title.isEmpty ? "Done" : model.title).font(.system(size: size, weight: .medium)).lineLimit(1)
        } else if model.menu {
            Text("Choose a mode").font(.system(size: size, weight: .medium)).lineLimit(1)
        } else if model.paused {
            Text("Paused").font(.system(size: size, weight: .medium)).lineLimit(1)
        } else {
            // "Listening · Custom" → "Listening" + a black tag with the full mode name in white.
            // Both use fixedSize so the mode tag never gets compressed/truncated — it always
            // shows the whole word at its natural width (the panel grows to fit).
            let parts = model.title.components(separatedBy: " · ")
            HStack(spacing: 6) {
                Text(parts.first ?? model.title)
                    .font(.system(size: size, weight: .medium))
                    .fixedSize(horizontal: true, vertical: false)
                if parts.count > 1, !parts[1].isEmpty {
                    modeTag(parts[1], size: size)
                }
            }
        }
    }

    /// The black mode pill on the right of "Listening". While recording with reprompt modes
    /// available it's a CLICKABLE menu: picking a mode switches THIS dictation's mode live
    /// (via onSelect, which retargets the forced profile) and keeps listening — no stop. A small
    /// chevron hints it's interactive. Falls back to a plain tag when there's nothing to switch.
    @ViewBuilder private func modeTag(_ name: String, size: CGFloat) -> some View {
        let switchable = model.recording && !model.paused && model.profiles.count > 1
        if switchable {
            Menu {
                ForEach(model.profiles) { p in
                    Button {
                        model.selectedID = p.id
                        model.onSelect?(p)
                    } label: {
                        if p.id == model.selectedID {
                            Label(p.name, systemImage: "checkmark")
                        } else {
                            Text(p.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(name).font(.system(size: size - 1, weight: .semibold))
                    Image(systemName: "chevron.down").font(.system(size: size - 4, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(Color.black))
                .fixedSize(horizontal: true, vertical: false)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Switch mode — keeps recording")
        } else {
            Text(name)
                .font(.system(size: size - 1, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(Color.black))
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    @ViewBuilder private func picker(font: CGFloat) -> some View {
        // Only in the picker menu, never during recording (a single Fn = a clean recording).
        if model.menu && !model.profiles.isEmpty {
            HStack(spacing: 6) {
                ForEach(Array(model.profiles.enumerated()), id: \.element.id) { idx, p in
                    let isActive = model.menu && p.id == model.activeID
                    let isSwitch = !model.menu && p.id == model.selectedID
                    let hot = isActive || isSwitch
                    let num = idx < 9 ? "\(idx + 1) " : ""   // 1-9: type the number to pick
                    Button {
                        if model.menu { model.onStart?(p) }
                        else { model.selectedID = p.id; model.onSelect?(p) }
                    } label: {
                        Text("\(num)\(p.name)").font(.system(size: font, weight: hot ? .semibold : .regular))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(hot ? Color.primary.opacity(0.95) : Color.primary.opacity(0.1)))
                            .foregroundStyle(hot ? (model.style == .floating ? Color.white : Color.black) : Color.primary.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
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
        let host = NSHostingController(rootView: OverlayView(model: model))
        host.sizingOptions = [.preferredContentSize]   // window tracks SwiftUI's intrinsic size → no truncation
        p.contentViewController = host
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
        reposition(animated: true)
    }

    func show() {
        prepare()
        model.style = Settings.shared.overlayStyle
        // Minimal = no floating UI at all. The menu-bar icon is the only indicator, and the
        // mode is chosen from the menu-bar dropdown (the picker gestures are disabled here).
        if model.style == .minimal { panel?.orderOut(nil); return }
        panel?.level = .statusBar
        reposition()
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    func reposition(animated: Bool = false) {
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 260, height: 80)
        lastSize = size
        let vf = screen.visibleFrame
        let x = vf.midX - size.width / 2
        let y: CGFloat
        switch model.style {
        case .floating: y = vf.minY + 90              // bottom center
        case .minimal:  y = vf.maxY - size.height - 6
        }
        // Account for the panel's title-bar inset so the *content* lands at the target size.
        let frame = NSRect(origin: NSPoint(x: x, y: y),
                           size: panel.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size)
        if animated && panel.isVisible {
            // Smoothly grow/shrink the pill as states change — kills the snap/morph glitch.
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.22
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                ctx.allowsImplicitAnimation = true
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }
}
