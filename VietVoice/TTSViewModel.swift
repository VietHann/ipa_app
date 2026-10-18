import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TTSStylePreset: String, CaseIterable, Identifiable {
    case natural
    case narration
    case soft
    case brisk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .natural: return "Tự nhiên"
        case .narration: return "Thuyết minh"
        case .soft: return "Dịu nhẹ"
        case .brisk: return "Nhanh rõ"
        }
    }

    var subtitle: String {
        switch self {
        case .natural: return "Cân bằng, nghe hằng ngày"
        case .narration: return "Rõ nhịp, hợp đoạn dài"
        case .soft: return "Chậm nhẹ, mềm hơn"
        case .brisk: return "Gọn, nhanh nhưng vẫn rõ"
        }
    }

    var speed: Double {
        switch self {
        case .natural: return 0.96
        case .narration: return 0.90
        case .soft: return 0.86
        case .brisk: return 1.08
        }
    }

    var pause: Double {
        switch self {
        case .natural: return 0.12
        case .narration: return 0.18
        case .soft: return 0.21
        case .brisk: return 0.08
        }
    }

    var qualitySteps: Int {
        switch self {
        case .brisk: return 6
        default: return 8
        }
    }
}

final class TTSViewModel: ObservableObject {
    @Published var text = "Đêm Sài Gòn, thành phố vẫn chưa ngủ. Giữa những ánh đèn xa, có những câu chuyện chỉ cần được kể bằng một giọng nói thật bình yên."
    @Published var speed: Double
    @Published var qualitySteps: Int
    @Published var pauseBetweenSentences: Double
    @Published var enhanceReadability: Bool
    @Published var style: TTSStylePreset
    @Published var autoPlay: Bool
    @Published var hapticsEnabled: Bool
    @Published var isGenerating = false
    @Published var status = "Sẵn sàng"
    @Published var errorMessage: String?
    @Published var currentAudioURL: URL?
    @Published var history: [URL] = []

    let player = AudioPlayerController()
    private let service = LocalTTSService()
    private let defaults = UserDefaults.standard

