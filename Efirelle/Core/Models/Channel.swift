/// Канал автора.
struct Channel: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let initials: String
    let tone: Tone
    let followers: Int
    let isVerified: Bool
}
