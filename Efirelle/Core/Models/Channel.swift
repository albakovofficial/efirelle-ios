/// Канал автора. `id` — адрес канала (efirelle.ru/live/<id>).
struct Channel: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let name: String
    let initials: String
    let tone: Tone
    let followers: Int
    let isVerified: Bool

    init(id: String, name: String, initials: String, tone: Tone, followers: Int, isVerified: Bool = false) {
        self.id = id
        self.name = name
        self.initials = initials
        self.tone = tone
        self.followers = followers
        self.isVerified = isVerified
    }

    private enum CodingKeys: String, CodingKey {
        case slug, name, initials, tone, followers, verified
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        initials = try container.decode(String.self, forKey: .initials)
        tone = try container.decode(Tone.self, forKey: .tone)
        followers = try container.decode(Int.self, forKey: .followers)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
    }
}

/// Канал вместе с текущим эфиром; `stream == nil` — канал не в сети.
struct ChannelStatus: Identifiable, Hashable, Sendable, Decodable {
    let channel: Channel
    let stream: LiveStream?

    var id: Channel.ID { channel.id }
}
