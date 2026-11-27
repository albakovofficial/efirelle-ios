import Observation

/// Состояние главного экрана: загружает все секции одним запросом и фильтрует ленту.
@MainActor
@Observable
final class HomeViewModel {
    struct Content {
        let viewer: Viewer
        let following: [LiveStream]
        let featured: [LiveStream]
        let moments: [Moment]
        let categories: [StreamCategory]
        let forYou: [LiveStream]
    }

    private(set) var state: LoadState<Content> = .idle
    var filter: StreamFilter = .all

    var filteredForYou: [LiveStream] {
        state.value?.forYou.filter(filter.includes) ?? []
    }

    /// Первая загрузка: при возврате на экран повторно не грузим.
    func loadIfNeeded(from repository: any StreamRepository) async {
        guard state.value == nil, !state.isLoading else { return }
        await load(from: repository)
    }

    /// Загружает секции параллельно. При обновлении старый контент остаётся на экране до получения нового.
    func load(from repository: any StreamRepository) async {
        if state.value == nil {
            state = .loading
        }
        let result = await LoadState<Content>.result {
            async let viewer = repository.currentViewer()
            async let following = repository.followingLive()
            async let featured = repository.featured()
            async let moments = repository.liveMoments()
            async let categories = repository.topCategories()
            async let forYou = repository.streamsForYou()

            return Content(
                viewer: try await viewer,
                following: try await following,
                featured: try await featured,
                moments: try await moments,
                categories: try await categories,
                forYou: try await forYou
            )
        }
        if let result {
            state = result
        }
    }
}
