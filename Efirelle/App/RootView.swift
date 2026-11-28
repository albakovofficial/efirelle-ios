import SwiftUI

/// Корневая навигация: вкладки и своя нижняя панель с кнопкой эфира.
/// Канал из нажатого уведомления или Live Activity открывается поверх.
struct RootView: View {
    @Environment(PushNotifications.self) private var push
    @Environment(Session.self) private var session
    @Environment(\.streamRepository) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .home
    @State private var launcher = BroadcastLauncher()
    @State private var tabBar = TabBarVisibility()

    var body: some View {
        @Bindable var push = push
        @Bindable var launcher = launcher
        TabView(selection: $tab) {
            ForEach(AppTab.allCases) { tab in
                screen(tab)
                    .tag(tab)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabBar.isHidden {
                AppTabBar(selection: $tab, broadcast: launcher.session, onGoLive: goLive)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: tabBar.isHidden)
        .environment(launcher)
        .environment(tabBar)
        .fullScreenCover(isPresented: $launcher.isPresented) {
            if let ingest = launcher.ingest {
                BroadcastView(session: launcher.session, ingest: ingest)
            }
        }
        .signInSheet(isPresented: $launcher.needsSignIn)
        .alert("Эфир не открылся", isPresented: $launcher.showsError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launcher.error ?? "")
        }
        .sheet(item: $push.pendingChannel) { channel in
            NavigationStack {
                WatchView(channel: channel)
                    .appDestinations()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Закрыть") { push.pendingChannel = nil }
                        }
                    }
            }
        }
        .onOpenURL { push.open(url: $0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { Task { await launcher.enteredBackground() } }
        }
    }

    @ViewBuilder
    private func screen(_ tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .browse: BrowseView()
        case .following: FollowingView()
        case .profile: ProfileView()
        }
    }

    private func goLive() {
        Task { await launcher.open(signedIn: session.viewer != nil, repository: repository) }
    }
}

#Preview {
    RootView()
        .environment(Session())
        .environment(PushNotifications())
}
