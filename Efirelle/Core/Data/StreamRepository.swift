/// Источник данных приложения. Экраны знают только этот протокол:
/// чтобы подключить настоящий API, достаточно новой реализации.
protocol StreamRepository: Sendable {
    func currentViewer() async throws -> Viewer
    func followingLive() async throws -> [LiveStream]
    /// Первый элемент — главный эфир витрины.
    func featured() async throws -> [LiveStream]
    func liveMoments() async throws -> [Moment]
    func topCategories() async throws -> [StreamCategory]
    func streamsForYou() async throws -> [LiveStream]
    func markers(for streamID: LiveStream.ID) async throws -> [Moment]
    func chatHistory(for streamID: LiveStream.ID) async throws -> [ChatEntry]
    func activePrediction(for streamID: LiveStream.ID) async throws -> Prediction?
    /// Жалоба на сообщение чата — уходит модераторам.
    func report(messageID: ChatMessage.ID, in streamID: LiveStream.ID, reason: ReportReason) async throws
}
