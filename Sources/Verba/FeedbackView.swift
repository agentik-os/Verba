import SwiftUI
import AppKit

struct FeedbackView: View {
    @State private var draft = ""
    @State private var submitting = false
    @State private var sent = false
    @State private var error: String?

    // Voice dictation: a dedicated recorder so we never touch the global dictation recorder.
    @State private var recorder = AudioRecorder()
    @State private var recording = false      // mic is capturing
    @State private var transcribing = false   // captured audio is being transcribed

    // Optional screenshot attachment (PNG bytes + a thumbnail for display).
    @State private var screenshot: Data?
    @State private var screenshotThumb: NSImage?

    /// Inset applied to the TextEditor. The placeholder is padded to the SAME origin the
    /// NSTextView actually starts typing at: +5pt horizontally for the text container's
    /// fixed lineFragmentPadding (which shifts text, not the placeholder), same vertically.
    private let editorInset: CGFloat = 10

    private var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !submitting && !recording && !transcribing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Feedback").font(.system(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)

            Text("Tell us what's working, what isn't, or anything on your mind. For specific feature ideas, use the Wishlist so others can upvote them.")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal, 28).padding(.bottom, 16)

            if sent {
                EmptyState(icon: "checkmark.circle",
                           title: "Thanks for the feedback",
                           message: "We read every message. Want to send another? Just start typing below.")
            }

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(editorInset)
                        .frame(minHeight: 160)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            // Mic button floats in the corner of the editor.
                            Button { toggleVoice() } label: {
                                if recording {
                                    Label("Listening…", systemImage: "stop.circle.fill").foregroundStyle(.red)
                                } else if transcribing {
                                    Label("Transcribing…", systemImage: "waveform")
                                } else {
                                    Image(systemName: "mic.fill")
                                }
                            }
                            .buttonStyle(.borderless)
                            .disabled(submitting || transcribing)
                            .help("Dictate your feedback")
                            .padding(10)
                        }
                        .onChange(of: draft) { _, _ in
                            if sent { sent = false }
                            if error != nil { error = nil }
                        }

                    if draft.isEmpty {
                        // Match the NSTextView's real text origin: +5pt horizontal for the
                        // text container's lineFragmentPadding (shifts text only, not this
                        // overlay), same vertical inset as the editor.
                        Text("Write your feedback…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, editorInset + 5).padding(.vertical, editorInset)
                            .allowsHitTesting(false)
                    }
                }

                // Screenshot: either an "Attach screenshot" affordance or a thumbnail with a remove (×).
                HStack(spacing: 10) {
                    if let thumb = screenshotThumb {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: thumb)
                                .resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.white.opacity(0.12)))
                            Button {
                                screenshot = nil; screenshotThumb = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white, .black.opacity(0.55))
                            }
                            .buttonStyle(.borderless)
                            .help("Remove screenshot")
                            .padding(4)
                        }
                        Text("Screenshot attached").font(.callout).foregroundStyle(.secondary)
                    } else {
                        Button { attachScreenshot() } label: {
                            Label("Attach screenshot", systemImage: "camera.viewfinder")
                        }
                        .buttonStyle(.borderless)
                        .disabled(submitting)
                        .help("Capture the current screen and attach it")
                    }
                    Spacer()
                }

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    if recording {
                        Label("Listening…", systemImage: "waveform")
                            .font(.callout).foregroundStyle(.red)
                    } else if transcribing {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Transcribing…").font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(action: submit) {
                        if submitting {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Send feedback")
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(.primary)
                    .disabled(!canSubmit)
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Clean teardown if the panel goes away mid-recording.
        .onDisappear {
            if recording { _ = recorder.stop(); recorder.releaseArmed(); recording = false }
        }
    }

    // MARK: voice dictation

    /// Tap once to start capturing, tap again to stop, transcribe, and append into the draft.
    private func toggleVoice() {
        if recording { stopVoice() } else { startVoice() }
    }

    private func startVoice() {
        guard !submitting, !transcribing, !recording else { return }
        error = nil
        recorder.requestPermission { ok in
            guard ok else {
                error = "Microphone access denied. Allow Verba under System Settings ▸ Privacy & Security ▸ Microphone."
                return
            }
            if recorder.start() {
                recording = true
            } else {
                // Single deferred retry: the mic may take a beat to free if just released.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if recorder.start() { recording = true }
                    else { error = "Couldn't start recording. The microphone may be in use — wait a moment, then try again." }
                }
            }
        }
    }

    private func stopVoice() {
        guard recording else { return }
        recording = false
        let url = recorder.stop()
        recorder.releaseArmed()   // free the mic; symmetric to AdaptPanel
        guard let url else {
            error = "Couldn't capture audio — try again."
            return
        }
        transcribeVoice(url)
    }

    private func transcribeVoice(_ url: URL) {
        transcribing = true; error = nil
        Task {
            do {
                let s = Settings.shared
                let transcriber: Transcriber
                switch s.engine {
                case .openAI:   transcriber = OpenAITranscriber()
                case .whisper:  transcriber = LocalTranscriber.shared
                case .parakeet: transcriber = ParakeetTranscriber.shared
                }
                let text = try await transcriber.transcribe(fileURL: url, language: nil,
                                                             hint: DictionaryStore.shared.hint())
                let captured = text.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    transcribing = false
                    guard !captured.isEmpty else {
                        error = "Didn't catch anything — try again."
                        return
                    }
                    if draft.isEmpty {
                        draft = captured
                    } else {
                        let sep = draft.hasSuffix(" ") || draft.hasSuffix("\n") ? "" : " "
                        draft += sep + captured
                    }
                }
            } catch {
                await MainActor.run { transcribing = false; self.error = error.localizedDescription }
            }
        }
    }

    private func submit() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        submitting = true
        error = nil
        sent = false
        Feedback.submit(t, screenshot: screenshot) { err in
            submitting = false
            if let err {
                error = err
            } else {
                sent = true
                draft = ""
                screenshot = nil
                screenshotThumb = nil
            }
        }
    }

    // MARK: screenshot attachment

    /// Capture the current screen as PNG and attach it (with a thumbnail). Prompts for
    /// Screen Recording permission the same way Context mode does if it's missing.
    private func attachScreenshot() {
        error = nil
        guard ScreenCapture.hasPermission() else {
            ScreenCapture.requestPermission()
            ScreenCapture.openPrivacySettings()
            error = "Attaching a screenshot needs Screen Recording. Enable Verba in System Settings ▸ Privacy & Security ▸ Screen Recording, then try again."
            return
        }
        guard let png = ScreenCapture.capturePNG(), !png.isEmpty else {
            error = "Couldn't capture the screen. If Screen Recording was just enabled, quit and reopen Verba, then try again."
            return
        }
        screenshot = png
        screenshotThumb = NSImage(data: png)
    }
}
