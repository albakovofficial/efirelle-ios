import Observation

/// Запуск эфира с iPhone из любого места: кнопка в нижней панели, карточка на главной, студия.
/// Держит сессию эфира, поэтому эфир продолжается, пока автор смотрит другие экраны.
@MainActor
@Observable
final class BroadcastLauncher {
    let session = BroadcastSession()
    var isPresented = false
    var needsSignIn = false
    var showsError = false
    private(set) var error: String?
    private(set) var ingest: Studio.Ingest?

    /// Открывает экран эфира. Адрес и ключ берутся из студии заново: ключ могли сменить.
    func open(signedIn: Bool, repository: any StreamRepository) async {
        guard signedIn else {
            needsSignIn = true
            return
        }
        if !session.isLive {
            do {
                ingest = try await repository.studio().ingest
            } catch {
                self.error = "Не удалось открыть студию. Проверьте интернет и попробуйте ещё раз."
                showsError = true
                return
            }
        }
        isPresented = ingest != nil
    }

    /// Свернули приложение: iOS выключает камеру, поэтому эфир честно завершаем.
    func enteredBackground() async {
        if session.isLive { await session.stop() }
    }
}
