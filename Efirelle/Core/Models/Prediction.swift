/// Прогноз зрителей с вариантами ответа.
struct Prediction: Identifiable, Hashable, Sendable {
    struct Outcome: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        /// Доля голосов, 0...100.
        let percent: Int
        let tone: Tone
    }

    let id: String
    let question: String
    let timeLeft: Duration
    let participants: Int
    let outcomes: [Outcome]
}
