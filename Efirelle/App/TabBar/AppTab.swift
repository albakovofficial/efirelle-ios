/// Вкладки приложения.
enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case browse
    case following
    case profile

    var id: Self { self }

    /// Короткая подпись — видна у выбранной вкладки в панели.
    var title: String {
        switch self {
        case .home: "Главная"
        case .browse: "Обзор"
        case .following: "Подписки"
        case .profile: "Профиль"
        }
    }

    /// Полное название для VoiceOver.
    var accessibilityTitle: String {
        self == .following ? "Отслеживаемые" : title
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .browse: "square.grid.2x2.fill"
        case .following: "heart.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
