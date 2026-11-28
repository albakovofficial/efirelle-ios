import SwiftUI

@main
struct EfirelleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let repository: any StreamRepository = APIStreamRepository()
    @State private var session = Session()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.streamRepository, repository)
                .environment(session)
                .environment(appDelegate.push)
                .tint(Palette.accent)
                .task { await session.restore(using: repository) }
                // После входа привязываем iPhone к аккаунту, если уведомления уже разрешены.
                .task(id: session.viewer?.id) {
                    guard session.viewer != nil else { return }
                    await appDelegate.push.activate(using: repository)
                }
        }
    }
}
