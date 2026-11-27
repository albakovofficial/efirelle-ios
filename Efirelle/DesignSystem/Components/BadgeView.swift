import SwiftUI

/// Короткая метка: «В ЭФИРЕ», число зрителей поверх превью, тип момента, значок в чате.
struct BadgeView: View {
    enum Style {
        case live
        case glass
        case dark
        case tone(Tone)

        var background: Color {
            switch self {
            case .live: Palette.live
            case .glass: Palette.glass
            case .dark: Palette.ink.opacity(0.85)
            case .tone(let tone): tone.surface
            }
        }

        var foreground: Color {
            switch self {
            case .live, .dark: .white
            case .glass: Palette.ink
            case .tone(let tone): tone.ink
            }
        }
    }

    enum Size {
        case small, regular
    }

    let text: String
    var style: Style = .glass
    var size: Size = .regular

    var body: some View {
        Text(text)
            .font(size == .small ? .brandMicro : .brandCaption)
            .tracking(style.isLive ? 0.8 : 0)
            .lineLimit(1)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, size == .small ? 6 : 9)
            .padding(.vertical, size == .small ? 3 : 5)
            .background(style.background, in: .rect(cornerRadius: size == .small ? 6 : 8))
    }
}

extension BadgeView {
    /// Бейдж прямого эфира — текст и стиль в одном месте на всё приложение.
    static func live(short: Bool = false, size: Size = .regular) -> BadgeView {
        BadgeView(text: short ? "LIVE" : "В ЭФИРЕ", style: .live, size: size)
    }
}

private extension BadgeView.Style {
    var isLive: Bool {
        if case .live = self { true } else { false }
    }
}

#Preview {
    HStack {
        BadgeView.live()
        BadgeView(text: "18,7 тыс.")
        BadgeView(text: "3:48:10", style: .dark, size: .small)
        BadgeView(text: "Рейд", style: .tone(.rose))
    }
    .padding()
    .background(Palette.background)
}
