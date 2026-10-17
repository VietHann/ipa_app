import SwiftUI

struct PlayerCard: View {
    @EnvironmentObject private var vm: TTSViewModel
    let url: URL
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("Đang nghe", systemImage: "waveform")
                    .font(.headline)
                Spacer()
                Text(vm.player.isPlaying ? "Đang phát" : "Sẵn sàng")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(vm.player.isPlaying ? VVTheme.lavender : .secondary)
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.82), in: Circle())
                }
                .buttonStyle(VVScaleButtonStyle())
            }

            HStack(spacing: 12) {
                Button { vm.player.skip(by: -5) } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title3)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(VVScaleButtonStyle())

                Button { vm.toggleCurrentAudioPlayback() } label: {
                    ZStack {
                        Circle()
                            .fill(VVTheme.primaryGradient)
                            .frame(width: 58, height: 58)
                            .shadow(color: VVTheme.lavender.opacity(0.25), radius: 15, x: 0, y: 8)
                        Image(systemName: vm.player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .offset(x: vm.player.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(VVScaleButtonStyle())
                .contentShape(Circle())

                Button { vm.player.skip(by: 5) } label: {
                    Image(systemName: "goforward.5")
                        .font(.title3)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(VVScaleButtonStyle())

                VStack(spacing: 5) {
                    Slider(
                        value: Binding(
                            get: { vm.player.currentTime },
                            set: { vm.player.seek(to: $0) }
                        ),
                        in: 0...max(vm.player.duration, 0.1)
                    )
                    .tint(.black)

                    HStack {
                        Text(formatTime(vm.player.currentTime))
                        Spacer()
                        Text(formatTime(vm.player.duration))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text(url.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text(vm.fileSizeString(for: url))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .vvCard()
    }

    private func formatTime(_ value: TimeInterval) -> String {
        guard value.isFinite else { return "0:00" }
        let seconds = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
