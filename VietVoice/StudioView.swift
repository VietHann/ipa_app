import SwiftUI
import UniformTypeIdentifiers

struct StudioView: View {
    @EnvironmentObject private var vm: TTSViewModel
    @State private var shareURL: URL?
    @State private var showImporter = false

    var body: some View {
        ZStack {
            VVTheme.pageGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    quickActions
                    editor
                    styleSelector
                    voiceSelector
                    controls
                    generateButton
                    if let url = vm.currentAudioURL {
                        PlayerCard(url: url) { shareURL = url }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    privacyFooter
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ActivityView(items: [shareURL])
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.plainText, .text]) { result in
            if case .success(let url) = result {
                vm.importText(from: url)
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            VoiceOrb(active: vm.isGenerating || vm.player.isPlaying)

            VStack(alignment: .leading, spacing: 4) {
                Text("VietVoice")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                Text("Giọng Việt local, riêng tư trên iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
                Label("Offline", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(VVTheme.mint.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)
                Text(vm.status)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tiện ích nhanh", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Text(vm.estimatedDurationText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    quickChip("Dán", "doc.on.clipboard") { vm.pasteFromClipboard() }
                    quickChip("Mở TXT", "doc.text") { showImporter = true }
                    quickChip("Văn mẫu", "text.quote") { vm.insertDemoText() }
                    quickChip("Xóa", "trash") { vm.clearText() }
                    quickChip(vm.enhanceReadability ? "Đã tối ưu" : "Tối ưu", vm.enhanceReadability ? "checkmark.circle.fill" : "wand.and.stars") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.enhanceReadability.toggle()
                            vm.persistSettings()
                        }
                    }
                }
            }
        }
        .vvCard()
    }

    private func quickChip(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.88), in: Capsule())
        }
        .buttonStyle(VVScaleButtonStyle())
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Nội dung", systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                Text("\(vm.text.count) ký tự")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $vm.text)
                    .frame(minHeight: 190)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .padding(9)
                    .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                if vm.text.isEmpty {
                    Text("Nhập đoạn văn bạn muốn đọc…")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
        .vvCard()
    }

    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Phong cách đọc", systemImage: "theatermasks")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TTSStylePreset.allCases) { preset in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                vm.apply(preset)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(preset.title)
                                        .font(.subheadline.weight(.semibold))
                                    if vm.style == preset {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                Text(preset.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(vm.style == preset ? .white.opacity(0.78) : .secondary)
                                    .lineLimit(2)
                            }
                            .frame(width: 145, height: 70, alignment: .topLeading)
                            .padding(12)
                            .background(vm.style == preset ? AnyShapeStyle(VVTheme.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.78)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(vm.style == preset ? Color.white : Color.primary)
                            .scaleEffect(vm.style == preset ? 1.02 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .vvCard()
    }

    private var voiceSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Chọn giọng", systemImage: "person.wave.2")
                    .font(.headline)
                Spacer()
                Text("10 giọng local")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.voices) { voice in
                        Button {
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
                                vm.selectedVoice = voice.id
                                vm.persistSettings()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: voice.symbol)
                                        .font(.title3)
                                    Spacer()
                                    if vm.selectedVoice == voice.id {
                                        Image(systemName: "heart.fill")
                                            .font(.caption)
                                    }
                                }
                                Text(voice.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(voice.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(vm.selectedVoice == voice.id ? .white.opacity(0.76) : .secondary)
                            }
                            .frame(width: 124, alignment: .leading)
                            .padding(12)
                            .background(vm.selectedVoice == voice.id ? AnyShapeStyle(VVTheme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.78)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(vm.selectedVoice == voice.id ? Color.white : Color.primary)
                        }
                        .buttonStyle(VVScaleButtonStyle())
                    }
                }
            }
        }
        .vvCard()
    }

    private var controls: some View {
        VStack(spacing: 18) {
            VStack(spacing: 9) {
                HStack {
                    Label("Tốc độ", systemImage: "gauge.with.dots.needle.33percent")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.2fx", vm.speed))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                Slider(value: $vm.speed, in: 0.78...1.16, step: 0.02, onEditingChanged: { editing in
                    if !editing { vm.persistSettings() }
                })
                .tint(.black)
            }

            Divider().opacity(0.45)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Độ mượt")
                        .font(.headline)
                    Spacer()
                    Text(vm.qualityLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Picker("Độ mượt", selection: $vm.qualitySteps) {
                    Text("Nhanh").tag(4)
                    Text("Mượt").tag(6)
                    Text("Tối đa").tag(8)
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.qualitySteps) { _ in vm.persistSettings() }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Ngắt nghỉ giữa câu")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(vm.pauseBetweenSentences * 1000))ms")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $vm.pauseBetweenSentences, in: 0.06...0.28, step: 0.01, onEditingChanged: { editing in
                    if !editing { vm.persistSettings() }
                })
                .tint(VVTheme.lavender)
            }
        }
        .vvCard()
    }

    private var generateButton: some View {
        Button(action: vm.generate) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 36, height: 36)
                    if vm.isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.isGenerating ? "Đang tạo giọng…" : "Tạo giọng nói")
                        .font(.headline)
                    Text(vm.generateCaption)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(vm.canGenerate ? 1 : 0.42))
            }
            .padding(.horizontal, 18)
            .frame(height: 66)
            .foregroundStyle(.white)
            .background(vm.canGenerate ? AnyShapeStyle(VVTheme.primaryGradient) : AnyShapeStyle(Color.gray), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: VVTheme.lavender.opacity(vm.canGenerate ? 0.24 : 0), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(VVScaleButtonStyle())
        .disabled(!vm.canGenerate)
    }

    private var privacyFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("Riêng tư mặc định")
                    .font(.caption.weight(.semibold))
                Text("Văn bản và âm thanh không rời khỏi thiết bị.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 5)
    }
}
