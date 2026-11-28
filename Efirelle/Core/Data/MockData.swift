import Foundation

/// Тестовые данные. Используются только `MockStreamRepository`, превью и тестами.
enum MockData {
    // MARK: Каналы

    enum Channels {
        static let timur = Channel(id: "timur", name: "Тимур Север", initials: "ТС", tone: .ink, followers: 312_000, isVerified: true)
        static let mira = Channel(id: "mira", name: "Мира Вольская", initials: "МВ", tone: .mint, followers: 486_000, isVerified: true)
        static let alisa = Channel(id: "alisa", name: "Алиса Грин", initials: "АГ", tone: .rose, followers: 74_000)
        static let kitchen = Channel(id: "kitchen", name: "Дом Кулинара", initials: "ДК", tone: .peach, followers: 128_000)
        static let nika = Channel(id: "nika", name: "Ника Лето", initials: "НЛ", tone: .mint, followers: 22_000)
        static let kai = Channel(id: "kai", name: "Кай Ветров", initials: "КВ", tone: .butter, followers: 205_000)
        static let offline = Channel(id: "sonya", name: "Соня Ри", initials: "СР", tone: .rose, followers: 18_000)
    }

    // MARK: Эфиры

    static let streams: [LiveStream] = [
        stream("s-timur", Channels.timur, "Финал сезона — играем до победы. Прогноз в чате!", "Стратегии", "strategy", ["Соревновательно"], 18_702, 13_690, .sky),
        stream("s-mira", Channels.mira, "Ночная сессия: живой рояль и ваши заявки", "Музыка", "music", ["Фортепиано"], 12_418, 6_120, .mint),
        stream("s-alisa", Channels.alisa, "Акварель с нуля: рисуем зимний Петербург", "Искусство", "art", ["Обучение"], 3_204, 3_300, .rose),
        stream("s-kitchen", Channels.kitchen, "Готовим хачапури по-аджарски", "Кулинария", "food", ["Рецепт"], 5_610, 2_160, .peach),
        stream("s-nika", Channels.nika, "Утренний кофе и разговор о дизайне", "Просто общение", "talk", ["Дизайн"], 1_120, 8_040, .mint),
        stream("s-kai", Channels.kai, "Ранговые до рассвета", "Шутеры", "shooters", ["Соревновательно"], 6_240, 19_860, .butter),
    ]

    static let moments: [Moment] = [
        Moment(id: "m1", kind: .raid, text: "Алиса Грин привела зрителей: 3 200", channel: Channels.nika, when: "2 мин назад", offset: .seconds(8_000)),
        Moment(id: "m2", kind: .prediction, text: "Прогноз: возьмёт ли Тимур финальную карту?", channel: Channels.timur, when: "только что", offset: .seconds(13_600)),
        Moment(id: "m3", kind: .chatPeak, text: "Пик чата: 240 сообщений в минуту", channel: Channels.mira, when: "4 мин назад", offset: .seconds(5_880)),
    ]

    static let categories: [StreamCategory] = [
        StreamCategory(id: "shooters", name: "Шутеры", group: "Игры", viewers: 6_240, liveCount: 1, tone: .butter),
        StreamCategory(id: "strategy", name: "Стратегии", group: "Игры", viewers: 18_702, liveCount: 1, tone: .sky),
        StreamCategory(id: "music", name: "Музыка", group: "Творчество", viewers: 12_418, liveCount: 1, tone: .lavender),
        StreamCategory(id: "talk", name: "Просто общение", group: "Общение", viewers: 1_120, liveCount: 1, tone: .mint),
        StreamCategory(id: "art", name: "Искусство", group: "Творчество", viewers: 3_204, liveCount: 1, tone: .rose),
        StreamCategory(id: "food", name: "Кулинария", group: "Жизнь", viewers: 5_610, liveCount: 1, tone: .peach),
    ]

    // MARK: Чат и прогноз

    static let chat: [ChatMessage] = [
        message("c1", "Аня", "anya", .rose, nil, "этот камбэк войдёт в историю"),
        message("c2", "Дмитрий", "dima", .sky, .newcomer, "первый раз тут, атмосфера топ"),
        message("c3", "Тимур Север", "timur", .ink, .broadcaster, "Прогноз открыт, выбирайте вариант"),
        message("c4", "Лиза", "liza", .mint, .moderator, "Напоминаю: уважаем друг друга"),
    ]

