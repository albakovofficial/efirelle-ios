import SwiftUI

/// Корневая навигация приложения по вкладкам. Канал из нажатого уведомления открывается поверх.
struct RootView: View {
    @Environment(PushNotifications.self) private var push

    var body: some View {
        @Bindable var bindable = push
        TabView {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house.fill") }
            BrowseView()
                .tabItem { Label("Обзор", systemImage: "square.grid.2x2.fill") }
            FollowingView()
                .tabItem { Label("Отслеживаемые", systemImage: "heart.fill") }
            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }
        }
        .sheet(item: $bindable.pendingChannel) { channel in
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
    }
}

#Preview {
    RootView()
        .environment(Session())
        .environment(PushNotifications())
}
