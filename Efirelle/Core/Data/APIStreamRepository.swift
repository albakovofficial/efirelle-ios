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

    func sendMessage(_ text: String, channel: Channel.ID) async throws {
        try await client.perform("POST", "/api/channels/\(channel)/chat", body: ["text": text])
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

    func unban(username: String) async throws {
        try await client.perform("DELETE", "/api/studio/bans/\(username)")
    }

    func raid(target: String) async throws -> Int {
        let result: RaidResult = try await client.send("POST", "/api/studio/raid", body: ["target": target])
        return result.viewers
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
