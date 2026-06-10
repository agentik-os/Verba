import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Soft capsule chip label for the footer actions (exemplar chip grammar);
/// dims itself when the wrapping Button is disabled.
private struct ActionChip: View {
    let title: String
    let icon: String
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(title).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6.5)
        .foregroundStyle(.primary.opacity(isEnabled ? 0.75 : 0.35))
        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
        .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
        .contentShape(Capsule())
    }
}

struct FeedbackView: View {
    @State private var draft = ""
    @State private var submitting = false
    @State private var sent = false
    @State private var error: String?

    // Drag & drop highlight + post-send toast.
    @State private var dropTargeted = false
    @State private var showToast = false

    // "Improve with AI" reformat state.
    @State private var improving = false

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
            && !submitting && !recording && !transcribing && !improving
    }

    private var canImprove: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !submitting && !recording && !transcribing && !improving
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Feedback").font(.system(size: 17, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)

            Text("Tell us what's working, what isn't, or anything on your mind. For specific feature ideas, use the Wishlist so others can upvote them.")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal, 28).padding(.bottom, 16)

            // Quiet confirmation row (the toast is the headline feedback): doesn't
            // push the editor around the way a full EmptyState block did.
            if sent {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle").foregroundStyle(.secondary)
                    Text("Thanks for the feedback — we read every message. Want to send another? Just start typing below.")
                        .font(.callout).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
                .padding(.horizontal, 28).padding(.bottom, 12)
            }

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(editorInset)
                        .frame(minHeight: 160)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                // VER-6: drag & drop an image file onto the editor to attach it as the screenshot.
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary, lineWidth: dropTargeted ? 2 : 0)
                )
                .onDrop(of: [.fileURL, .image], isTargeted: $dropTargeted) { providers in
                    handleDrop(providers)
                }

                // Screenshot + dictation affordances, then "Improve with AI".
                HStack(spacing: 10) {
                    // Dictate: a chip that mirrors the three voice states (idle / listening / transcribing).
                    // Lives in the action row — never floating over the editor's growing text.
                    Button { toggleVoice() } label: {
                        if recording {
                            ActionChip(title: "Listening…", icon: "stop.circle.fill")
                        } else if transcribing {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Transcribing…").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 4.5)
                        } else {
                            ActionChip(title: "Dictate", icon: "mic.fill")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(submitting || transcribing)
                    .help("Dictate your feedback")

                    if let thumb = screenshotThumb {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: thumb)
                                .resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.primary.opacity(0.1)))
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
                            ActionChip(title: "Attach screenshot", icon: "camera.viewfinder")
                        }
                        .buttonStyle(.plain)
                        .disabled(submitting)
                        .help("Capture the current screen, or drag an image onto the editor, to attach it")
                    }
                    Spacer()
                    // VER-8: reformat the current draft through the reprompt pipeline.
                    Button { improveWithAI() } label: {
                        if improving {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Improving…").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 4.5)
                        } else {
                            ActionChip(title: "Improve with AI", icon: "sparkles")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canImprove)
                    .help("Clean up and format your feedback with AI")
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
                    .dialogPrimary(tint: .primary)
                    .disabled(!canSubmit)
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // VER-7: graceful "sent" toast — appears, holds ~1s, fades out.
        .overlay(alignment: .top) {
            if showToast {
                Label("Feedback sent", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glass(in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1)))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // Clean teardown if the panel goes away mid-recording.
        .onDisappear {
            if recording { _ = recorder.stop(); recorder.releaseArmed(); recording = false }
        }
    }

    /// Flash the "Feedback sent" toast: animate in, hold ~1s, animate out gracefully.
    private func flashToast() {
        withAnimation(.easeOut(duration: 0.25)) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.45)) { showToast = false }
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
                flashToast()
            }
        }
    }

    // MARK: Improve with AI (VER-8)

    /// Send the current draft through the reprompt pipeline with a concise clean-up instruction
    /// and replace the draft with the improved version. Non-destructive on error.
    private func improveWithAI() {
        let original = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty, !improving else { return }
        improving = true
        error = nil
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let system = "You clean up and format user feedback. Rewrite the text so it reads clearly and is well structured, fixing grammar, punctuation and flow. Keep the original meaning, tone and all concrete details — do not add new ideas, do not answer or comment on the feedback. Return only the improved feedback text, with no preamble, quotes or labels."
        Task {
            do {
                let improved = try await Reprompter(model: model)
                    .reprompt(transcript: original, systemPrompt: system)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    improving = false
                    guard !improved.isEmpty else { return }
                    draft = improved
                }
            } catch {
                await MainActor.run {
                    improving = false
                    self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: drag & drop image attachment (VER-6)

    /// Accept a dropped image (file URL or in-memory image) and attach it as the screenshot.
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        // Prefer a file URL (gives us the on-disk image, incl. PNG/JPEG).
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, let img = NSImage(contentsOf: url) else {
                    DispatchQueue.main.async { self.error = "That file isn't a readable image. Drop a PNG or JPEG." }
                    return
                }
                self.attach(image: img)
            }
            return true
        }
        // Fall back to an in-memory image payload.
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: NSImage.self) }) {
            _ = provider.loadObject(ofClass: NSImage.self) { obj, _ in
                guard let img = obj as? NSImage else {
                    DispatchQueue.main.async { self.error = "Couldn't read the dropped image. Try a PNG or JPEG." }
                    return
                }
                self.attach(image: img)
            }
            return true
        }
        return false
    }

    /// Re-encode an NSImage to PNG and set it as the attached screenshot (with thumbnail).
    private func attach(image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]), !png.isEmpty else {
            DispatchQueue.main.async { self.error = "Couldn't process that image. Try a PNG or JPEG." }
            return
        }
        DispatchQueue.main.async {
            self.error = nil
            self.screenshot = png
            self.screenshotThumb = NSImage(data: png)
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
        Task { @MainActor in
            guard let png = await ScreenCapture.capturePNG(), !png.isEmpty else {
                error = "Couldn't capture the screen. If Screen Recording was just enabled, quit and reopen Verba, then try again."
                return
            }
            screenshot = png
            screenshotThumb = NSImage(data: png)
        }
    }
}
