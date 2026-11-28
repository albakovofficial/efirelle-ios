import Foundation

/// Идущий сейчас эфир.
struct LiveStream: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let channel: Channel
    let title: String
    let category: String
    let categoryID: String
    let tags: [String]
    let viewers: Int
    /// Сколько идёт эфир на момент загрузки.
    let duration: Duration
    /// Коротко о том, что происходит сейчас, — для списков.
    let status: String
    /// Тон обложки, пока нет кадра-превью.
    let tone: Tone
    /// Адрес HLS-потока. `nil` — показываем обложку вместо видео (превью и тесты).
    let playbackURL: URL?
    /// Качества эфира; первое — исходное. Больше одного — когда на сервере включено перекодирование.
    let qualities: [Quality]

    /// Один из вариантов качества: «Источник», «720p», «480p».
    struct Quality: Hashable, Sendable, Decodable {
        let label: String
        let url: URL
    }

    init(
        id: String, channel: Channel, title: String, category: String, categoryID: String, tags: [String],
        viewers: Int, duration: Duration, status: String, tone: Tone, playbackURL: URL? = nil, qualities: [Quality] = []
    ) {
        self.id = id
        self.channel = channel
        self.title = title
        self.category = category
        self.categoryID = categoryID
        self.tags = tags
        self.viewers = viewers
        self.duration = duration
        self.status = status
        self.tone = tone
        self.playbackURL = playbackURL
        self.qualities = qualities
    }

    private enum CodingKeys: String, CodingKey {
        case id, channel, title, category, categoryId, tags, viewers, durationSeconds, status, tone, playbackUrl, qualities
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        channel = try container.decode(Channel.self, forKey: .channel)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        categoryID = try container.decode(String.self, forKey: .categoryId)
        tags = try container.decode([String].self, forKey: .tags)
        viewers = try container.decode(Int.self, forKey: .viewers)
        duration = .seconds(try container.decode(Int.self, forKey: .durationSeconds))
        status = try container.decode(String.self, forKey: .status)
        tone = try container.decode(Tone.self, forKey: .tone)
        playbackURL = try container.decodeIfPresent(URL.self, forKey: .playbackUrl)
        qualities = try container.decodeIfPresent([Quality].self, forKey: .qualities) ?? []
    }
}
