import Foundation

extension String {
    /// Пустая строка или одни пробелы.
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
