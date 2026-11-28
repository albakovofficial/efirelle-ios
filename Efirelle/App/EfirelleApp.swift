import SwiftUI

@main
struct EfirelleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let repository: any StreamRepository = APIStreamRepository()
    @State private var session = Session()
    @State private var showsLaunch = true

    var body: some Scene {
        WindowGroup {
            RootView()
                .overlay {
                    if showsLaunch {
                        LaunchAnimationView {
                            withAnimation(.easeOut(duration: 0.35)) { showsLaunch = false }
                        }
                        .transition(.opacity)
                    }
                }
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
