import SwiftUI

extension View {
    /// Переходы по `NavigationLink(value:)`: канал → экран канала, категория → её эфиры.
    /// Подключается в каждом `NavigationStack`.
    func appDestinations() -> some View {
        navigationDestination(for: Channel.self) { channel in
            WatchView(channel: channel)
        }
        .navigationDestination(for: StreamCategory.self) { category in
            CategoryView(category: category)
        }
    }
}
