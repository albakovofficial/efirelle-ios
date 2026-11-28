import AVFoundation
import SwiftUI
import UIKit

/// Область видео. Если у эфира есть HLS-адрес — играет поток, иначе показывает обложку.
/// `isActive` — этот слой сейчас на экране: к нему привязывается картинка в картинке.
struct VideoSurface: View {
    let playback: StreamPlayback
    let tone: Tone
    var hasVideo = true
    var isActive = true
    var gravity: AVLayerVideoGravity = .resizeAspect

    var body: some View {
        ZStack {
            ThumbnailView(tone: tone, cornerRadius: 0)
            if hasVideo {
                PlayerLayerView(playback: playback, isActive: isActive, gravity: gravity)
            }
        }
    }
}

/// Слой AVPlayerLayer без системных кнопок — управление своё.
private struct PlayerLayerView: UIViewRepresentable {
    let playback: StreamPlayback
    let isActive: Bool
    let gravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.playerLayer.videoGravity = gravity
        view.playerLayer.player = playback.player
        if isActive { playback.attach(view.playerLayer) }
        return view
    }

    func updateUIView(_ view: LayerView, context: Context) {
        view.playerLayer.videoGravity = gravity
        if isActive { playback.attach(view.playerLayer) }
    }

    final class LayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer } // swiftlint:disable:this force_cast
    }
}
