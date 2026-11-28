/// Прогноз зрителей. Участие бесплатное, за верный ответ начисляются искры.
struct Prediction: Identifiable, Hashable, Sendable, Decodable {
    enum Status: String, Sendable, Hashable, Decodable {
        /// Идёт приём ответов.
        case open
        /// Время вышло, автор ещё не выбрал верный вариант.
        case locked
        case resolved
        case cancelled
    }

    struct Outcome: Identifiable, Hashable, Sendable, Decodable {
        let id: String
        let label: String
        /// Доля голосов, 0...100.
        let percent: Int
        let votes: Int
        let tone: Tone
    }

    /// Награда за верный ответ (api/src/modules/predictions).
    static let reward = 100

    let id: String
    let question: String
    let status: Status
    /// Сколько секунд оставалось до конца приёма на момент получения.
    let endsInSeconds: Int
    let participants: Int
    let outcomes: [Outcome]
    var myOutcomeId: String?
    let winningOutcomeId: String?

    var isActive: Bool { status == .open || status == .locked }
}
