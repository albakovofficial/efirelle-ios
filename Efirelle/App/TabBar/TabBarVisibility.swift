import Observation
import SwiftUI

/// Прячет нижнюю панель на экранах, где снизу своё управление (эфир с чатом).
/// Счётчик, а не флаг: такие экраны могут открываться друг поверх друга.
@MainActor
@Observable
final class TabBarVisibility {
    private var hideRequests = 0

    var isHidden: Bool { hideRequests > 0 }

    fileprivate func hide() { hideRequests += 1 }
    fileprivate func show() { hideRequests = max(0, hideRequests - 1) }
}

private struct HidesTabBar: ViewModifier {
    @Environment(TabBarVisibility.self) private var visibility: TabBarVisibility?

    func body(content: Content) -> some View {
        content
            .onAppear { visibility?.hide() }
            .onDisappear { visibility?.show() }
    }
}

extension View {
    /// Пока экран открыт, нижней панели нет.
    func hidesTabBar() -> some View {
        modifier(HidesTabBar())
    }
}
