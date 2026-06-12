import SwiftUI

/// Reusable "Adapt" panel: re-process an existing piece of text through any reprompting mode
/// in one click, or with a custom typed instruction, and show/copy the adapted result.
/// Shared by the History detail pane and the Home "Recent" cards so the logic lives in one place.
struct AdaptPanel: View {
    /// The text to adapt (e.g. the reprompted output, falling back to the raw transcript).
    let source: String

    @State private var adapting = false
    @State private var adaptResult = ""
    @State private var adaptError: String?
    @State private var adaptLabel = ""        // which mode/intent produced the result
    @State private var customIntent = ""
    @State private var saved = false          // the adapted result was saved into History

    // Voice intent: a dedicated recorder so we never touch the global dictation recorder.
    @State private var recorder = AudioRecorder()
    @State private var recording = false      // mic is capturing
    @State private var transcribing = false   // captured audio is being transcribed

    /// Modes offered for one-click re-adaptation: every reprompting mode except raw flow
    /// and the screen-capture Context mode (which needs a screenshot it can't get here).
    private var adaptModes: [Profile] {
        Settings.shared.profiles.filter { !$0.raw && !$0.vision }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Text(L("Adapt this dictation")).font(.headline)
                }
                // Make clear Adapt is a throwaway variation, in contrast to Re-run which overwrites
                // the saved entry, so the two reprocessing paths aren't confused.
                Text(L("Try a variation, this doesn't change the saved entry. Use Save to keep one."))
                    .font(.caption).foregroundStyle(.secondary)
            }

            // One-click mode buttons.
            AdaptModeChips(modes: adaptModes) { mode in adapt(mode: mode) }
                .disabled(adapting)

            // Custom "Intent" adapt: type how you want it transformed, or speak it.
            // One soft-fill field with the mic + Adapt actions embedded (alias-field idiom).
            HStack(spacing: 8) {
                TextField(L("Describe how to adapt it (e.g. make it a bug report)"), text: $customIntent)
                    .textFieldStyle(.plain)
                    .onSubmit { adaptCustom() }
                    .disabled(recording || transcribing)
                Divider().frame(height: 12)
                Button { toggleVoiceIntent() } label: {
                    if recording {
                        Label(L("Listening…"), systemImage: "stop.circle.fill")
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(.red)
                    } else if transcribing {
                        Label(L("Transcribing…"), systemImage: "waveform")
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.borderless)
                .disabled(adapting || transcribing)
                .help(L("Speak how to adapt the text"))
                Divider().frame(height: 12)
                Button { adaptCustom() } label: {
                    Label(L("Adapt"), systemImage: "wand.and.stars")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .disabled(adapting || recording || transcribing
                          || customIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            // Result / progress / error.
            if adapting {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("\(L("Adapting"))\(adaptLabel.isEmpty ? "" : " · \(adaptLabel)")…")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if let err = adaptError {
                Text(err).font(.caption).foregroundStyle(.red)
            } else if !adaptResult.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Text(adaptLabel.isEmpty ? L("Result") : "\(L("Result")) · \(adaptLabel)")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        // The adapted output is no longer a dead-end: paste it where you were typing,
                        // or keep it as a new dictation in History, alongside Copy.
                        Button { _ = Output.paste(adaptResult) } label: {
                            Label(L("Paste"), systemImage: "arrow.down.doc")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .help(L("Paste the adapted text into the app you were last using"))
                        Button { saveToHistory() } label: {
                            Label(saved ? L("Saved") : L("Save"), systemImage: saved ? "checkmark" : "tray.and.arrow.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .disabled(saved)
                        .help(L("Keep this adapted result as a new dictation in your History"))
                        CopyButton(text: adaptResult)
                    }
                    Text(adaptResult)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        // Clean teardown if the panel goes away mid-recording (switched entry / closed card).
        .onDisappear {
            if recording { _ = recorder.stop(); recorder.releaseArmed(); recording = false }
        }
    }

    /// Re-process the source through a built-in mode and surface the result (does not overwrite history).
    private func adapt(mode: Profile) {
        guard !adapting else { return }
        runAdapt(label: mode.name, systemPrompt: mode.effectiveSystemPrompt,
                 model: mode.model ?? Settings.shared.claudeModel, transcript: source)
    }

    /// Re-process the source with the user's typed instruction.
    private func adaptCustom() {
        let intent = customIntent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !adapting, !intent.isEmpty else { return }
        // Build a faithful single-language prompt around the user's instruction.
        let sys = """
        You adapt an existing piece of text according to the user's instruction below. \
        Apply it faithfully and output ONLY the adapted text, with no preamble, notes, or quotes.

        INSTRUCTION: \(intent)

        Do not add facts that are not in the text. Keep every detail the instruction does not \
        ask you to drop. ALWAYS write the output in the SAME language as the input text, unless \
        the instruction explicitly asks for another language. This is mandatory.
        NEVER use an em dash, an en dash, or a spaced hyphen; use commas, periods, parentheses, \
        or colons instead.
        """
        runAdapt(label: "Intent", systemPrompt: sys,
                 model: Settings.shared.claudeModel, transcript: source)
    }

    // MARK: voice intent

    /// Tap once to start capturing the spoken instruction, tap again to stop, transcribe, and adapt.
    private func toggleVoiceIntent() {
        if recording { stopVoiceIntent() } else { startVoiceIntent() }
    }

    private func startVoiceIntent() {
        guard !adapting, !transcribing, !recording else { return }
        adaptError = nil
        recorder.requestPermission { ok in
            guard ok else {
                adaptError = L("Microphone access denied. Allow Verba under System Settings ▸ Privacy & Security ▸ Microphone.")
                return
            }
            if recorder.start() {
                recording = true
            } else {
                // Single deferred retry: the mic may take a beat to free if just released.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if recorder.start() { recording = true }
                    else { adaptError = L("Couldn't start recording. The microphone may be in use — wait a moment, then try again.") }
                }
            }
        }
    }

    private func stopVoiceIntent() {
        guard recording else { return }
        recording = false
        let url = recorder.stop()
        recorder.releaseArmed()   // free the mic; symmetric to NotesView / AppDelegate
        guard let url else {
            adaptError = L("Couldn't capture audio — try again.")
            return
        }
        transcribeVoiceIntent(url)
    }

    private func transcribeVoiceIntent(_ url: URL) {
        transcribing = true; adaptError = nil
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
                let intent = text.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    transcribing = false
                    guard !intent.isEmpty else {
                        adaptError = L("Didn't catch anything — try again.")
                        return
                    }
                    customIntent = intent
                    adaptCustom()
                }
            } catch {
                await MainActor.run { transcribing = false; adaptError = error.localizedDescription }
            }
        }
    }

    /// Persist the adapted result as a new dictation in History so it isn't a throwaway.
    /// Stored with the original (pre-adapt) source as the raw transcript and the adapted text
    /// as the reprompted output, tagged with the mode/intent that produced it.
    private func saveToHistory() {
        guard !adaptResult.isEmpty, !saved else { return }
        guard Settings.shared.saveHistory else {
            // History is off (S14) — History.add() would silently early-return, so don't
            // claim a save that never reached disk. Surface why instead.
            adaptError = L("History saving is off — enable it in Settings to keep this.")
            return
        }
        History.shared.add(original: source, reprompted: adaptResult,
                           profileName: adaptLabel.isEmpty ? "Adapt" : adaptLabel,
                           engine: "adapt", audioURL: nil)
        withAnimation(.easeOut(duration: 0.2)) { saved = true }
    }

    private func runAdapt(label: String, systemPrompt: String, model: String, transcript: String) {
        Gamification.shared.flag(.reworkedHistory)
        adapting = true; adaptError = nil; adaptResult = ""; adaptLabel = label; saved = false
        Task {
            do {
                let out = try await Reprompter(model: model).reprompt(transcript: transcript, systemPrompt: systemPrompt)
                await MainActor.run { adaptResult = out; adapting = false }
            } catch {
                await MainActor.run { adaptError = error.localizedDescription; adapting = false }
            }
        }
    }
}

/// Wrapping row of small mode chips used by the "Adapt" panel. Reuses the shared
/// FlowLayout from ModesView so chips wrap as the container resizes.
struct AdaptModeChips: View {
    let modes: [Profile]
    let action: (Profile) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(modes) { mode in
                Button { action(mode) } label: {
                    Text(mode.name)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .foregroundStyle(.primary.opacity(0.75))
                        .background(Capsule(style: .continuous).fill(Color.primary.opacity(VGlass.fillSecondary)))
                        .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
