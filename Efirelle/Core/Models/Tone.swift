/// Пастельный тон обложки или аватара. Конкретные цвета задаёт `Palette`.
enum Tone: String, Sendable, Hashable, CaseIterable, Decodable {
    case ink
    case lavender
    case peach
    case mint
    case sky
    case butter
    case rose

    /// Неизвестный тон от сервера не ломает экран — берём нейтральный.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Tone(rawValue: raw) ?? .lavender
    }
}
