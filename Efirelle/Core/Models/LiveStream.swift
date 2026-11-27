import Foundation

/// Идущий сейчас эфир.
struct LiveStream: Identifiable, Hashable, Sendable {
    let id: String
    let channel: Channel
    let title: String
    let category: String
    let tags: [String]
    let viewers: Int
    /// Сколько идёт эфир.
    let duration: Duration
    let quality: String
    let latency: Duration
    /// Коротко о том, что происходит сейчас, — для списков.
    let status: String
    /// Тон обложки, пока нет кадра-превью.
    let tone: Tone
    /// Адрес HLS-потока. `nil` — показываем обложку вместо видео.
    let playbackURL: URL?
}
