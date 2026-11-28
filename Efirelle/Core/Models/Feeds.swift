/// Ответы API, которые собирают экран целиком.

struct HomeFeed: Hashable, Sendable, Decodable {
    /// Отслеживаемые каналы в эфире (пусто без входа).
    let following: [ChannelStatus]
    /// Первый элемент — главный эфир витрины.
    let featured: [LiveStream]
    let moments: [Moment]
    let categories: [StreamCategory]
    let forYou: [LiveStream]
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
}
