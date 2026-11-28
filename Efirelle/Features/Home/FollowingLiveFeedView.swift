import SwiftUI

/// «Ваши каналы в эфире»: лента карточек эфиров отслеживаемых каналов.
/// Показывается, только когда кто-то из них в эфире.
struct FollowingLiveFeedView: View {
    let streams: [LiveStream]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Ваши каналы в эфире")
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(streams) { stream in
                        NavigationLink(value: stream.channel) {
                            StreamCardView(stream: stream)
                                .frame(width: 264)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    NavigationStack {
        FollowingLiveFeedView(streams: Array(MockData.streams.prefix(3)))
            .padding()
    }
}
