import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: TTSViewModel
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    editorCard
                    voiceCard
                    controlsCard
                    generateButton
                    if let url = vm.currentAudioURL {
                        playerCard(url)
                    }
                    historyCard
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let url = shareURL {
                ActivityView(items: [url])
            }
        }
        .alert("VietVoice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.black)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text("VietVoice")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("Text → Speech · 100% local")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("Offline", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.green.opacity(0.12), in: Capsule())
                .foregroundStyle(.green)
        }
        .padding(.top, 18)
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Nội dung", systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                Text("\(vm.text.count) ký tự")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $vm.text)
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .font(.body)
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .cardStyle()
    }

    private var voiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Chọn giọng", systemImage: "person.wave.2")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.voices) { voice in
                        Button {
                            vm.selectedVoice = voice.id
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: voice.symbol)
                                    .font(.title3)
                                Text(voice.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(voice.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 118, alignment: .leading)
                            .padding(12)
                            .background(
                                vm.selectedVoice == voice.id ? Color.black : Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .foregroundStyle(vm.selectedVoice == voice.id ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var controlsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Tốc độ", systemImage: "gauge.with.dots.needle.33percent")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2fx", vm.speed))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            Slider(value: $vm.speed, in: 0.75...1.50, step: 0.05)
                .tint(.black)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chất lượng")
                        .font(.headline)
                    Text("Nhiều bước hơn = chậm hơn nhưng ổn định hơn")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Quality", selection: $vm.qualitySteps) {
                    Text("Nhanh").tag(4)
                    Text("Cân bằng").tag(6)
                    Text("Đẹp").tag(8)
                }
                .pickerStyle(.menu)
            }
        }
        .cardStyle()
    }

    private var generateButton: some View {
        Button(action: vm.generate) {
            HStack(spacing: 10) {
                if vm.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "waveform.badge.plus")
                }
                Text(vm.isGenerating ? "Đang tạo giọng…" : "Tạo giọng nói")
                    .fontWeight(.semibold)
                Spacer()
                Text(vm.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .foregroundStyle(.white)
            .background(vm.canGenerate ? Color.black : Color.gray, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!vm.canGenerate)
    }

    private func playerCard(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Bản mới nhất", systemImage: "waveform")
                    .font(.headline)
                Spacer()
                Button {
                    shareURL = url
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 14) {
                Button {
                    vm.player.toggle()
                } label: {
                    Image(systemName: vm.player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.white)
                        .background(.black, in: Circle())
                }
                .buttonStyle(.plain)

                VStack(spacing: 4) {
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

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text("Đã lưu local: \(url.lastPathComponent)")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
            }
        }
        .cardStyle()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Lịch sử", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text("\(vm.history.count) file")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if vm.history.isEmpty {
                Text("Các file WAV tạo ra sẽ xuất hiện ở đây và được lưu trong Documents/VietVoice.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(vm.history.prefix(8).enumerated()), id: \.element) { index, url in
                    if index > 0 { Divider() }
                    HStack(spacing: 12) {
                        Button {
                            vm.play(url)
                        } label: {
                            Image(systemName: "play.fill")
                                .frame(width: 36, height: 36)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text("WAV · local")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            shareURL = url
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                        Button(role: .destructive) {
                            vm.delete(url)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Không gửi văn bản hay âm thanh lên máy chủ")
                .font(.caption.weight(.medium))
            Text("VietVoice · Local Vietnamese TTS")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func formatTime(_ value: TimeInterval) -> String {
        guard value.isFinite else { return "0:00" }
        let seconds = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.045), lineWidth: 1)
            }
    }
}
