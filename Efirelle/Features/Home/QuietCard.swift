import SwiftUI

/// Когда никто не в эфире: спокойная карточка с «дышащими» полосками уровня звука из логотипа.
struct QuietCard: View {
    var body: some View {
        HStack(spacing: Spacing.m) {
            BreathingBars()
            VStack(alignment: .leading, spacing: 2) {
                Text("Эфиров сейчас нет")
                    .font(.brandHeadline)
                    .foregroundStyle(Palette.ink)
                Text("Пришлём уведомление, когда ваши стримеры начнут трансляцию")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }
}

/// Три полоски медленно поднимаются и опускаются по очереди; при «Уменьшении движения» стоят на месте.
private struct BreathingBars: View {
    @State private var isUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let colors = [Palette.accent, Palette.wave, Palette.accent]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(colors.indices, id: \.self) { index in
                Capsule()
                    .fill(colors[index])
                    .frame(width: 5, height: isUp ? 24 : 8)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever().delay(Double(index) * 0.25),
                        value: isUp
                    )
            }
        }
        .frame(width: 26, height: 28)
        .onAppear { isUp = !reduceMotion }
    }
}

#Preview {
    QuietCard()
        .padding()
        .background(Palette.background)
}
