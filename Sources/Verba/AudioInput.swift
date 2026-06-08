import Foundation
import AVFoundation

/// Normalizes a dropped/picked audio file into something the local engines
/// (WhisperKit / FluidAudio) and AVFoundation can actually read.
///
/// WhatsApp voice notes ship as raw Opus in an `.opus`/`.ogg` container that
/// AVFoundation refuses to open ("Failed while reading audio … error 0"). When we
/// detect such a file — or any file AVFoundation can't decode — we transcode it to
/// a plain 16 kHz mono PCM WAV in the temp directory and hand that to the engine.
enum AudioInput {
    /// Containers AVFoundation can't reliably decode and that we always transcode.
    private static let unreadableExtensions: Set<String> = ["opus", "ogg", "oga", "spx", "amr", "weba"]

    struct ConversionError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Returns a URL that downstream transcribers can read.
    ///
    /// - If the input is already AVFoundation-readable, the original URL is returned
    ///   unchanged (caller cleans up nothing).
    /// - Otherwise a freshly converted temp `.wav` URL is returned; the caller is
    ///   responsible for deleting it via `cleanup(_:original:)` when done.
    static func readable(_ url: URL) async throws -> URL {
        let ext = url.pathExtension.lowercased()
        let forceConvert = unreadableExtensions.contains(ext)

        if !forceConvert, await isReadable(url) { return url }

        // Try ffmpeg first (handles Opus/Ogg cleanly), then fall back to AVFoundation.
        if let ff = ffmpegPath() {
            if let out = try? convertWithFFmpeg(url, ffmpeg: ff) { return out }
        }
        if let out = try? await convertWithAVFoundation(url) { return out }

        throw ConversionError(message: clearError(for: url))
    }

    /// Delete a converted temp file (no-op if `converted == original`).
    static func cleanup(_ converted: URL, original: URL) {
        guard converted != original else { return }
        try? FileManager.default.removeItem(at: converted)
    }

    // MARK: - Readability probe

    private static func isReadable(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        do {
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            guard let track = tracks.first else { return false }
            // Probe that we can actually start a read — opening the file is what fails for Opus.
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            guard reader.canAdd(output) else { return false }
            reader.add(output)
            let ok = reader.startReading()
            reader.cancelReading()
            return ok
        } catch {
            return false
        }
    }

    // MARK: - ffmpeg

    private static func ffmpegPath() -> String? {
        let candidates = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        // Fall back to PATH lookup.
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        which.arguments = ["which", "ffmpeg"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        try? which.run()
        which.waitUntilExit()
        guard which.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return path.isEmpty ? nil : path
    }

    private static func convertWithFFmpeg(_ url: URL, ffmpeg: String) throws -> URL {
        let out = tempWAVURL()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: ffmpeg)
        // Decode anything → 16 kHz mono signed-16 PCM WAV (what the local engines want).
        proc.arguments = ["-y", "-i", url.path, "-ac", "1", "-ar", "16000",
                          "-acodec", "pcm_s16le", out.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0,
              FileManager.default.fileExists(atPath: out.path) else {
            try? FileManager.default.removeItem(at: out)
            throw ConversionError(message: "ffmpeg could not convert this file.")
        }
        return out
    }

    // MARK: - AVFoundation fallback

    private static func convertWithAVFoundation(_ url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ConversionError(message: "No audio track found.")
        }

        let reader = try AVAssetReader(asset: asset)
        let readSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: readSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw ConversionError(message: "Could not read this audio format.")
        }
        reader.add(output)

        let out = tempWAVURL()
        let writer = try AVAssetWriter(outputURL: out, fileType: .wav)
        let writeSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1
        ]
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: writeSettings)
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else {
            throw ConversionError(message: "Could not write converted audio.")
        }
        writer.add(input)

        guard reader.startReading(), writer.startWriting() else {
            try? FileManager.default.removeItem(at: out)
            throw ConversionError(message: "Could not start audio conversion.")
        }
        writer.startSession(atSourceTime: .zero)

        // The reader/output/input are only ever touched on the single serial `queue`
        // below, so boxing them as @unchecked Sendable to cross the closure is safe.
        let box = ConvertBox(reader: reader, output: output, input: input)
        let queue = DispatchQueue(label: "verba.audioinput.convert")
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            box.input.requestMediaDataWhenReady(on: queue) {
                while box.input.isReadyForMoreMediaData {
                    if let buffer = box.output.copyNextSampleBuffer() {
                        if !box.input.append(buffer) {
                            box.reader.cancelReading()
                            box.input.markAsFinished()
                            cont.resume(throwing: ConversionError(message: "Audio conversion failed midway."))
                            return
                        }
                    } else {
                        box.input.markAsFinished()
                        if box.reader.status == .failed {
                            cont.resume(throwing: ConversionError(message: "Could not read this audio format."))
                        } else {
                            cont.resume()
                        }
                        return
                    }
                }
            }
        }

        await writer.finishWriting()
        guard writer.status == .completed,
              FileManager.default.fileExists(atPath: out.path) else {
            try? FileManager.default.removeItem(at: out)
            throw ConversionError(message: "Could not finalize converted audio.")
        }
        return out
    }

    /// Carries the non-Sendable AVFoundation reader objects across the conversion
    /// closure. They are confined to one serial queue, so this is safe.
    private final class ConvertBox: @unchecked Sendable {
        let reader: AVAssetReader
        let output: AVAssetReaderTrackOutput
        let input: AVAssetWriterInput
        init(reader: AVAssetReader, output: AVAssetReaderTrackOutput, input: AVAssetWriterInput) {
            self.reader = reader; self.output = output; self.input = input
        }
    }

    // MARK: - Helpers

    private static func tempWAVURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("verba-\(UUID().uuidString).wav")
    }

    private static func clearError(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        let kind = ext.isEmpty ? "this file" : "\(ext.uppercased()) files"
        return "Verba couldn't read \(kind). WhatsApp voice notes (.opus) and Ogg files "
            + "need conversion — install ffmpeg (e.g. `brew install ffmpeg`) and try again, "
            + "or export the recording as M4A/WAV/MP3 first."
    }
}
