/// Вкладки приложения.
enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case search
    case following
    case profile

    var id: Self { self }

    /// Короткая подпись — видна у выбранной вкладки в панели.
    var title: String {
        switch self {
        case .home: "Главная"
        case .search: "Поиск"
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
        case .search: "magnifyingglass"
        case .following: "heart.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
