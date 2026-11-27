import Testing
@testable import Efirelle

@Suite("Фильтр сообщений")
struct ContentFilterTests {
    @Test("Обычные сообщения проходят", arguments: [
        "привет всем!",
        "колебания курса и корабля не страшны",
        "оскорблять нельзя, это правило",
        "мандарины и команда",
        "GG, если возьмёт эту карту",
        "",
    ])
    func allowsClean(_ text: String) {
        #expect(ContentFilter.isAllowed(text))
    }

    @Test("Мат и оскорбления не проходят", arguments: [
        "ну ты и сука",
        "Да заебал уже",
        "БЛЯ",
        "какой пиздец",
        "ты пидор",
        "fuck this",
        "Ёбаный стыд",
    ])
    func blocksProfanity(_ text: String) {
        #expect(ContentFilter.isAllowed(text) == false)
    }
}
