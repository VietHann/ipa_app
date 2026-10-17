import Foundation
#if canImport(SherpaOnnx)
import SherpaOnnx
#elseif canImport(SherpaOnnxShared)
import SherpaOnnxShared
#else
#error("SherpaOnnx module not found. Resolve Swift Packages in Xcode.")
#endif

enum TTSError: LocalizedError {
    case missingModel(String)
    case failedToCreateOutputDirectory
    case generationFailed
    case invalidGeneratedAudio
    case invalidFileName

    var errorDescription: String? {
        switch self {
        case .missingModel(let name):
            return "Thiếu model local: \(name). Hãy build lại bằng workflow mới."
        case .failedToCreateOutputDirectory:
            return "Không thể tạo thư mục lưu âm thanh."
        case .generationFailed:
            return "Không thể tạo giọng nói."
        case .invalidGeneratedAudio:
            return "Model không trả về audio hợp lệ."
        case .invalidFileName:
            return "Tên file không hợp lệ."
        }
    }
}

private struct SpeechChunk {
    let text: String
    let trailingPause: TimeInterval
}

final class LocalTTSService {
    private var tts: SherpaOnnxOfflineTtsWrapper?
    private let lock = NSLock()

    private func resource(_ name: String, _ ext: String) throws -> String {
        if let path = Bundle.main.path(forResource: name, ofType: ext) {
            return path
        }
        if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Supertonic") {
            return path
        }
        throw TTSError.missingModel("\(name).\(ext)")
    }

    private func loadIfNeeded() throws -> SherpaOnnxOfflineTtsWrapper {
        lock.lock()
        defer { lock.unlock() }

        if let tts { return tts }

        let supertonic = sherpaOnnxOfflineTtsSupertonicModelConfig(
            durationPredictor: try resource("duration_predictor", "int8.onnx"),
            textEncoder: try resource("text_encoder", "int8.onnx"),
            vectorEstimator: try resource("vector_estimator", "int8.onnx"),
            vocoder: try resource("vocoder", "int8.onnx"),
            ttsJson: try resource("tts", "json"),
            unicodeIndexer: try resource("unicode_indexer", "bin"),
            voiceStyle: try resource("voice", "bin")
        )

        let modelConfig = sherpaOnnxOfflineTtsModelConfig(
            numThreads: 2,
            debug: 0,
            supertonic: supertonic
        )
        var config = sherpaOnnxOfflineTtsConfig(model: modelConfig)
        let wrapper = SherpaOnnxOfflineTtsWrapper(config: &config)
        tts = wrapper
        return wrapper
    }

    func synthesize(
        text: String,
        speakerId: Int,
        speed: Float,
        numSteps: Int,
        sentencePause: TimeInterval,
        enhanceReadability: Bool
    ) throws -> URL {
        let tts = try loadIfNeeded()
        let prepared = enhanceReadability ? normalize(text) : text.trimmingCharacters(in: .whitespacesAndNewlines)
        let chunks = makeChunks(from: prepared, basePause: sentencePause)
        guard !chunks.isEmpty else { throw TTSError.generationFailed }

        var generation = SherpaOnnxGenerationConfigSwift()
        generation.sid = speakerId
        generation.speed = speed
        generation.numSteps = numSteps
        generation.silenceScale = 0.16
        generation.extra = ["lang": "vi"]

        var sampleRate: Int32 = 0
        var outputSamples: [Float] = []

        for (index, chunk) in chunks.enumerated() {
            autoreleasepool {
                let audio = tts.generateWithConfig(
                    text: chunk.text,
                    config: generation,
                    callback: nil,
                    arg: nil
                )

                if audio.sampleRate > 0, sampleRate == 0 {
                    sampleRate = audio.sampleRate
                }

                var samples = audio.samples
                if !samples.isEmpty {
                    smoothEdges(&samples, sampleRate: Int(audio.sampleRate))
                    outputSamples.append(contentsOf: samples)

                    if index < chunks.count - 1, audio.sampleRate > 0 {
                        let pauseFrames = Int(Double(audio.sampleRate) * chunk.trailingPause)
                        if pauseFrames > 0 {
                            outputSamples.append(contentsOf: repeatElement(0, count: pauseFrames))
                        }
                    }
                }
            }
        }

        guard sampleRate > 0, !outputSamples.isEmpty else {
            throw TTSError.invalidGeneratedAudio
        }

        normalizePeak(&outputSamples, targetPeak: 0.92)
        let output = try makeOutputURL()
        try writePCM16Wav(samples: outputSamples, sampleRate: Int(sampleRate), to: output)
        return output
    }

    func listGeneratedFiles() -> [URL] {
        guard let folder = try? outputDirectory() else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls
            .filter { $0.pathExtension.lowercased() == "wav" }
            .sorted {
                let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return a > b
            }
    }

    func delete(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    func deleteAll() throws {
        for url in listGeneratedFiles() {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func rename(_ url: URL, to proposedName: String) throws -> URL {
        let clean = sanitizeFileName(proposedName)
        guard !clean.isEmpty else { throw TTSError.invalidFileName }
        let destination = url.deletingLastPathComponent().appendingPathComponent(clean).appendingPathExtension("wav")
        if destination == url { return url }

        var finalURL = destination
        var suffix = 2
        while FileManager.default.fileExists(atPath: finalURL.path) {
            finalURL = url.deletingLastPathComponent()
                .appendingPathComponent("\(clean)-\(suffix)")
                .appendingPathExtension("wav")
            suffix += 1
        }
        try FileManager.default.moveItem(at: url, to: finalURL)
        return finalURL
    }

    func fileSizeString(for url: URL) -> String {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = values.fileSize else {
            return "WAV"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func makeOutputURL() throws -> URL {
        let folder = try outputDirectory()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return folder.appendingPathComponent("VietVoice-\(formatter.string(from: Date())).wav")
    }

    private func outputDirectory() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw TTSError.failedToCreateOutputDirectory
        }
        let folder = documents.appendingPathComponent("VietVoice", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func normalize(_ input: String) -> String {
        var text = input
            .replacingOccurrences(of: "…", with: ".")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: ". ")
            .replacingOccurrences(of: "&", with: " và ")
            .replacingOccurrences(of: "%", with: " phần trăm")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        let replacements: [(String, String)] = [
            ("TP.HCM", "Thành phố Hồ Chí Minh"),
            ("TPHCM", "Thành phố Hồ Chí Minh"),
            ("TP. HCM", "Thành phố Hồ Chí Minh"),
            ("TP.HN", "Thành phố Hà Nội"),
            ("VN", "Việt Nam")
        ]
        for (from, to) in replacements {
            text = text.replacingOccurrences(of: from, with: to)
        }

        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\.{2,}"#, with: ".", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let last = text.last, !".!?".contains(last) {
            text.append(".")
        }
        return text
    }

    private func makeChunks(from text: String, basePause: TimeInterval) -> [SpeechChunk] {
        let pattern = #"[^.!?;:]+[.!?;:]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [SpeechChunk(text: text, trailingPause: basePause)]
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)
        var result: [SpeechChunk] = []

        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let raw = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { continue }
            let pause = pauseForEnding(raw.last, base: basePause)
            let pieces = splitLong(raw, limit: 150)
            for (index, piece) in pieces.enumerated() {
                let piecePause = index == pieces.count - 1 ? pause : max(0.055, basePause * 0.5)
                result.append(SpeechChunk(text: piece, trailingPause: piecePause))
            }
        }

        return result.isEmpty ? [SpeechChunk(text: text, trailingPause: basePause)] : result
    }

    private func splitLong(_ text: String, limit: Int) -> [String] {
        guard text.count > limit else { return [text] }

        var result: [String] = []
        var current = ""
        let words = text.split(separator: " ")

        for word in words {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count > limit, !current.isEmpty {
                result.append(current + (current.last == "," ? "" : ","))
                current = String(word)
            } else {
                current = candidate
            }
        }

        if !current.isEmpty { result.append(current) }
        return result
    }

    private func pauseForEnding(_ ending: Character?, base: TimeInterval) -> TimeInterval {
        switch ending {
        case "?", "!": return min(0.34, base * 1.35)
        case ";", ":": return max(0.07, base * 0.72)
        default: return base
        }
    }

    private func smoothEdges(_ samples: inout [Float], sampleRate: Int) {
        guard sampleRate > 0, samples.count > 16 else { return }
        let fadeCount = min(samples.count / 4, max(12, Int(Double(sampleRate) * 0.012)))
        guard fadeCount > 1 else { return }
        for i in 0..<fadeCount {
            let gain = Float(i) / Float(fadeCount - 1)
            samples[i] *= gain
            samples[samples.count - 1 - i] *= gain
        }
    }

    private func normalizePeak(_ samples: inout [Float], targetPeak: Float) {
        let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
        guard peak > 0.001, peak > targetPeak else { return }
        let scale = targetPeak / peak
        for index in samples.indices {
            samples[index] *= scale
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        var clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().hasSuffix(".wav") {
            clean.removeLast(4)
        }
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        clean = clean.components(separatedBy: invalid).joined(separator: "-")
        clean = clean.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return String(clean.prefix(70)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func writePCM16Wav(samples: [Float], sampleRate: Int, to url: URL) throws {
        guard sampleRate > 0 else { throw TTSError.invalidGeneratedAudio }

        var pcm = Data(capacity: samples.count * 2)
        for sample in samples {
            let clipped = min(1, max(-1, sample))
            var value = Int16(clipped * Float(Int16.max)).littleEndian
            withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
        }

        let dataSize = UInt32(pcm.count)
        let byteRate = UInt32(sampleRate * 2)
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let chunkSize = UInt32(36) + dataSize

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        appendLE(chunkSize, to: &wav)
        wav.append("WAVE".data(using: .ascii)!)
        wav.append("fmt ".data(using: .ascii)!)
        appendLE(UInt32(16), to: &wav)
        appendLE(UInt16(1), to: &wav)
        appendLE(UInt16(1), to: &wav)
        appendLE(UInt32(sampleRate), to: &wav)
        appendLE(byteRate, to: &wav)
        appendLE(blockAlign, to: &wav)
        appendLE(bitsPerSample, to: &wav)
        wav.append("data".data(using: .ascii)!)
        appendLE(dataSize, to: &wav)
        wav.append(pcm)

        try wav.write(to: url, options: .atomic)
    }

    private func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
}
