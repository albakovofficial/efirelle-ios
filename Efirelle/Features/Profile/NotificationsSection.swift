import SwiftUI
import UIKit

/// Раздел «Уведомления» в профиле: о начале эфира отслеживаемых каналов.
/// Включается и на сервере (настройка аккаунта), и в iPhone (разрешение системы).
struct NotificationsSection: View {
    @Environment(\.streamRepository) private var repository
    @Environment(PushNotifications.self) private var push
    @Environment(\.openURL) private var openURL
    @State private var isOn = false
    /// Пока настройка не пришла с сервера, переключатель не трогаем — иначе запишем неверное значение.
    @State private var isLoaded = false

    var body: some View {
        Section {
            if push.authorization == .denied {
                Button("Разрешить уведомления в настройках iPhone") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            } else if isLoaded {
                Toggle("Когда отслеживаемый канал начинает эфир", isOn: $isOn)
            } else {
                ProgressView()
            }
        } header: {
            Text("Уведомления")
        } footer: {
            Text("Не чаще раза в полчаса на канал.")
        }
        .task {
            await push.refreshAuthorization()
            let enabled = (try? await repository.liveNotificationsEnabled()) ?? true
            isOn = enabled && push.isAuthorized
            isLoaded = true
        }
        .onChange(of: isOn) { _, value in
            guard isLoaded else { return }
            Task { await update(value) }
        }
    }

    private func update(_ value: Bool) async {
        if value, !push.isAuthorized {
            guard await push.requestAuthorization(using: repository) else {
                isOn = false
                return
            }
        }
        try? await repository.setLiveNotifications(value)
    }
}
