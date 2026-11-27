/// Причина жалобы на сообщение. Уходит модераторам вместе с жалобой.
enum ReportReason: String, CaseIterable, Identifiable, Sendable {
    case insult
    case hate
    case sexual
    case spam
    case personalData
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .insult: "Оскорбления или травля"
        case .hate: "Разжигание ненависти"
        case .sexual: "Откровенный контент"
        case .spam: "Спам или мошенничество"
        case .personalData: "Чужие личные данные"
        case .other: "Другое нарушение"
        }
    }
}
