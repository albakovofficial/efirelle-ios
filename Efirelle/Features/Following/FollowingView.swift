import SwiftUI

/// Вкладка «Отслеживаемые»: каналы в эфире прямо сейчас.
struct FollowingView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model = FollowingViewModel()

    var body: some View {
        NavigationStack {
            LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { streams in
                if streams.isEmpty {
                    ContentUnavailableView(
                        "Никого нет в эфире",
                        systemImage: "heart",
                        description: Text("Когда отслеживаемые каналы начнут трансляцию, они появятся здесь.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.xs) {
                            ForEach(streams) { stream in
                                NavigationLink(value: stream) {
                                    StreamRowView(stream: stream)
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
            .background(Palette.background)
            .refreshable { await model.load(from: repository) }
            .navigationTitle("Отслеживаемые")
            .watchDestination()
        }
        .task { await model.load(from: repository) }
    }
}

#Preview {
    FollowingView()
        .environment(\.streamRepository, MockStreamRepository.instant)
}
