import Testing
@testable import Efirelle

@Suite("Форматирование")
struct FormattersTests {
    @Test("Склонение по числу", arguments: [
        (1, "зритель"), (2, "зрителя"), (4, "зрителя"), (5, "зрителей"),
        (11, "зрителей"), (12, "зрителей"), (21, "зритель"), (22, "зрителя"), (111, "зрителей"),
    ])
    func pluralForms(number: Int, expected: String) {
        #expect(PluralForms.viewers.form(for: number) == expected)
    }

    @Test("После «тыс.» слово всегда во множественном числе")
    func compactCountUsesManyForm() {
        let text = Formatters.count(18_702, .viewers)
        #expect(text.hasSuffix("зрителей"))
        #expect(text.contains("18,7"))
    }

    @Test("Без сокращения число выводится полностью")
    func fullCount() {
        #expect(Formatters.count(22, .viewers, compact: false) == "22 зрителя")
    }

    @Test("Длительность в формате часов и минут", arguments: [
        (13_690, "3:48:10"), (754, "12:34"), (0, "0:00"), (3_600, "1:00:00"),
    ])
    func clock(seconds: Int, expected: String) {
        #expect(Formatters.clock(.seconds(seconds)) == expected)
    }
}
