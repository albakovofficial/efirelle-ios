import Foundation
import Observation
import UIKit
import UserNotifications

/// Уведомления на iPhone: разрешение, токен устройства для сервера и переход в эфир по нажатию.
/// Один объект на приложение — его держит `AppDelegate`, который получает токен от системы.
@MainActor
@Observable
final class PushNotifications {
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Канал из нажатого уведомления — корневой экран откроет его и сбросит значение.
    var pendingChannel: Channel?
    private var deviceToken: String?
    private var repository: (any StreamRepository)?

    var isAuthorized: Bool {
        authorization == .authorized || authorization == .provisional || authorization == .ephemeral
    }

    /// Вошёл пользователь или запустилось приложение со входом: если уведомления разрешены — привязываем iPhone.
    func activate(using repository: any StreamRepository) async {
        self.repository = repository
        await refreshAuthorization()
        if isAuthorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Спрашиваем разрешение в подходящий момент (после «Отслеживать» или в профиле). Повторно система не спрашивает.
    @discardableResult
    func requestAuthorization(using repository: any StreamRepository) async -> Bool {
        self.repository = repository
        let granted = await Self.askPermission()
        await refreshAuthorization()
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
        }
        return granted
    }

    func refreshAuthorization() async {
        authorization = await Self.authorizationStatus()
    }

    /// Токен от системы. Отправляем на сервер каждый раз: Apple может выдать новый.
    func didRegister(deviceToken data: Data) {
        let token = Self.hexString(data)
        deviceToken = token
        guard let repository else { return }
        Task {
            try? await repository.registerDevice(token: token, environment: .current)
        }
    }

    /// Перед выходом из аккаунта: уведомления чужого аккаунта на этот iPhone больше не придут.
    func signOut() async {
        guard let token = deviceToken, let repository else { return }
        try? await repository.unregisterDevice(token: token)
    }

    func open(channel slug: String) {
        pendingChannel = Channel(id: slug, name: slug, initials: "", tone: .lavender, followers: 0)
    }

    nonisolated static func hexString(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    // Системные вызовы — вне главного потока, чтобы объекты UserNotifications не пересекали границу актёра.

    private nonisolated static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private nonisolated static func askPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
