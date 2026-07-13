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
        .background(Capsule(style: .continuous).fill(Color.softFill))
        .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
        .contentShape(Capsule())
    }
}

/// VER-16: compact, monochrome live mic meter for the feedback Dictate chip. Mirrors the floating
/// overlay's Waveform grammar (level + a self-advanced phase so motion never stalls while another
/// app owns the run loop), sized to sit inline beside "Listening…".
private struct FeedbackWaveform: View {
    let level: Float
    let phase: Double
    private let bars = 7
    private let maxH: CGFloat = 13

    var body: some View {
        let lvl = CGFloat(max(0.05, min(1, level)))
        HStack(spacing: 2) {
            ForEach(0..<bars, id: \.self) { i in
                // two detuned sines per bar → organic motion; amplitude follows the live level
                let w = (sin(phase * 3.4 + Double(i) * 0.9) + sin(phase * 5.1 + Double(i) * 1.7)) / 2.0
                let wobble = CGFloat((w + 1) / 2)                  // 0…1
                let center = 1 - abs(CGFloat(i) - CGFloat(bars - 1) / 2) / CGFloat(bars)  // taller in middle
                let h = max(0.12, min(1, lvl * (0.35 + 0.95 * wobble) * (0.6 + 0.6 * center)))
                Capsule()
                    .fill(.primary.opacity(0.5 + 0.4 * Double(h)))
                    .frame(width: 2.5, height: h * maxH)
            }
        }
        .frame(height: maxH, alignment: .center)
        .animation(.linear(duration: 0.05), value: phase)
    }
}

struct FeedbackView: View {
    @State private var draft = ""
    @State private var submitting = false
    @State private var error: String?

    // Drag & drop highlight + post-send toast.
    @State private var dropTargeted = false
    @State private var showToast = false

    // "Improve with AI" reformat state.
    @State private var improving = false
    // VER-52: after Send auto-runs "Improve with AI", we hold here so the user can edit the
    // enhanced text and explicitly Confirm or Cancel before it's actually submitted.
    @State private var awaitingConfirm = false
    // VER-8: the pre-improve draft, kept so the rewrite is reversible. Non-nil only
    // while the current draft IS an AI rewrite the user hasn't edited or reverted yet.
    @State private var preImproveDraft: String?
    // The exact text "Improve with AI" produced; an edit away from it retires the revert chip.
    @State private var lastImproved: String?
    /// True when the current draft is still a pristine AI rewrite we can revert.
    private var canRevertImprove: Bool { preImproveDraft != nil && draft == lastImproved }

    // Voice dictation: a dedicated recorder so we never touch the global dictation recorder.
    @State private var recorder = AudioRecorder()
    @State private var recording = false      // mic is capturing
    @State private var transcribing = false   // captured audio is being transcribed

    // VER-16: live mic-level animation for the Dictate chip while listening. `level` is the
    // metered mic input (0…1); `phase` is advanced by our own timer so the waveform keeps
    // moving even when the focused app owns the run loop — same idiom as the floating overlay.
    @State private var level: Float = 0
    @State private var phase: Double = 0
    @State private var levelTimer: Timer?

    // Optional screenshot attachment (PNG bytes + a thumbnail for display).
    @ObservedObject private var feedbackInbox = FeedbackInbox.shared
    @State private var screenshot: Data?
    @State private var screenshotThumb: NSImage?

    /// Inset applied to the TextEditor. The placeholder is padded to the SAME origin the
    /// NSTextView actually starts typing at: +5pt horizontally for the text container's
    /// fixed lineFragmentPadding (which shifts text, not the placeholder), same vertically.
    private let editorInset: CGFloat = 10

    private var canSubmit: Bool {
        // VER-13: a screenshot alone is enough — the AI reads it to build the feedback.
        (!draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || screenshot != nil)
            && !submitting && !recording && !transcribing && !improving
    }

