import Foundation

/// Формы слова для русского склонения по числу: 1 зритель, 2 зрителя, 5 зрителей.
struct PluralForms: Sendable {
    let one: String
    let few: String
    let many: String

    static let viewers = PluralForms(one: "зритель", few: "зрителя", many: "зрителей")
    static let followers = PluralForms(one: "отслеживает", few: "отслеживают", many: "отслеживают")
    static let participants = PluralForms(one: "участник", few: "участника", many: "участников")
    static let views = PluralForms(one: "просмотр", few: "просмотра", many: "просмотров")

    func form(for number: Int) -> String {
        let value = abs(number)
        let mod10 = value % 10
        let mod100 = value % 100
        if mod10 == 1 && mod100 != 11 { return one }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return few }
        return many
    }
}

/// Единое форматирование чисел и времени для интерфейса.
enum Formatters {
    private static let locale = Locale(identifier: "ru_RU")

    /// 18702 → «18,7 тыс.», 950 → «950».
    static func compact(_ number: Int) -> String {
        number.formatted(
            .number
                .notation(.compactName)
                .precision(.fractionLength(0...1))
                .locale(locale)
        )
    }

    /// 18702 → «18 702».
    static func number(_ number: Int) -> String {
        number.formatted(.number.locale(locale))
    }

    /// Число со словом. После «тыс.»/«млн» слово всегда во множественном числе родительного падежа.
    static func count(_ number: Int, _ forms: PluralForms, compact isCompact: Bool = true) -> String {
        let shortened = isCompact && number >= 1_000
        let value = shortened ? compact(number) : self.number(number)
        return "\(value) \(shortened ? forms.many : forms.form(for: number))"
    }

    /// 13690 с → «3:48:10», 754 с → «12:34».
    static func clock(_ duration: Duration) -> String {
        let total = max(0, Int(duration.components.seconds))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        let paddedSeconds = String(format: "%02d", seconds)
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(paddedSeconds)"
        }
        return "\(minutes):\(paddedSeconds)"
    }
}