    init() {
        let storedStyle = defaults.string(forKey: "vv.style").flatMap(TTSStylePreset.init(rawValue:)) ?? .narration
        style = storedStyle
        speed = defaults.object(forKey: "vv.speed") as? Double ?? storedStyle.speed
        qualitySteps = defaults.object(forKey: "vv.steps") as? Int ?? storedStyle.qualitySteps
        pauseBetweenSentences = defaults.object(forKey: "vv.pause") as? Double ?? storedStyle.pause
        enhanceReadability = defaults.object(forKey: "vv.enhance") as? Bool ?? true
        autoPlay = defaults.object(forKey: "vv.autoplay") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "vv.haptics") as? Bool ?? true
        history = service.listGeneratedFiles()
    }

    var canGenerate: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    var qualityLabel: String {
        switch qualitySteps {
        case 8...: return "Tối đa"
        case 6...: return "Mượt"
        default: return "Nhanh"
        }
    }

    var estimatedDurationText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "0 giây" }
        let charsPerSecond = max(7.0, 12.0 * speed)
        let seconds = max(1, Int(Double(trimmed.count) / charsPerSecond))
        if seconds < 60 { return "~\(seconds) giây" }
        return "~\(seconds / 60)p \(seconds % 60)s"
    }

    var generateCaption: String {
        "\(style.title) · \(qualityLabel) · \(estimatedDurationText)"
    }

    func apply(_ preset: TTSStylePreset) {
        style = preset
        speed = preset.speed
        pauseBetweenSentences = preset.pause
        qualitySteps = preset.qualitySteps
        persistSettings()
        haptic(.selection)
    }

    func generate() {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty, !isGenerating else { return }

        isGenerating = true
        status = "Đang tạo giọng…"
        errorMessage = nil
        persistSettings()

        let selectedSpeed = Float(speed)
        let steps = qualitySteps
        let pause = pauseBetweenSentences
        let shouldEnhance = enhanceReadability
        let shouldAutoPlay = autoPlay

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let url = try self.service.synthesize(
                    text: cleanText,
                    speed: selectedSpeed,
                    numSteps: steps,
                    sentencePause: pause,
                    enhanceReadability: shouldEnhance
                )

                DispatchQueue.main.async {
                    self.currentAudioURL = url
                    self.player.load(url, autoPlay: shouldAutoPlay)
                    self.refreshHistory()
                    self.status = "Đã tạo xong"
                    self.isGenerating = false
                    self.haptic(.success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.status = "Có lỗi"
                    self.isGenerating = false
                    self.haptic(.error)
                }
            }
        }
    }

    func toggleCurrentAudioPlayback() {
        guard let url = currentAudioURL else { return }
        if player.loadedURL != url {
            player.load(url, autoPlay: true)
        } else {
            player.toggle()
        }
        haptic(.selection)
    }

    func play(_ url: URL) {
        if currentAudioURL == url, player.loadedURL == url {
            player.toggle()
        } else {
            currentAudioURL = url
            player.load(url, autoPlay: true)
        }
        haptic(.selection)
    }

    func delete(_ url: URL) {
        do {
            if currentAudioURL == url {
                player.stop()
                currentAudioURL = nil
            }
            try service.delete(url)
            refreshHistory()
            haptic(.success)
        } catch {
            errorMessage = error.localizedDescription
            haptic(.error)
        }
    }

    func deleteAll() {
        do {
            player.stop()
            currentAudioURL = nil
            try service.deleteAll()
            refreshHistory()
            haptic(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rename(_ url: URL, to name: String) {
        do {
            let wasCurrent = currentAudioURL == url
            let isPlaying = player.isPlaying
            let renamed = try service.rename(url, to: name)
            if wasCurrent {
                currentAudioURL = renamed
                player.load(renamed, autoPlay: isPlaying)
            }
            refreshHistory()
            haptic(.success)
        } catch {
            errorMessage = error.localizedDescription
            haptic(.error)
        }
    }

    func fileSizeString(for url: URL) -> String {
        service.fileSizeString(for: url)
    }

    func clearText() {
        text = ""
        haptic(.selection)
    }

    func insertDemoText() {
        text = "Đêm Sài Gòn, một cơn mưa vừa đi qua. Ánh đèn vàng hắt xuống mặt đường còn ướt. Có những câu chuyện không cần kể vội. Chỉ một giọng nói trầm ấm, một chút lặng im, cũng đủ khiến người ta muốn lắng nghe."
        haptic(.selection)
    }

    func pasteFromClipboard() {
        #if canImport(UIKit)
        if let string = UIPasteboard.general.string, !string.isEmpty {
            text = string
            haptic(.selection)
        }
        #endif
    }

    func importText(from url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            text = try String(contentsOf: url, encoding: .utf8)
            haptic(.success)
        } catch {
            errorMessage = "Không đọc được file văn bản này."
            haptic(.error)
        }
    }

    func refreshHistory() {
        history = service.listGeneratedFiles()
    }

    func persistSettings() {
        defaults.set(style.rawValue, forKey: "vv.style")
        defaults.set(speed, forKey: "vv.speed")
        defaults.set(qualitySteps, forKey: "vv.steps")
        defaults.set(pauseBetweenSentences, forKey: "vv.pause")
        defaults.set(enhanceReadability, forKey: "vv.enhance")
        defaults.set(autoPlay, forKey: "vv.autoplay")
        defaults.set(hapticsEnabled, forKey: "vv.haptics")
    }

    func resetSettings() {
        style = .narration
        speed = TTSStylePreset.narration.speed
        qualitySteps = TTSStylePreset.narration.qualitySteps
        pauseBetweenSentences = TTSStylePreset.narration.pause
        enhanceReadability = true
        autoPlay = true
        hapticsEnabled = true
        persistSettings()
        haptic(.success)
    }

    private enum Feedback {
        case selection
        case success
        case error
    }

    private func haptic(_ feedback: Feedback) {
        guard hapticsEnabled else { return }
        #if canImport(UIKit)
        switch feedback {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
