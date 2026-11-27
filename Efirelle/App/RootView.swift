import SwiftUI

/// Корневая навигация приложения по вкладкам.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house.fill") }
            FollowingView()
                .tabItem { Label("Отслеживаемые", systemImage: "heart.fill") }
        }
    }
}

#Preview {
    RootView()
        .environment(\.streamRepository, MockStreamRepository.instant)
}
