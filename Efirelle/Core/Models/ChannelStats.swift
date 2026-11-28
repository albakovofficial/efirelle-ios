import Foundation

/// Статистика канала: сводка за неделю и лента прошедших эфиров.
struct ChannelStats: Hashable, Sendable, Decodable {
    /// Значение за эту неделю и за прошлую — для стрелки «больше/меньше».
    struct Weekly<Value: Hashable & Sendable & Decodable & Comparable>: Hashable, Sendable, Decodable {
        let week: Value
        let previousWeek: Value
    }

    struct Peak: Hashable, Sendable, Decodable {
        let viewers: Int
        let at: String?
    }

    struct Summary: Hashable, Sendable, Decodable {
        let followers: Int
        let newFollowers: Weekly<Int>
        let avgViewers: Weekly<Int>
        let peak: Peak
        let hoursLive: Weekly<Double>
    }

    struct Stream: Identifiable, Hashable, Sendable, Decodable {
        let id: String
        let title: String
        let category: String
        let startedAt: String
        let durationSeconds: Int
        let peakViewers: Int
        let avgViewers: Int
        let newFollowers: Int
        /// Зрители по ходу эфира, равными отрезками.
        let points: [Int]

        var startDate: Date? { ISODate.parse(startedAt) }
    }

    let summary: Summary
    let streams: [Stream]
}

/// Страница рекомендованных эфиров для «Сейчас в эфире».
struct RecommendedStreams: Hashable, Sendable, Decodable {
    let streams: [LiveStream]
    let total: Int
}
