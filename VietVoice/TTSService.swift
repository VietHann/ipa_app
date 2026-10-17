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

    var errorDescription: String? {
        switch self {
        case .missingModel(let name):
            return "Thiếu model local: \(name). Chạy scripts/fetch_model.sh trước khi build."
        case .failedToCreateOutputDirectory:
            return "Không thể tạo thư mục lưu âm thanh."
        case .generationFailed:
            return "Không thể tạo file WAV."
        }
    }
}

final class LocalTTSService {
    private var tts: SherpaOnnxOfflineTtsWrapper?
    private let lock = NSLock()

    private func resource(_ name: String, _ ext: String) throws -> String {
        if let path = Bundle.main.path(forResource: name, ofType: ext) {
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
        numSteps: Int
    ) throws -> URL {
        let tts = try loadIfNeeded()

        var generation = SherpaOnnxGenerationConfigSwift()
        generation.sid = speakerId
        generation.speed = speed
        generation.numSteps = numSteps
        generation.extra = ["lang": "vi"]

        let audio = tts.generateWithConfig(
            text: text,
            config: generation,
            callback: nil,
            arg: nil
        )

        let folder = try outputDirectory()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let output = folder.appendingPathComponent("VietVoice-\(formatter.string(from: Date())).wav")

        guard audio.save(filename: output.path) == 1 else {
            throw TTSError.generationFailed
        }
        return output
    }

    func listGeneratedFiles() -> [URL] {
        guard let folder = try? outputDirectory() else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
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
}
