import SwiftUI

/// Кнопки под видео: пауза, звук, качество, клип, длительность эфира или возврат к прямому эфиру.
struct PlayerControls: View {
    let isPlaying: Bool
    let isMuted: Bool
    let isBehindLive: Bool
    /// Когда начался эфир — для тикающей длительности.
    let startedAt: Date
    let onTogglePlay: () -> Void
    let onToggleMute: () -> Void
    let onReturnToLive: () -> Void
    /// «Клип» — последние 30 секунд эфира.
    var onClip: (() -> Void)?
    /// Варианты качества; меню появляется, когда их больше одного.
    var qualities: [LiveStream.Quality] = []
    var selectedQuality: URL?
    var onSelectQuality: (URL) -> Void = { _ in }

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

            if qualities.count > 1 {
                qualityMenu
            }

            if let onClip {
                ControlButton(systemImage: "scissors", label: "Сделать клип", action: onClip)
            }

            Spacer(minLength: 0)
            status
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isPlaying)
    }

    private var qualityMenu: some View {
        Menu {
            ForEach(qualities, id: \.url) { quality in
                Button {
                    onSelectQuality(quality.url)
                } label: {
                    if quality.url == selectedQuality {
                        Label(quality.label, systemImage: "checkmark")
                    } else {
                        Text(quality.label)
                    }
                }
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: TapTarget.minimum, height: TapTarget.minimum)
                .background(Palette.surfaceMuted, in: .rect(cornerRadius: Radius.s))
        }
        .accessibilityLabel("Качество")
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
