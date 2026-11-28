import SwiftUI

/// Все идущие эфиры списком в порядке рекомендаций — по кнопке «Ещё». Подгружаются страницами.
struct LiveStreamsListView: View {
    private static let pageSize = 20

    @Environment(\.streamRepository) private var repository
    @State private var streams: [LiveStream] = []
    @State private var total: Int?
    @State private var isLoading = false

    var body: some View {
        List {
            ForEach(streams) { stream in
                NavigationLink(value: stream.channel) {
                    StreamRowView(stream: stream)
                }
                .onAppear {
                    if stream.id == streams.last?.id { Task { await loadMore() } }
                }
            }
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .overlay {
            if total == 0 {
                ContentUnavailableView("Эфиров сейчас нет", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
        .navigationTitle(total.map { "Сейчас в эфире · \($0)" } ?? "Сейчас в эфире")
        .navigationBarTitleDisplayMode(.inline)
        .task { if streams.isEmpty { await loadMore() } }
        .refreshable {
            streams = []
            total = nil
            await loadMore()
        }
    }

    private func loadMore() async {
        guard !isLoading, total.map({ streams.count < $0 }) ?? true else { return }
        isLoading = true
        defer { isLoading = false }
        guard let page = try? await repository.recommendedStreams(offset: streams.count, limit: Self.pageSize) else { return }
        let known = Set(streams.map(\.id))
        streams += page.streams.filter { !known.contains($0.id) }
        total = page.total
    }
}
