import SwiftUI

@main
struct VietVoiceApp: App {
    @StateObject private var viewModel = TTSViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.light)
        }
    }
}
