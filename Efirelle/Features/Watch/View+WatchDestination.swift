import SwiftUI

extension View {
    /// Переход на экран эфира по `NavigationLink(value: stream)`. Подключается в каждом `NavigationStack`.
    func watchDestination() -> some View {
        navigationDestination(for: LiveStream.self) { stream in
            WatchView(stream: stream)
        }
    }
}
