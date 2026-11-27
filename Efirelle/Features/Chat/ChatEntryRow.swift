import SwiftUI

/// Одна запись чата: сообщение участника или событие канала (рейд, донат).
/// На чужое сообщение долгим нажатием можно пожаловаться или заблокировать автора.
struct ChatEntryRow: View {
    let entry: ChatEntry
    var onReport: (ChatMessage, ReportReason) -> Void = { _, _ in }
    var onBlock: (ChatMessage) -> Void = { _ in }

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
                if !message.isOwn {
                    moderationActions(for: message)
                }
            }

        case .event(let event):
            Text(event.text)
                .font(.brandCallout)
                .foregroundStyle(event.tone.ink)
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(event.tone.surface, in: .rect(cornerRadius: Radius.m))
        }
    }

    @ViewBuilder
    private func moderationActions(for message: ChatMessage) -> some View {
        Menu {
            ForEach(ReportReason.allCases) { reason in
                Button(reason.title) { onReport(message, reason) }
            }
        } label: {
            Label("Пожаловаться", systemImage: "flag")
        }
        Button(role: .destructive) {
            onBlock(message)
        } label: {
            Label("Заблокировать \(message.author)", systemImage: "hand.raised")
        }
    }
}
