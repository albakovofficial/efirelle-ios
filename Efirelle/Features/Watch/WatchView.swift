import SwiftUI

/// Экран эфира. На iPhone чат идёт под плеером, на iPad и в широком окне — справа.
struct WatchView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: WatchViewModel

    private let sideChatWidth: CGFloat = 380
    private let inlineChatHeight: CGFloat = 560

    init(stream: LiveStream) {
        _model = State(initialValue: WatchViewModel(stream: stream))
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: Spacing.l) {
                    ScrollView { mainColumn }
                    ChatView(streamID: model.stream.id)
                        .frame(width: sideChatWidth)
                }
                .padding(Spacing.l)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.l) {
                        mainColumn
                        ChatView(streamID: model.stream.id)
                            .frame(height: inlineChatHeight)
                    }
                    .padding(Spacing.m)
                }
            }
        }
        .background(Palette.background)
        .navigationTitle(model.stream.channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadMarkers(from: repository) }
    }

    private var mainColumn: some View {
        VStack(spacing: Spacing.l) {
            PlayerView(model: model)
            ChannelHeaderView(stream: model.stream, isFollowing: $model.isFollowing)
            if !model.markers.isEmpty {
                StreamMomentsView(markers: model.markers, onSeek: model.seek(to:))
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchView(stream: MockData.streams[0])
    }
    .environment(\.streamRepository, MockStreamRepository.instant)
}
