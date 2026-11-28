/// Категория эфиров: «Стратегии», «Музыка» и т. д.
struct StreamCategory: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let name: String
    let group: String
    let viewers: Int
    let liveCount: Int
    let tone: Tone
}
