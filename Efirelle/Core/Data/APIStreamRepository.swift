import Foundation

/// Репозиторий поверх API efirelle.ru.
struct APIStreamRepository: StreamRepository {
    var client: APIClient = .production

    private struct AuthResult: Decodable { let token: String; let user: Viewer }
    private struct UserResult: Decodable { let user: Viewer }
    private struct ChannelsResult: Decodable { let channels: [ChannelStatus] }
    private struct CategoriesResult: Decodable { let categories: [StreamCategory] }
    private struct PredictionResult: Decodable { let prediction: Prediction }
    private struct UsersResult: Decodable { let users: [BlockedUser] }
    private struct KeyResult: Decodable { let streamKey: String }
    private struct RaidResult: Decodable { let viewers: Int }
    private struct NotificationPreferences: Codable { let live: Bool }
    private struct DeviceBody: Encodable { let token: String; let environment: PushEnvironment }
    private struct ActivityStartBody: Encodable { let startToken: String? }
    private struct LiveActivityBody: Encodable { let token: String; let channel: String; let environment: PushEnvironment }

    // MARK: Аккаунт

    func currentViewer() async throws -> Viewer? {
        guard client.tokens.load() != nil else { return nil }
        do {
            let result: UserResult = try await client.get("/api/me")
            return result.user
        } catch let error as APIError where error.isUnauthorized {
            // Сессия истекла или аккаунт заблокирован — забываем ключ.
            client.tokens.delete()
            return nil
        }
    }

    func login(email: String, password: String) async throws -> Viewer {
        try await authenticate("/api/auth/login", body: ["email": email, "password": password])
    }

    func register(_ form: RegistrationForm) async throws -> Viewer {
        try await authenticate("/api/auth/register", body: form)
    }

    func logout() async {
        try? await client.perform("POST", "/api/auth/logout", body: [String: String]())
        client.tokens.delete()
    }

    func requestPasswordReset(email: String) async throws {
        try await client.perform("POST", "/api/auth/password/forgot", body: ["email": email])
    }

    func resetPassword(email: String, code: String, password: String) async throws -> Viewer {
        try await authenticate("/api/auth/password/reset", body: ["email": email, "code": code, "password": password])
    }

    func deleteAccount(password: String) async throws {
        try await client.perform("DELETE", "/api/me", body: ["password": password])
        client.tokens.delete()
    }

    private func authenticate(_ path: String, body: some Encodable) async throws -> Viewer {
        let result: AuthResult = try await client.send("POST", path, body: body)
        client.tokens.save(result.token)
        return result.user
    }

    // MARK: Витрина

    func home() async throws -> HomeFeed {
        try await client.get("/api/home")
    }

    func categories() async throws -> [StreamCategory] {
        let result: CategoriesResult = try await client.get("/api/categories")
        return result.categories
    }

    func category(id: StreamCategory.ID) async throws -> CategoryStreams {
        try await client.get("/api/categories/\(id)")
    }

    func search(_ query: String) async throws -> SearchResults {
        try await client.get("/api/search", query: [URLQueryItem(name: "q", value: query)])
    }

