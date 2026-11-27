import AVKit
import SwiftUI

/// Область видео. Если у эфира есть HLS-адрес — играет поток, иначе показывает обложку.
struct VideoSurface: View {
    let url: URL?
    let tone: Tone
    let isPlaying: Bool
    let isMuted: Bool

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .disabled(true) // управление — своими кнопками под видео
            } else {
                ThumbnailView(tone: tone, cornerRadius: 0)
            }
        }
        .task(id: url) {
            guard let url else {
                player = nil
                return
            }
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
        .onDisappear { player?.pause() }
    }
}
