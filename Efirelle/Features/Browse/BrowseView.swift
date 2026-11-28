import SwiftUI

/// Вкладка «Обзор»: все категории и поиск по каналам, эфирам и категориям.
struct BrowseView: View {
    @Environment(\.streamRepository) private var repository
    @State private var categories: LoadState<[StreamCategory]> = .idle
    @State private var query = ""
    @State private var results: SearchResults?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: Spacing.s)]

    var body: some View {
        NavigationStack {
            Group {
                if query.isBlank {
                    LoadStateView(state: categories, retry: loadCategories) { categories in
                        ScrollView {
                            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.m) {
                                ForEach(categories) { category in
                                    NavigationLink(value: category) { CategoryCardView(category: category) }
                                        .buttonStyle(.plain)
                                }
                            }
                            .padding(Spacing.m)
                        }
                    }
                    .refreshable { await loadCategories() }
                } else {
                    SearchResultsView(results: results)
                }
            }
            .background(Palette.background)
            .navigationTitle("Обзор")
            .searchable(text: $query, prompt: "Каналы, эфиры, категории")
            .appDestinations()
        }
        .task { await loadCategories() }
        .task(id: query) { await search() }
    }

    private func loadCategories() async {
        if categories.value == nil { categories = .loading }
        if let result = await LoadState<[StreamCategory]>.result(of: { try await repository.categories() }) {
            categories = result
        }
    }

    /// Ищем, когда пользователь перестал печатать.
    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = nil
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(350))
            results = try await repository.search(text)
        } catch {
            // Отмена (печатают дальше) или нет сети — оставляем прошлые результаты.
        }
    }
}

private struct SearchResultsView: View {
    let results: SearchResults?

    var body: some View {
        if let results {
            if results.isEmpty {
                ContentUnavailableView.search(text: results.query)
            } else {
                List {
                    if !results.channels.isEmpty {
                        Section("Каналы") {
                            ForEach(results.channels) { status in
                                NavigationLink(value: status.channel) { ChannelStatusRow(status: status) }
                            }
                        }
                    }
                    if !results.categories.isEmpty {
                        Section("Категории") {
                            ForEach(results.categories) { category in
                                NavigationLink(category.name, value: category)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    BrowseView()
}
