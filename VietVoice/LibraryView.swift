import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var vm: TTSViewModel
    @State private var searchText = ""
    @State private var shareURL: URL?
    @State private var renameURL: URL?
    @State private var renameText = ""
    @State private var showDeleteAll = false

    private var filtered: [URL] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return vm.history
        }
        return vm.history.filter {
            $0.deletingPathExtension().lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VVTheme.pageGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        summaryCard
                        if let url = vm.currentAudioURL {
                            PlayerCard(url: url) { shareURL = url }
                        }
                        filesCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Thư viện")
            .searchable(text: $searchText, prompt: "Tìm file đã tạo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !vm.history.isEmpty {
                        Button(role: .destructive) {
                            showDeleteAll = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .onAppear { vm.refreshHistory() }
        .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
            if let shareURL { ActivityView(items: [shareURL]) }
        }
        .alert("Đổi tên file", isPresented: Binding(get: { renameURL != nil }, set: { if !$0 { renameURL = nil } })) {
            TextField("Tên mới", text: $renameText)
            Button("Hủy", role: .cancel) {}
            Button("Lưu") {
                if let renameURL {
                    vm.rename(renameURL, to: renameText)
                }
            }
        } message: {
            Text("Không cần nhập đuôi .wav")
        }
        .confirmationDialog("Xóa toàn bộ lịch sử?", isPresented: $showDeleteAll, titleVisibility: .visible) {
            Button("Xóa tất cả", role: .destructive) { vm.deleteAll() }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Các file WAV trong VietVoice sẽ bị xóa khỏi máy.")
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(VVTheme.lavender.opacity(0.12))
                    .frame(width: 54, height: 54)
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundStyle(VVTheme.lavender)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(vm.history.count) bản ghi")
                    .font(.headline)
                Text("Tất cả đều lưu local trong Documents/VietVoice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .vvCard()
    }

    private var filesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("File WAV", systemImage: "folder.fill")
                    .font(.headline)
                Spacer()
                Text("\(filtered.count) file")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text(vm.history.isEmpty ? "Chưa có bản ghi nào" : "Không tìm thấy file")
                        .font(.subheadline.weight(.semibold))
                    Text(vm.history.isEmpty ? "Tạo giọng ở tab Studio, file sẽ xuất hiện ở đây." : "Thử một từ khóa khác nhé.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(Array(filtered.enumerated()), id: \.element) { index, url in
                    if index > 0 { Divider().opacity(0.4) }
                    fileRow(url)
                }
            }
        }
        .vvCard()
    }

    private func fileRow(_ url: URL) -> some View {
        HStack(spacing: 12) {
            Button { vm.play(url) } label: {
                ZStack {
                    Circle()
                        .fill(vm.currentAudioURL == url ? VVTheme.accentGradient : LinearGradient(colors: [Color.white, Color.white], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                    Image(systemName: vm.currentAudioURL == url && vm.player.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(vm.currentAudioURL == url ? Color.white : Color.primary)
                }
            }
            .buttonStyle(VVScaleButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(vm.fileSizeString(for: url))
                    Text("•")
                    Text(vm.currentAudioURL == url ? "Đang chọn" : "Local")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)

            Menu {
                Button {
                    renameURL = url
                    renameText = url.deletingPathExtension().lastPathComponent
                } label: {
                    Label("Đổi tên", systemImage: "pencil")
                }
                Button {
                    shareURL = url
                } label: {
                    Label("Chia sẻ", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    vm.delete(url)
                } label: {
                    Label("Xóa", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.vertical, 2)
    }
}
