import Foundation

/// Ошибка API. `message` уже написан для пользователя — его можно показывать как есть.
struct APIError: LocalizedError, Equatable, Sendable {
    let status: Int
    let code: String
    let message: String

    var errorDescription: String? { message }

    var isUnauthorized: Bool { status == 401 }

    static let offline = APIError(status: 0, code: "offline", message: "Нет связи с сервером. Проверьте интернет")
    static let unexpected = APIError(status: 0, code: "unexpected", message: "Что-то пошло не так. Попробуйте ещё раз")
}
