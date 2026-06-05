import SwiftUI
import AppKit
import AVFoundation

/// First-run flow. Real sign-in (Clerk via the web), guided tour, and BLOCKING gates:
/// you can't pass the account step until signed in, can't finish until macOS permissions
/// are granted, and the app itself stays locked until onboarding is done.
struct OnboardingView: View {
    @ObservedObject var settings = Settings.shared
    let onDone: () -> Void

    @State private var step = 0
    @ObservedObject private var coach = InputCoach.shared
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var copied = false
    @State private var signingIn = false
    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var axGranted = Output.accessibilityTrusted
    @State private var pulse = false

    private let total = 8
    private let poll = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Animated aurora backdrop → modern, alive.
            LinearGradient(colors: [.clear, accent.opacity(0.18), .clear],
                           startPoint: pulse ? .topLeading : .bottomTrailing,
                           endPoint: pulse ? .bottomTrailing : .topLeading)
                .blur(radius: 60).ignoresSafeArea()
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 0) {
                progressBar.padding(.horizontal, 30).padding(.top, 22).padding(.bottom, 6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        content
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)))
                            .id(step)
                    }
                    .padding(.horizontal, 30).padding(.top, 6).padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                nav
            }
        }
        .frame(width: 620, height: 720)
        .onAppear { pulse = true; coach.reset() }
        .onReceive(poll) { _ in
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            axGranted = Output.accessibilityTrusted
        }
    }

    private var accent: Color { .accentColor }

    // MARK: chrome
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule().fill(i <= step ? Color.primary : Color.primary.opacity(0.16))
                    .frame(width: i == step ? 24 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
            }
            Spacer()
            Text("\(step + 1) / \(total)").font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var hero: some View {
        let icons = ["sparkles", "person.crop.circle.badge.checkmark", "keyboard", "wand.and.stars",
                     "pause.circle", "chart.bar.doc.horizontal", "gift", "checkmark.shield"]
        return ZStack {
            Circle().fill(accent.opacity(0.16)).frame(width: 96, height: 96).blur(radius: 8)
                .scaleEffect(pulse ? 1.08 : 0.96)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)
            Image(systemName: icons[min(step, icons.count - 1)])
                .font(.system(size: 38, weight: .light))
                .frame(width: 84, height: 84)
                .glass(in: Circle())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 6).padding(.bottom, 2)
        .id("hero\(step)")
        .transition(.scale.combined(with: .opacity))
    }

    private var nav: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step -= 1 } }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            Spacer()
            if step < total - 1 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step += 1 }
                } label: { Text("Continue").frame(minWidth: 110) }
                    .buttonStyle(DarkButton())
                    .opacity(canAdvance ? 1 : 0.35)
                    .disabled(!canAdvance)
            } else {
                Button(action: finish) { Text("Start using Verba").frame(minWidth: 140) }
                    .buttonStyle(DarkButton())
                    .opacity(micGranted && axGranted ? 1 : 0.35)
                    .disabled(!(micGranted && axGranted))
            }
        }
        .padding(.horizontal, 30).padding(.top, 14).padding(.bottom, 46)   // roomy, not glued to the edge
    }

    /// Gating: account needs sign-in; permissions are on the last step (handled there).
    private var canAdvance: Bool {
        switch step {
        case 1: return !settings.proEmail.isEmpty
        default: return true
        }
    }

    // MARK: steps
    @ViewBuilder private var content: some View {
        switch step {
        case 0: welcome
        case 1: account
        case 2: triggerKey
        case 3: modes
        case 4: pauseAndFormatting
        case 5: insightsAndTools
        case 6: referral
        default: permissions
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Welcome to Verba", "Talk, and it lands as clean, structured text, right where your cursor is.")
            grid([
                ("lock.shield", "Private by default", "Transcription runs on your Mac. Your audio never has to leave the device."),
                ("bolt.fill", "Instant, anywhere", "One key from any app. No window to open, no copy-paste."),
                ("brain", "Your AI, your way", "Use your Claude plan or your own key, no markup on someone's cloud."),
                ("slider.horizontal.3", "Modes that fit", "Coding, writing, casual, intent, each routed to the right model."),
            ])
        }
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Create your account", "Sign in to unlock Verba, sync your plan, and earn referral rewards.")
            VStack(alignment: .leading, spacing: 12) {
                Button(action: doSignIn) {
                    HStack {
                        if signingIn { ProgressView().controlSize(.small) }
                        Image(systemName: "globe")
                        Text(settings.proEmail.isEmpty ? "Continue with Google / email" : "Signed in")
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(DarkButton())
                .opacity(settings.proEmail.isEmpty ? 1 : 0.5)
                .disabled(signingIn || !settings.proEmail.isEmpty)

                if !settings.proEmail.isEmpty {
                    Label("Signed in as \(settings.proEmail)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green).font(.callout)
                    Button("Use a different account") { settings.proEmail = "" }
                        .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Opens a secure window on verba.run. Sign up with Google or email, your account is created instantly.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var triggerKey: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Your trigger key", "The Fn (🌐 globe) key is the fastest way to dictate.")
            Toggle(isOn: $settings.useFnAsPrimary) {
                VStack(alignment: .leading) {
                    Text("Use the Fn (🌐 globe) key").font(.callout.weight(.medium))
                    Text("Verba swallows the globe key so macOS won't show the keyboard/emoji popup.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            if !settings.useFnAsPrimary {
                HStack {
                    Text("Or pick a shortcut:").font(.callout)
                    ShortcutRecorder(label: shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods),
                                     onCapture: { c, m in settings.primaryKeyCode = c; settings.primaryMods = m })
                    Spacer()
                }
            }
            HStack {
                Text("Three ways to use it").font(.headline)
                Spacer()
                Text("Try each one now 👇").font(.caption).foregroundStyle(.secondary)
            }
            actionRow("hand.tap", "Single tap", "Tap Fn once to start recording your default mode. Tap again to send.", done: coach.singleFn)
            actionRow("hand.tap.fill", "Press & hold", "Hold Fn while you speak, release to send (push-to-talk).", done: coach.holdFn)
            actionRow("rectangle.2.swap", "Double-tap", "Double-tap Fn to open the mode picker.", done: coach.doubleFn)
            if coach.singleFn && coach.holdFn && coach.doubleFn {
                Label("Nice, you've got the trigger key down.", systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.green)
            }
        }
    }

    /// A guided row that lights up green with a checkmark once the user performs the action.
    private func actionRow(_ icon: String, _ title: String, _ desc: String, done: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : icon)
                .font(.system(size: 17)).frame(width: 26)
                .foregroundStyle(done ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(desc).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(done ? Color.green.opacity(0.12) : Color.clear)
        )
        .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: done)
    }

    private var modes: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Five modes, one per moment", "Verba cleans your speech differently per mode.")
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars").font(.system(size: 17)).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try it live right now").font(.callout.weight(.medium))
                    Text("Press Fn (or your shortcut) and speak. The floating widget appears and the result lands where your cursor is.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            modeCard("Flow", "Haiku", "Raw dictation, your exact words, no AI.", nil)
            modeCard("Intent", "Sonnet", "The power mode. Say what you want, then the content, Verba does exactly that.",
                     "“Turn the following into three bullet points: we ship dark mode, postpone billing, hire a designer in Q3.”")
            modeCard("Polish", "Haiku", "Clear, courteous work messages, in your own voice.",
                     "“hey um can we move standup to ten, we ship friday, I need final copy by thursday”")
            modeCard("Coding", "Opus", "Rambling feedback → a precise prompt for Cursor / Claude Code.",
                     "“the login button doesn't work on mobile, the onclick is wrong, show the spinner while it loads”")
            modeCard("Casual", "Haiku", "Warm, natural texts to friends.",
                     "“yo tell mom I'll be like 20 min late, traffic is insane, I'll grab dinner on the way”")
            Label("You can also create your own Custom mode later in Settings ▸ Modes.", systemImage: "plus.circle")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var pauseAndFormatting: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Pause without lifting a finger", "Start a recording with Fn, then press Control to try it.")
            HStack(spacing: 12) {
                Text(coach.control ? "✓" : "⌃").font(.system(size: 24, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(coach.control ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                    .glass(in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(coach.control ? "You paused with Control" : "Tap Control to pause / resume").font(.callout.weight(.medium))
                    Text("While recording, press ⌃ (Control) to pause listening, and again to resume. Esc cancels.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(coach.control ? Color.green.opacity(0.12) : .clear))
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: coach.control)
            title("Format with your voice", "")
            grid([
                ("text.append", "Say the punctuation", "“new line”, “new paragraph”, “comma”, “bullet point”."),
                ("arrow.uturn.backward", "Fix on the fly", "“scratch that” deletes your last phrase, keep talking."),
            ])
        }
    }

    private var insightsAndTools: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Track your flow", "After you dictate, Verba shows a few simple KPIs.")
            grid([
                ("chart.bar.fill", "Insights", "Words dictated, words-per-minute, streak and a daily chart."),
                ("clock.arrow.circlepath", "History", "Every dictation, searchable, with replayable audio."),
                ("text.badge.plus", "Snippets", "Save blocks (signature, address) and insert them by intent."),
                ("character.book.closed", "Dictionary", "Teach Verba names and jargon so they're always spelled right."),
            ])
        }
    }

    private var referral: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Give a month, get a month", "Share Verba, it pays you back.")
            VStack(alignment: .leading, spacing: 10) {
                Text("Your referral link").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button(copied ? "Copied ✓" : "Copy") {
                        let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string); copied = true
                    }.glassButton()
                }
                .padding(12).frame(maxWidth: .infinity).glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            grid([
                ("gift.fill", "1 free month per friend", "Every person who subscribes through your link earns you a free month, unlimited."),
                ("checkmark.seal", "How it validates", "They count once they're a paying subscriber and have dictated 15,000+ words."),
            ])
        }
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Two permissions to finish", "Verba needs these to hear you and paste for you. You can't continue without them.")
            VStack(alignment: .leading, spacing: 12) {
                permRow("mic.fill", "Microphone", "To record what you say.", granted: micGranted) {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in }
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
                permRow("hand.point.up.left.fill", "Accessibility", "To paste into the active field.", granted: axGranted) {
                    Output.promptAccessibility()
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !(micGranted && axGranted) {
                Label("Grant both to start using Verba.", systemImage: "lock.fill").font(.caption).foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional, your own Claude key").font(.callout.weight(.medium))
                SecureField("sk-ant-… (skip if you use Claude Code or OpenRouter)", text: $anthropicKey).textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: actions
    private func doSignIn() {
        signingIn = true
        AuthSession.shared.signIn { email in
            DispatchQueue.main.async {
                signingIn = false
                guard let email else { return }
                settings.proEmail = email
                Task { _ = await settings.verifyPro() }
                // Signed in → the web window is already closed; move straight to the next step.
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { if step == 1 { step += 1 } }
            }
        }
    }

    private func finish() {
        Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.onboarded = true
        onDone()
    }

    // MARK: helpers
    private func title(_ t: String, _ s: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(t).font(.title.bold())
            if !s.isEmpty { Text(s).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }

    private func grid(_ items: [(String, String, String)]) -> some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.1) { icon, t, d in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon).font(.system(size: 17)).frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t).font(.callout.weight(.medium))
                        Text(d).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func modeCard(_ name: String, _ model: String, _ desc: String, _ sample: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).font(.callout.weight(.semibold))
                Spacer()
                Text(model).font(.caption2).padding(.horizontal, 7).padding(.vertical, 2).background(.softFill, in: Capsule())
            }
            Text(desc).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if let sample {
                Text(sample).font(.caption.italic()).foregroundStyle(.primary.opacity(0.8))
                    .padding(9).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func permRow(_ icon: String, _ t: String, _ d: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(t).font(.callout.weight(.medium))
                Text(d).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if granted { Label("Granted", systemImage: "checkmark.seal.fill").labelStyle(.iconOnly).foregroundStyle(.green) }
            else { Button("Enable", action: action).glassButton() }
        }
    }
}
