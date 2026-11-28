import AVKit
import SwiftUI

/// Область видео. Если у эфира есть HLS-адрес — играет поток, иначе показывает обложку.
struct VideoSurface: View {
    let url: URL?
    let tone: Tone
    let isPlaying: Bool
    let isMuted: Bool
    /// Смена значения — перейти к прямому эфиру.
    var liveRequest = 0

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            ThumbnailView(tone: tone, cornerRadius: 0)
            if let player {
                VideoPlayer(player: player)
                    .disabled(true) // управление — своими кнопками под видео
            }
        }
        .task(id: url) {
            guard let url else {
                player = nil
                return
            }
            // Звук эфира слышен и при выключенном беззвучном режиме.
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            if isPlaying { player.play() }
            self.player = player
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onChange(of: isMuted) { _, muted in
            player?.isMuted = muted
        }
        .onChange(of: liveRequest) {
            guard let player, let range = player.currentItem?.seekableTimeRanges.last?.timeRangeValue else { return }
            player.seek(to: range.end)
            player.play()
        }
        .onDisappear { player?.pause() }
    }
}
