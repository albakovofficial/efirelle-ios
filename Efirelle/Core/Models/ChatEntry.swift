/// Запись в чате: сообщение участника или событие канала (рейд).
enum ChatEntry: Identifiable, Hashable, Sendable {
    case message(ChatMessage)
    case event(ChatEvent)

    var id: String {
        switch self {
        case .message(let message): message.id
        case .event(let event): event.id
        }
    }

    /// «Важное»: события канала, сообщения автора эфира и модераторов.
    var isImportant: Bool {
        switch self {
        case .event: true
        case .message(let message): message.badge?.isPrivileged ?? false
        }
    }
}

struct ChatMessage: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let author: String
    /// Адрес канала автора — для блокировки и запрета писать.
    let authorSlug: String
    let authorId: String
    let tone: Tone
    let badge: ChatBadge?
    let text: String
    /// Ответ на сообщение: кому и начало исходного текста.
    var replyTo: Reply?

    struct Reply: Hashable, Sendable, Decodable {
        let id: String
        let author: String
        let text: String
    }
}

/// Служебное событие — живёт только на экране.
struct ChatEvent: Identifiable, Hashable, Sendable {
    let id: String
    let tone: Tone
    let text: String
    /// Канал, куда ушёл рейд.
    var channel: Channel.ID?
}

enum ChatBadge: String, Hashable, Sendable, Decodable {
    case broadcaster
    case moderator
    case newcomer

    private enum CodingKeys: String, CodingKey { case type }

    init(from decoder: any Decoder) throws {
        let raw = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .type)
        guard let badge = ChatBadge(rawValue: raw) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Неизвестный значок \(raw)"))
        }
        self = badge
    }

    var isPrivileged: Bool { self != .newcomer }

    var title: String {
        switch self {
        case .broadcaster: "АВТОР"
        case .moderator: "МОД"
        case .newcomer: "НОВЫЙ"
        }
    }

    var tone: Tone {
        switch self {
        case .broadcaster: .rose
        case .moderator: .mint
        case .newcomer: .sky
        }
    }
}
