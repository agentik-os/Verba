import SwiftUI
import AVFoundation

@main
struct VerbaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Keyboard taps a mic → opens verba://record?mode=Polish
                .onOpenURL { url in
                    guard url.host == "record" else { return }
                    let mode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "mode" })?.value ?? "Polish"
                    Recorder.shared.start(mode: mode)
                }
        }
    }
}

struct ContentView: View {
    @ObservedObject var rec = Recorder.shared
    var body: some View {
        VStack(spacing: 20) {
            Text("Verba").font(.largeTitle.bold())
            Text(rec.status).foregroundStyle(.secondary)
            Button(rec.isRecording ? "Stop & send" : "Record") {
                rec.isRecording ? rec.stop() : rec.start(mode: "Polish")
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Text("Add the Verba keyboard in Settings ▸ General ▸ Keyboard, then tap the mic from any app.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding()
        }
        .padding()
    }
}

/// Records, transcribes, reprompts, writes the result to the App Group, returns to caller.
final class Recorder: NSObject, ObservableObject {
    static let shared = Recorder()
    @Published var isRecording = false
    @Published var status = "Ready"
    private var mode = "Polish"
    // TODO: wire AVAudioRecorder + OpenAI transcription + Anthropic reprompt (reuse the
    // macOS pipeline logic). On finish: Verba.setPendingResult(text) and return to the app
    // the user came from. This is the scaffold's main remaining implementation.
    func start(mode: String) { self.mode = mode; isRecording = true; status = "Listening (\(mode))…" }
    func stop() { isRecording = false; status = "Transcribing…" /* → set pending result */ }
}
