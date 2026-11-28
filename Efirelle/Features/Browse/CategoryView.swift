import SwiftUI

/// Эфиры одной категории, самые популярные — первыми.
struct CategoryView: View {
    let category: StreamCategory

    @Environment(\.streamRepository) private var repository
    @State private var state: LoadState<CategoryStreams> = .idle

    var body: some View {
        LoadStateView(state: state, retry: load) { content in
            if content.streams.isEmpty {
                ContentUnavailableView(
                    "Сейчас никого нет",
                    systemImage: "antenna.radiowaves.left.and.right.slash",
                    description: Text("В категории «\(content.category.name)» пока нет эфиров — загляните позже.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.l) {
                        ForEach(content.streams) { stream in
                            NavigationLink(value: stream.channel) { StreamCardView(stream: stream) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.m)
                }
            }
        }
        .background(Palette.background)
        .refreshable { await load() }
        .navigationTitle(category.name)
        .task { await load() }
    }

    private func load() async {
        if state.value == nil { state = .loading }
        if let result = await LoadState<CategoryStreams>.result(of: { try await repository.category(id: category.id) }) {
            state = result
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView(category: MockData.categories[1])
    }
}
