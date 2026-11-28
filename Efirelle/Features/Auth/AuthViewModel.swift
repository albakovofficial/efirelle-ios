import Foundation
import Observation

/// Вход, регистрация и восстановление пароля.
@MainActor
@Observable
final class AuthViewModel {
    enum Mode: Hashable, CaseIterable, Identifiable {
        case login
        case register
        case reset

        var id: Self { self }

        var title: String {
            switch self {
            case .login: "Вход"
            case .register: "Регистрация"
            case .reset: "Новый пароль"
            }
        }
    }

    static let minPasswordLength = 8

    var mode: Mode
    var email = ""
    var password = ""
    var displayName = ""
    var username = ""
    var code = ""
    /// Согласие с правилами сообщества и политикой — обязательно при регистрации (App Review 1.2).
    var acceptsRules = false
    private(set) var isBusy = false
    private(set) var error: String?
    /// Код восстановления отправлен — показываем поля для кода и нового пароля.
    private(set) var isCodeSent = false

    init(mode: Mode = .login) {
        self.mode = mode
    }

    var canSubmit: Bool {
        guard !isBusy, email.contains("@") else { return false }
        switch mode {
        case .login:
            return !password.isEmpty
        case .register:
            return password.count >= Self.minPasswordLength && !displayName.isBlank && username.count >= 3 && acceptsRules
        case .reset:
            return !isCodeSent || (code.count == 6 && password.count >= Self.minPasswordLength)
        }
    }

    /// Возвращает пользователя, если вход состоялся.
    func submit(using repository: any StreamRepository) async -> Viewer? {
        guard canSubmit else { return nil }
        isBusy = true
        error = nil
        defer { isBusy = false }
        let email = self.email.trimmingCharacters(in: .whitespaces).lowercased()
        do {
            switch mode {
            case .login:
                return try await repository.login(email: email, password: password)
            case .register:
                let form = RegistrationForm(
                    email: email,
                    password: password,
                    username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                return try await repository.register(form)
            case .reset where !isCodeSent:
                try await repository.requestPasswordReset(email: email)
                isCodeSent = true
                password = ""
                return nil
            case .reset:
                return try await repository.resetPassword(email: email, code: code, password: password)
            }
        } catch let error as APIError where error.code == "mail_disabled" {
            self.error = "Восстановление по почте временно недоступно. Напишите нам: \(AppLinks.supportEmail)"
        } catch {
            self.error = error.localizedDescription
        }
        return nil
    }

    /// При смене режима старые ошибки и отправленный код больше не относятся к делу.
    func clearMessages() {
        error = nil
        isCodeSent = false
    }
}
