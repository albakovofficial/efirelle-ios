import SwiftUI

/// «Сводка защиты»: сверху — статус чата и сколько сообщений скрыто за эфир, ниже — правила.
struct ModerationView: View {
    @State private var model: ModerationViewModel
    @Environment(\.streamRepository) private var repository

    init(settings: ModerationSettings) {
        _model = State(initialValue: ModerationViewModel(settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s) {
                summary
                rules
                if let notice = model.notice {
                    Text(notice)
                        .font(.brandCaption)
                        .foregroundStyle(Palette.live)
                }
            }
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Модерация чата")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: model.settings)
    }

    private var summary: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: model.isProtected ? "checkmark.shield.fill" : "shield")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.12), in: .rect(cornerRadius: Radius.s))
            VStack(alignment: .leading, spacing: 2) {
                Text(model.isProtected ? "Чат защищён" : "Защита выключена")
                    .font(.brandHeadline)
                Text(hiddenText)
                    .font(.brandCaption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(Spacing.m)
        .background(Palette.inkSurface, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    private var hiddenText: String {
        let hidden = model.settings.hiddenThisStream
        return hidden == 0 ? "За эфир фильтр ничего не скрыл" : "За эфир скрыто \(Formatters.count(hidden, .messages))"
    }

    private var rules: some View {
        VStack(spacing: 0) {
            RuleRow(symbol: "hourglass", title: "Медленный режим", subtitle: model.settings.slowModeSeconds == 0 ? nil : "Одно сообщение раз в \(model.settings.slowModeSeconds) с", isOn: model.settings.slowModeSeconds > 0) {
                Picker("Медленный режим", selection: Binding(
                    get: { model.settings.slowModeSeconds },
                    set: { seconds in Task { await model.setSlowMode(seconds, using: repository) } }
                )) {
                    ForEach(ChatRules.slowModeOptions, id: \.self) { seconds in
                        Text(seconds == 0 ? "Выкл" : "\(seconds) с").tag(seconds)
                    }
                }
                .labelsHidden()
                .tint(Palette.accent)
            }
            Divider().padding(.leading, 64)
            RuleRow(symbol: "heart.fill", title: "Только подписчики", subtitle: "Остальные читают, но не пишут", isOn: model.settings.followersOnly) {
                Toggle("Только подписчики", isOn: Binding(
                    get: { model.settings.followersOnly },
                    set: { enabled in Task { await model.setFollowersOnly(enabled, using: repository) } }
                ))
                .labelsHidden()
                .tint(Palette.accent)
            }
            Divider().padding(.leading, 64)
            NavigationLink {
                BlockedWordsView(model: model)
            } label: {
                RuleRow(
                    symbol: "line.3.horizontal.decrease",
                    title: "Запрещённые слова",
                    subtitle: model.settings.blockedWords.isEmpty ? "Не заданы" : Formatters.count(model.settings.blockedWords.count, .words),
                    isOn: !model.settings.blockedWords.isEmpty
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                }
            }
            .buttonStyle(.plain)
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
    }
}

/// Строка правила: значок (синий, когда правило работает), название, пояснение и управление справа.
private struct RuleRow<Accessory: View>: View {
    let symbol: String
    let title: String
    let subtitle: String?
    let isOn: Bool
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? Palette.accent : Palette.inkSoft)
                .frame(width: 38, height: 38)
                .background(isOn ? Palette.accent.opacity(0.12) : Palette.surfaceMuted, in: .rect(cornerRadius: Radius.s))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brandBody)
                    .foregroundStyle(Palette.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                }
            }
            Spacer(minLength: 0)
            accessory()
        }
        .padding(.horizontal, Spacing.s)
        .frame(minHeight: 64)
        .contentShape(.rect)
    }
}
