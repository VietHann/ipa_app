import AVFoundation
import Foundation

final class AudioPlayerController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var loadedURL: URL?

    private var player: AVAudioPlayer?
    private var timer: Timer?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP])
        try? session.setActive(true)
    }

    func load(_ url: URL, autoPlay: Bool = false) {
        if loadedURL == url, let player {
            duration = player.duration
            currentTime = player.currentTime
            if autoPlay && !player.isPlaying {
                play()
            }
            return
        }

        stop(clearLoadedURL: false)

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.enableRate = true
            newPlayer.prepareToPlay()
            player = newPlayer
            loadedURL = url
            duration = newPlayer.duration
            currentTime = 0
            if autoPlay {
                play()
            }
        } catch {
            player = nil
            loadedURL = nil
            duration = 0
            currentTime = 0
            isPlaying = false
        }
    }

    func toggle() {
        guard player != nil else { return }
        isPlaying ? pause() : play()
    }

    func play() {
        guard let player else { return }
        if currentTime >= max(0, duration - 0.05) {
            player.currentTime = 0
            currentTime = 0
        }
        configureSession()
        guard player.play() else {
            isPlaying = false
            return
        }
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func seek(to value: TimeInterval) {
        guard let player else { return }
        let safeValue = min(max(0, value), player.duration)
        player.currentTime = safeValue
        currentTime = safeValue
    }

    func skip(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func stop(clearLoadedURL: Bool = true) {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
        if clearLoadedURL {
            loadedURL = nil
            player = nil
            duration = 0
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = duration
        stopTimer()
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        isPlaying = false
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.duration = player.duration
            self.isPlaying = player.isPlaying
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
