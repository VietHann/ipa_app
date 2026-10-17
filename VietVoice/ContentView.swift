import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: TTSViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StudioView()
                .tabItem {
                    Label("Studio", systemImage: selectedTab == 0 ? "waveform.circle.fill" : "waveform.circle")
                }
                .tag(0)

            LibraryView()
                .tabItem {
                    Label("Thư viện", systemImage: selectedTab == 1 ? "books.vertical.fill" : "books.vertical")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .tint(.black)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .alert("VietVoice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
