import SwiftUI

@main
struct EfirelleApp: App {
    private let repository: any StreamRepository = APIStreamRepository()
    @State private var session = Session()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.streamRepository, repository)
                .environment(session)
                .tint(Palette.accent)
                .task { await session.restore(using: repository) }
        }
    }
}
