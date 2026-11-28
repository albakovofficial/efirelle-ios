import Foundation
import Testing
@testable import Efirelle

@MainActor
@Suite("Недавние запросы")
struct RecentSearchesTests {
    private func makeStore() -> RecentSearches {
        let defaults = UserDefaults(suiteName: "RecentSearchesTests-\(UUID().uuidString)")!
        return RecentSearches(defaults: defaults)
    }

    @Test("Новые первыми, без повторов и не больше лимита")
    func order() {
        let recent = makeStore()
        for index in 0..<10 { recent.add("запрос \(index)") }
        recent.add("ЗАПРОС 5")
        #expect(recent.items.first == "ЗАПРОС 5")
        #expect(recent.items.count == RecentSearches.limit)
        let duplicates = recent.items.filter { $0.lowercased() == "запрос 5" }.count
        #expect(duplicates == 1)
    }

    @Test("Короткие запросы не запоминаются, очистка убирает всё")
    func clear() {
        let recent = makeStore()
        recent.add("а")
        #expect(recent.items.isEmpty)
        recent.add("мира")
        recent.clear()
        #expect(recent.items.isEmpty)
    }
}
