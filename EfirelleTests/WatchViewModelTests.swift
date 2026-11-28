import Testing
@testable import Efirelle

@MainActor
@Suite("Экран канала")
struct WatchViewModelTests {
    private let repository = MockStreamRepository.instant

    @Test("Загружает канал, эфир, моменты и чат")
    func load() async throws {
        let model = WatchViewModel(channel: MockData.Channels.timur)
        await model.load(from: repository)
        let watch = try #require(model.state.value)
        #expect(watch.stream != nil)
        #expect(model.viewers == watch.stream?.viewers)
        #expect(model.markers == watch.markers)
        #expect(model.chat.entries.count == MockData.chat.count)
        #expect(model.chat.prediction?.id == MockData.prediction.id)
    }

    @Test("Канал не в сети открывается без эфира")
    func offline() async throws {
        let model = WatchViewModel(channel: MockData.Channels.offline)
        await model.load(from: repository)
        #expect(try #require(model.state.value).stream == nil)
    }

    @Test("Число зрителей и моменты приходят событиями")
    func events() async throws {
        let model = WatchViewModel(channel: MockData.Channels.timur)
        await model.load(from: repository)
        await model.handle(.viewers(77), repository: repository)
        #expect(model.viewers == 77)

        let moment = Moment(id: "new", kind: .highlight, text: "Финал", channel: MockData.Channels.timur, when: "только что", offset: .seconds(5))
        await model.handle(.moment(moment), repository: repository)
        #expect(model.markers.last == moment)
    }

    @Test("Отслеживание переключается и берёт число подписчиков с сервера")
    func follow() async {
        let model = WatchViewModel(channel: MockData.Channels.timur)
        await model.load(from: repository)
        await model.toggleFollow(using: repository)
        #expect(model.isFollowing)
        #expect(model.followers == 1)
    }
}
