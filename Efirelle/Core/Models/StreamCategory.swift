/// Категория эфиров: «Стратегии», «Музыка» и т. д.
struct StreamCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let group: String
    let viewers: Int
    let tone: Tone
}
