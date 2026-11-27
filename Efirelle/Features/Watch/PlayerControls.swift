import SwiftUI

/// Кнопки под видео. Знает о прямом эфире: показывает отставание и кнопку «К эфиру».
struct PlayerControls: View {
    let model: WatchViewModel

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ControlButton(
                systemImage: model.isPlaying ? "pause.fill" : "play.fill",
                label: model.isPlaying ? "Пауза" : "Смотреть",
                isProminent: true
            ) {
                model.isPlaying.toggle()
            }
            ControlButton(systemImage: "gobackward.30", label: "Назад на 30 секунд") {
                model.rewind()
            }
            ControlButton(
                systemImage: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: model.isMuted ? "Включить звук" : "Выключить звук"
            ) {
                model.isMuted.toggle()
            }

            Spacer(minLength: 0)
            status
        }
        .sensoryFeedback(.impact(weight: .light), trigger: model.isPlaying)
    }

    @ViewBuilder
    private var status: some View {
        if model.isAtLiveEdge {
            Label {
                Text("Прямой эфир")
            } icon: {
                Circle().fill(Palette.live).frame(width: 8, height: 8)
            }
            .font(.brandCaption)
            .foregroundStyle(Palette.ink)
        } else {
            Button {
                model.returnToLive()
            } label: {
                Text("−\(Formatters.clock(model.lag)) · К эфиру")
                    .font(.brandCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: 32)
                    .background(Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
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
