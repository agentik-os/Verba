import SwiftUI
import AppKit

/// First-run flow: a guided, paged onboarding that signs the user in, explains what
/// makes Verba different, configures the trigger key, walks through the modes, the
/// keyboard pause, and hands over the referral link.
struct OnboardingView: View {
    @ObservedObject var settings = Settings.shared
    let onDone: () -> Void

    @State private var step = 0
    @State private var email = Settings.shared.proEmail
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    @State private var copied = false

    private let total = 8

    var body: some View {
        GlassContainer(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.primary : Color.primary.opacity(0.18))
                            .frame(width: i == step ? 22 : 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: step)
                    }
                    Spacer()
                    Text("\(step + 1) / \(total)").font(.caption2).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 28).padding(.top, 22).padding(.bottom, 10)

                ScrollView {
                    content
                        .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)

                // Nav buttons
                HStack {
                    if step > 0 {
                        Button("Back") { withAnimation { step -= 1 } }.buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if step < total - 1 {
                        Button(action: { withAnimation { step += 1 } }) { Text(nextLabel).frame(minWidth: 90) }
                            .glassProminentButton().controlSize(.large)
                            .disabled(step == 1 && !emailValid)
                    } else {
                        Button("Start using Verba", action: finish).glassProminentButton().controlSize(.large)
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 18)
            }
            .frame(width: 560, height: 660)
        }
    }

    private var nextLabel: String { step == 1 ? "Continue" : "Next" }
    private var emailValid: Bool { email.contains("@") && email.contains(".") }

    // MARK: - Steps
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

    // 0 — Welcome / differentiation
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Welcome to Verba", "Talk, and it lands as clean, structured text — right where your cursor is.")
            grid([
                ("lock.shield", "Private by default", "Transcription runs on your Mac. Your audio never has to leave the device, and nothing is written to disk."),
                ("bolt.fill", "Instant, anywhere", "One key from any app. No window to open, no copy-paste."),
                ("brain", "Your AI, your way", "Use your Claude Code plan or your own key — you're not paying a markup on someone's cloud."),
                ("slider.horizontal.3", "Modes that fit", "Coding, writing, casual, intent — each routed to the right model."),
            ])
        }
    }

    // 1 — Sign in
    private var account: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Sign in to Verba", "Your plan, history and referral rewards live in your account.")
            VStack(alignment: .leading, spacing: 10) {
                Text("Email").font(.caption).foregroundStyle(.secondary)
                TextField("you@example.com", text: $email).textFieldStyle(.roundedBorder)
                Button {
                    if let u = URL(string: "https://verba.run/account") { NSWorkspace.shared.open(u) }
                } label: { Label("Create account / sign in on verba.run", systemImage: "arrow.up.forward.app") }
                    .buttonStyle(.plain).foregroundStyle(.tint).font(.callout)
                Text("Create your account in the browser, then enter the same email here to link this Mac. We'll restore Pro automatically if you're subscribed.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            if !emailValid {
                Label("Enter your email to continue.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // 2 — Trigger key + Fn behaviours
    private var triggerKey: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Your trigger key", "The Fn (🌐 globe) key is the fastest way to dictate. Make it yours.")
            Toggle(isOn: $settings.useFnAsPrimary) {
                VStack(alignment: .leading) {
                    Text("Use the Fn (🌐 globe) key").font(.callout.weight(.medium))
                    Text("Verba swallows the globe key so macOS won't show the keyboard/emoji popup.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(14).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !settings.useFnAsPrimary {
                HStack {
                    Text("Or pick a shortcut:").font(.callout)
                    ShortcutRecorder(
                        label: shortcutLabel(keyCode: settings.primaryKeyCode, modifiers: settings.primaryMods),
                        onCapture: { code, mods in settings.primaryKeyCode = code; settings.primaryMods = mods })
                    Spacer()
                }
            }

            Text("Three ways to use it").font(.headline)
            grid([
                ("hand.tap", "Single tap", "Start recording your default mode. Tap again to send."),
                ("hand.tap.fill", "Press & hold", "Push-to-talk: keep it held while you speak, release to send."),
                ("rectangle.2.swap", "Double-tap", "Open the mode picker — choose Coding / Polish / Casual / Intent / Flow on the fly."),
            ])
        }
    }

    // 3 — Modes
    private var modes: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Five modes, one for every moment", "Verba reorders and cleans your speech differently per mode. Try dictating these:")
            modeCard("Flow", "Haiku", "Raw dictation — your exact words, no AI. Great for notes and quotes.", nil)
            modeCard("Intent", "Sonnet", "The power mode. Start by saying what you want, then the content — and Verba does exactly that.",
                     "“Turn the following into three bullet points of decisions: we ship dark mode, postpone billing, hire a designer in Q3.”")
            modeCard("Polish", "Haiku", "Clear, courteous work messages and emails — in your own voice.",
                     "“hey um can we move standup to ten, we ship friday, and I need final copy by thursday”")
            modeCard("Coding", "Opus", "Turns rambling feedback into a precise prompt for Cursor / Claude Code.",
                     "“ok the login button doesn't work on mobile, I think the onclick is wrong, and show the spinner while it loads”")
            modeCard("Casual", "Haiku", "Warm, natural texts to friends and family.",
                     "“yo tell mom I'll be like 20 min late, traffic is insane, I'll grab dinner on the way”")
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").foregroundStyle(.secondary)
                Text("You can also create your own **Custom** mode later in Settings ▸ Modes.").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }

    // 4 — Pause + formatting
    private var pauseAndFormatting: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Pause without lifting a finger", "No need to reach for the mouse mid-sentence.")
            HStack(spacing: 12) {
                Text("⌃").font(.system(size: 26, weight: .semibold)).frame(width: 46, height: 46).glass(in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tap Control to pause / resume").font(.callout.weight(.medium))
                    Text("While recording, press the ⌃ (Control) key to pause listening, and again to resume. Esc cancels.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            title("Format with your voice", "")
            grid([
                ("text.append", "Say the punctuation", "“new line”, “new paragraph”, “comma”, “question mark”, “bullet point”."),
                ("arrow.uturn.backward", "Fix on the fly", "“scratch that” deletes your last phrase — keep talking."),
            ])
        }
    }

    // 5 — Insights + tools
    private var insightsAndTools: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Track your flow", "After you dictate, Verba shows you a few simple KPIs.")
            grid([
                ("chart.bar.fill", "Insights", "Words dictated, words-per-minute, your streak and a daily chart."),
                ("clock.arrow.circlepath", "History", "Every dictation, searchable, with the audio you can replay."),
                ("text.badge.plus", "Snippets", "Save blocks (signature, address, links) and insert them by intent — just ask."),
                ("character.book.closed", "Dictionary", "Teach Verba names and jargon so they're always spelled right."),
            ])
        }
    }

    // 6 — Referral
    private var referral: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Give a month, get a month", "Share Verba — it pays you back.")
            VStack(alignment: .leading, spacing: 10) {
                Text("Your referral link").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button(copied ? "Copied ✓" : "Copy") {
                        let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string)
                        copied = true
                    }.glassButton()
                }
                .padding(12).glass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            grid([
                ("gift.fill", "1 free month per friend", "Every person who subscribes through your link earns you a free month — unlimited, no cap."),
                ("checkmark.seal", "How it validates", "They count once they're a paying subscriber and have dictated at least 15,000 words."),
            ])
        }
    }

    // 7 — Permissions + finish
    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Two quick permissions", "So Verba can hear you and paste for you.")
            VStack(alignment: .leading, spacing: 12) {
                permRow("mic.fill", "Microphone", "To record what you say.", granted: false) { /* prompted on first record */ }
                permRow("hand.point.up.left.fill", "Accessibility", "To paste straight into the active field.", granted: Output.accessibilityTrusted) { Output.promptAccessibility() }
            }
            .padding(16).glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Optional — bring your own Claude key").font(.callout.weight(.medium))
                SecureField("sk-ant-… (skip if you use Claude Code or OpenRouter)", text: $anthropicKey).textFieldStyle(.roundedBorder)
                Text("Verba detects Claude Code automatically and uses your plan. Otherwise add a key here or in Settings.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers
    private func finish() {
        settings.proEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.onboarded = true
        if !settings.proEmail.isEmpty { Task { _ = await settings.verifyPro() } }
        onDone()
    }

    private func title(_ t: String, _ s: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(t).font(.title2.bold())
            if !s.isEmpty { Text(s).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }

    private func grid(_ items: [(String, String, String)]) -> some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.1) { icon, t, d in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon).font(.system(size: 17)).frame(width: 26).foregroundStyle(.primary)
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
                Text(model).font(.caption2).padding(.horizontal, 7).padding(.vertical, 2)
                    .background(.softFill, in: Capsule())
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
            Image(systemName: icon).frame(width: 24).foregroundStyle(.primary)
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
