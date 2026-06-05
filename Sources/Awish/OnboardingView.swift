import SwiftUI

/// First-run flow: explain the app, collect keys, and request permissions.
struct OnboardingView: View {
    @ObservedObject var settings = Settings.shared
    @State private var openAIKey = Keychain.openAIKey ?? ""
    @State private var anthropicKey = Keychain.anthropicKey ?? ""
    let onDone: () -> Void

    var body: some View {
        GlassContainer(spacing: 16) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Awish").font(.largeTitle.bold())
                    Text("Talk, and Claude turns your rambling into a clean prompt or message.")
                        .foregroundStyle(.secondary)
                }

                step("1", "Add your API keys", "Bring your own keys — they're stored in your macOS Keychain and never leave your Mac.") {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("OpenAI key (sk-…) — cloud transcription", text: $openAIKey)
                        SecureField("Anthropic key (sk-ant-…) — Claude reprompting", text: $anthropicKey)
                    }
                    .textFieldStyle(.roundedBorder)
                }

                step("2", "How to talk", "Press your shortcut (default ⌃⌥Space) or switch to the Fn key in Settings. Press to start, again to stop.") {
                    HStack { ShortcutRecorder(); Spacer() }
                }

                step("3", "Allow auto-paste", "Grant Accessibility so Awish can paste straight into the active field. You can skip and use the clipboard instead.") {
                    HStack {
                        Button("Open Accessibility…") { Output.promptAccessibility() }
                        if Output.accessibilityTrusted {
                            Label("Granted", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Start using Awish") {
                        Keychain.openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        Keychain.anthropicKey = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        settings.onboarded = true
                        onDone()
                    }
                    .glassProminentButton()
                    .controlSize(.large)
                }
            }
            .padding(28)
            .frame(width: 540)
        }
    }

    @ViewBuilder
    private func step<C: View>(_ n: String, _ title: String, _ subtitle: String, @ViewBuilder content: () -> C) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(n)
                .font(.headline)
                .frame(width: 30, height: 30)
                .glass(in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                content()
            }
        }
    }
}
