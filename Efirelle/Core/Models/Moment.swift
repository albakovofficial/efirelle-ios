/// Событие эфира: попадает в ленту «Живые моменты» и на таймлайн плеера.
struct Moment: Identifiable, Hashable, Sendable {
    enum Kind: Sendable, Hashable {
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
    /// Человекочитаемое время: «2 мин назад», «идёт сейчас».
    let when: String
    /// Смещение от начала эфира — для перемотки.
    let offset: Duration
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