    private var canImprove: Bool {
        (!draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || screenshot != nil)
            && !submitting && !recording && !transcribing && !improving
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("Feedback")).font(.system(size: 17, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)

            Text(L("Tell us what's working, what isn't, or anything on your mind. For specific feature ideas, use the Wishlist so others can upvote them."))
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal, 28).padding(.bottom, 16)

            // Send confirmation is the transient "Feedback sent" toast (flashToast) alone —
            // a single, non-redundant acknowledgement. The earlier persistent "thanks" row was
            // dropped so we don't confirm the same send twice.
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(editorInset)
                        .frame(minHeight: 160)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: draft) { _, newValue in
                            if error != nil { error = nil }
                            // Any manual edit that diverges from the AI rewrite retires the "revert"
                            // affordance — EXCEPT while awaiting Confirm (VER-52), where the user is
                            // meant to edit the AI text and Cancel must still restore the original.
                            if preImproveDraft != nil, !improving, !awaitingConfirm, newValue != lastImproved {
                                preImproveDraft = nil
                                lastImproved = nil
                            }
                        }

                    if draft.isEmpty {
                        // Match the NSTextView's real text origin: +5pt horizontal for the
                        // text container's lineFragmentPadding (shifts text only, not this
                        // overlay), same vertical inset as the editor.
                        Text(L("Write your feedback…"))
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, editorInset + 5).padding(.vertical, editorInset)
                            .allowsHitTesting(false)
                    }
                }

                // VER-12: the screenshot preview sits above the unified action bar (below) so the
                // bar height stays stable. The Dictate / Attach buttons now live in that one bar
                // alongside Cancel / Give feedback, instead of floating as a disconnected group.
                if let thumb = screenshotThumb {
                    HStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: thumb)
                                .resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.hairlineTint))
                            Button {
                                screenshot = nil; screenshotThumb = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white, .black.opacity(0.55))
                            }
                            .buttonStyle(.borderless)
                            .help(L("Remove screenshot"))
                            .padding(4)
                        }
                        Text(L("Screenshot attached")).font(.callout).foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // VER-16: a stable bottom bar — the status sits left, the primary action keeps a
                // fixed footprint (so it never jumps between "Give feedback" / "Improving…" /
                // "Confirm feedback"), and Cancel sits to its left only while confirming.
                HStack(spacing: 10) {
                    // Dictate chip (mirrors idle / listening / transcribing) + Attach screenshot,
                    // now grouped in the SAME bar as the primary actions (VER-12).
                    Button { toggleVoice() } label: {
                        if recording {
                            HStack(spacing: 7) {
                                Image(systemName: "stop.circle.fill").font(.system(size: 10, weight: .semibold))
                                Text(L("Listening…")).font(.system(size: 12, weight: .medium))
                                FeedbackWaveform(level: level, phase: phase)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .foregroundStyle(.primary.opacity(0.75))
                            .background(Capsule(style: .continuous).fill(Color.softFill))
                            .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                            .contentShape(Capsule())
                        } else if transcribing {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text(L("Transcribing…")).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 4.5)
                        } else {
                            ActionChip(title: L("Dictate"), icon: "mic.fill")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(submitting || transcribing || improving)
                    .help(L("Dictate your feedback"))
                    if screenshotThumb == nil {
                        // VER-39: two explicit choices — capture the screen now, or pick an existing
                        // file — so the button no longer surprises the user by auto-capturing. Drag &
                        // drop (below, on the whole panel) still works as a third way to attach.
                        Button { attachScreenshot() } label: {
                            ActionChip(title: L("Take screenshot"), icon: "camera.viewfinder")
                        }
                        .buttonStyle(.plain)
                        .disabled(submitting || improving)
                        .help(L("Capture the current screen now and attach it"))
                        Button { attachFile() } label: {
                            ActionChip(title: L("Add file"), icon: "paperclip")
                        }
                        .buttonStyle(.plain)
                        .disabled(submitting || improving)
                        .help(L("Choose an image from your Mac, or drag one onto this panel, to attach it"))
                    }
                    Spacer(minLength: 12)
                    if awaitingConfirm {
                        // VER-52: the AI-enhanced feedback is shown above (editable) — confirm to send it,
                        // or cancel back to your original text.
                        Button(L("Cancel")) {
                            revertImprove()
                            awaitingConfirm = false
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary).disabled(submitting)
                        Button(action: submit) {
                            Group {
                                if submitting { ProgressView().controlSize(.small) } else { Text(L("Confirm feedback")) }
                            }.frame(minWidth: 124)
                        }
                        .dialogPrimary(tint: .primary).disabled(!canSubmit)
                    } else {
                        // Optional AI polish — never gates the send. Shown only when there's something
                        // to improve, disabled while busy. On failure the draft is untouched.
                        if canSubmit {
                            Button(action: improveTapped) {
                                Group {
                                    if improving {
                                        HStack(spacing: 6) { ProgressView().controlSize(.small); Text(L("Improving…")).font(.callout) }
                                    } else {
                                        Label(L("Improve with AI"), systemImage: "sparkles").font(.callout)
                                    }
                                }
                            }
                            .buttonStyle(.plain).foregroundStyle(.secondary)
                            .disabled(submitting || improving)
                            if preImproveDraft != nil {
                                Button(L("Undo")) { revertImprove() }
                                    .buttonStyle(.plain).foregroundStyle(.secondary).disabled(submitting || improving)
                            }
                        }
                        Button(action: sendTapped) {
                            Group {
                                if submitting {
                                    HStack(spacing: 7) { ProgressView().controlSize(.small); Text(L("Sending…")).font(.callout) }
                                } else {
                                    Text(L("Give feedback"))
                                }
                            }.frame(minWidth: 124)
                        }
                        .dialogPrimary(tint: .primary)
                        .disabled(!canSubmit || improving || submitting)
                    }
                }
                .frame(minHeight: 30)
            }
            .padding(.horizontal, 28).padding(.bottom, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Drag & drop an image ANYWHERE in the Feedback view to attach it as the screenshot —
        // not just over the editor. contentShape makes the whole (incl. empty) area a drop target.
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL, .image], isTargeted: $dropTargeted) { providers in
            handleDrop(providers)
        }
        // A gentle full-panel accent ring + wash while a drag hovers, so it's obvious the whole
        // Feedback view accepts the drop.
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(VerbaAppearance.shared.accentColor.opacity(0.35), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(VerbaAppearance.shared.accentColor.opacity(0.05)))
                    .padding(8)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: dropTargeted)
        // VER-7: graceful "sent" toast — appears, holds ~1s, fades out.
        .overlay(alignment: .top) {
            if showToast {
                Label(L("Feedback sent"), systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glass(in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.hairlineTint))
                    .shadow(color: VGlass.shadowColor, radius: VGlass.shadowRadius, y: VGlass.shadowY)
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // A screenshot dropped on the sidebar Feedback row lands here: attach it on appear (and if
        // another lands while Feedback is already open, the openSignal change re-consumes it).
        .onAppear { consumeInbox() }
        .onChange(of: feedbackInbox.openSignal) { _, _ in consumeInbox() }
        // Clean teardown if the panel goes away mid-recording.
        .onDisappear {
            if recording { _ = recorder.stop(); recorder.releaseArmed(); recording = false }
            stopLevelMeter()
        }
    }

    /// Attach a screenshot that was dropped onto the sidebar Feedback row.
    private func consumeInbox() {
        guard let png = feedbackInbox.take() else { return }
        error = nil
        screenshot = png
        screenshotThumb = NSImage(data: png)
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
                error = L("Microphone access denied. Allow Verba under System Settings ▸ Privacy & Security ▸ Microphone.")
                return
            }
            if recorder.start() {
                recording = true
                startLevelMeter()
            } else {
                // Single deferred retry: the mic may take a beat to free if just released.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if recorder.start() { recording = true; startLevelMeter() }
                    else { error = L("Couldn't start recording. The microphone may be in use — wait a moment, then try again.") }
                }
            }
        }
    }

    /// Drive the Dictate chip's waveform from live mic metering. We advance `phase` ourselves
    /// (rather than rely on TimelineView) so the animation never stalls while another app owns
    /// the run loop — the same approach the floating recording overlay uses.
    private func startLevelMeter() {
        levelTimer?.invalidate()
        let t = Timer(timeInterval: 0.04, repeats: true) { _ in
            guard recording else { return }
            let lvl = recorder.level()
            level = lvl
            phase += 0.025 + 0.18 * Double(lvl)
        }
        RunLoop.main.add(t, forMode: .common)
        levelTimer = t
    }

    private func stopLevelMeter() {
        levelTimer?.invalidate(); levelTimer = nil
        level = 0
    }

    private func stopVoice() {
        guard recording else { return }
        recording = false
        stopLevelMeter()
        let url = recorder.stop()
        recorder.releaseArmed()   // free the mic; symmetric to AdaptPanel
        guard let url else {
            error = L("Couldn't capture audio — try again.")
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
                        error = L("Didn't catch anything — try again.")
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
        Feedback.submit(t, screenshot: screenshot) { err in
            submitting = false
            if let err {
                error = err
            } else {
                draft = ""
                screenshot = nil
                screenshotThumb = nil
                awaitingConfirm = false
                preImproveDraft = nil
                lastImproved = nil
                flashToast()
            }
        }
    }

    // MARK: Improve with AI (VER-8)

    /// Restore the pre-improve draft (undo the AI rewrite). Clears the revert state.
    private func revertImprove() {
        guard let original = preImproveDraft else { return }
        preImproveDraft = nil
        lastImproved = nil
        draft = original
    }

    /// "Give feedback" submits the draft DIRECTLY — it must NEVER depend on an AI model. The
    /// server accepts a raw text POST (no auth, no AI); coupling submit to the "Improve" call is
    /// exactly what made feedback silently fail for users whose local model was still downloading
    /// or whose backend hiccuped (the improve error blocked the send). "Improve with AI" is now a
    /// separate, optional enhancement (improveTapped) that rewrites the draft in place but never
    /// gates submission.
    private func sendTapped() {
        submit()
    }

    /// Optional: rewrite the draft with AI before sending. Best-effort — on any failure the draft
    /// is untouched and the user can still Give feedback. Never blocks submission.
    private func improveTapped() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!t.isEmpty || screenshot != nil), !submitting, !improving else { return }
        improveWithAI(thenConfirm: false)
    }

    /// Send the current draft through the reprompt pipeline with a concise clean-up instruction
    /// and replace the draft with the improved version. Non-destructive on error. When
    /// `thenConfirm` is true (the Send flow), surface the Confirm/Cancel step on success.
    private func improveWithAI(thenConfirm: Bool = false) {
        let original = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let shot = screenshot
        // VER-13: allow Improve even with no typed text as long as a screenshot is attached —
        // the model reads the image to infer the section and what's wrong.
        guard !(original.isEmpty && shot == nil), !improving else { return }
        improving = true
        error = nil
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let imageNote = shot != nil
            ? "\n\nA screenshot of the app is attached. Read it to identify the exact screen/feature for Section and to flesh out Issue/Expected — infer these from the image, never output \"—\" for Section when a screenshot is provided."
            : ""
        let system = """
        You structure user feedback so the team instantly understands what part of the app it concerns, what is wrong, and what the user wants. Rewrite the feedback into exactly these three labelled lines, fixing grammar, punctuation and flow:

        Section: <which screen, feature or area of the app the feedback targets>
        Issue: <what is currently wrong, confusing or missing>
        Expected: <the behaviour or outcome the user wants instead>

        Rules: Keep every concrete detail, the original meaning and the user's tone. Be concise — one short line per field. Do not add new ideas, do not answer or comment on the feedback. If a field is genuinely not stated and cannot be reasonably inferred from the text, write "—" for that field rather than inventing content. Return only the three labelled lines, with no preamble, quotes or extra commentary.\(imageNote)
        """
        // Screenshot-free system prompt for the text-only path: without it, a text model is told to
        // "read the attached screenshot" it never receives and is pressured to invent a Section.
        let systemTextOnly = system.replacingOccurrences(of: imageNote, with: "")
        Task {
            do {
                let improved = try await {
                    // Only send the screenshot to a backend that can actually see it (not a local model,
                    // not an unsigned/keyless backend). Otherwise degrade to a text-only reprompt on the
                    // SAME selected model, so Improve works on every engine instead of erroring on local.
                    if let shot, Reprompter.backendSupportsVision {
                        return try await Reprompter(model: model)
                            .repromptVision(transcript: original, systemPrompt: system, imagePNG: shot)
                    }
                    // No usable vision: if there's typed text, clean it up text-only; a screenshot-only
                    // feedback on a vision-incapable backend has nothing to improve, so keep the draft.
                    guard !original.isEmpty else { return original }
                    do {
                        return try await Reprompter(model: model)
                            .reprompt(transcript: original, systemPrompt: systemTextOnly)
                    } catch {
                        // BULLETPROOF: Improve must work with ANY engine. If the chosen backend fails for
                        // ANY reason (CLI hiccup, rate limit, timeout), fall back to the fully-local model
                        // (self-installs on demand) rather than showing an error — feedback cleanup is
                        // low-stakes text. Only surface an error if local ALSO fails.
                        return try await LocalLLM.chat(system: systemTextOnly, user: original, model: Settings.shared.localLLMModel)
                    }
                }().trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    improving = false
                    guard !improved.isEmpty else {
                        // The backend returned nothing usable. Don't dead-end silently (button just
                        // reverts, nothing happens): if the user was sending, submit their ORIGINAL
                        // draft so the click still does something; otherwise surface a retry hint.
                        if thenConfirm, !original.isEmpty {
                            draft = original
                            submit()
                        } else {
                            error = L("Couldn’t improve that — try again, or send it as-is.")
                        }
                        return
                    }
                    // Stash the original BEFORE swapping in the rewrite so the user can
                    // revert. Set the trackers first so the draft-onChange (which fires
                    // on the next line) sees a matching `lastImproved` and keeps them.
                    preImproveDraft = original
                    lastImproved = improved
                    draft = improved
                    if thenConfirm { awaitingConfirm = true }   // VER-52: now show Confirm / Cancel
                }
            } catch {
                await MainActor.run {
                    improving = false
                    self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: drag & drop image attachment (VER-6 / VER-14)

    /// Accept a dropped image and attach it as the screenshot.
    ///
    /// VER-14: we must attach the actual image BYTES, never a file-path string. The hard case
    /// is a screenshot dragged from the macOS screenshot-UI thumbnail: that item is a short-lived
    /// security-scoped temp file (…/TemporaryItems/…/Screenshot.png) and/or a file promise, so
    /// resolving it to a URL and re-reading from disk races the OS deleting the temp file and can
    /// silently fail. So we ask the provider for the raw DATA of the image type directly —
    /// `loadDataRepresentation` materializes file promises and hands back bytes, no path involved.
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { isImageDrop($0) }) else { return false }

        // 1) Pull the real image bytes for the best matching image UTI (png/jpeg/tiff/heic/generic image).
        if let typeID = imageTypeIdentifier(for: provider) {
            _ = provider.loadDataRepresentation(forTypeIdentifier: typeID) { data, _ in
                if let data, let img = NSImage(data: data) {
                    self.attach(image: img)
                } else {
                    // 2) Bytes-by-type failed — fall back to the on-disk file URL (security-scoped read).
                    self.attachFromFileURL(provider)
                }
            }
            return true
        }

        // 3) No image-typed payload advertised — try the file URL, then an in-memory NSImage.
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            attachFromFileURL(provider)
            return true
        }
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { obj, _ in
                guard let img = obj as? NSImage else {
                    DispatchQueue.main.async { self.error = L("Couldn't read the dropped image. Try a PNG or JPEG.") }
                    return
                }
                self.attach(image: img)
            }
            return true
        }
        return false
    }

    /// True if the provider advertises any image payload (image UTI or an image file URL).
    private func isImageDrop(_ provider: NSItemProvider) -> Bool {
        imageTypeIdentifier(for: provider) != nil
            || provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
            || provider.canLoadObject(ofClass: NSImage.self)
    }

    /// The most specific image UTI the provider can vend as data, if any.
    private func imageTypeIdentifier(for provider: NSItemProvider) -> String? {
        let preferred: [UTType] = [.png, .jpeg, .tiff, .heic, .gif, .bmp, .image]
        for type in preferred where provider.hasItemConformingToTypeIdentifier(type.identifier) {
            return type.identifier
        }
        // Any registered type that conforms to public.image (covers exotic screenshot UTIs).
        return provider.registeredTypeIdentifiers.first {
            UTType($0)?.conforms(to: .image) == true
        }
    }

    /// Resolve the provider's file URL and read the image bytes off disk, honoring the
    /// security-scoped access the screenshot-UI temp file requires. Reads into Data immediately
    /// (synchronously inside the access scope) so we never depend on a path surviving.
    private func attachFromFileURL(_ provider: NSItemProvider) {
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else {
                DispatchQueue.main.async { self.error = L("That file isn't a readable image. Drop a PNG or JPEG.") }
                return
            }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url), let img = NSImage(data: data) else {
                DispatchQueue.main.async { self.error = L("That file isn't a readable image. Drop a PNG or JPEG.") }
                return
            }
            self.attach(image: img)
        }
    }

    /// Re-encode an NSImage to PNG and set it as the attached screenshot (with thumbnail).
    private func attach(image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]), !png.isEmpty else {
            DispatchQueue.main.async { self.error = L("Couldn't process that image. Try a PNG or JPEG.") }
            return
        }
        DispatchQueue.main.async {
            self.error = nil
            self.screenshot = png
            self.screenshotThumb = NSImage(data: png)
        }
    }

    // MARK: file attachment (VER-39)

    /// Pick an existing image from disk via an open panel and attach it. Reuses the same
    /// NSImage → PNG plumbing as drag-and-drop and screen capture, so it flows through the
    /// identical attachment pipeline (screenshot bytes + thumbnail).
    private func attachFile() {
        error = nil
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .gif, .bmp, .image]
        panel.prompt = L("Attach")
        panel.message = L("Choose an image to attach to your feedback.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let img = NSImage(contentsOf: url) else {
            error = L("That file isn't a readable image. Choose a PNG or JPEG.")
            return
        }
        attach(image: img)
    }

    // MARK: screenshot attachment

    /// Capture the current screen as PNG and attach it (with a thumbnail). Prompts for
    /// Screen Recording permission the same way Context mode does if it's missing.
    private func attachScreenshot() {
        error = nil
        guard ScreenCapture.hasPermission() else {
            ScreenCapture.requestPermission()
            ScreenCapture.openPrivacySettings()
            error = L("Attaching a screenshot needs Screen Recording. Enable Verba in System Settings ▸ Privacy & Security ▸ Screen Recording, then try again.")
            return
        }
        Task { @MainActor in
            guard let png = await ScreenCapture.capturePNG(), !png.isEmpty else {
                error = L("Couldn't capture the screen. If Screen Recording was just enabled, quit and reopen Verba, then try again.")
                return
            }
            screenshot = png
            screenshotThumb = NSImage(data: png)
        }
    }
}
