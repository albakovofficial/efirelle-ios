import Foundation
import Observation

/// Недавние запросы поиска: хранятся на iPhone, новые первыми, без повторов.
@MainActor
@Observable
final class RecentSearches {
    static let limit = 8
    private static let key = "recentSearches"

    private(set) var items: [String]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        items = defaults.stringArray(forKey: Self.key) ?? []
    }

    func add(_ query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { return }
        items.removeAll { $0.caseInsensitiveCompare(text) == .orderedSame }
        items.insert(text, at: 0)
        items = Array(items.prefix(Self.limit))
        save()
    }

    func remove(_ query: String) {
        items.removeAll { $0 == query }
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func save() {
        defaults.set(items, forKey: Self.key)
    }
}
