import SwiftUI
import AppKit
import AVFoundation
import IOKit.hid

/// First-run flow. Real sign-in (Clerk via the web), guided tour, and BLOCKING gates:
/// you can't pass the account step until signed in, can't finish until macOS permissions
/// are granted, and the app itself stays locked until onboarding is done.
struct OnboardingView: View {
    @ObservedObject var settings = Settings.shared
    let onDone: () -> Void

    @State private var step = 0
    @ObservedObject private var coach = InputCoach.shared
    @State private var copied = false
    @State private var signingIn = false
    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var axGranted = Output.accessibilityTrusted
    @State private var imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    @State private var screenGranted = ScreenCapture.hasPermission()
    @State private var pulse = false

    private let total = 9
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
        .onAppear {
            pulse = true; coach.reset()
            // Resumed after signing in but before finishing → skip the account step. If the
            // user already chose a public handle, jump straight to permissions (step 3);
            // otherwise land on the alias step (step 2) so they still see and confirm their
            // public username instead of silently keeping the random default.
            if step == 0 && !settings.proEmail.isEmpty {
                step = settings.usernameCustomized ? 3 : 2
            }
        }
        .onReceive(poll) { _ in
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            axGranted = Output.accessibilityTrusted
            imGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
            screenGranted = ScreenCapture.hasPermission()
            // Once Input Monitoring is granted on the permissions slide, bring the Fn tap up
            // so the trigger-key step can detect taps (idempotent once started).
            if imGranted && settings.useFnAsPrimary { FnTap.shared.start() }
        }
        .onChange(of: step) { newStep in
            // Reset the coach flags for the gesture slides on (re)entry so a Back/retry
            // reflects the CURRENT attempt rather than staying permanently green from
            // an earlier visit. Step 4 = trigger key (tap/hold/mode), step 5 = pause.
            switch newStep {
            case 4: coach.singleFn = false; coach.holdFn = false; coach.doubleFn = false; coach.changeMode = false
            case 5: coach.singleFn = false; coach.control = false
            default: break
            }
        }
    }

    private var accent: Color { .primary }

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
        let icons = ["sparkles", "person.crop.circle.badge.checkmark", "at", "lock.shield",
                     "globe", "pause.circle", "wand.and.stars", "chart.bar.doc.horizontal", "gift"]
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
                Button(L("Back")) { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step -= 1 } }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            Spacer()
            if step < total - 1 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step += 1 }
                } label: { Text(L("Continue")).frame(minWidth: 110) }
                    .buttonStyle(DarkButton())
                    .opacity(canAdvance ? 1 : 0.35)
                    .disabled(!canAdvance)
            } else {
                VStack(spacing: 8) {
                    Button(action: finish) { Text(L("Start using Verba")).frame(minWidth: 140) }
                        .buttonStyle(DarkButton())
                        .opacity(micGranted && axGranted && imGranted ? 1 : 0.35)
                        .disabled(!(micGranted && axGranted && imGranted))
                    // If a core permission was revoked after the permissions step, don't leave a
                    // silent dead button — name what's still missing so the user can go back.
                    if !(micGranted && axGranted && imGranted) {
                        let missing = [micGranted ? nil : L("Microphone"),
                                       axGranted ? nil : L("Accessibility"),
                                       imGranted ? nil : L("Input Monitoring")].compactMap { $0 }.joined(separator: ", ")
                        Text(L("Still needed: ") + missing)
                            .font(.caption).foregroundStyle(.orange).multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(.horizontal, 30).padding(.top, 14).padding(.bottom, 46)   // roomy, not glued to the edge
    }

    /// Gating: account needs sign-in; the three core permissions are blocking, granted
    /// right after the account step, before the user can go any further or use the app.
    private var canAdvance: Bool {
        switch step {
        case 1: return !settings.proEmail.isEmpty
        case 2: return !settings.username.trimmingCharacters(in: .whitespaces).isEmpty   // username set
        case 3: return micGranted && axGranted && imGranted   // the 3 core permissions (Screen Recording is optional)
        default: return true
        }
    }

    // MARK: steps
    @ViewBuilder private var content: some View {
        switch step {
        case 0: welcome
        case 1: account
        case 2: aliasStep
        case 3: permissionsStep
        case 4: triggerKey
        case 5: pauseAndFormatting
        case 6: modes
        case 7: insightsAndTools
        default: referral
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Welcome to Verba"), L("Talk, and it lands as clean, structured text, right where your cursor is."))
            grid([
                ("lock.shield", L("Private by default"), L("Transcription runs on your Mac. Your audio never has to leave the device.")),
                ("bolt.fill", L("Instant, anywhere"), L("One key from any app. No window to open, no copy-paste.")),
                ("brain", L("Your AI, your way"), L("Run a local model with no key, or bring your own — OpenAI, Claude, or a Claude Pro plan. Your AI, no markup.")),
                ("slider.horizontal.3", L("Modes that fit"), L("Coding, writing, casual, intent — each one shaped for the moment, and you can build your own.")),
            ])
        }
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Create your account"), L("Sign in to unlock Verba, sync your plan, and earn referral rewards."))
            VStack(alignment: .leading, spacing: 12) {
                Button(action: doSignIn) {
                    HStack {
                        if signingIn { ProgressView().controlSize(.small) }
                        Image(systemName: "globe")
                        Text(settings.proEmail.isEmpty ? L("Continue with Google / email") : L("Signed in"))
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(DarkButton())
                .opacity(settings.proEmail.isEmpty ? 1 : 0.5)
                .disabled(signingIn || !settings.proEmail.isEmpty)

                if !settings.proEmail.isEmpty {
                    Label(L("Signed in as") + " \(settings.proEmail)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green).font(.callout)
                    Button(L("Use a different account")) { AuthSession.shared.signOut() }
                        .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(L("Opens a secure window on verba.run. Sign up with Google or email, your account is created instantly."))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // Username step: the PUBLIC leaderboard handle. It is deliberately a random alias by
    // default (NEVER the Clerk first/last name or email), and the user makes it their own.
    // Synced to the account (Clerk) so the same handle follows them across Macs and the web.
    private var aliasStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            title(L("Pick your username"), L("It is never your real name or email. Pick something you like — you decide below whether it shows on the public leaderboard."))
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.primary.opacity(0.08)).frame(width: 52, height: 52)
                        Text(aliasInitials).font(.title3.weight(.semibold)).foregroundStyle(.primary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(L("Your username"), text: $settings.username)
                            .textFieldStyle(.plain).font(.title2.weight(.semibold))
                        Text(settings.showOnLeaderboard ? L("Shown on the public leaderboard — not your real name")
                                                        : L("Private — used only inside the app, never shown publicly")).font(.caption).foregroundStyle(.secondary)
                    }
                    Button { settings.username = Settings.randomAlias() } label: {
                        Image(systemName: "shuffle")
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary).help(L("Shuffle a new username"))
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                // Privacy choice: a user who doesn't want a public profile still keeps a name,
                // but it never appears on the leaderboard (binds to the existing opt-out flag).
                Toggle(isOn: Binding(get: { !settings.showOnLeaderboard },
                                     set: { settings.showOnLeaderboard = !$0 })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("Keep my profile private")).font(.callout.weight(.medium))
                        Text(L("Don't show me on the public leaderboard. Your name stays just for you.")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Label(L("Synced to your account. You can change your name or this choice anytime in Settings."), systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var aliasInitials: String {
        let parts = settings.username.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        let s = String(chars).uppercased()
        return s.isEmpty ? "V" : s
    }

    private var triggerKey: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Your trigger key"), L("The Fn (🌐 globe) key is the fastest way to dictate."))
            Toggle(isOn: $settings.useFnAsPrimary) {
                VStack(alignment: .leading) {
                    Text(L("Use the Fn (🌐 globe) key")).font(.callout.weight(.medium))
                    Text(L("Verba intercepts the globe key so macOS won't show the keyboard/emoji popup.")).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            if settings.useFnAsPrimary {
                Toggle(L("Keep the macOS Fn / emoji popup"), isOn: Binding(
                    get: { !settings.suppressFnPopup },
                    set: { settings.suppressFnPopup = !$0 }))
                Toggle(L("Keep the keyboard / input-source switcher"), isOn: Binding(
                    get: { !settings.disableInputSwitcher },
                    set: { settings.disableInputSwitcher = !$0 }))
                Text(L("Off (recommended) lets Verba use Fn cleanly. You can change these anytime in Settings ▸ Fn key behaviour."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if !settings.useFnAsPrimary {
                HStack {
                    Text(L("Or pick a shortcut:")).font(.callout)
                    ShortcutRecorder(label: shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods),
                                     onCapture: { c, m in settings.primaryKeyCode = c; settings.primaryMods = m })
                    Spacer()
                }
            }
            if settings.useFnAsPrimary {
                HStack {
                    Text(L("Main controls")).font(.headline)
                    Spacer()
                    Text(L("Try each one now 👇")).font(.caption).foregroundStyle(.secondary)
                }
                actionRow("hand.tap", L("Single tap"), L("Tap Fn once to start recording your default mode. Tap again to send."), done: coach.singleFn)
                actionRow("hand.tap.fill", L("Press & hold"), L("Hold Fn while you speak, release to send (push-to-talk)."), done: coach.holdFn)
                actionRow("number.circle", L("Pick a mode: Fn + number"), L("Hold Fn and press 1 to 9 to dictate in a specific mode (1 Raw, 2 Intent, …). The mode you pick sticks for next time."), done: coach.doubleFn)
                actionRow("slider.horizontal.3", L("Switch mode on the fly"), L("Fn + Tab → next mode, Fn + ⇧ + Tab → previous — even mid-sentence while holding Fn. ⌃ (Control) pauses & resumes, ⌥ (Option) also switches mode, Esc cancels."), done: coach.changeMode)
                if coach.singleFn && coach.holdFn && coach.doubleFn && coach.changeMode {
                    Label(L("Nice, you've got the trigger key down."), systemImage: "checkmark.seal.fill")
                        .font(.callout.weight(.medium)).foregroundStyle(.green)
                }
            } else {
                // Shortcut path: the Fn-tap/hold/number gestures don't apply, so coach the
                // ONE achievable action — pressing the chosen shortcut. `singleFn` fires from
                // the shared startDictation path whether the trigger is Fn or a shortcut.
                HStack {
                    Text(L("Try your shortcut")).font(.headline)
                    Spacer()
                    Text(L("Press it now 👇")).font(.caption).foregroundStyle(.secondary)
                }
                actionRow("command", L("Start / stop dictation"),
                          L("Press your shortcut to start recording your default mode. Press it again to send."),
                          done: coach.singleFn)
                Text(L("Tip: ⌃ (Control) pauses & resumes while recording, ⌥ (Option) switches mode mid-sentence, and Esc cancels — these work no matter which trigger you choose."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if coach.singleFn {
                    Label(L("Nice, your shortcut works."), systemImage: "checkmark.seal.fill")
                        .font(.callout.weight(.medium)).foregroundStyle(.green)
                }
            }

            // Full shortcut reference — the power keys beyond plain dictation, so nothing is hidden.
            Text(L("All shortcuts")).font(.headline).padding(.top, 4)
            grid([
                ("bolt.fill", L("Action — Fn + X"), L("Speak a command and Verba acts for you across 1,000+ connected apps (send an email, create an event…). It always asks you to confirm before doing anything.")),
                ("doc.text", L("Note — Fn + Z"), L("Record a long voice memo; Verba turns it into a clean, structured note.")),
                ("checklist", L("To-do — Fn + T"), L("Capture a task by voice (Fn + § on ISO keyboards). “Pay the invoice Friday at 6pm.”")),
                ("calendar.day.timeline.left", L("Today's to-dos — ⌥ + Fn"), L("Glance at what's due today without leaving what you're doing.")),
                ("wand.and.rays", L("Transform selection — ⌥ + X"), L("Select any text in any app, then ⌥ + X to rewrite, translate or restyle it.")),
                ("paintbrush", L("Switch style — Fn + ] / Fn + ["), L("Cycle the tone/format layer (next / previous) on top of the active mode.")),
                ("pause.circle", L("Pause · switch · cancel"), L("⌃ (Control) pauses & resumes, ⌥ (Option) switches mode mid-sentence, Esc cancels — any time you're recording.")),
            ])
            // Emoji/keyboard popup escape hatch: if macOS still shows it, point to the system toggle.
            Label(L("Still seeing the macOS emoji / keyboard popup? Turn it off in System Settings ▸ Keyboard ▸ “Press 🌐 key to” → Do Nothing."), systemImage: "keyboard.badge.ellipsis")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
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
            title(L("A mode for every moment"), L("Verba cleans your speech differently per mode, and detects the language you speak automatically."))
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars").font(.system(size: 17)).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Try it live right now")).font(.callout.weight(.medium))
                    Text(L("Press Fn (or your shortcut) and speak. The recording indicator appears and the result lands where your cursor is.")).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            // VER-27: lead with the one mode you need to start (Raw), then clearly mark the rest
            // as advanced so new users aren't overwhelmed by every mode at once.
            Text(L("Start here")).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
            modeCard("Raw", L("No AI"), L("Raw dictation, your exact words, no AI. This is all you need to start, the rest is for later."), nil)
            Text(L("Advanced modes — explore when you're ready")).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase).padding(.top, 4)
            modeCard("Intent", L("Smart"), L("The power mode. Say what you want, then the content, Verba does exactly that."),
                     L("“Turn the following into three bullet points: we ship dark mode, postpone billing, hire a designer in Q3.”"))
            modeCard("Prompt", L("Pro"), L("What you say → a clean, optimized AI prompt. For ChatGPT, Claude, an image generator, or a coding agent like Cursor / Claude Code."),
                     L("“a prompt to plan a 3-day Tokyo trip on a 1500 euro budget, foodie, skip museums” or “the login button doesn't work on mobile, the onclick is wrong, show a spinner while it loads”"))
            modeCard("Context", L("Vision"), L("The new advanced mode. Verba takes a screenshot, reads your screen, and acts on what is there."),
                     L("“reply to this email and say I'm in”, “write a caption for this photo”, “answer the question on screen”"))
            modeCard(L("Create your own"), L("Custom"), L("Build a mode for exactly your need — describe it and Verba writes the prompt. Auto-switch it per app. In Settings ▸ Modes."), nil)
            Label(L("Every mode runs on the model you choose — a local model, your Claude/OpenAI/OpenRouter key, or your Claude plan. Adjustable anytime in Settings ▸ Modes."), systemImage: "slider.horizontal.3")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Label(L("Context needs Screen Recording permission (you'll grant it on first use) and a vision-capable model."), systemImage: "camera.viewfinder")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pauseAndFormatting: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Pause without lifting a finger"), L("While a recording is running, press Control to pause — tap it again to resume."))
            HStack(spacing: 12) {
                Text(coach.control ? "✓" : "⌃").font(.system(size: 24, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(coach.control ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                    .glass(in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(coach.control ? L("You paused with Control") : L("Tap Control to pause / resume")).font(.callout.weight(.medium))
                    Text(L("While recording, press ⌃ (Control) to pause listening, and again to resume. Tap ⌥ (Option) to switch mode mid-sentence. Esc cancels.")).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(coach.control ? Color.green.opacity(0.12) : .clear))
            .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: coach.control)
            title(L("Format with your voice"), "")
            grid([
                ("text.append", L("Say the punctuation"), L("“new line”, “new paragraph”, “comma”, “bullet point”.")),
                ("arrow.uturn.backward", L("Fix on the fly"), L("“scratch that” deletes your last phrase, keep talking.")),
                ("square.stack.3d.up.fill", L("Chain recordings"), L("No need to wait: tap Fn and dictate the next one while the last is still processing. Every dictation still working stacks up above the pill, so you can fire off 10 in a row and watch them all land.")),
            ])
        }
    }

    private var insightsAndTools: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Track your flow"), L("Verba turns every dictation into simple insight — and keeps your work within reach."))
            grid([
                ("chart.bar.fill", L("Insights"), L("Words dictated, words-per-minute, streak and a daily chart — your flow at a glance.")),
                ("clock.arrow.circlepath", L("History you can rework"), L("Every dictation is saved and searchable. Reopen one and re-run it in another mode to reshape it. Audio replay is optional — keep or turn it off in Settings.")),
                ("text.badge.plus", L("Snippets"), L("Save blocks (signature, address) and insert them by intent.")),
                ("character.book.closed", L("Dictionary"), L("Teach Verba names and jargon so they're always spelled right.")),
            ])
        }
    }

    private var referral: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(L("Give a month, get a month"), L("Share Verba, it pays you back."))
            VStack(alignment: .leading, spacing: 10) {
                Text(L("Your referral link")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button(copied ? L("Copied ✓") : L("Copy")) {
                        let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string); copied = true
                    }.glassButton()
                    // Same Share affordance as the Free Month tab + Account card.
                    Button { shareReferral() } label: { Label(L("Share…"), systemImage: "square.and.arrow.up") }
                        .glassButton()
                }
                .padding(12).frame(maxWidth: .infinity).glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            grid([
                ("gift.fill", L("1 free month per friend"), L("Every person who subscribes through your link earns you a free month, unlimited.")),
                ("checkmark.seal", L("How it validates"), L("They count once they're a paying subscriber and have dictated 15,000+ words.")),
            ])
            Label(L("AI rewriting works out of the box with your Verba plan, no API key needed. You can still add your own key later in Settings."), systemImage: "sparkles")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: permissions (all four on one step, right after the account step)

    private var permissionsStep: some View {
        let core = micGranted && axGranted && imGranted
        return VStack(alignment: .leading, spacing: 16) {
            title(L("Grant permissions"), L("Verba needs these to hear you, paste for you, and use the Fn key. Grant the three core ones to continue."))
            VStack(spacing: 12) {
                permRow("mic.fill", L("Microphone"), L("To record what you say."), granted: micGranted) {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in }
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
                Divider()
                permRow("hand.point.up.left.fill", L("Accessibility"), L("To paste into the active app."), granted: axGranted) {
                    Output.promptAccessibility()
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                Divider()
                permRow("keyboard", L("Input Monitoring"), L("To use the Fn key as your trigger."), granted: imGranted) {
                    _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
                }
                Divider()
                permRow("camera.viewfinder", L("Screen Recording (optional)"), L("Only for Context mode."), granted: screenGranted) {
                    ScreenCapture.requestPermission()
                    ScreenCapture.openPrivacySettings()
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if core {
                Label(L("All set, you can continue. Screen Recording is optional (Context mode)."), systemImage: "checkmark.seal.fill")
                    .font(.callout.weight(.medium)).foregroundStyle(.green).fixedSize(horizontal: false, vertical: true)
            } else {
                Label(L("Grant Microphone, Accessibility and Input Monitoring to continue. The Continue button unlocks once they're on."), systemImage: "lock.fill")
                    .font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
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
        // API-key entry lives in Settings ▸ AI rewriting; onboarding never touches it.
        settings.onboarded = true
        onDone()
    }

    // MARK: helpers

    /// Share the referral link through the native macOS share sheet — mirrors the
    /// Free Month tab + Account card so the referral surfaces stay consistent.
    private func shareReferral() {
        let picker = NSSharingServicePicker(items: [URL(string: settings.referralLink) ?? settings.referralLink as Any])
        if let win = NSApp.keyWindow, let view = win.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }

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
            if granted { Label(L("Granted"), systemImage: "checkmark.seal.fill").labelStyle(.iconOnly).foregroundStyle(.green) }
            else { Button(L("Enable"), action: action).glassButton() }
        }
    }
}
