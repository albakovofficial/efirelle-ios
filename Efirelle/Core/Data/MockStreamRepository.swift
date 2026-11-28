import Foundation

/// Репозиторий на тестовых данных для превью и тестов. Ничего не сохраняет.
/// Имитирует сетевую задержку, чтобы были видны состояния загрузки.
struct MockStreamRepository: StreamRepository {
    var latency: Duration = .milliseconds(300)
    var viewer: Viewer? = MockData.viewer
    /// Ошибка, которую вернёт любой запрос, — для проверки экранов ошибок.
    var failure: APIError?
    /// События чата, которые «придут» после подключения.
    var events: [ChatServerEvent] = []

    func currentViewer() async throws -> Viewer? { try await respond(viewer) }
    func login(email: String, password: String) async throws -> Viewer { try await respond(MockData.viewer) }
    func register(_ form: RegistrationForm) async throws -> Viewer { try await respond(MockData.viewer) }
    func logout() async {}
    func requestPasswordReset(email: String) async throws { try await respond(()) }
    func resetPassword(email: String, code: String, password: String) async throws -> Viewer { try await respond(MockData.viewer) }
    func deleteAccount(password: String) async throws { try await respond(()) }

    func home() async throws -> HomeFeed { try await respond(MockData.home) }
    func categories() async throws -> [StreamCategory] { try await respond(MockData.categories) }

    func category(id: StreamCategory.ID) async throws -> CategoryStreams {
        guard let category = MockData.categories.first(where: { $0.id == id }) else { throw APIError(status: 404, code: "not_found", message: "Категория не найдена") }
        return try await respond(CategoryStreams(category: category, streams: MockData.streams.filter { $0.categoryID == id }))
    }

    func recommendedStreams(offset: Int, limit: Int) async throws -> RecommendedStreams {
        let page = Array(MockData.streams.dropFirst(offset).prefix(limit))
        return try await respond(RecommendedStreams(streams: page, total: MockData.streams.count))
    }

    func search(_ query: String) async throws -> SearchResults {
        let needle = query.lowercased()
        let streams = MockData.streams.filter { $0.title.lowercased().contains(needle) || $0.channel.name.lowercased().contains(needle) }
        let categories = MockData.categories.filter { $0.name.lowercased().contains(needle) }
        let channels = streams.map { ChannelStatus(channel: $0.channel, stream: $0) }
        return try await respond(SearchResults(query: query, streams: streams, channels: channels, categories: categories))
    }

    func followedChannels() async throws -> [ChannelStatus] { try await respond(MockData.following) }

    func watch(channel: Channel.ID) async throws -> ChannelWatch {
        guard let watch = MockData.watch(channel) else { throw APIError(status: 404, code: "not_found", message: "Канал не найден") }
        return try await respond(watch)
    }

    func setFollowing(_ following: Bool, channel: Channel.ID) async throws -> FollowState {
        try await respond(FollowState(isFollowing: following, followers: following ? 1 : 0))
    }

    func chatEvents(channel: Channel.ID) -> AsyncStream<ChatServerEvent> {
        AsyncStream { continuation in
            for event in events { continuation.yield(event) }
            // Поток не заканчивается, пока экран открыт, — как живое подключение.
        }
    }

    func sendMessage(_ text: String, replyTo: ChatMessage.ID?, channel: Channel.ID) async throws { try await respond(()) }

    func createClip(title: String, channel: Channel.ID) async throws -> Clip {
        try await respond(Clip(id: "c1", title: title, channel: MockData.Channels.timur, author: nil, status: .processing, url: nil, durationSeconds: 30, views: 0))
    }

    func clip(_ id: Clip.ID) async throws -> Clip {
        try await respond(Clip(id: id, title: "Клип", channel: MockData.Channels.timur, author: nil, status: .ready, url: nil, durationSeconds: 30, views: 1))
    }

    func countClipView(_ id: Clip.ID) async {}

    func setReminder(_ on: Bool, for scheduled: ScheduledStream.ID) async throws -> ReminderState {
        try await respond(ReminderState(isReminded: on, reminders: on ? 1 : 0))
    }

    func vote(prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws -> Prediction {
        var result = MockData.prediction
        result.myOutcomeId = outcome
        return try await respond(result)
    }

    func report(message: ChatMessage.ID, reason: ReportReason) async throws { try await respond(()) }
    func deleteMessage(_ message: ChatMessage.ID) async throws { try await respond(()) }
    func block(username: String) async throws { try await respond(()) }
    func unblock(username: String) async throws { try await respond(()) }
    func blockedUsers() async throws -> [BlockedUser] { try await respond([]) }

    func registerDevice(token: String, environment: PushEnvironment) async throws { try await respond(()) }
    func unregisterDevice(token: String) async throws { try await respond(()) }
    func setActivityStartToken(_ token: String?, device: String) async throws { try await respond(()) }
    func registerLiveActivity(token: String, channel: String, environment: PushEnvironment) async throws { try await respond(()) }
    func liveNotificationsEnabled() async throws -> Bool { try await respond(true) }
    func setLiveNotifications(_ enabled: Bool) async throws { try await respond(()) }

    func studio() async throws -> Studio { try await respond(MockData.studio) }
    func updateStudio(_ settings: Studio.Settings) async throws { try await respond(()) }
    func rotateStreamKey() async throws -> String { try await respond("demo?key=new") }
    func createPrediction(question: String, outcomes: [String], duration: Duration) async throws { try await respond(()) }
    func resolvePrediction(_ prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws { try await respond(()) }
    func cancelPrediction(_ prediction: Prediction.ID) async throws { try await respond(()) }
    func addMoment(_ text: String) async throws { try await respond(()) }
    func ban(username: String, minutes: Int?) async throws { try await respond(()) }
    func updateModeration(_ patch: ModerationPatch) async throws -> ModerationSettings {
        var settings = MockData.studio.moderation
        settings.slowModeSeconds = patch.slowModeSeconds ?? settings.slowModeSeconds
        settings.followersOnly = patch.followersOnly ?? settings.followersOnly
        settings.blockedWords = patch.blockedWords ?? settings.blockedWords
        return try await respond(settings)
    }
    func channelStats() async throws -> ChannelStats { try await respond(MockData.stats) }
    func unban(username: String) async throws { try await respond(()) }
    func raid(target: String) async throws -> Int { try await respond(42) }
    func uploadAvatar(_ jpeg: Data) async throws -> URL? { try await respond(nil) }
    func removeAvatar() async throws { try await respond(()) }
    func uploadBanner(_ jpeg: Data) async throws -> URL? { try await respond(nil) }
    func removeBanner() async throws { try await respond(()) }
    func updateAbout(description: String, links: [ChannelAbout.Link]) async throws { try await respond(()) }
    func scheduleStream(title: String, categoryId: String, startsAt: Date) async throws { try await respond(()) }
    func deleteScheduled(_ id: ScheduledStream.ID) async throws { try await respond(()) }
    func addEmote(code: String, png: Data) async throws { try await respond(()) }
    func removeEmote(code: String) async throws { try await respond(()) }

    private func respond<Value: Sendable>(_ value: Value) async throws -> Value {
        if latency > .zero {
            try await Task.sleep(for: latency)
        }
        if let failure { throw failure }
        return value
    }
}

extension MockStreamRepository {
    /// Без задержки — для превью и тестов.
    static let instant = MockStreamRepository(latency: .zero)
}
