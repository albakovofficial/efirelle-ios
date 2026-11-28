import SwiftUI

/// Карточка эфира в ленте: превью, канал, название, теги.
struct StreamCardView: View {
    let stream: LiveStream

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ThumbnailView(tone: stream.tone)
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    BadgeView.live(short: true, size: .small).padding(Spacing.xs)
                }
                .overlay(alignment: .bottomLeading) {
                    BadgeView(text: Formatters.count(stream.viewers, .viewers), size: .small).padding(Spacing.xs)
                }
                .overlay(alignment: .bottomTrailing) {
                    BadgeView(text: Formatters.clock(stream.duration), style: .dark, size: .small).padding(Spacing.xs)
                }

            HStack(alignment: .top, spacing: Spacing.s) {
                AvatarView(channel: stream.channel)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(stream.title)
                        .font(.brandHeadline)
                        .foregroundStyle(Palette.ink)
                    Text("\(stream.channel.name) · \(stream.category)")
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                    TagsView(tags: stream.tags)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Открыть эфир")
    }
}

#Preview {
    StreamCardView(stream: MockData.streams[4])
        .padding()
}
