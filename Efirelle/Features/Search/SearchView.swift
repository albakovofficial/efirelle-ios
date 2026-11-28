import SwiftUI

/// Вкладка «Поиск»: недавние запросы, «Сейчас в эфире» (рекомендации и «Ещё») и категории списком.
/// Когда пользователь печатает — каналы, эфиры и категории по запросу.
struct SearchView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model = SearchViewModel()
    @State private var recent = RecentSearches()

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Group {
                if model.isSearching {
                    SearchResultsView(results: model.results) { recent.add(model.query) }
                } else {
                    LoadStateView(state: model.categories, retry: { await model.load(from: repository) }) { categories in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: Spacing.l) {
                                if !recent.items.isEmpty { recentSection }
                                if !model.live.isEmpty { liveSection }
                                categoriesSection(categories)
                            }
                            .padding(Spacing.m)
                        }
                    }
                    .refreshable { await model.load(from: repository) }
                }
            }
            .background(Palette.background)
            .navigationTitle("Поиск")
            .searchable(text: $model.query, prompt: "Каналы, эфиры, категории")
            .onSubmit(of: .search) { recent.add(model.query) }
            .appDestinations()
        }
        .task { await model.load(from: repository) }
        .task(id: model.query) { await model.search(using: repository) }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Недавние").font(.brandHeadline).foregroundStyle(Palette.ink)
                Spacer()
                Button("Очистить", action: recent.clear)
                    .font(.brandCaption)
                    .foregroundStyle(Palette.accent)
            }
            FlowLayout(spacing: 6) {
                ForEach(recent.items, id: \.self) { item in
                    Button {
                        model.query = item
                    } label: {
                        Label(item, systemImage: "clock")
                            .font(.brandCaption)
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(Palette.surface, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Убрать из недавних", systemImage: "xmark", role: .destructive) { recent.remove(item) }
                    }
                }
            }
        }
    }

    private var liveSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Сейчас в эфире").font(.brandHeadline).foregroundStyle(Palette.ink)
                Spacer()
                if model.liveTotal > model.live.count {
                    NavigationLink {
                        LiveStreamsListView()
                    } label: {
                        Text("Ещё \(model.liveTotal - model.live.count)")
                            .font(.brandCaption)
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(model.live) { stream in
                        NavigationLink(value: stream.channel) {
                            StreamCardView(stream: stream).frame(width: 240)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func categoriesSection(_ categories: [StreamCategory]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Категории").font(.brandHeadline).foregroundStyle(Palette.ink)
            VStack(spacing: 0) {
                ForEach(categories) { category in
                    NavigationLink(value: category) { CategoryRowView(category: category) }
                        .buttonStyle(.plain)
                    if category.id != categories.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        }
    }
}

/// Результаты поиска: каналы и категории. Нажатие на результат запоминает запрос в недавних.
private struct SearchResultsView: View {
    let results: SearchResults?
    let onOpen: () -> Void

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
                                    .simultaneousGesture(TapGesture().onEnded(onOpen))
                            }
                        }
                    }
                    if !results.categories.isEmpty {
                        Section("Категории") {
                            ForEach(results.categories) { category in
                                NavigationLink(value: category) { CategoryRowView(category: category) }
                                    .simultaneousGesture(TapGesture().onEnded(onOpen))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SearchView()
}
