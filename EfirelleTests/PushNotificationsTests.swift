import Foundation
import Testing
@testable import Efirelle

@MainActor
@Suite("Уведомления")
struct PushNotificationsTests {
    @Test("Токен устройства передаётся серверу в шестнадцатеричном виде")
    func hexToken() {
        let token = PushNotifications.hexString(Data([0x00, 0x0f, 0xa0, 0xff]))
        #expect(token == "000fa0ff")
    }

    @Test("Нажатие на уведомление открывает канал")
    func opensChannel() {
        let push = PushNotifications()
        push.open(channel: "mira")
        #expect(push.pendingChannel?.id == "mira")
    }
}
