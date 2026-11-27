import SwiftUI

/// Плеер: видео с метками поверх, шкала перемотки и кнопки управления.
struct PlayerView: View {
    let model: WatchViewModel

    var body: some View {
        VStack(spacing: Spacing.s) {
            VideoSurface(
                url: model.stream.playbackURL,
                tone: model.stream.tone,
                isPlaying: model.isPlaying,
                isMuted: model.isMuted
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: Radius.l))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    BadgeView.live()
                    BadgeView(text: Formatters.count(model.stream.viewers, .viewers, compact: false))
                }
                .padding(Spacing.s)
            }
            .overlay(alignment: .topTrailing) {
                BadgeView(text: model.stream.quality)
                    .padding(Spacing.s)
            }

            VStack(spacing: Spacing.xs) {
                StreamTimeline(
                    position: model.position,
                    duration: model.duration,
                    markers: model.markers,
                    onSeek: model.seek(to:)
                )
                PlayerControls(model: model)
            }
            .padding(.horizontal, Spacing.xxs)
        }
        .padding(Spacing.xs)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .shadow(color: Palette.accent.opacity(0.12), radius: 30, y: 16)
    }
}
