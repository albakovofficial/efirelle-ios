/// Репозиторий на тестовых данных. Имитирует сетевую задержку, чтобы были видны состояния загрузки.
struct MockStreamRepository: StreamRepository {
    var latency: Duration = .milliseconds(300)

    func currentViewer() async throws -> Viewer {
        try await respond(MockData.viewer)
    }

    func followingLive() async throws -> [LiveStream] {
        try await respond(MockData.streams(ids: MockData.followingIDs))
    }

    func featured() async throws -> [LiveStream] {
        try await respond(MockData.streams(ids: MockData.featuredIDs))
    }

    func liveMoments() async throws -> [Moment] {
        try await respond(MockData.liveMoments)
    }

    func topCategories() async throws -> [StreamCategory] {
        try await respond(MockData.categories)
    }

    func streamsForYou() async throws -> [LiveStream] {
        try await respond(MockData.streams(ids: MockData.forYouIDs))
    }

    func markers(for streamID: LiveStream.ID) async throws -> [Moment] {
        try await respond(MockData.markers[streamID] ?? [])
    }

    func chatHistory(for streamID: LiveStream.ID) async throws -> [ChatEntry] {
        try await respond(MockData.chatHistory)
    }

    func activePrediction(for streamID: LiveStream.ID) async throws -> Prediction? {
        try await respond(MockData.predictions[streamID])
    }

    private func respond<Value: Sendable>(_ value: Value) async throws -> Value {
        if latency > .zero {
            try await Task.sleep(for: latency)
        }
        return value
    }
}

extension MockStreamRepository {
    /// Без задержки — для превью и тестов.
    static let instant = MockStreamRepository(latency: .zero)
}
