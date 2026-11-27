/// Быстрые фильтры ленты «Для вас».
enum StreamFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case smallChannels
    case justStarted

    private static let smallChannelMaxViewers = 2_000
    private static let justStartedMaxDuration: Duration = .seconds(60 * 60)

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Все"
        case .smallChannels: "Небольшие"
        case .justStarted: "Только начали"
        }
    }

    func includes(_ stream: LiveStream) -> Bool {
        switch self {
        case .all: true
        case .smallChannels: stream.viewers <= Self.smallChannelMaxViewers
        case .justStarted: stream.duration <= Self.justStartedMaxDuration
        }
    }
}
