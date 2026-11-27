import SwiftUI

/// Цветовые токены. В интерфейсе не используются «сырые» цвета — только эти.
enum Palette {
    static let background = Color(hex: 0xF6F5F9)
    static let surface = Color.white
    static let surfaceMuted = Color(hex: 0xF1EFF6)
    static let line = Color(hex: 0xE8E6EF)

    static let ink = Color(hex: 0x16151C)
    static let inkSoft = Color(hex: 0x3E3B48)
    static let muted = Color(hex: 0x6B6878)

    /// Основной цвет бренда «Океан» — высокая полоска логотипа.
    static let accent = Color(hex: 0x2F5BDE)
    /// Бирюзовая волна — низкая полоска логотипа.
    static let wave = Color(hex: 0x22C3E6)

    static let live = Color(hex: 0xD9303A)
    static let glass = Color.white.opacity(0.86)
}

extension Tone {
    /// Фон обложки или аватара.
    var surface: Color {
        switch self {
        case .ink: Palette.ink
        case .lavender: Color(hex: 0xE8E3FF)
        case .peach: Color(hex: 0xFFE4D6)
        case .mint: Color(hex: 0xDDF1E8)
        case .sky: Color(hex: 0xDCEBFF)
        case .butter: Color(hex: 0xFFF1C9)
        case .rose: Color(hex: 0xF7DDEB)
        }
    }

    /// Более глубокий оттенок для декоративных кругов.
    var shade: Color {
        switch self {
        case .ink: Color(hex: 0x2A2833)
        case .lavender: Color(hex: 0xD6CCFF)
        case .peach: Color(hex: 0xFFCDB4)
        case .mint: Color(hex: 0xC3E6D6)
        case .sky: Color(hex: 0xC2DAFF)
        case .butter: Color(hex: 0xFFE39A)
        case .rose: Color(hex: 0xEFC3DA)
        }
    }

    /// Цвет текста поверх `surface`; контраст не ниже 4.5:1.
    var ink: Color {
        switch self {
        case .ink: .white
        case .lavender: Color(hex: 0x3D2FA8)
        case .peach: Color(hex: 0x8A3B17)
        case .mint: Color(hex: 0x1F6B4A)
        case .sky: Color(hex: 0x1E4E99)
        case .butter: Color(hex: 0x7A5A00)
        case .rose: Color(hex: 0x8E2A5E)
        }
    }
}

extension Color {
    /// Цвет из 24-битного значения: `Color(hex: 0x2F5BDE)`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
