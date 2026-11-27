import SwiftUI

/// Карточка «живого момента»: что происходит в эфире прямо сейчас.
struct MomentCardView: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                BadgeView(text: moment.kind.title, style: .tone(moment.kind.tone))
                Spacer()
                Text(moment.when)
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
            }
            Text(moment.text)
                .font(.brandCallout)
                .foregroundStyle(Palette.ink)
                .lineLimit(3, reservesSpace: true)
            Text(moment.channel.name)
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.m)
        .frame(width: 250, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }
}
