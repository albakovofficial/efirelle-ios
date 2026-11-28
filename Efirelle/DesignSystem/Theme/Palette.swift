import SwiftUI
import UIKit

/// Цветовые токены. В интерфейсе не используются «сырые» цвета — только эти.
/// У каждого токена два значения: светлая тема и тёмная «Графит»; тема следует настройке iPhone.
enum Palette {
    static let background = Color(light: 0xF6F5F9, dark: 0x0F0F13)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1B1B22)
    static let surfaceMuted = Color(light: 0xF1EFF6, dark: 0x24242C)
    static let line = Color(light: 0xE8E6EF, dark: 0x2C2C35)

    static let ink = Color(light: 0x16151C, dark: 0xF2F1F6)
    static let inkSoft = Color(light: 0x3E3B48, dark: 0xC9C7D3)
    static let muted = Color(light: 0x6B6878, dark: 0x8D8A9C)
    /// Тёмная плашка под белым текстом (кнопки, уведомления): в тёмной теме — приподнятая серая.
    static let inkSurface = Color(light: 0x16151C, dark: 0x2E2E38)

    /// Основной цвет бренда «Океан» — высокая полоска логотипа. В тёмной теме чуть светлее, чтобы читался.
    static let accent = Color(light: 0x2F5BDE, dark: 0x5B7FFF)
    /// Бирюзовая волна — низкая полоска логотипа.
    static let wave = Color(hex: 0x22C3E6)

    static let live = Color(light: 0xD9303A, dark: 0xE5484D)
    static let glass = Color(light: 0xFFFFFF, dark: 0x1B1B22).opacity(0.86)
    /// Светлый блик на обложках.
    static let highlight = Color(light: 0xFFFFFF, dark: 0xFFFFFF, darkOpacity: 0.12).opacity(0.5)
}

extension Tone {
    /// Фон обложки или аватара.
    var surface: Color {
        switch self {
        case .ink: Palette.inkSurface
        case .lavender: Color(light: 0xE8E3FF, dark: 0x2E2550)
        case .peach: Color(light: 0xFFE4D6, dark: 0x3A2A22)
        case .mint: Color(light: 0xDDF1E8, dark: 0x1D3A2E)
        case .sky: Color(light: 0xDCEBFF, dark: 0x1D2C4A)
        case .butter: Color(light: 0xFFF1C9, dark: 0x3A3216)
        case .rose: Color(light: 0xF7DDEB, dark: 0x3A2232)
        }
    }

    /// Более глубокий оттенок для декоративных кругов.
    var shade: Color {
        switch self {
        case .ink: Color(light: 0x2A2833, dark: 0x3A3A46)
        case .lavender: Color(light: 0xD6CCFF, dark: 0x3A2F66)
        case .peach: Color(light: 0xFFCDB4, dark: 0x4A352B)
        case .mint: Color(light: 0xC3E6D6, dark: 0x24473A)
        case .sky: Color(light: 0xC2DAFF, dark: 0x243860)
        case .butter: Color(light: 0xFFE39A, dark: 0x4A401C)
        case .rose: Color(light: 0xEFC3DA, dark: 0x4A2B40)
        }
    }

    /// Цвет текста поверх `surface`; контраст не ниже 4.5:1 в обеих темах.
    var ink: Color {
        switch self {
        case .ink: .white
        case .lavender: Color(light: 0x3D2FA8, dark: 0xC6B9FF)
        case .peach: Color(light: 0x8A3B17, dark: 0xF2C3A8)
        case .mint: Color(light: 0x1F6B4A, dark: 0x9FE3C2)
        case .sky: Color(light: 0x1E4E99, dark: 0xA9C8FF)
        case .butter: Color(light: 0x7A5A00, dark: 0xF0D27A)
        case .rose: Color(light: 0x8E2A5E, dark: 0xF2B8D6)
        }
    }
}

extension Color {
    /// Цвет из 24-битного значения: `Color(hex: 0x2F5BDE)`.
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// Цвет, который сам меняется вместе с темой iPhone.
    init(light: UInt32, dark: UInt32, darkOpacity: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark).withAlphaComponent(darkOpacity) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
