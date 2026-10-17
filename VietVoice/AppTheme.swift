import SwiftUI

enum VVTheme {
    static let lavender = Color(red: 0.66, green: 0.53, blue: 0.96)
    static let pink = Color(red: 1.00, green: 0.58, blue: 0.76)
    static let sky = Color(red: 0.43, green: 0.73, blue: 1.00)
    static let mint = Color(red: 0.39, green: 0.82, blue: 0.70)

    static let pageGradient = LinearGradient(
        colors: [
            Color(red: 0.985, green: 0.965, blue: 1.0),
            Color(red: 0.955, green: 0.985, blue: 1.0),
            Color.white
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [Color.black, Color(red: 0.27, green: 0.19, blue: 0.47)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [lavender, pink],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension View {
    func vvCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.68), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }
}

struct VVScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
