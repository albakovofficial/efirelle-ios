import AVFoundation
import HaishinKit
import Observation
import RTMPHaishinKit
import UIKit
import VideoToolbox

/// Эфир с камеры iPhone: захват камеры и микрофона, кодирование H.264/AAC и отправка на сервер по RTMP —
/// туда же, куда шлёт OBS, поэтому сервер ничем не отличает такой эфир от обычного.
@MainActor
@Observable
final class BroadcastSession {
    enum State: Equatable {
        /// Камера ещё не включена.
        case preparing
        /// Нет доступа к камере или микрофону.
        case denied
        /// Предпросмотр, эфир не идёт.
        case ready
        case connecting
        case live(since: Date)
        case failed(String)
    }

    private(set) var state: State = .preparing
    private(set) var isMuted = false
    private(set) var usesFrontCamera = false

    var isLive: Bool {
        if case .live = state { true } else { false }
    }

    /// Вертикальное видео 720×1280, 30 кадров, ключевой кадр каждые 2 с — как советуем для OBS.
    private static let videoSettings = VideoCodecSettings(
        videoSize: CGSize(width: 720, height: 1280),
        bitRate: 2_500_000,
        profileLevel: kVTProfileLevel_H264_Main_AutoLevel as String,
        maxKeyFrameIntervalDuration: 2
    )

    @ObservationIgnored private let mixer = MediaMixer()
    @ObservationIgnored private var preview: MTHKView?
    @ObservationIgnored private var connection: RTMPConnection?
    @ObservationIgnored private var stream: RTMPStream?
    @ObservationIgnored private var statusTask: Task<Void, Never>?

    /// Спрашивает доступ и включает камеру с микрофоном для предпросмотра.
    func prepare() async {
        guard state == .preparing else { return }
        guard await AVCaptureDevice.requestAccess(for: .video), await AVCaptureDevice.requestAccess(for: .audio) else {
            state = .denied
            return
        }
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)

        await mixer.setSessionPreset(.hd1280x720)
        await mixer.setVideoOrientation(.portrait)
        try? await mixer.setFrameRate(30)
        do {
            try await attachCamera()
            try await mixer.attachAudio(AVCaptureDevice.default(for: .audio))
        } catch {
            state = .failed("Камера или микрофон не включились. Закройте другие приложения, которые ими пользуются.")
            return
        }
        await mixer.startRunning()
        if let preview { await mixer.addOutput(preview) }
        state = .ready
    }

    /// Подключает окно предпросмотра; если камера уже работает — сразу показывает картинку.
    func attach(_ view: MTHKView) {
        preview = view
        guard state != .preparing, state != .denied else { return }
        Task { await mixer.addOutput(view) }
    }

    /// Выходит в эфир. `server` и `streamKey` — те же, что в OBS («Сервер» и «Ключ потока»).
    func start(server: String, streamKey: String) async {
        switch state {
        case .ready, .failed: break
        default: return
        }
        state = .connecting
        let connection = RTMPConnection()
        let stream = RTMPStream(connection: connection)
        do {
            try await stream.setVideoSettings(Self.videoSettings)
            try await stream.setAudioSettings(AudioCodecSettings(bitRate: 128_000))
            await mixer.addOutput(stream)
            _ = try await connection.connect(server)
            _ = try await stream.publish(streamKey)
        } catch {
            await mixer.removeOutput(stream)
            try? await connection.close()
            state = .failed("Не получилось выйти в эфир. Проверьте интернет и попробуйте ещё раз.")
            return
        }
        self.connection = connection
        self.stream = stream
        state = .live(since: .now)
        UIApplication.shared.isIdleTimerDisabled = true
        watch(connection)
    }

    /// Завершает эфир; камера остаётся включённой.
    func stop() async {
        await disconnect()
        if isLive || state == .connecting { state = .ready }
    }

    /// Завершает эфир и выключает камеру с микрофоном — при закрытии экрана.
    func shutdown() async {
        await disconnect()
        await mixer.stopRunning()
        try? await mixer.attachVideo(nil)
        try? await mixer.attachAudio(nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .preparing
    }

    func toggleMute() async {
        var settings = await mixer.audioMixerSettings
        settings.isMuted.toggle()
        await mixer.setAudioMixerSettings(settings)
        isMuted = settings.isMuted
    }

    func flipCamera() async {
        usesFrontCamera.toggle()
        try? await attachCamera()
    }

    private func attachCamera() async throws {
        let front = usesFrontCamera
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: front ? .front : .back)
        try await mixer.attachVideo(camera) { unit in
            unit.isVideoMirrored = front
        }
    }

    /// Следит за соединением: обрыв связи — эфир окончен, сообщаем автору.
    private func watch(_ connection: RTMPConnection) {
        statusTask = Task { [weak self] in
            for await status in await connection.status {
                let closed: Set<String> = [
                    RTMPConnection.Code.connectClosed.rawValue,
                    RTMPConnection.Code.connectFailed.rawValue,
                    RTMPConnection.Code.connectIdleTimeOut.rawValue,
                ]
                guard closed.contains(status.code) else { continue }
                await self?.connectionLost()
                return
            }
        }
    }

    private func connectionLost() async {
        guard isLive else { return }
        await disconnect()
        state = .failed("Связь с сервером прервалась — эфир остановлен.")
    }

    private func disconnect() async {
        statusTask?.cancel()
        statusTask = nil
        if let stream {
            _ = try? await stream.close()
            await mixer.removeOutput(stream)
        }
        try? await connection?.close()
        stream = nil
        connection = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
