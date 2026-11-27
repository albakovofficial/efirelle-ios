import Foundation

/// Внешние ссылки и контакты. Те же адреса указаны в App Store Connect (политика, поддержка).
enum AppLinks {
    static let rules = URL(string: "https://efirelle.ru/rules")!
    static let privacy = URL(string: "https://efirelle.ru/privacy")!
    static let support = URL(string: "https://efirelle.ru/support")!
    /// Поддержка и жалобы на контент.
    static let supportEmail = "support@efirelle.ru"
    static let supportMail = URL(string: "mailto:support@efirelle.ru")!
}
