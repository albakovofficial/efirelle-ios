import Observation

/// Кто сейчас в приложении. Один объект на всё приложение, лежит в окружении SwiftUI.
@MainActor
@Observable
final class Session {
    enum State: Equatable {
        /// Проверяем сохранённый ключ при запуске.
        case restoring
        case guest
        case signedIn(Viewer)
    }

    private(set) var state: State = .restoring

    var viewer: Viewer? {
        if case .signedIn(let viewer) = state { viewer } else { nil }
    }

    /// Сохранённая сессия при запуске. Без сети остаёмся гостем — экраны покажут ошибку сами.
    func restore(using repository: any StreamRepository) async {
        let viewer = try? await repository.currentViewer()
        state = viewer.map(State.signedIn) ?? .guest
    }

    /// Обновить данные пользователя (например, искры после прогноза).
    func refresh(using repository: any StreamRepository) async {
        guard viewer != nil, let fresh = try? await repository.currentViewer() else { return }
        state = .signedIn(fresh)
    }

    func signIn(_ viewer: Viewer) {
        state = .signedIn(viewer)
    }

    func signOut(using repository: any StreamRepository) async {
        await repository.logout()
        state = .guest
    }

    func deleteAccount(password: String, using repository: any StreamRepository) async throws {
        try await repository.deleteAccount(password: password)
        state = .guest
    }
}
