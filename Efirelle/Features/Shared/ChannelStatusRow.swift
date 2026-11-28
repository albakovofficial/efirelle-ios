import SwiftUI

/// Строка канала: в эфире — превью эфира, не в сети — аватар и «не в сети».
struct ChannelStatusRow: View {
    let status: ChannelStatus

    var body: some View {
        if let stream = status.stream {
            StreamRowView(stream: stream)
        } else {
            HStack(spacing: Spacing.s) {
                AvatarView(channel: status.channel, size: .large)
                    .frame(width: 112)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.channel.name)
                        .font(.brandCallout)
                        .foregroundStyle(Palette.ink)
                    Text("Не в сети · \(Formatters.count(status.channel.followers, .followers))")
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        }
    }
}
