import SwiftUI

/// Канал под плеером: автор, название эфира, теги и кнопка «Отслеживать».
struct ChannelHeaderView: View {
    let stream: LiveStream
    @Binding var isFollowing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.s) {
                AvatarView(channel: stream.channel, size: .large, ring: .live)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: 6) {
                        Text(stream.channel.name)
                            .font(.brandHeadline)
                        if stream.channel.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Palette.accent)
                                .accessibilityLabel("Подтверждённый канал")
                        }
                    }
                    Text(Formatters.count(stream.channel.followers, .followers))
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                }
            }

            Text(stream.title)
                .font(.brandTitle)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            TagsView(tags: [stream.category] + stream.tags, leadingTone: stream.tone)

            Button {
                isFollowing.toggle()
            } label: {
                Label(isFollowing ? "Отслеживаете" : "Отслеживать", systemImage: isFollowing ? "heart.fill" : "heart")
                    .font(.brandCallout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isFollowing ? Palette.ink : Palette.accent)
            .sensoryFeedback(.selection, trigger: isFollowing)
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
    }
}
