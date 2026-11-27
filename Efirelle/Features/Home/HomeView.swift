import SwiftUI

/// Главная: отслеживаемые, витрина, живые моменты, категории и лента «Для вас».
struct HomeView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model = HomeViewModel()

    var body: some View {
        NavigationStack {
            LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { content in
                HomeContentView(content: content, filter: $model.filter, forYou: model.filteredForYou)
            }
            .background(Palette.background)
            .refreshable { await model.load(from: repository) }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    LogoView(size: 22)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let viewer = model.state.value?.viewer {
                        SparksBalanceView(amount: viewer.sparks)
                    }
                }
            }
            .watchDestination()
        }
        .task { await model.loadIfNeeded(from: repository) }
    }
}

private struct HomeContentView: View {
    let content: HomeViewModel.Content
    @Binding var filter: StreamFilter
    let forYou: [LiveStream]

    /// Эфир по каналу — чтобы карточка момента вела в нужный эфир.
    private var streamsByChannel: [Channel.ID: LiveStream] {
        let all = content.following + content.featured + content.forYou
        return Dictionary(all.map { ($0.channel.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                if !content.following.isEmpty {
                    FollowingStripView(streams: content.following)
                }
                featured
                moments
                categories
                forYouSection
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
    }

    @ViewBuilder
    private var featured: some View {
        if let main = content.featured.first {
            VStack(spacing: Spacing.xs) {
                NavigationLink(value: main) {
                    FeaturedStreamCard(stream: main)
                }
                ForEach(content.featured.dropFirst()) { stream in
                    NavigationLink(value: stream) {
                        StreamRowView(stream: stream)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var moments: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Живые моменты", subtitle: "Подключайтесь в самый разгар")
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.s) {
                    ForEach(content.moments) { moment in
                        if let stream = streamsByChannel[moment.channel.id] {
                            NavigationLink(value: stream) { MomentCardView(moment: moment) }
                                .buttonStyle(.plain)
                        } else {
                            MomentCardView(moment: moment)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Категории")
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(content.categories) { category in
                        CategoryCardView(category: category)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Для вас в эфире")
            Picker("Фильтр", selection: $filter) {
                ForEach(StreamFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if forYou.isEmpty {
                ContentUnavailableView("Таких эфиров сейчас нет", systemImage: "antenna.radiowaves.left.and.right.slash")
            } else {
                ForEach(forYou) { stream in
                    NavigationLink(value: stream) {
                        StreamCardView(stream: stream)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(\.streamRepository, MockStreamRepository.instant)
}
