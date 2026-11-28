import ActivityKit
import Foundation

/// Live Activities «канал в эфире». Запускает и обновляет их сервер пушем; приложение только сообщает токены:
/// токен запуска (iOS 17.2+) — к устройству, токен каждой запущенной активности — к её каналу.
@MainActor
final class LiveActivities {
    private var tasks: [Task<Void, Never>] = []
    private var deviceToken: String?

    /// Устройство привязано к аккаунту — начинаем слушать токены. Повторный вызов с тем же токеном ничего не делает.
    func activate(deviceToken: String, repository: any StreamRepository) {
        guard deviceToken != self.deviceToken else { return }
        self.deviceToken = deviceToken
        stop()
        if #available(iOS 17.2, *) {
            tasks.append(Task {
                for await data in Activity<LiveStreamAttributes>.pushToStartTokenUpdates {
                    let token = PushNotifications.hexString(data)
                    guard ActivityAuthorizationInfo().areActivitiesEnabled else { continue }
                    try? await repository.setActivityStartToken(token, device: deviceToken)
                }
            })
            tasks.append(Task {
                // Выключили Live Activities в настройках — сервер снова присылает обычные уведомления.
                for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates where !enabled {
                    try? await repository.setActivityStartToken(nil, device: deviceToken)
                }
            })
        }
        tasks.append(Task {
            for await activity in Activity<LiveStreamAttributes>.activityUpdates {
                let channel = activity.attributes.slug
                Task {
                    for await data in activity.pushTokenUpdates {
                        try? await repository.registerLiveActivity(
                            token: PushNotifications.hexString(data),
                            channel: channel,
                            environment: .current
                        )
                    }
                }
            }
        })
    }

    /// Выход из аккаунта: чужие эфиры на этом iPhone больше не показываем.
    func signOut() async {
        stop()
        deviceToken = nil
        for activity in Activity<LiveStreamAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
