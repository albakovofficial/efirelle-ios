import SwiftUI

/// Экран канала. На iPhone чат идёт под плеером, на iPad и в широком окне — справа.
struct WatchView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: WatchViewModel

    private let sideChatWidth: CGFloat = 380
    private let inlineChatHeight: CGFloat = 560

    init(channel: Channel) {
        _model = State(initialValue: WatchViewModel(channel: channel))
    }

    var body: some View {
        LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { watch in
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: Spacing.l) {
                    ScrollView { mainColumn(watch) }
                    ChatView(model: model.chat)
                        .frame(width: sideChatWidth)
                }
                .padding(Spacing.l)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.l) {
                        mainColumn(watch)
                        ChatView(model: model.chat)
                            .frame(height: inlineChatHeight)
                    }
                    .padding(Spacing.m)
                }
            }
        }
        .background(Palette.background)
        .navigationTitle(model.state.value?.channel.name ?? model.channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(from: repository) }
        .task { await model.listen(to: repository) }
    }

    private func mainColumn(_ watch: ChannelWatch) -> some View {
        VStack(spacing: Spacing.l) {
            if let stream = watch.stream {
                PlayerView(stream: stream, viewers: model.viewers)
            } else {
                OfflineStageView(channel: watch.channel)
            }
            ChannelHeaderView(model: model, watch: watch)
            if watch.stream != nil, !model.markers.isEmpty {
                StreamMomentsView(markers: model.markers)
            }
        }
    }
}

/// Заставка, пока канал не в эфире. Экран обновится сам, когда эфир начнётся.
private struct OfflineStageView: View {
    let channel: Channel

    var body: some View {
        ThumbnailView(tone: channel.tone, cornerRadius: Radius.l)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(channel.name) сейчас не в эфире")
                        .font(.brandHeadline)
                        .foregroundStyle(Palette.ink)
                    Text("Экран обновится сам, когда эфир начнётся")
                        .font(.brandCaption)
                        .foregroundStyle(channel.tone.ink)
                }
                .padding(Spacing.m)
            }
            .padding(Spacing.xs)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
    }
}

#Preview {
    NavigationStack {
        WatchView(channel: MockData.Channels.timur)
    }
    .environment(Session())
    .environment(PushNotifications())
}