    static let prediction = Prediction(
        id: "p1",
        question: "Возьмёт ли Тимур финальную карту?",
        status: .open,
        endsInSeconds: 84,
        participants: 4_812,
        outcomes: [
            .init(id: "yes", label: "Да, забирает", percent: 61, votes: 2_935, tone: .sky),
            .init(id: "no", label: "Нет, проиграет", percent: 39, votes: 1_877, tone: .peach),
        ],
        myOutcomeId: nil,
        winningOutcomeId: nil
    )

    static let viewer = Viewer(
        id: "u-demo", email: "demo@efirelle.ru", username: "demo", displayName: "Демо Зритель",
        initials: "ДЗ", role: .user, tone: .peach, sparks: 2_480, avatarUrl: nil
    )

    static func watch(_ channel: Channel.ID) -> ChannelWatch? {
        if let stream = streams.first(where: { $0.channel.id == channel }) {
            return ChannelWatch(
                channel: stream.channel, stream: stream, isFollowing: false, isOwner: false,
                markers: moments.filter { $0.channel.id == channel },
                prediction: channel == Channels.timur.id ? prediction : nil,
                chat: chat,
                about: about,
                emotes: [],
                schedule: schedule,
                recordings: [],
                clips: []
            )
        }
        guard channel == Channels.offline.id else { return nil }
        return ChannelWatch(
            channel: Channels.offline, stream: nil, isFollowing: true, isOwner: false, markers: [], prediction: nil, chat: [],
            about: ChannelAbout(description: "", links: [], bannerUrl: nil), emotes: [], schedule: schedule,
            recordings: [], clips: []
        )
    }

    static let following: [ChannelStatus] = [
        ChannelStatus(channel: Channels.timur, stream: streams[0]),
        ChannelStatus(channel: Channels.mira, stream: streams[1]),
        ChannelStatus(channel: Channels.offline, stream: nil),
    ]

    static let home = HomeFeed(
        following: following.filter { $0.stream != nil },
        featured: Array(streams.prefix(3)),
        moments: moments,
        categories: categories,
        forYou: streams,
        upcoming: schedule,
        clips: []
    )

    static let studio = Studio(
        channel: Channel(id: "demo", name: "Демо Зритель", initials: "ДЗ", tone: .peach, followers: 12),
        stream: nil,
        settings: .init(title: "Мой первый эфир", categoryId: "talk", tags: ["Общение"]),
        ingest: .init(server: "rtmp://efirelle.ru/live", streamKey: "demo?key=preview"),
        prediction: nil,
        bans: [],
        about: about,
        emotes: [],
        schedule: schedule
    )

    static let about = ChannelAbout(
        description: "Финалы турниров и разборы партий каждую пятницу.",
        links: [.init(title: "Telegram", url: "https://t.me/efirelle")],
        bannerUrl: nil
    )

    static let schedule: [ScheduledStream] = [
        ScheduledStream(
            id: "sc1", channel: Channels.offline, title: "Акварель на ночь", category: "Искусство", categoryId: "art",
            startsAt: Date(timeIntervalSince1970: 1_800_000_000), reminders: 12, isReminded: false
        ),
    ]

    // MARK: Сборка

    private static func stream(
        _ id: String, _ channel: Channel, _ title: String, _ category: String, _ categoryID: String,
        _ tags: [String], _ viewers: Int, _ seconds: Int, _ tone: Tone
    ) -> LiveStream {
        LiveStream(
            id: id, channel: channel, title: title, category: category, categoryID: categoryID, tags: tags,
            viewers: viewers, duration: .seconds(seconds), status: title, tone: tone
        )
    }

    private static func message(
        _ id: String, _ author: String, _ slug: String, _ tone: Tone, _ badge: ChatBadge?, _ text: String
    ) -> ChatMessage {
        ChatMessage(id: id, author: author, authorSlug: slug, authorId: "u-\(slug)", tone: tone, badge: badge, text: text)
    }
}
