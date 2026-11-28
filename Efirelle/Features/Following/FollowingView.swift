import SwiftUI

/// Вкладка «Отслеживаемые»: каналы из подписок, кто в эфире — сверху.
struct FollowingView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @State private var model = FollowingViewModel()
    @State private var showsSignIn = false

    var body: some View {
        NavigationStack {
            Group {
                if session.viewer == nil {
                    ContentUnavailableView {
                        Label("Отслеживаемые", systemImage: "heart")
                    } description: {
                        Text("Войдите, чтобы отслеживать каналы и видеть, кто из них сейчас в эфире.")
                    } actions: {
                        Button("Войти") { showsSignIn = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { channels in
                        list(channels)
                    }
                    .refreshable { await model.load(from: repository) }
                }
            }
            .background(Palette.background)
            .navigationTitle("Отслеживаемые")
            .appDestinations()
            .signInSheet(isPresented: $showsSignIn)
        }
        .task(id: session.viewer?.id) {
            guard session.viewer != nil else { return }
            await model.load(from: repository)
        }
    }

    @ViewBuilder
    private func list(_ channels: [ChannelStatus]) -> some View {
        if channels.isEmpty {
            ContentUnavailableView(
                "Пока пусто",
                systemImage: "heart",
                description: Text("Нажмите «Отслеживать» на странице канала — он появится здесь.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(channels) { status in
                        NavigationLink(value: status.channel) {
                            ChannelStatusRow(status: status)
                                .padding(Spacing.xs)
                                .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.m)
            }
        }
    }
}

#Preview {
    FollowingView()
        .environment(Session())
}
