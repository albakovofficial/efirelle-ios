/// Запись в чате: сообщение участника или событие канала.
enum ChatEntry: Identifiable, Hashable, Sendable {
    case message(ChatMessage)
    case event(ChatEvent)

    var id: String {
        switch self {
        case .message(let message): message.id
        case .event(let event): event.id
        }
    }

    /// «Важное»: события канала, сообщения модераторов и VIP.
    var isImportant: Bool {
        switch self {
        case .event: true
        case .message(let message): message.badge?.isPrivileged ?? false
        }
    }
}

struct ChatMessage: Identifiable, Hashable, Sendable {
    let id: String
    let author: String
    let tone: Tone
    let badge: ChatBadge?
    let text: String
}

struct ChatEvent: Identifiable, Hashable, Sendable {
    let id: String
    let tone: Tone
    let text: String
}

enum ChatBadge: Hashable, Sendable {
    case moderator
    case vip
    case newcomer
    case subscriber(months: Int)

    var isPrivileged: Bool {
        switch self {
        case .moderator, .vip: true
        case .newcomer, .subscriber: false
        }
    }

    var title: String {
        switch self {
        case .moderator: "МОД"
        case .vip: "VIP"
        case .newcomer: "НОВЫЙ"
        case .subscriber(let months): "\(months) МЕС"
        }
    }

    var tone: Tone {
        switch self {
        case .moderator: .mint
        case .vip: .butter
        case .newcomer: .sky
        case .subscriber: .lavender
        }
    }
}
