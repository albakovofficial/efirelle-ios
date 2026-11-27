import Foundation
import Observation

/// Заблокированные авторы. Хранятся на устройстве и действуют во всех чатах.
/// Когда появятся аккаунты, блокировка будет синхронизироваться с сервером.
@MainActor
@Observable
final class ModerationStore {
    static let shared = ModerationStore()

    private static let blockedKey = "moderation.blockedAuthors"

    private let defaults: UserDefaults
    private(set) var blockedAuthors: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        blockedAuthors = Set(defaults.stringArray(forKey: Self.blockedKey) ?? [])
    }

    func isBlocked(_ author: String) -> Bool {
        blockedAuthors.contains(author)
    }

    func block(_ author: String) {
        blockedAuthors.insert(author)
        save()
    }

    func unblock(_ author: String) {
        blockedAuthors.remove(author)
        save()
    }

    private func save() {
        defaults.set(blockedAuthors.sorted(), forKey: Self.blockedKey)
    }
}
