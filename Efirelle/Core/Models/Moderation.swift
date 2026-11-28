/// Правила чата канала, которые видят зрители.
struct ChatRules: Hashable, Sendable, Codable {
    /// Секунд между сообщениями одного зрителя; 0 — медленный режим выключен.
    var slowModeSeconds: Int
    var followersOnly: Bool

    static let none = ChatRules(slowModeSeconds: 0, followersOnly: false)
    /// Варианты медленного режима — те же, что принимает сервер.
    static let slowModeOptions = [0, 5, 10, 30, 60]

    /// Подсказка в поле ввода, например «Медленный режим 10 с · только подписчики».
    var hint: String? {
        let parts = [
            slowModeSeconds > 0 ? "медленный режим \(slowModeSeconds) с" : nil,
            followersOnly ? "только подписчики" : nil,
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ").capitalizedFirst
    }
}

/// Настройки модерации в студии.
struct ModerationSettings: Hashable, Sendable, Codable {
    var slowModeSeconds: Int
    var followersOnly: Bool
    var blockedWords: [String]
    /// Сколько сообщений фильтр скрыл за текущий или последний эфир.
    let hiddenThisStream: Int

    var rules: ChatRules { ChatRules(slowModeSeconds: slowModeSeconds, followersOnly: followersOnly) }
}

/// Изменение настроек модерации: передаются только заданные поля.
struct ModerationPatch: Sendable, Encodable {
    var slowModeSeconds: Int?
    var followersOnly: Bool?
    var blockedWords: [String]?
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
