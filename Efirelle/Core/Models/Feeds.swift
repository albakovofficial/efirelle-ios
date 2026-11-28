import Foundation

/// Ответы API, которые собирают экран целиком.

struct HomeFeed: Hashable, Sendable, Decodable {
    /// Отслеживаемые каналы в эфире (пусто без входа).
    let following: [ChannelStatus]
    /// Первый элемент — главный эфир витрины.
    let featured: [LiveStream]
    let moments: [Moment]
    let categories: [StreamCategory]
    let forYou: [LiveStream]
    let upcoming: [ScheduledStream]
    let clips: [Clip]
}

struct CategoryStreams: Hashable, Sendable, Decodable {
    let category: StreamCategory
    let streams: [LiveStream]
}

struct SearchResults: Hashable, Sendable, Decodable {
    let query: String
    let streams: [LiveStream]
    let channels: [ChannelStatus]
    let categories: [StreamCategory]

    var isEmpty: Bool { streams.isEmpty && channels.isEmpty && categories.isEmpty }
}

/// Всё для экрана канала одним запросом.
struct ChannelWatch: Hashable, Sendable, Decodable {
    let channel: Channel
    let stream: LiveStream?
    let isFollowing: Bool
    let isOwner: Bool
    let markers: [Moment]
    let prediction: Prediction?
    let chat: [ChatMessage]
    let about: ChannelAbout
    let emotes: [Emote]
    let schedule: [ScheduledStream]
    let recordings: [Recording]
    let clips: [Clip]
}

struct FollowState: Hashable, Sendable, Decodable {
    let isFollowing: Bool
    let followers: Int
}

/// Студия автора.
struct Studio: Hashable, Sendable, Decodable {
    struct Settings: Hashable, Sendable, Codable {
        var title: String
        var categoryId: String
        var tags: [String]
    }

    struct Ingest: Hashable, Sendable, Decodable {
        /// «Сервер» в OBS.
        let server: String
        /// «Ключ потока» в OBS.
        var streamKey: String
    }

    struct Ban: Identifiable, Hashable, Sendable, Decodable {
        let slug: String
        let name: String
        /// ISO-дата окончания; `nil` — навсегда.
        let until: String?

        var id: String { slug }
    }

    let channel: Channel
    let stream: LiveStream?
    var settings: Settings
    var ingest: Ingest
    let prediction: Prediction?
    let bans: [Ban]
    let about: ChannelAbout
    let emotes: [Emote]
    let schedule: [ScheduledStream]
}

/// Оформление канала: описание, ссылки, баннер.
struct ChannelAbout: Hashable, Sendable, Codable {
    struct Link: Hashable, Sendable, Codable {
        var title: String
        var url: String
    }

    var description: String
    var links: [Link]
    var bannerUrl: URL?

    var isEmpty: Bool { description.isEmpty && links.isEmpty && bannerUrl == nil }
}

/// Эмодзи канала: в чате пишется как :code:.
struct Emote: Hashable, Sendable, Decodable, Identifiable {
    let code: String
    let url: URL

    var id: String { code }
}

/// Анонс эфира.
struct ScheduledStream: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let channel: Channel
    let title: String
    let category: String
    let categoryId: String
    let startsAt: Date
    var reminders: Int
    var isReminded: Bool

    private enum CodingKeys: String, CodingKey {
        case id, channel, title, category, categoryId, startsAt, reminders, isReminded
    }

    init(id: String, channel: Channel, title: String, category: String, categoryId: String, startsAt: Date, reminders: Int, isReminded: Bool) {
        self.id = id
        self.channel = channel
        self.title = title
        self.category = category
        self.categoryId = categoryId
        self.startsAt = startsAt
        self.reminders = reminders
        self.isReminded = isReminded
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        channel = try container.decode(Channel.self, forKey: .channel)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        let raw = try container.decode(String.self, forKey: .startsAt)
        guard let date = ISODate.parse(raw) else {
            throw DecodingError.dataCorruptedError(forKey: .startsAt, in: container, debugDescription: "Неверная дата \(raw)")
        }
        startsAt = date
        reminders = try container.decode(Int.self, forKey: .reminders)
        isReminded = try container.decode(Bool.self, forKey: .isReminded)
    }
}

/// Запись завершённого эфира (хранится 3 дня).
struct Recording: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let title: String
    let category: String
    let startedAt: String
    let durationSeconds: Int
    let peakViewers: Int
    let url: URL

    var startDate: Date? { ISODate.parse(startedAt) }
}

/// Клип — 30 секунд эфира отдельным файлом.
struct Clip: Identifiable, Hashable, Sendable, Decodable {
    enum Status: String, Hashable, Sendable, Decodable {
        case processing, ready, failed
    }

    let id: String
    let title: String
    let channel: Channel
    let author: String?
    let status: Status
    let url: URL?
    let durationSeconds: Int
    let views: Int

    /// Ссылка, которой делятся.
    var shareURL: URL { URL(string: "https://efirelle.ru/clip/\(id)")! }
}
