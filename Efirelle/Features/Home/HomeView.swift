import SwiftUI

/// Главная: отслеживаемые, витрина, живые моменты, категории и лента «Для вас».
struct HomeView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @State private var model = HomeViewModel()

    var body: some View {
        NavigationStack {
            LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { content in
                HomeContentView(feed: content, following: model.followingLive, filter: $model.filter, forYou: model.filteredForYou)
            }
            .background(Palette.background)
            .refreshable { await model.load(from: repository) }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    LogoView(size: 22)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let viewer = session.viewer {
                        SparksBalanceView(amount: viewer.sparks)
                    }
                }
            }
            .appDestinations()
        }
        // Вход и выход меняют ленту (отслеживаемые) — перезагружаем.
        .task(id: session.viewer?.id) { await model.load(from: repository) }
    }
}

private struct HomeContentView: View {
    let feed: HomeFeed
    let following: [LiveStream]
    @Binding var filter: StreamFilter
    let forYou: [LiveStream]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                if !following.isEmpty {
                    FollowingStripView(streams: following)
                }
                if feed.featured.isEmpty {
                    ContentUnavailableView(
                        "Сейчас никто не в эфире",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Станьте первым: адрес сервера и ключ для OBS — в Профиле → Студия.")
                    )
                } else {
                    featured
                }
                if !feed.upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        SectionHeader(title: "Скоро в эфире", subtitle: "Нажмите «Напомнить» — пришлём уведомление")
                        ScheduleStripView(items: feed.upcoming)
                    }
                }
                if !feed.moments.isEmpty {
                    moments
                }
                if !feed.clips.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        SectionHeader(title: "Популярные клипы", subtitle: "Лучшие моменты недели")
                        ClipsStripView(clips: feed.clips)
                    }
                }
                categories
                if !feed.forYou.isEmpty {
                    forYouSection
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
    }

    @ViewBuilder
    private var featured: some View {
        if let main = feed.featured.first {
            VStack(spacing: Spacing.xs) {
                NavigationLink(value: main.channel) {
                    FeaturedStreamCard(stream: main)
                }
                ForEach(feed.featured.dropFirst()) { stream in
                    NavigationLink(value: stream.channel) {
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
                    ForEach(feed.moments) { moment in
                        NavigationLink(value: moment.channel) { MomentCardView(moment: moment) }
                            .buttonStyle(.plain)
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
                    ForEach(feed.categories) { category in
                        NavigationLink(value: category) { CategoryCardView(category: category) }
                            .buttonStyle(.plain)
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
                    NavigationLink(value: stream.channel) {
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
        .environment(Session())
        .environment(PushNotifications())
}
