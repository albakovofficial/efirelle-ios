/// Причина жалобы на сообщение. Значения совпадают с API (`REPORT_REASONS`).
enum ReportReason: String, CaseIterable, Identifiable, Sendable, Encodable {
    case spam
    case harassment
    case hate
    case sexual
    case violence
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .spam: "Спам или реклама"
        case .harassment: "Оскорбления, травля"
        case .hate: "Разжигание ненависти"
        case .sexual: "Сексуальный контент"
        case .violence: "Насилие или угрозы"
        case .other: "Другое"
        }
    }
}
