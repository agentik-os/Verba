import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileTranscribeView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var state = "idle"   // idle / working / done / error
    @State private var result = ""
    @State private var error = ""
    @State private var fileName = ""
    @State private var dropTargeted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Transcribe file").font(.system(size: 28, weight: .bold))
                    Text("Drop in an audio or video file and Verba transcribes it with your current engine (\(settings.engine.label)).")
                        .font(.callout).foregroundStyle(.secondary)
                }

                HStack {
                    Button { pick() } label: { Label("Choose file…", systemImage: "folder") }
                        .disabled(state == "working")
                    if !fileName.isEmpty { Text(fileName).font(.callout).foregroundStyle(.secondary).lineLimit(1) }
                    Spacer()
                    if state == "working" { ProgressView().controlSize(.small) }
                }

                dropZone

                if state == "error" { Text(error).font(.callout).foregroundStyle(.red) }

                if result.isEmpty && state != "working" {
                    EmptyState(icon: "waveform.badge.plus", title: "No file transcribed yet",
                               message: "Pick an audio or video file with “Choose file…” and Verba transcribes it with your current engine. Perfect for meeting recordings, voice memos, podcasts, and interviews.")
                }

                if !result.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transcript").font(.subheadline.weight(.semibold))
                            Spacer()
                            CopyButton(text: result, title: "Copy")
                        }
                        Text(result).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14).background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(28).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(dropTargeted ? Color.accentColor : .secondary)
            Text(dropTargeted ? "Release to transcribe" : "Drag & drop an audio or video file here")
                .font(.callout)
                .foregroundStyle(dropTargeted ? Color.accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    dropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: dropTargeted ? 2 : 1, dash: [6, 4])
                )
        )
        .animation(.easeInOut(duration: 0.15), value: dropTargeted)
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            guard state != "working", let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    fileName = url.lastPathComponent
                    transcribe(url)
                }
            }
            return true
        }
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        var types: [UTType] = [.audio, .movie, .mpeg4Movie, .mp3, .wav, .mpeg4Audio]
        // WhatsApp voice notes (.opus) / Ogg often lack a registered UTType — add them explicitly.
        types += ["opus", "ogg", "oga"].compactMap { UTType(filenameExtension: $0) }
        panel.allowedContentTypes = types
        panel.message = "Choose an audio or video file to transcribe"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        fileName = url.lastPathComponent
        transcribe(url)
    }

    private func transcribe(_ url: URL) {
        state = "working"; error = ""; result = ""
        let lang = settings.language.isEmpty ? nil : settings.language
        let t: Transcriber
        switch settings.engine {
        case .openAI:   t = OpenAITranscriber()
        case .whisper:  t = LocalTranscriber.shared
        case .parakeet: t = ParakeetTranscriber.shared
        }
        Task {
            do {
                // WhatsApp .opus / .ogg and other AVFoundation-unreadable inputs are
                // transcoded to a 16 kHz mono WAV first; readable files pass through.
                let readable = try await AudioInput.readable(url)
                defer { AudioInput.cleanup(readable, original: url) }
                var text = try await t.transcribe(fileURL: readable, language: lang, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                await MainActor.run { result = Output.trimTrailingNewlines(text); state = "done" }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; state = "error" }
            }
        }
    }
}
