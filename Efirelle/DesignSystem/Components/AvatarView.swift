import SwiftUI

/// Аватар канала или пользователя: инициалы на тоне.
struct AvatarView: View {
    enum Size {
        case small, medium, large, extraLarge

        var points: CGFloat {
            switch self {
            case .small: 28
            case .medium: 40
            case .large: 48
            case .extraLarge: 60
            }
        }
    }

    enum Ring {
        /// Красное кольцо — канал в эфире.
        case live
        /// Тёмное кольцо — выбранный канал.
        case active

        var color: Color {
            switch self {
            case .live: Palette.live
            case .active: Palette.ink
            }
        }
    }

    let initials: String
    let tone: Tone
    var size: Size = .medium
    var ring: Ring?
    /// Красная точка «в эфире» в углу.
    var showsLiveDot = false

    var body: some View {
        Text(initials)
            .font(.system(size: size.points * 0.32, weight: .heavy))
            .foregroundStyle(tone.ink)
            .frame(width: size.points, height: size.points)
            .background(tone.surface, in: .circle)
            .padding(ring == nil ? 0 : 3)
            .overlay {
                if let ring {
                    Circle().strokeBorder(ring.color, lineWidth: 2)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if showsLiveDot {
                    Circle()
                        .fill(Palette.live)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(Palette.background, lineWidth: 2))
                }
            }
            .accessibilityHidden(true)
    }
}

extension AvatarView {
    init(channel: Channel, size: Size = .medium, ring: Ring? = nil, showsLiveDot: Bool = false) {
        self.init(initials: channel.initials, tone: channel.tone, size: size, ring: ring, showsLiveDot: showsLiveDot)
    }
}

#Preview {
    HStack(spacing: Spacing.m) {
        AvatarView(channel: MockData.Channels.mira, size: .small)
        AvatarView(channel: MockData.Channels.timur, showsLiveDot: true)
        AvatarView(channel: MockData.Channels.alisa, size: .extraLarge, ring: .live)
    }
    .padding()
}
