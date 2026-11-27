import SwiftUI

@main
struct EfirelleApp: App {
    /// Единственная точка выбора источника данных. Для API — заменить реализацию здесь.
    private let repository: any StreamRepository = MockStreamRepository()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.streamRepository, repository)
                .tint(Palette.accent)
        }
    }
}
