import Observation

/// Вкладка «Поиск»: рекомендованные эфиры, категории и результаты поиска.
@MainActor
@Observable
final class SearchViewModel {
    /// Сколько эфиров в ленте «Сейчас в эфире»; остальные — по кнопке «Ещё».
    static let featuredCount = 10

    private(set) var categories: LoadState<[StreamCategory]> = .idle
    private(set) var live: [LiveStream] = []
    private(set) var liveTotal = 0
    private(set) var results: SearchResults?
    var query = ""

    var isSearching: Bool { !query.isBlank }

    func load(from repository: any StreamRepository) async {
        if categories.value == nil { categories = .loading }
        // Эфиры и категории грузятся параллельно; категории решают, удалась ли загрузка экрана.
        async let page = try? repository.recommendedStreams(offset: 0, limit: Self.featuredCount)
        if let list = await LoadState<[StreamCategory]>.result(of: { try await repository.categories() }) {
            categories = list
        }
        if let page = await page {
            live = page.streams
            liveTotal = page.total
        }
    }

    /// Ищем, когда пользователь перестал печатать.
    func search(using repository: any StreamRepository) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = nil
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(350))
            results = try await repository.search(text)
        } catch {
            // Отмена (печатают дальше) или нет сети — оставляем прошлые результаты.
        }
    }
}
