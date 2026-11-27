import SwiftUI

/// Главный эфир витрины: крупная обложка с подписью на «стекле».
struct FeaturedStreamCard: View {
    let stream: LiveStream

    var body: some View {
        ThumbnailView(tone: stream.tone, cornerRadius: Radius.xl)
            .frame(height: 260)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    BadgeView.live()
                    BadgeView(text: Formatters.compact(stream.viewers))
                }
                .padding(Spacing.s)
            }
            .overlay(alignment: .bottom) {
                caption.padding(Spacing.s)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Открыть эфир")
    }

    private var caption: some View {
        HStack(spacing: Spacing.s) {
            AvatarView(channel: stream.channel, size: .large)
            VStack(alignment: .leading, spacing: 2) {
                Text(stream.title)
                    .font(.brandHeadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                Text("\(stream.channel.name) · \(stream.category)")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.s)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: Radius.l))
    }
}

#Preview {
    FeaturedStreamCard(stream: MockData.streams[0])
        .padding()
}
