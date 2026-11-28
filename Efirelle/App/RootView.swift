import SwiftUI

/// Корневая навигация приложения по вкладкам.
struct RootView: View {
    var body: some View {
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
    }
}

#Preview {
    RootView()
        .environment(Session())
}
