import Foundation
import SwiftUI

struct VoicePreset: Identifiable, Hashable {
    let id: Int
    let name: String
    let subtitle: String
    let symbol: String
}

final class TTSViewModel: ObservableObject {
    @Published var text = "Xin chào! Đây là VietVoice. Giọng nói này được tạo hoàn toàn trên iPhone và không cần kết nối Internet."
    @Published var selectedVoice = 0
    @Published var speed: Double = 1.0
    @Published var qualitySteps = 8
    @Published var isGenerating = false
    @Published var status = "Sẵn sàng"
    @Published var errorMessage: String?
    @Published var currentAudioURL: URL?
    @Published var history: [URL] = []

    let player = AudioPlayerController()
    let voices: [VoicePreset] = (0..<10).map { index in
        VoicePreset(
            id: index,
            name: "Giọng \(index + 1)",
            subtitle: index < 5 ? "Tự nhiên · rõ" : "Ấm · biểu cảm",
            symbol: index.isMultiple(of: 2) ? "waveform" : "speaker.wave.2.fill"
        )
    }

    private let service = LocalTTSService()

    init() {
        history = service.listGeneratedFiles()
    }

    var canGenerate: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func generate() {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty, !isGenerating else { return }

        isGenerating = true
        status = "Đang tạo giọng local…"
        errorMessage = nil
        let speaker = selectedVoice
        let selectedSpeed = Float(speed)
        let steps = qualitySteps

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let url = try self.service.synthesize(
                    text: cleanText,
                    speakerId: speaker,
                    speed: selectedSpeed,
                    numSteps: steps
                )
                DispatchQueue.main.async {
                    self.currentAudioURL = url
                    self.player.load(url)
                    self.history = self.service.listGeneratedFiles()
                    self.status = "Đã tạo xong"
                    self.isGenerating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.status = "Có lỗi"
                    self.isGenerating = false
                }
            }
        }
    }

    func play(_ url: URL) {
        currentAudioURL = url
        player.load(url)
        player.toggle()
    }

    func delete(_ url: URL) {
        do {
            if currentAudioURL == url {
                player.stop()
                currentAudioURL = nil
            }
            try service.delete(url)
            history = service.listGeneratedFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
