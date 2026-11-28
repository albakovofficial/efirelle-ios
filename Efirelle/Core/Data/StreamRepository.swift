import Foundation

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
    /// «Сейчас в эфире» в порядке рекомендаций для зрителя, страницами.
    func recommendedStreams(offset: Int, limit: Int) async throws -> RecommendedStreams
    func followedChannels() async throws -> [ChannelStatus]

    // MARK: Канал и чат

    func watch(channel: Channel.ID) async throws -> ChannelWatch
    func setFollowing(_ following: Bool, channel: Channel.ID) async throws -> FollowState
    /// События чата в реальном времени. Поток заканчивается при обрыве связи.
    func chatEvents(channel: Channel.ID) -> AsyncStream<ChatServerEvent>
    func sendMessage(_ text: String, replyTo: ChatMessage.ID?, channel: Channel.ID) async throws
    func vote(prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws -> Prediction

    // MARK: Модерация

    func report(message: ChatMessage.ID, reason: ReportReason) async throws
    func deleteMessage(_ message: ChatMessage.ID) async throws
    func block(username: String) async throws
    func unblock(username: String) async throws
    func blockedUsers() async throws -> [BlockedUser]

    // MARK: Клипы

    /// Клип последних 30 секунд идущего эфира; файл готовится около полуминуты.
    func createClip(title: String, channel: Channel.ID) async throws -> Clip
    func clip(_ id: Clip.ID) async throws -> Clip
    func countClipView(_ id: Clip.ID) async

    // MARK: Расписание

    func setReminder(_ on: Bool, for scheduled: ScheduledStream.ID) async throws -> ReminderState

    // MARK: Уведомления

    /// Привязать iPhone к аккаунту: на него придут уведомления о начале эфиров.
    func registerDevice(token: String, environment: PushEnvironment) async throws
    func unregisterDevice(token: String) async throws
    /// Токен запуска Live Activity для устройства; `nil` — Live Activities выключены.
    func setActivityStartToken(_ token: String?, device: String) async throws
    /// Токен запущенной Live Activity канала — по нему придут зрители и конец эфира.
    func registerLiveActivity(token: String, channel: String, environment: PushEnvironment) async throws
    /// Уведомлять ли о начале эфира отслеживаемых каналов.
    func liveNotificationsEnabled() async throws -> Bool
    func setLiveNotifications(_ enabled: Bool) async throws

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
    /// Меняет только переданные настройки модерации чата.
    func updateModeration(_ patch: ModerationPatch) async throws -> ModerationSettings
    func channelStats() async throws -> ChannelStats
    /// Возвращает, сколько зрителей ушло в рейд.
    func raid(target: String) async throws -> Int
    /// Картинки уходят в JPEG (см. `ImageUpload`). Возвращают новый адрес картинки.
    func uploadAvatar(_ jpeg: Data) async throws -> URL?
    func removeAvatar() async throws
    func uploadBanner(_ jpeg: Data) async throws -> URL?
    func removeBanner() async throws
    func updateAbout(description: String, links: [ChannelAbout.Link]) async throws
    func scheduleStream(title: String, categoryId: String, startsAt: Date) async throws
    func deleteScheduled(_ id: ScheduledStream.ID) async throws
    func addEmote(code: String, png: Data) async throws
    func removeEmote(code: String) async throws
}

struct ReminderState: Sendable, Decodable, Equatable {
    let isReminded: Bool
    let reminders: Int
}

/// Данные формы регистрации.
struct RegistrationForm: Sendable, Encodable {
    var email: String
    var password: String
    var username: String
    var displayName: String
}

/// Сервер APNs, через который пойдут уведомления: сборки из Xcode получают их из «песочницы».
enum PushEnvironment: String, Sendable, Encodable {
    case production
    case sandbox

    static var current: PushEnvironment {
        #if DEBUG
        .sandbox
        #else
        .production
        #endif
    }
}
