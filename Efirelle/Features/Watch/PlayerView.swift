import Foundation
import SwiftUI

/// Плеер прямого эфира: видео с метками поверх и кнопки управления.
struct PlayerView: View {
    let stream: LiveStream
    /// Зрители из чата в реальном времени.
    let viewers: Int

    @State private var isPlaying = true
    @State private var isMuted = false
    /// Зритель ставил на паузу — смотрит с отставанием.
    @State private var isBehindLive = false
    /// Увеличивается, когда нужно вернуться к прямому эфиру.
    @State private var liveRequest = 0
    /// Когда начался эфир — для тикающей длительности.
    @State private var startedAt: Date

    init(stream: LiveStream, viewers: Int) {
        self.stream = stream
        self.viewers = viewers
        _startedAt = State(initialValue: Date.now.addingTimeInterval(-Double(stream.duration.components.seconds)))
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            VideoSurface(
                url: stream.playbackURL,
                tone: stream.tone,
                isPlaying: isPlaying,
                isMuted: isMuted,
                liveRequest: liveRequest
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: Radius.l))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    BadgeView.live()
                    BadgeView(text: Formatters.count(viewers, .viewers, compact: false))
                }
                .padding(Spacing.s)
            }

            PlayerControls(
                isPlaying: isPlaying,
                isMuted: isMuted,
                isBehindLive: isBehindLive,
                startedAt: startedAt,
                onTogglePlay: togglePlay,
                onToggleMute: { isMuted.toggle() },
                onReturnToLive: returnToLive
            )
            .padding(.horizontal, Spacing.xxs)
        }
        .padding(Spacing.xs)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .shadow(color: Palette.accent.opacity(0.12), radius: 30, y: 16)
    }

    private func togglePlay() {
        isPlaying.toggle()
        if !isPlaying { isBehindLive = true }
    }

    private func returnToLive() {
        liveRequest += 1
        isPlaying = true
        isBehindLive = false
    }
}
