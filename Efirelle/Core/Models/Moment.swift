/// Событие эфира: попадает в ленту «Живые моменты» и в список моментов эфира.
struct Moment: Identifiable, Hashable, Sendable, Decodable {
    enum Kind: String, Sendable, Hashable, Decodable {
        case raid
        case prediction
        case chatPeak
        case giveaway
        case highlight
    }

    let id: String
    let kind: Kind
    let text: String
    let channel: Channel
    /// Человекочитаемое время: «2 мин назад».
    let when: String
    /// Смещение от начала эфира.
    let offset: Duration

    init(id: String, kind: Kind, text: String, channel: Channel, when: String, offset: Duration) {
        self.id = id
        self.kind = kind
        self.text = text
        self.channel = channel
        self.when = when
        self.offset = offset
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, text, channel, when, offsetSeconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        text = try container.decode(String.self, forKey: .text)
        channel = try container.decode(Channel.self, forKey: .channel)
        when = try container.decode(String.self, forKey: .when)
        offset = .seconds(try container.decode(Int.self, forKey: .offsetSeconds))
    }
}

extension Moment.Kind {
    var title: String {
        switch self {
        case .raid: "Рейд"
        case .prediction: "Прогноз"
        case .chatPeak: "Пик чата"
        case .giveaway: "Розыгрыш"
        case .highlight: "Момент"
        }
    }

    var tone: Tone {
        switch self {
        case .raid: .rose
        case .prediction: .sky
        case .chatPeak: .butter
        case .giveaway: .mint
        case .highlight: .lavender
        }
    }
}
