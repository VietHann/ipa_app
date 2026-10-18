import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: TTSViewModel
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $vm.autoPlay) {
                        Label("Tự phát sau khi tạo", systemImage: "play.circle.fill")
                    }
                    .onChange(of: vm.autoPlay) { _ in vm.persistSettings() }

                    Toggle(isOn: $vm.enhanceReadability) {
                        Label("Tối ưu văn bản", systemImage: "wand.and.stars")
                    }
                    .onChange(of: vm.enhanceReadability) { _ in vm.persistSettings() }

                    Toggle(isOn: $vm.hapticsEnabled) {
                        Label("Rung phản hồi", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: vm.hapticsEnabled) { _ in vm.persistSettings() }
                } header: {
                    Text("Trải nghiệm")
                }

                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Label("Giọng", systemImage: "waveform")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(NarratorVoice.title).fontWeight(.semibold)
                            Text("Cố định · offline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Phong cách", selection: Binding(
                        get: { vm.style },
                        set: { vm.apply($0) }
                    )) {
                        ForEach(TTSStylePreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }

                    HStack {
                        Label("Chất lượng", systemImage: "waveform.path.ecg")
                        Spacer()
                        Text(vm.qualityLabel)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Giọng nói")
                }

                Section {
                    HStack {
                        Label("Model", systemImage: "cpu")
                        Spacer()
                        Text("Supertonic 3 INT8")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Chế độ", systemImage: "lock.shield")
                        Spacer()
                        Text("100% local")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Label("Định dạng xuất", systemImage: "waveform")
                        Spacer()
                        Text("WAV PCM16")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Engine")
                } footer: {
                    Text("VietVoice xử lý văn bản và tạo audio ngay trên thiết bị. Không cần API key hoặc backend khi sử dụng model đã đóng gói.")
                }

                Section {
                    Button(role: .destructive) {
                        showReset = true
                    } label: {
                        Label("Đặt lại cài đặt", systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("VietVoice 2.1")
                            .font(.headline)
                        Text("Local Vietnamese Text to Speech")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("cre: VietHannn")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(VVTheme.lavender)
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(VVTheme.pageGradient)
            .navigationTitle("Cài đặt")
        }
        .confirmationDialog("Đặt lại cài đặt?", isPresented: $showReset, titleVisibility: .visible) {
            Button("Đặt lại", role: .destructive) { vm.resetSettings() }
            Button("Hủy", role: .cancel) {}
        }
    }
}
