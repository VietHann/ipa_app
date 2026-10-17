import SwiftUI

struct AnimatedWaveform: View {
    var isActive: Bool
    var barCount: Int = 13
    var height: CGFloat = 32
    var tint: Color = .primary

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let wave = abs(sin((t * 4.2) + Double(index) * 0.63))
                    let idle = 0.22 + Double(index % 4) * 0.08
                    let value = isActive ? wave : idle
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.9))
                        .frame(width: 3.5, height: max(5, height * CGFloat(0.22 + value * 0.78)))
                }
            }
            .frame(height: height)
        }
        .accessibilityHidden(true)
    }
}

struct VoiceOrb: View {
    var active: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [VVTheme.lavender.opacity(0.18), VVTheme.pink.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: pulse ? 88 : 70, height: pulse ? 88 : 70)
                .blur(radius: 1)

            Circle()
                .fill(VVTheme.primaryGradient)
                .frame(width: 62, height: 62)
                .shadow(color: VVTheme.lavender.opacity(0.22), radius: 16, x: 0, y: 8)

            AnimatedWaveform(isActive: active, barCount: 9, height: 27, tint: .white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
