import Foundation

/// Фильтр исходящих сообщений чата: не даёт отправить мат и оскорбления (App Review 1.2).
/// Это первая линия защиты на устройстве — сервер чата должен повторять проверку.
enum ContentFilter {
    /// Запрещённые корни. Слово запрещено, если начинается с корня — сразу или после приставки,
    /// поэтому «заебал» ловится, а «колебания» — нет.
    private static let roots: [String] = [
        "хуй", "хуе", "хуя", "хуи", "пизд", "ебан", "ебат", "ебал", "ебло", "ебуч", "ебну",
        "бляд", "блят", "сука", "суки", "сучк", "сучар", "мудак", "мудил", "пидор", "пидар", "пидр",
        "гандон", "шлюх", "залуп",
        "fuck", "shit", "bitch", "cunt", "nigg", "fagg",
    ]

    /// Отдельные слова, которые нельзя ловить по корню без ложных срабатываний.
    private static let bannedWords: Set<String> = ["бля", "еблан", "уебан", "уебок"]

    private static let prefixes: [String] = [
        "", "за", "на", "по", "от", "вы", "у", "при", "под", "раз", "рас", "с", "съ", "до", "про",
        "пере", "недо", "не", "о", "об", "из", "вз", "въ",
    ]

    /// Можно ли отправить текст в чат.
    static func isAllowed(_ text: String) -> Bool {
        !tokens(in: text).contains(where: isForbidden)
    }

    private static func tokens(in text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    private static func isForbidden(_ word: String) -> Bool {
        if bannedWords.contains(word) { return true }
        return prefixes.contains { prefix in
            guard word.hasPrefix(prefix) else { return false }
            let rest = word.dropFirst(prefix.count)
            return roots.contains { rest.hasPrefix($0) }
        }
    }
}
