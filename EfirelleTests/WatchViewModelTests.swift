import Testing
@testable import Efirelle

@MainActor
@Suite("Экран эфира")
struct WatchViewModelTests {
    private let stream = MockData.streams[0]

    @Test("Открывается в прямом эфире")
    func startsAtLiveEdge() {
        let model = WatchViewModel(stream: stream)
        #expect(model.isAtLiveEdge)
        #expect(model.lag == .zero)
    }

    @Test("Перемотка назад на 30 секунд")
    func rewind() {
        let model = WatchViewModel(stream: stream)
        model.rewind()
        #expect(model.lag == WatchViewModel.rewindStep)
        #expect(!model.isAtLiveEdge)
    }

    @Test("Перемотка не выходит за границы эфира")
    func seekIsClamped() {
        let model = WatchViewModel(stream: stream)
        model.seek(to: .seconds(-10))
        #expect(model.position == .zero)
        model.seek(to: stream.duration + .seconds(60))
        #expect(model.position == stream.duration)
    }

    @Test("Кнопка «К эфиру» возвращает в прямой эфир")
    func returnToLive() {
        let model = WatchViewModel(stream: stream)
        model.seek(to: .seconds(100))
        model.returnToLive()
        #expect(model.isAtLiveEdge)
    }

    @Test("Отметки моментов загружаются из репозитория")
    func loadsMarkers() async {
        let model = WatchViewModel(stream: stream)
        await model.loadMarkers(from: MockStreamRepository.instant)
        #expect(model.markers.count == MockData.markers[stream.id]?.count)
    }
}
