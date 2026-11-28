import Testing
@testable import Efirelle

@MainActor
@Suite("Главная")
struct HomeViewModelTests {
    @Test("Загружает ленту")
    func load() async throws {
        let model = HomeViewModel()
        await model.load(from: MockStreamRepository.instant)
        let feed = try #require(model.state.value)
        #expect(!feed.featured.isEmpty)
        #expect(!feed.moments.isEmpty)
        #expect(feed.forYou.count == model.filteredForYou.count)
        #expect(model.followingLive.count == feed.following.count)
    }

    @Test("Фильтры ленты", arguments: StreamFilter.allCases)
    func filter(_ filter: StreamFilter) async throws {
        let model = HomeViewModel()
        await model.load(from: MockStreamRepository.instant)
        model.filter = filter
        let matches = model.filteredForYou.allSatisfy(filter.includes)
        #expect(matches)
    }

    @Test("Ошибка загрузки переводит экран в состояние ошибки")
    func failure() async {
        let model = HomeViewModel()
        var repository = MockStreamRepository.instant
        repository.failure = .offline
        await model.load(from: repository)
        guard case .failed(let message) = model.state else {
            Issue.record("Ожидалось состояние ошибки")
            return
        }
        #expect(message == APIError.offline.message)
    }
}
