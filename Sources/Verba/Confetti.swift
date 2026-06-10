import SwiftUI

// MARK: - Celebration effects (confetti + a reward card)
//
// A GPU-friendly Canvas confetti burst plus a glass reward card, driven by Gamification.pending.
// Drop `CelebrationOverlay()` once near the app root; it pops each queued Celebration with confetti
// and a card, auto-dismisses, and respects reduce-motion (a calm fade, no particles).

private struct ConfettiPiece {
    var x: Double, y: Double, vx: Double, vy: Double, rot: Double, vrot: Double, size: Double, hue: Double
}

/// A one-shot confetti burst from the top, time-driven so there are no timers to leak.
struct ConfettiCannon: View {
    var tint: Color
    var seed: Int
    @State private var start = Date()

    private var pieces: [ConfettiPiece] {
        // Deterministic pseudo-random off the seed so SwiftUI re-renders are stable.
        var rng = seed &* 2654435761
        func rnd() -> Double { rng = rng &* 1103515245 &+ 12345; return Double((rng >> 16) & 0x7fff) / 32768.0 }
        return (0..<120).map { _ in
            ConfettiPiece(x: rnd(), y: -rnd() * 0.2, vx: (rnd() - 0.5) * 0.6, vy: 0.25 + rnd() * 0.5,
                          rot: rnd() * 360, vrot: (rnd() - 0.5) * 480,
                          size: 4 + rnd() * 7, hue: rnd())
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard t < 2.6 else { return }
                let g = 0.9
                for p in pieces {
                    let px = (p.x + p.vx * t) * size.width
                    let py = (p.y + p.vy * t + 0.5 * g * t * t) * size.height
                    if py > size.height + 20 { continue }
                    let fade = max(0, 1 - t / 2.6)
                    var color = Color(hue: p.hue, saturation: 0.7, brightness: 0.95)
                    if p.hue > 0.6 { color = tint }   // bias toward the accent
                    let rect = CGRect(x: px, y: py, width: p.size, height: p.size * 0.5)
                    ctx.opacity = fade
                    ctx.translateBy(x: rect.midX, y: rect.midY)
                    ctx.rotate(by: .degrees(p.rot + p.vrot * t))
                    ctx.fill(Path(CGRect(x: -rect.width/2, y: -rect.height/2, width: rect.width, height: rect.height)),
                             with: .color(color))
                    ctx.rotate(by: .degrees(-(p.rot + p.vrot * t)))
                    ctx.translateBy(x: -rect.midX, y: -rect.midY)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A slowly spinning radial ray burst (conic gradient) used behind a level-up.
struct RaysBurst: View {
    var tint: Color
    @State private var spin = false
    var body: some View {
        AngularGradient(gradient: Gradient(stops: (0..<24).map { i in
            .init(color: i % 2 == 0 ? tint.opacity(0.16) : .clear, location: Double(i) / 24)
        }), center: .center)
        .frame(width: 900, height: 900)
        .rotationEffect(.degrees(spin ? 360 : 0))
        .blur(radius: 2)
        .allowsHitTesting(false)
        .onAppear { withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { spin = true } }
        .mask(RadialGradient(colors: [.white, .clear], center: .center, startRadius: 60, endRadius: 420))
    }
}

/// Sits once near the app root and celebrates each queued Celebration.
struct CelebrationOverlay: View {
    @ObservedObject private var game = Gamification.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var current: Celebration?
    @State private var shown = false

    var body: some View {
        ZStack {
            if let c = current {
                if !reduceMotion {
                    ConfettiCannon(tint: c.tint, seed: c.id.hashValue)
                        .ignoresSafeArea()
                    // A spinning ray burst behind a LEVEL-UP, for extra punch.
                    if case .levelUp = c.kind { RaysBurst(tint: c.tint).opacity(shown ? 1 : 0) }
                }
                card(c)
                    .scaleEffect(shown ? 1 : 0.8)
                    .opacity(shown ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: shown)
        .onReceive(game.$pending) { _ in pump() }
        .onAppear { pump() }
        .allowsHitTesting(current != nil)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
    }

    private func card(_ c: Celebration) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(c.tint.opacity(0.18)).frame(width: 86, height: 86)
                Circle().strokeBorder(c.tint.opacity(0.5), lineWidth: 2).frame(width: 86, height: 86)
                Image(systemName: c.icon).font(.system(size: 36, weight: .semibold)).foregroundStyle(c.tint)
            }
            .shadow(color: c.tint.opacity(0.4), radius: 18)
            VStack(spacing: 4) {
                Text(badgeLabel(c)).font(.caption.weight(.semibold)).foregroundStyle(c.tint).textCase(.uppercase)
                Text(c.title).font(.title2.weight(.bold))
                Text(c.subtitle).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Text("Tap to continue").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(28).frame(width: 320)
        .glass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.hairlineTint))
        .shadow(color: .black.opacity(0.25), radius: 40, y: 16)
    }

    private func badgeLabel(_ c: Celebration) -> String {
        switch c.kind {
        case .achievement: return "Achievement unlocked"
        case .levelUp: return "Level up"
        case .milestone: return "Milestone"
        }
    }

    private func pump() {
        guard current == nil, !game.pending.isEmpty else { return }
        current = game.consume()
        shown = false
        DispatchQueue.main.async { shown = true }
        // Auto-dismiss after a beat; tap dismisses sooner.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if shown { dismiss() }
        }
    }

    private func dismiss() {
        shown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            current = nil
            pump()   // show the next queued celebration, if any
        }
    }
}
