import Foundation

/// Вошедший пользователь.
struct Viewer: Identifiable, Hashable, Sendable, Decodable {
    enum Role: String, Sendable, Hashable, Decodable {
        case user
        case admin
    }

    let id: String
    let email: String
    let username: String
    let displayName: String
    let initials: String
    let role: Role
    let tone: Tone
    /// Баланс искр — внутренних баллов за верные прогнозы. Не покупаются и не выводятся.
    let sparks: Int
    let avatarUrl: URL?
}

/// Пользователь, чьи сообщения зритель скрыл.
struct BlockedUser: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let slug: String
    let name: String
}
