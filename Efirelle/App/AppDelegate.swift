import UIKit
import UserNotifications

/// Принимает от системы токен для уведомлений, нажатия на уведомления и разрешённые ориентации экрана.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let push = PushNotifications()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Лёжа — только полноэкранный эфир (см. OrientationLock).
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        push.didRegister(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        // Без токена уведомления просто не придут; приложение работает как обычно.
    }

    /// Уведомление пришло, пока приложение открыто, — всё равно показываем баннер.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// Нажатие на уведомление открывает канал.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let channel = response.notification.request.content.userInfo["channel"] as? String else { return }
        await MainActor.run {
            push.open(channel: channel)
        }
    }
}
