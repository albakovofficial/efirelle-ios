import SwiftUI

/// Одна запись чата: сообщение участника или событие канала (рейд).
/// Долгое нажатие на чужое сообщение — жалоба, скрытие автора, а для автора эфира — удаление и запрет писать.
struct ChatEntryRow: View {
    /// Что зритель может сделать с сообщением. `nil` — ничего (своё сообщение или гость).
    struct Actions {
        let canDelete: Bool
        let canBan: Bool
        let report: (ReportReason) -> Void
        let hideAuthor: () -> Void
        let delete: () -> Void
        /// Минуты запрета; `nil` — навсегда.
        let ban: (Int?) -> Void
    }

    let entry: ChatEntry
    var actions: Actions?

    var body: some View {
        switch entry {
        case .message(let message):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let badge = message.badge {
                    BadgeView(text: badge.title, style: .tone(badge.tone), size: .small)
                }
                Text("\(Text(message.author).fontWeight(.heavy).foregroundStyle(message.tone.ink)) \(message.text)")
                    .font(.brandBody)
                    .foregroundStyle(Palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .contextMenu {
                if let actions {
                    menu(for: message, actions: actions)
                }
            }

        case .event(let event):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(event.text)
                    .font(.brandCallout)
                    .foregroundStyle(event.tone.ink)
                if let target = event.channel {
                    NavigationLink("Перейти", value: Channel(id: target, name: target, initials: "", tone: event.tone, followers: 0))
                        .font(.brandCallout)
                }
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(event.tone.surface, in: .rect(cornerRadius: Radius.m))
        }
    }

    @ViewBuilder
    private func menu(for message: ChatMessage, actions: Actions) -> some View {
        Menu {
            ForEach(ReportReason.allCases) { reason in
                Button(reason.title) { actions.report(reason) }
            }
        } label: {
            Label("Пожаловаться", systemImage: "flag")
        }
        Button {
            actions.hideAuthor()
        } label: {
            Label("Скрыть все сообщения \(message.author)", systemImage: "eye.slash")
        }
        if actions.canDelete {
            Button(role: .destructive, action: actions.delete) {
                Label("Удалить сообщение", systemImage: "trash")
            }
        }
        if actions.canBan {
            Button(role: .destructive) { actions.ban(10) } label: {
                Label("Запретить писать на 10 минут", systemImage: "timer")
            }
            Button(role: .destructive) { actions.ban(nil) } label: {
                Label("Запретить писать навсегда", systemImage: "hand.raised")
            }
        }
    }
}
