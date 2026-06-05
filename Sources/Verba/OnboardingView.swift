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
    @StateObject private var dictation = OnboardingDictation()
    @State private var tryMode = "Polish"
    @State private var customPrompt = "Convert my text into binary code (just 0s and 1s)."
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
        .onAppear { pulse = true }
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
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            Text("Three ways to use it").font(.headline)
            grid([
                ("hand.tap", "Single tap", "Start recording your default mode. Tap again to send."),
                ("hand.tap.fill", "Press & hold", "Push-to-talk: hold while you speak, release to send."),
                ("rectangle.2.swap", "Double-tap", "Open the mode picker, choose a mode on the fly."),
            ])
        }
    }

    private var modes: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Five modes, one per moment", "Verba cleans your speech differently per mode. Try it live below:")
            tryBlock
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
            title("Pause without lifting a finger", "")
            HStack(spacing: 12) {
                Text("⌃").font(.system(size: 26, weight: .semibold)).frame(width: 46, height: 46).glass(in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tap Control to pause / resume").font(.callout.weight(.medium))
                    Text("While recording, press ⌃ (Control) to pause listening, and again to resume. Esc cancels.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .padding(12).glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !(micGranted && axGranted) {
                Label("Grant both to start using Verba.", systemImage: "lock.fill").font(.caption).foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional, your own Claude key").font(.callout.weight(.medium))
                SecureField("sk-ant-… (skip if you use Claude Code or OpenRouter)", text: $anthropicKey).textFieldStyle(.roundedBorder)
            }
        }
    }

    // Live, in-onboarding dictation. The result lands in this field only, never on the
    // clipboard, so it can't be used before finishing onboarding. 6 tries per mode.
    private var tryBlock: some View {
        let key = tryMode
        let left = dictation.remaining(key)
        return VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $tryMode) {
                ForEach(["Flow", "Polish", "Casual", "Intent", "Coding", "Custom"], id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.segmented).labelsHidden()

            if tryMode == "Custom" {
                TextField("Your instruction…", text: $customPrompt, axis: .vertical)
                    .textFieldStyle(.plain).lineLimit(1...3)
                    .padding(10).background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack {
                Button {
                    if let p = profileForTry(key) { dictation.toggle(modeKey: key, profile: p) }
                } label: {
                    Label(dictation.state == .recording ? "Stop & transcribe"
                          : dictation.state == .working ? "Working…" : "Record & try",
                          systemImage: dictation.state == .recording ? "stop.circle.fill" : "mic.fill")
                }
                .buttonStyle(DarkButton())
                .opacity(left == 0 || dictation.state == .working ? 0.4 : 1)
                .disabled(left == 0 || dictation.state == .working)
                Spacer()
                Text("\(left)/6 left").font(.caption).foregroundStyle(.secondary)
            }

            ScrollView {
                Text(dictation.error.isEmpty ? (dictation.result.isEmpty ? "Your cleaned-up text will appear here." : dictation.result) : dictation.error)
                    .font(.callout)
                    .foregroundStyle(dictation.error.isEmpty ? (dictation.result.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)) : AnyShapeStyle(.red))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 96).padding(10)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .textSelection(.enabled)

            Text("Stays here during setup. Not copied to your clipboard yet.").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Resolve the profile for a try-block mode. Custom builds an ad-hoc profile from the
    /// user's typed instruction; Flow and the built-ins come from settings.
    private func profileForTry(_ key: String) -> Profile? {
        if key == "Custom" {
            let p = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !p.isEmpty else { return nil }
            return Profile(name: "Custom", systemPrompt: p + "\n\nKeep the speaker's language. Output ONLY the result.")
        }
        return settings.profiles.first { $0.name == key }
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

/// Runs a real dictation during onboarding, delivering the result into the onboarding
/// field only (never the clipboard or another app). Capped at 6 tries per mode.
@MainActor final class OnboardingDictation: ObservableObject {
    enum S { case idle, recording, working }
    @Published var state: S = .idle
    @Published var result = ""
    @Published var error = ""
    @Published private var counts: [String: Int] = [:]
    private let recorder = AudioRecorder()
    let maxPerStep = 6

    func remaining(_ key: String) -> Int { max(0, maxPerStep - (counts[key] ?? 0)) }

    func toggle(modeKey: String, profile: Profile) {
        switch state {
        case .working: return
        case .recording: stopAndRun(modeKey: modeKey, profile: profile)
        case .idle:
            guard remaining(modeKey) > 0 else { return }
            recorder.requestPermission { [weak self] ok in
                guard let self else { return }
                guard ok, self.recorder.start() else { self.error = "Microphone access is needed."; return }
                self.state = .recording
            }
        }
    }

    private func stopAndRun(modeKey: String, profile: Profile) {
        guard let url = recorder.stop() else { state = .idle; return }
        state = .working; error = ""; result = ""
        Task { [weak self] in
            do {
                let r = try await Pipeline.run(audioURL: url, frontmostBundleID: nil, forcedProfile: profile, selection: nil) { _ in }
                await MainActor.run {
                    guard let self else { return }
                    self.result = Output.trimTrailingNewlines(r.reprompted)
                    self.counts[modeKey, default: 0] += 1
                    self.state = .idle
                }
            } catch {
                await MainActor.run { self?.error = error.localizedDescription; self?.state = .idle }
            }
        }
    }
}
