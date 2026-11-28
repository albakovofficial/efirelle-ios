/// Источник данных приложения. Экраны знают только этот протокол:
/// настоящая реализация — `APIStreamRepository`, для превью и тестов — `MockStreamRepository`.
protocol StreamRepository: Sendable {
    // MARK: Аккаунт

    /// `nil` — пользователь не вошёл.
    func currentViewer() async throws -> Viewer?
    func login(email: String, password: String) async throws -> Viewer
    func register(_ form: RegistrationForm) async throws -> Viewer
    func logout() async
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, password: String) async throws -> Viewer
    /// Удаляет аккаунт вместе с каналом, сообщениями и подписками.
    func deleteAccount(password: String) async throws

    // MARK: Витрина

    func home() async throws -> HomeFeed
    func categories() async throws -> [StreamCategory]
    func category(id: StreamCategory.ID) async throws -> CategoryStreams
    func search(_ query: String) async throws -> SearchResults
    func followedChannels() async throws -> [ChannelStatus]

    // MARK: Канал и чат

    func watch(channel: Channel.ID) async throws -> ChannelWatch
    func setFollowing(_ following: Bool, channel: Channel.ID) async throws -> FollowState
    /// События чата в реальном времени. Поток заканчивается при обрыве связи.
    func chatEvents(channel: Channel.ID) -> AsyncStream<ChatServerEvent>
    func sendMessage(_ text: String, channel: Channel.ID) async throws
    func vote(prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws -> Prediction

    // MARK: Модерация

    func report(message: ChatMessage.ID, reason: ReportReason) async throws
    func deleteMessage(_ message: ChatMessage.ID) async throws
    func block(username: String) async throws
    func unblock(username: String) async throws
    func blockedUsers() async throws -> [BlockedUser]

    // MARK: Студия

    func studio() async throws -> Studio
    func updateStudio(_ settings: Studio.Settings) async throws
    func rotateStreamKey() async throws -> String
    func createPrediction(question: String, outcomes: [String], duration: Duration) async throws
    func resolvePrediction(_ prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws
    func cancelPrediction(_ prediction: Prediction.ID) async throws
    func addMoment(_ text: String) async throws
    /// `minutes == nil` — навсегда.
    func ban(username: String, minutes: Int?) async throws
    func unban(username: String) async throws
    /// Возвращает, сколько зрителей ушло в рейд.
    func raid(target: String) async throws -> Int
}

/// Данные формы регистрации.
struct RegistrationForm: Sendable, Encodable {
    var email: String
    var password: String
    var username: String
    var displayName: String
}
