import AVFoundation
import AVKit
import Observation

/// Воспроизведение эфира: один плеер на экран канала и полный экран, картинка в картинке.
/// Картинка в картинке включается кнопкой и сама — когда приложение сворачивают во время просмотра.
@MainActor
@Observable
final class StreamPlayback {
    let player = AVPlayer()
    private(set) var isPlaying = true
    private(set) var isMuted = false
    /// Зритель ставил на паузу — смотрит с отставанием.
    private(set) var isBehindLive = false
    private(set) var isPictureInPictureActive = false

    var isPictureInPictureSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    @ObservationIgnored private var url: URL?
    @ObservationIgnored private var pictureInPicture: AVPictureInPictureController?
    @ObservationIgnored private weak var pictureInPictureLayer: AVPlayerLayer?
    @ObservationIgnored private lazy var pictureInPictureDelegate = PictureInPictureDelegate { [weak self] active in
        self?.isPictureInPictureActive = active
    }

    /// Новый адрес (другое качество) — меняем поток, не трогая паузу и звук.
    func load(_ url: URL?) {
        guard url != self.url else { return }
        self.url = url
        // Звук эфира слышен и при выключенном беззвучном режиме, и в картинке в картинке.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        player.replaceCurrentItem(with: url.map { AVPlayerItem(url: $0) })
        player.isMuted = isMuted
        if isPlaying { player.play() }
    }

    func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            player.play()
        } else {
            player.pause()
            isBehindLive = true
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    func returnToLive() {
        if let range = player.currentItem?.seekableTimeRanges.last?.timeRangeValue {
            player.seek(to: range.end)
        }
        isPlaying = true
        isBehindLive = false
        player.play()
    }

    func togglePictureInPicture() {
        guard let pictureInPicture else { return }
        if pictureInPicture.isPictureInPictureActive {
            pictureInPicture.stopPictureInPicture()
        } else {
            pictureInPicture.startPictureInPicture()
        }
    }

    /// Видимый слой видео (на экране канала или в полном экране) — к нему привязывается картинка в картинке.
    func attach(_ layer: AVPlayerLayer) {
        layer.player = player
        guard isPictureInPictureSupported, layer !== pictureInPictureLayer, !isPictureInPictureActive else { return }
        let controller = AVPictureInPictureController(playerLayer: layer)
        controller?.canStartPictureInPictureAutomaticallyFromInline = true
        controller?.delegate = pictureInPictureDelegate
        pictureInPicture = controller
        pictureInPictureLayer = layer
    }

    /// Ушли с экрана канала: без картинки в картинке звук не должен продолжаться.
    func stopIfNotInPictureInPicture() {
        if !isPictureInPictureActive { player.pause() }
    }
}

/// Сообщает, когда картинка в картинке включилась и выключилась. Система зовёт делегата на главном потоке.
@MainActor
private final class PictureInPictureDelegate: NSObject, AVPictureInPictureControllerDelegate {
    private let onChange: @MainActor (Bool) -> Void

    init(onChange: @escaping @MainActor (Bool) -> Void) {
        self.onChange = onChange
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        MainActor.assumeIsolated { onChange(true) }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        MainActor.assumeIsolated { onChange(false) }
    }
}
