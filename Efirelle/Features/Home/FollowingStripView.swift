import SwiftUI

/// Горизонтальная лента отслеживаемых каналов в эфире.
struct FollowingStripView: View {
    let streams: [LiveStream]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("В СЕТИ")
                .font(.brandMicro)
                .tracking(1)
                .foregroundStyle(Palette.muted)

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.m) {
                    ForEach(streams) { stream in
                        NavigationLink(value: stream.channel) {
                            VStack(spacing: 6) {
                                AvatarView(channel: stream.channel, size: .extraLarge, ring: .live)
                                Text(stream.channel.name.split(separator: " ").first.map(String.init) ?? stream.channel.name)
                                    .font(.brandCaption)
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                            }
                            .frame(width: 68)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(stream.channel.name), в эфире")
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
            .scrollIndicators(.hidden)
        }
    }
}
