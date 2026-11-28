import SwiftUI

/// Канал под плеером: автор, название эфира, теги и кнопка «Отслеживать» (или «Студия» для автора).
struct ChannelHeaderView: View {
    let model: WatchViewModel
    let watch: ChannelWatch

    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @State private var showsSignIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.s) {
                AvatarView(channel: watch.channel, size: .large, ring: watch.stream == nil ? nil : .live)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: 6) {
                        Text(watch.channel.name)
                            .font(.brandHeadline)
                        if watch.channel.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Palette.accent)
                                .accessibilityLabel("Подтверждённый канал")
                        }
                    }
                    Text(Formatters.count(model.followers, .followers))
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                }
            }

            if let stream = watch.stream {
                Text(stream.title)
                    .font(.brandTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                TagsView(tags: [stream.category] + stream.tags, leadingTone: stream.tone)
            }

            action
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .signInSheet(isPresented: $showsSignIn)
    }

    @ViewBuilder
    private var action: some View {
        if watch.isOwner {
            NavigationLink { StudioView() } label: {
                Label("Студия", systemImage: "dot.radiowaves.left.and.right")
                    .font(.brandCallout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Palette.ink)
        } else {
            Button {
                if session.viewer == nil {
                    showsSignIn = true
                } else {
                    Task { await model.toggleFollow(using: repository) }
                }
            } label: {
                Label(model.isFollowing ? "Отслеживаете" : "Отслеживать", systemImage: model.isFollowing ? "heart.fill" : "heart")
                    .font(.brandCallout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(model.isFollowing ? Palette.ink : Palette.accent)
            .disabled(model.isUpdatingFollow)
            .sensoryFeedback(.selection, trigger: model.isFollowing)
        }
    }
}
