import Observation

/// Состояние главного экрана: загружает ленту одним запросом и фильтрует «Для вас».
@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: LoadState<HomeFeed> = .idle
    var filter: StreamFilter = .all

    var filteredForYou: [LiveStream] {
        state.value?.forYou.filter(filter.includes) ?? []
    }

    /// Категории по числу зрителей; при равенстве — в исходном порядке.
    var categories: [StreamCategory] {
        let list = state.value?.categories ?? []
        return list.indices
            .sorted { (list[$0].viewers, -$0) > (list[$1].viewers, -$1) }
            .map { list[$0] }
    }

    /// Отслеживаемые каналы, которые сейчас в эфире.
    var followingLive: [LiveStream] {
        state.value?.following.compactMap(\.stream) ?? []
    }

    /// При обновлении старая лента остаётся на экране до получения новой.
    func load(from repository: any StreamRepository) async {
        if state.value == nil {
            state = .loading
        }
        if let result = await LoadState<HomeFeed>.result(of: { try await repository.home() }) {
            state = result
        }
    }
}
