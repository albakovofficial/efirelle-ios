import SwiftUI

/// Кнопки под видео: пауза, звук, клип, «Ещё» (качество, картинка в картинке), полный экран
/// и длительность эфира или возврат к прямому эфиру.
struct PlayerControls: View {
    let playback: StreamPlayback
    /// Когда начался эфир — для тикающей длительности.
    let startedAt: Date
    let qualities: [LiveStream.Quality]
    let selectedQuality: URL?
    let onSelectQuality: (URL) -> Void
    let onFullscreen: () -> Void
    /// «Клип» — последние 30 секунд эфира.
    var onClip: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ControlButton(
                systemImage: playback.isPlaying ? "pause.fill" : "play.fill",
                label: playback.isPlaying ? "Пауза" : "Смотреть",
                isProminent: true,
                action: playback.togglePlay
            )
            ControlButton(
                systemImage: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: playback.isMuted ? "Включить звук" : "Выключить звук",
                action: playback.toggleMute
            )
            if let onClip {
                ControlButton(systemImage: "scissors", label: "Сделать клип", action: onClip)
            }
            PlaybackMenu(playback: playback, qualities: qualities, selectedQuality: selectedQuality, onSelectQuality: onSelectQuality) {
                ControlIcon(systemImage: "ellipsis")
            }
            ControlButton(systemImage: "arrow.up.left.and.arrow.down.right", label: "Во весь экран", action: onFullscreen)

            Spacer(minLength: 0)
            status
        }
        .sensoryFeedback(.impact(weight: .light), trigger: playback.isPlaying)
    }

    @ViewBuilder
    private var status: some View {
        if playback.isBehindLive {
            Button(action: playback.returnToLive) {
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
                    Text(Formatters.clock(.seconds(context.date.timeIntervalSince(startedAt))))
                        .monospacedDigit()
                } icon: {
                    Circle().fill(Palette.live).frame(width: 8, height: 8)
                }
                .font(.brandCaption)
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Прямой эфир")
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
            ControlIcon(systemImage: systemImage, isProminent: isProminent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct ControlIcon: View {
    let systemImage: String
    var isProminent = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isProminent ? .white : Palette.ink)
            .frame(width: TapTarget.minimum, height: TapTarget.minimum)
            .background(isProminent ? Palette.inkSurface : Palette.surfaceMuted, in: .rect(cornerRadius: Radius.s))
    }
}
