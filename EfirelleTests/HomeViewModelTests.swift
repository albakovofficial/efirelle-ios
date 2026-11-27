import Testing
@testable import Efirelle

@MainActor
@Suite("Главная")
struct HomeViewModelTests {
    @Test("Загружает все секции")
    func load() async throws {
        let model = HomeViewModel()
        await model.load(from: MockStreamRepository.instant)
        let content = try #require(model.state.value)
        #expect(!content.featured.isEmpty)
        #expect(!content.moments.isEmpty)
        #expect(content.forYou.count == model.filteredForYou.count)
    }

    @Test("Фильтры ленты", arguments: StreamFilter.allCases)
    func filter(_ filter: StreamFilter) async throws {
        let model = HomeViewModel()
        await model.load(from: MockStreamRepository.instant)
        model.filter = filter
        #expect(model.filteredForYou.allSatisfy(filter.includes))
    }

    @Test("Ошибка загрузки переводит экран в состояние ошибки")
    func failure() async {
        let model = HomeViewModel()
        await model.load(from: FailingRepository())
        guard case .failed = model.state else {
            Issue.record("Ожидалось состояние ошибки")
            return
        }
    }
}

/// Репозиторий, который всегда отвечает ошибкой.
private struct FailingRepository: StreamRepository {
    struct Failure: Error {}

    func currentViewer() async throws -> Viewer { throw Failure() }
    func followingLive() async throws -> [LiveStream] { throw Failure() }
    func featured() async throws -> [LiveStream] { throw Failure() }
    func liveMoments() async throws -> [Moment] { throw Failure() }
    func topCategories() async throws -> [StreamCategory] { throw Failure() }
    func streamsForYou() async throws -> [LiveStream] { throw Failure() }
    func markers(for streamID: LiveStream.ID) async throws -> [Moment] { throw Failure() }
    func chatHistory(for streamID: LiveStream.ID) async throws -> [ChatEntry] { throw Failure() }
    func activePrediction(for streamID: LiveStream.ID) async throws -> Prediction? { throw Failure() }
    func report(messageID: ChatMessage.ID, in streamID: LiveStream.ID, reason: ReportReason) async throws { throw Failure() }
}
