import SwiftUI

/// «Щит» автора над полем ввода: медленный режим и «только подписчики» не уходя из эфира.
/// Полные настройки, включая запрещённые слова, — в студии.
struct ChatShieldBar: View {
    let rules: ChatRules
    let onChange: (ModerationPatch) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Label("Щит", systemImage: "shield.lefthalf.filled")
                    .chip(style: .dark)
                    .accessibilityHidden(true)

                Menu {
                    Picker("Медленный режим", selection: Binding(get: { rules.slowModeSeconds }, set: { onChange(ModerationPatch(slowModeSeconds: $0)) })) {
                        ForEach(ChatRules.slowModeOptions, id: \.self) { seconds in
                            Text(seconds == 0 ? "Выключен" : "Раз в \(seconds) с").tag(seconds)
                        }
                    }
                } label: {
                    Label(rules.slowModeSeconds == 0 ? "Медленно: выкл" : "\(rules.slowModeSeconds) с", systemImage: "hourglass")
                        .chip(style: rules.slowModeSeconds > 0 ? .on : .off)
                }
                .accessibilityLabel("Медленный режим")

                Button {
                    onChange(ModerationPatch(followersOnly: !rules.followersOnly))
                } label: {
                    Label("Подписчики", systemImage: "heart.fill")
                        .chip(style: rules.followersOnly ? .on : .off)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Писать могут только подписчики")
                .accessibilityAddTraits(rules.followersOnly ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: rules)
    }
}

private enum ChipStyle {
    case dark, on, off
}

private extension View {
    func chip(style: ChipStyle) -> some View {
        font(.brandCaption)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .foregroundStyle(style == .dark ? .white : style == .on ? Palette.accent : Palette.inkSoft)
            .background(
                style == .dark ? Palette.inkSurface : style == .on ? Palette.accent.opacity(0.12) : Palette.surfaceMuted,
                in: .capsule
            )
    }
}

#Preview {
    ChatShieldBar(rules: ChatRules(slowModeSeconds: 10, followersOnly: false)) { _ in }
        .padding()
}
