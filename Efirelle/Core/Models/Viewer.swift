/// Текущий пользователь приложения.
struct Viewer: Hashable, Sendable {
    let name: String
    let initials: String
    let tone: Tone
    /// Баланс искр — внутренней валюты для прогнозов и наград.
    let sparks: Int
}
