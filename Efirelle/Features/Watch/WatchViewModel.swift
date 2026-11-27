import Observation

/// Состояние просмотра эфира: позиция с перемоткой, отметки моментов, воспроизведение, подписка.
@MainActor
@Observable
final class WatchViewModel {
    static let rewindStep: Duration = .seconds(30)
    /// Отставание меньше этого считается «в прямом эфире».
    static let liveEdgeTolerance: Duration = .seconds(1)

    let stream: LiveStream
    private(set) var markers: [Moment] = []
    private(set) var position: Duration
    var isPlaying = true
    var isMuted = false
    var isFollowing = false

    init(stream: LiveStream) {
        self.stream = stream
        self.position = stream.duration
    }

    var duration: Duration { stream.duration }

    /// На сколько зритель отстаёт от прямого эфира.
    var lag: Duration { duration - position }

    var isAtLiveEdge: Bool { lag < Self.liveEdgeTolerance }

    func seek(to target: Duration) {
        position = min(max(target, .zero), duration)
    }

    func rewind() {
        seek(to: position - Self.rewindStep)
    }

    func returnToLive() {
        seek(to: duration)
    }

    /// Отметки не критичны для просмотра: при ошибке эфир показывается без них.
    func loadMarkers(from repository: any StreamRepository) async {
        markers = (try? await repository.markers(for: stream.id)) ?? []
    }
}
