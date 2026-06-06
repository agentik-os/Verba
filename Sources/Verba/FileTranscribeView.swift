import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileTranscribeView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var state = "idle"   // idle / working / done / error
    @State private var result = ""
    @State private var error = ""
    @State private var fileName = ""

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

                if state == "error" { Text(error).font(.callout).foregroundStyle(.red) }

                if !result.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transcript").font(.subheadline.weight(.semibold))
                            Spacer()
                            Button { Output.copyToClipboard(result) } label: { Label("Copy", systemImage: "doc.on.doc") }
                                .buttonStyle(.borderless)
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

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio, .movie, .mpeg4Movie, .mp3, .wav, .mpeg4Audio]
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
                var text = try await t.transcribe(fileURL: url, language: lang, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                await MainActor.run { result = Output.trimTrailingNewlines(text); state = "done" }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; state = "error" }
            }
        }
    }
}
