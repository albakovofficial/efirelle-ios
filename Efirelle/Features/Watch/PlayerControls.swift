import SwiftUI

/// Кнопки под видео: пауза, звук, длительность эфира или возврат к прямому эфиру.
struct PlayerControls: View {
    let isPlaying: Bool
    let isMuted: Bool
    let isBehindLive: Bool
    /// Когда начался эфир — для тикающей длительности.
    let startedAt: Date
    let onTogglePlay: () -> Void
    let onToggleMute: () -> Void
    let onReturnToLive: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ControlButton(
                systemImage: isPlaying ? "pause.fill" : "play.fill",
                label: isPlaying ? "Пауза" : "Смотреть",
                isProminent: true,
                action: onTogglePlay
            )
            ControlButton(
                systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: isMuted ? "Включить звук" : "Выключить звук",
                action: onToggleMute
            )

            Spacer(minLength: 0)
            status
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isPlaying)
    }

    @ViewBuilder
    private var status: some View {
        if isBehindLive {
            Button(action: onReturnToLive) {
                Text("К эфиру")
                    .font(.brandCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: 32)
                    .background(Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Label {
                    Text("Прямой эфир · \(Formatters.clock(.seconds(context.date.timeIntervalSince(startedAt))))")
                        .monospacedDigit()
                } icon: {
                    Circle().fill(Palette.live).frame(width: 8, height: 8)
                }
                .font(.brandCaption)
                .foregroundStyle(Palette.ink)
            }
        }
    }
}

private struct ControlButton: View {
    let systemImage: String
    let label: String
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isProminent ? .white : Palette.ink)
                .frame(width: TapTarget.minimum, height: TapTarget.minimum)
                .background(isProminent ? Palette.ink : Palette.surfaceMuted, in: .rect(cornerRadius: Radius.s))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