    func recommendedStreams(offset: Int, limit: Int) async throws -> RecommendedStreams {
        try await client.get("/api/streams/recommended", query: [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit)),
        ])
    }

    func followedChannels() async throws -> [ChannelStatus] {
        let result: ChannelsResult = try await client.get("/api/me/following")
        return result.channels
    }

    // MARK: Канал и чат

    func watch(channel: Channel.ID) async throws -> ChannelWatch {
        try await client.get("/api/channels/\(channel)/watch")
    }

    func setFollowing(_ following: Bool, channel: Channel.ID) async throws -> FollowState {
        try await client.send(following ? "PUT" : "DELETE", "/api/channels/\(channel)/follow")
    }

    func chatEvents(channel: Channel.ID) -> AsyncStream<ChatServerEvent> {
        ChatSocket.events(for: client.socketRequest("/api/channels/\(channel)/ws"), session: client.session)
    }

    func sendMessage(_ text: String, replyTo: ChatMessage.ID?, channel: Channel.ID) async throws {
        struct Body: Encodable { let text: String; let replyTo: String? }
        try await client.perform("POST", "/api/channels/\(channel)/chat", body: Body(text: text, replyTo: replyTo))
    }

    // MARK: Клипы

    private struct ClipResult: Decodable { let clip: Clip }

    func createClip(title: String, channel: Channel.ID) async throws -> Clip {
        let result: ClipResult = try await client.send("POST", "/api/channels/\(channel)/clips", body: ["title": title])
        return result.clip
    }

    func clip(_ id: Clip.ID) async throws -> Clip {
        let result: ClipResult = try await client.get("/api/clips/\(id)")
        return result.clip
    }

    func countClipView(_ id: Clip.ID) async {
        try? await client.perform("POST", "/api/clips/\(id)/view", body: [String: String]())
    }

    // MARK: Расписание

    func setReminder(_ on: Bool, for scheduled: ScheduledStream.ID) async throws -> ReminderState {
        try await client.send(on ? "PUT" : "DELETE", "/api/schedule/\(scheduled)/remind")
    }

    func vote(prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws -> Prediction {
        let result: PredictionResult = try await client.send("POST", "/api/predictions/\(prediction)/vote", body: ["outcomeId": outcome])
        return result.prediction
    }

    // MARK: Модерация

    func report(message: ChatMessage.ID, reason: ReportReason) async throws {
        try await client.perform("POST", "/api/chat/messages/\(message)/report", body: ["reason": reason])
    }

    func deleteMessage(_ message: ChatMessage.ID) async throws {
        try await client.perform("DELETE", "/api/chat/messages/\(message)")
    }

    func block(username: String) async throws {
        try await client.perform("PUT", "/api/me/blocks/\(username)")
    }

    func unblock(username: String) async throws {
        try await client.perform("DELETE", "/api/me/blocks/\(username)")
    }

    func blockedUsers() async throws -> [BlockedUser] {
        let result: UsersResult = try await client.get("/api/me/blocks")
        return result.users
    }

    // MARK: Уведомления

    func registerDevice(token: String, environment: PushEnvironment) async throws {
        try await client.perform("PUT", "/api/me/devices", body: DeviceBody(token: token, environment: environment))
    }

    func unregisterDevice(token: String) async throws {
        try await client.perform("DELETE", "/api/me/devices/\(token)")
    }

    func setActivityStartToken(_ token: String?, device: String) async throws {
        try await client.perform("PUT", "/api/me/devices/\(device)/live-activity", body: ActivityStartBody(startToken: token))
    }

    func registerLiveActivity(token: String, channel: String, environment: PushEnvironment) async throws {
        try await client.perform(
            "PUT",
            "/api/me/live-activities",
            body: LiveActivityBody(token: token, channel: channel, environment: environment)
        )
    }

    func liveNotificationsEnabled() async throws -> Bool {
        let result: NotificationPreferences = try await client.get("/api/me/notifications")
        return result.live
    }

    func setLiveNotifications(_ enabled: Bool) async throws {
        let _: NotificationPreferences = try await client.send("PUT", "/api/me/notifications", body: NotificationPreferences(live: enabled))
    }

    // MARK: Студия

    func studio() async throws -> Studio {
        try await client.get("/api/studio")
    }

    func updateStudio(_ settings: Studio.Settings) async throws {
        let _: ChannelStatus = try await client.send("PATCH", "/api/studio", body: settings)
    }

    func rotateStreamKey() async throws -> String {
        let result: KeyResult = try await client.send("POST", "/api/studio/stream-key", body: [String: String]())
        return result.streamKey
    }

    func createPrediction(question: String, outcomes: [String], duration: Duration) async throws {
        struct Body: Encodable { let question: String; let outcomes: [String]; let durationSeconds: Int64 }
        let body = Body(question: question, outcomes: outcomes, durationSeconds: duration.components.seconds)
        try await client.perform("POST", "/api/studio/predictions", body: body)
    }

    func resolvePrediction(_ prediction: Prediction.ID, outcome: Prediction.Outcome.ID) async throws {
        try await client.perform("POST", "/api/studio/predictions/\(prediction)/resolve", body: ["outcomeId": outcome])
    }

    func cancelPrediction(_ prediction: Prediction.ID) async throws {
        try await client.perform("POST", "/api/studio/predictions/\(prediction)/cancel", body: [String: String]())
    }

    func addMoment(_ text: String) async throws {
        try await client.perform("POST", "/api/studio/moments", body: ["text": text])
    }

    func ban(username: String, minutes: Int?) async throws {
        try await client.perform("POST", "/api/studio/bans", body: NullableBan(username: username, minutes: minutes))
    }

    func updateModeration(_ patch: ModerationPatch) async throws -> ModerationSettings {
        try await client.send("PATCH", "/api/studio/moderation", body: patch)
    }

    func channelStats() async throws -> ChannelStats {
        try await client.get("/api/studio/stats")
    }

    func unban(username: String) async throws {
        try await client.perform("DELETE", "/api/studio/bans/\(username)")
    }

    func raid(target: String) async throws -> Int {
        let result: RaidResult = try await client.send("POST", "/api/studio/raid", body: ["target": target])
        return result.viewers
    }

    func uploadAvatar(_ jpeg: Data) async throws -> URL? {
        struct Result: Decodable { let avatarUrl: URL? }
        let result: Result = try await client.upload("PUT", "/api/me/avatar", image: jpeg, contentType: "image/jpeg")
        return result.avatarUrl
    }

    func removeAvatar() async throws {
        try await client.perform("DELETE", "/api/me/avatar")
    }

    func uploadBanner(_ jpeg: Data) async throws -> URL? {
        struct Result: Decodable { let bannerUrl: URL? }
        let result: Result = try await client.upload("PUT", "/api/studio/banner", image: jpeg, contentType: "image/jpeg")
        return result.bannerUrl
    }

    func removeBanner() async throws {
        try await client.perform("DELETE", "/api/studio/banner")
    }

    func updateAbout(description: String, links: [ChannelAbout.Link]) async throws {
        struct Body: Encodable { let description: String; let links: [ChannelAbout.Link] }
        let _: ChannelAbout = try await client.send("PATCH", "/api/studio/profile", body: Body(description: description, links: links))
    }

    func scheduleStream(title: String, categoryId: String, startsAt: Date) async throws {
        struct Body: Encodable { let title: String; let categoryId: String; let startsAt: String }
        let body = Body(title: title, categoryId: categoryId, startsAt: startsAt.ISO8601Format())
        try await client.perform("POST", "/api/studio/schedule", body: body)
    }

    func deleteScheduled(_ id: ScheduledStream.ID) async throws {
        try await client.perform("DELETE", "/api/studio/schedule/\(id)")
    }

    func addEmote(code: String, png: Data) async throws {
        struct Result: Decodable {}
        let _: Result = try await client.upload(
            "POST", "/api/studio/emotes", query: [URLQueryItem(name: "code", value: code)], image: png, contentType: "image/png"
        )
    }

    func removeEmote(code: String) async throws {
        try await client.perform("DELETE", "/api/studio/emotes/\(code)")
    }
}

/// Тело запроса бана: `minutes` кодируется как `null`, а не пропускается.
private struct NullableBan: Encodable {
    let username: String
    let minutes: Int?

    private enum CodingKeys: String, CodingKey { case username, minutes }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(minutes, forKey: .minutes)
    }
}
