import ActivityKit
import Foundation

/// Live Activity «канал в эфире» — общая часть приложения и расширения.
/// Сервер запускает и обновляет её пушем; имена полей совпадают с payloads.ts в API.
struct LiveStreamAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var title: String
        var viewers: Int
        /// `false` — эфир закончился, активность скоро исчезнет.
        var isLive: Bool
    }

    /// Адрес канала: по нажатию открывается его эфир.
    let slug: String
    let name: String

    /// Ссылка, которую приложение открывает по нажатию на активность.
    var url: URL { URL(string: "efirelle://channel/\(slug)")! }
}
