import SwiftUI

/// Анимация запуска «Волна»: от центра расходятся два круга эфира, логотип проявляется,
/// затем экран растворяется в приложении. Фон совпадает с экраном запуска, поэтому переход незаметен.
/// С включённым «Уменьшением движения» логотип просто появляется и исчезает.
struct LaunchAnimationView: View {
    let onFinish: () -> Void

    @State private var wavesOut = false
    @State private var logoShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            if !reduceMotion {
                Wave(color: Palette.wave, isOut: wavesOut)
                    .animation(.easeOut(duration: 1.3), value: wavesOut)
                Wave(color: Palette.accent, isOut: wavesOut)
                    .animation(.easeOut(duration: 1.3).delay(0.22), value: wavesOut)
            }
            LogoView(size: 40)
                .scaleEffect(logoShown || reduceMotion ? 1 : 0.8)
                .opacity(logoShown ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.62), value: logoShown)
        }
        .task {
            wavesOut = true
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 600))
            logoShown = true
            try? await Task.sleep(for: .milliseconds(900))
            onFinish()
        }
        .accessibilityHidden(true)
    }
}

/// Кольцо, которое расширяется из точки и тает.
private struct Wave: View {
    let color: Color
    let isOut: Bool

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .frame(width: 60, height: 60)
            .scaleEffect(isOut ? 6 : 0.2)
            .opacity(isOut ? 0 : 1)
    }
}

#Preview {
    LaunchAnimationView {}
}
