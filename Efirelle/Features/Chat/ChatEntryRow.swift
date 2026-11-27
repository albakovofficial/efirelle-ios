import SwiftUI

/// Одна запись чата: сообщение участника или событие канала (рейд, донат).
struct ChatEntryRow: View {
    let entry: ChatEntry

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
            .accessibilityElement(children: .combine)

        case .event(let event):
            Text(event.text)
                .font(.brandCallout)
                .foregroundStyle(event.tone.ink)
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(event.tone.surface, in: .rect(cornerRadius: Radius.m))
        }
    }
}
