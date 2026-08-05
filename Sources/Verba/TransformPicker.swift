import SwiftUI
import AppKit
import Carbon.HIToolbox

/// The phase of the transform picker: choosing from the list, or running the chosen transform.
enum TransformPickerPhase: Equatable {
    case list
    case working(String)   // the transform name being applied
}

final class TransformPickerModel: ObservableObject {
    @Published var phase: TransformPickerPhase = .list
}

/// The ⌥X transform picker: a floating glass panel (same design language as the to-do glance and
/// the widget) listing the user's transforms, NUMBERED 1-9. Press the number — or click a row — to
/// run that transform on the current selection. While it runs, the panel shows a live
/// "Transforming…" state (mirroring the dictation pill's listening / transcribing states). Esc or a
/// click-away dismisses it.
struct TransformPickerView: View {
    let transforms: [Transform]
    @ObservedObject var model: TransformPickerModel
    var onPick: (Transform) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Text(L("Transform selection")).font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 18)
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary).padding(6).contentShape(Rectangle())
                }
                .buttonStyle(.plain).help(L("Close (Esc)"))
            }

            switch model.phase {
            case .list:
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(transforms.prefix(9).enumerated()), id: \.element.id) { i, t in
                        row(index: i + 1, transform: t)
                    }
                }
                Text(L("Press 1-9 or click"))
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
                    .padding(.top, 2)
            case .working(let name):
                workingRow(name)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(width: 300, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.18), value: model.phase)
    }

    /// The live "applying this transform" state — a spinner + the transform name, styled like the
    /// dictation pill's transcribing state.
    @ViewBuilder private func workingRow(_ name: String) -> some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small).scaleEffect(0.85)
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Transforming…")).font(.system(size: 13, weight: .medium))
                Text(name.isEmpty ? L("your selection") : name)
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
    }

    @ViewBuilder private func row(index: Int, transform t: Transform) -> some View {
        Button { onPick(t) } label: {
            HStack(spacing: 10) {
                Text("\(index)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(t.name.isEmpty ? L("(unnamed)") : t.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private final class PickerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Owns the floating transform-picker panel. Number keys 1-9 pick, Esc / click-away dismiss.
final class TransformPickerController {
    static let shared = TransformPickerController()

    private var panel: NSPanel?
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private var workingEscapeMonitor: Any?
    private var transforms: [Transform] = []
    private var onPick: ((Transform) -> Void)?
    private let model = TransformPickerModel()

    var isShowing: Bool { panel?.isVisible ?? false }

    /// Present the picker near a screen point (typically the mouse), for the given transforms.
    func present(_ transforms: [Transform], at point: NSPoint, onPick: @escaping (Transform) -> Void) {
        self.transforms = Array(transforms.prefix(9))
        self.onPick = onPick
        model.phase = .list
        rebuild()
        guard let panel, let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 300, height: 200)
        let vf = screen.visibleFrame
        // Anchor the panel's top-left near the cursor, clamped on screen.
        var x = point.x
        var y = point.y - size.height
        x = min(max(vf.minX + 8, x), vf.maxX - size.width - 8)
        y = min(max(vf.minY + 8, y), vf.maxY - size.height - 8)
        let frame = NSRect(origin: NSPoint(x: x, y: y),
                           size: panel.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size)
        panel.setFrame(frame, display: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        installDismissMonitors()
    }

    private func rebuild() {
        // Always rebuild the hosted view so the row list reflects the current transforms.
        let p = panel ?? {
            let np = PickerPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                                 styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
            np.isFloatingPanel = true
            np.level = .statusBar
            np.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            np.backgroundColor = .clear
            np.isOpaque = false
            np.hasShadow = true
            panel = np
            return np
        }()
        let host = NSHostingController(rootView: TransformPickerView(
            transforms: transforms,
            model: model,
            onPick: { [weak self] t in self?.pick(t) },
            onClose: { [weak self] in self?.hide() }))
        host.sizingOptions = [.preferredContentSize]
        p.contentViewController = host
        // Clip to the rounded shape at the window layer so the glass material / window shadow never
        // bleed a square edge past the 18pt rounded corners.
        host.view.wantsLayer = true
        host.view.layer?.cornerRadius = 18
        host.view.layer?.cornerCurve = .continuous
        host.view.layer?.masksToBounds = true
        p.layoutIfNeeded()
    }

    private func pick(_ t: Transform) {
        // Flip to the live "Transforming…" state and keep the panel up; the action handler runs the
        // transform and calls hide() when it finishes (or fails). Stop accepting list input (number
        // keys / click-away) so a second transform can't be launched mid-run — but keep an Esc-only
        // monitor alive so a stalled/slow provider call can never leave the panel spinning forever
        // with no dismiss affordance. Esc here just orders the panel out (the eventual completion
        // still calls hide()); it is the one always-available escape hatch during .working.
        removeDismissMonitors()
        installWorkingEscapeMonitor()
        model.phase = .working(t.name)
        onPick?(t)
    }

    func hide() {
        panel?.orderOut(nil)
        // Reset the phase with the panel: `pick` is the only writer and it never clears it, so a
        // hidden panel stays `.working` forever. `present` re-seeds `.list`, but any future show
        // path that skips it would open straight onto a stale spinner.
        model.phase = .list
        removeDismissMonitors()
        removeWorkingEscapeMonitor()
    }

    /// During the `.working` phase the list monitors are gone; keep a lone Esc monitor so the spinner
    /// panel always has a dismiss affordance, even if the background transform stalls. Esc orders the
    /// panel out (a still-running transform's late result is handled by the action handler's hide()).
    private func installWorkingEscapeMonitor() {
        removeWorkingEscapeMonitor()
        workingEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == UInt16(kVK_Escape) { self.hide(); return nil }
            return event
        }
    }

    private func removeWorkingEscapeMonitor() {
        if let m = workingEscapeMonitor { NSEvent.removeMonitor(m); workingEscapeMonitor = nil }
    }

    private func installDismissMonitors() {
        removeDismissMonitors()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == UInt16(kVK_Escape) { self.hide(); return nil }
            if let n = Self.digit(Int(event.keyCode)), n >= 1, n <= self.transforms.count {
                self.pick(self.transforms[n - 1]); return nil
            }
            return event
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    private func removeDismissMonitors() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }

    private static func digit(_ code: Int) -> Int? {
        switch code {
        case kVK_ANSI_1: return 1; case kVK_ANSI_2: return 2; case kVK_ANSI_3: return 3
        case kVK_ANSI_4: return 4; case kVK_ANSI_5: return 5; case kVK_ANSI_6: return 6
        case kVK_ANSI_7: return 7; case kVK_ANSI_8: return 8; case kVK_ANSI_9: return 9
        default: return nil
        }
    }
}
