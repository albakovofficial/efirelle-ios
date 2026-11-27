/// Тестовые данные. Используются только `MockStreamRepository`, превью и тестами.
enum MockData {
    // MARK: Каналы

    enum Channels {
        static let timur = Channel(id: "timur-sever", name: "Тимур Север", initials: "ТС", tone: .ink, followers: 312_000, isVerified: true)
        static let mira = Channel(id: "mira", name: "Мира Вольская", initials: "МВ", tone: .mint, followers: 486_000, isVerified: true)
        static let alisa = Channel(id: "alisa-green", name: "Алиса Грин", initials: "АГ", tone: .rose, followers: 74_000, isVerified: false)
        static let kitchen = Channel(id: "dom-kulinara", name: "Дом Кулинара", initials: "ДК", tone: .peach, followers: 128_000, isVerified: false)
        static let soundLab = Channel(id: "sound-lab", name: "Лаборатория Звука", initials: "ЛЗ", tone: .lavender, followers: 96_000, isVerified: false)
        static let marat = Channel(id: "marat-put", name: "Марат Путь", initials: "МП", tone: .butter, followers: 41_000, isVerified: false)
        static let nika = Channel(id: "nika-leto", name: "Ника Лето", initials: "НЛ", tone: .mint, followers: 22_000, isVerified: false)
        static let sonya = Channel(id: "sonya-ri", name: "Соня Ри", initials: "СР", tone: .rose, followers: 18_000, isVerified: false)
        static let kai = Channel(id: "kai-vetrov", name: "Кай Ветров", initials: "КВ", tone: .butter, followers: 205_000, isVerified: false)
    }

    // MARK: Эфиры

    static let streams: [LiveStream] = [
        stream("s-timur", Channels.timur, "Финал сезона — играем до победы. Прогноз в чате!", "Стратегии", ["Русский", "Соревновательно"], 18_702, 13_690, "Финал сезона · стратегии", .sky),
        stream("s-mira", Channels.mira, "Ночная сессия: живой рояль и ваши заявки", "Музыка", ["Фортепиано", "Русский"], 12_418, 6_120, "Рояль по заявкам", .mint),
        stream("s-alisa", Channels.alisa, "Акварель с нуля: рисуем зимний Петербург", "Искусство", ["Рисование", "Обучение"], 3_204, 3_300, "Акварель · Петербург", .rose),
        stream("s-kitchen", Channels.kitchen, "Готовим хачапури по-аджарски", "Кулинария", ["Рецепт", "Русский"], 5_610, 2_160, "Хачапури по-аджарски", .peach),
        stream("s-sound", Channels.soundLab, "Собираем синтезатор вживую", "Музыка", ["Железо", "DIY"], 4_820, 7_400, "Собираем синтезатор", .lavender),
        stream("s-marat", Channels.marat, "Пешком по Казани: старый город", "Путешествия", ["IRL", "Прогулка"], 2_310, 4_800, "Пешком по Казани", .butter),
        stream("s-nika", Channels.nika, "Утренний кофе и разговор о дизайне", "Просто общение", ["Дизайн", "Русский"], 1_120, 8_040, "Кофе и дизайн", .mint),
        stream("s-sonya", Channels.sonya, "Скетчинг персонажей: вопросы и ответы", "Искусство", ["Рисование", "Обучение"], 1_930, 2_880, "Скетчинг персонажей", .rose),
        stream("s-kai", Channels.kai, "Ранговые до рассвета", "Шутеры", ["Соревновательно", "Русский"], 6_240, 19_860, "Ранговые до рассвета", .butter),
    ]

    static let followingIDs = ["s-timur", "s-mira", "s-alisa", "s-kitchen", "s-sound", "s-marat"]
    static let featuredIDs = ["s-timur", "s-mira", "s-alisa", "s-sound"]
    static let forYouIDs = ["s-nika", "s-sonya", "s-kai", "s-marat", "s-kitchen"]

    static func streams(ids: [LiveStream.ID]) -> [LiveStream] {
        ids.compactMap { id in streams.first { $0.id == id } }
    }

    // MARK: Моменты

    static let liveMoments: [Moment] = [
        Moment(id: "m1", kind: .raid, text: "Алиса Грин привела 3 200 зрителей к Ника Лето", channel: Channels.nika, when: "2 мин назад", offset: .seconds(8_000)),
        Moment(id: "m2", kind: .prediction, text: "Возьмёт ли Тимур финальную карту? 61% верят в победу", channel: Channels.timur, when: "идёт сейчас", offset: .seconds(13_600)),
        Moment(id: "m3", kind: .chatPeak, text: "Чат взорвался: Мира сыграла заявку с первой ноты", channel: Channels.mira, when: "4 мин назад", offset: .seconds(5_880)),
        Moment(id: "m4", kind: .giveaway, text: "Синтезатор от Лаборатории Звука — участвуйте за искры", channel: Channels.soundLab, when: "через 10 мин", offset: .seconds(7_400)),
    ]

    static let markers: [LiveStream.ID: [Moment]] = [
        "s-timur": [
            Moment(id: "t1", kind: .highlight, text: "Начало финала", channel: Channels.timur, when: "", offset: .seconds(760)),
            Moment(id: "t2", kind: .highlight, text: "Камбэк на второй карте", channel: Channels.timur, when: "", offset: .seconds(5_465)),
            Moment(id: "t3", kind: .chatPeak, text: "Пик чата", channel: Channels.timur, when: "", offset: .seconds(10_042)),
            Moment(id: "t4", kind: .raid, text: "Рейд от Алисы Грин", channel: Channels.timur, when: "", offset: .seconds(13_258)),
        ],
    ]

    // MARK: Категории

    static let categories: [StreamCategory] = [
        StreamCategory(id: "strategy", name: "Стратегии", group: "Игры", viewers: 42_000, tone: .sky),
        StreamCategory(id: "music", name: "Музыка", group: "Творчество", viewers: 31_000, tone: .lavender),
        StreamCategory(id: "talk", name: "Просто общение", group: "IRL", viewers: 58_000, tone: .mint),
        StreamCategory(id: "art", name: "Искусство", group: "Творчество", viewers: 9_000, tone: .rose),
        StreamCategory(id: "food", name: "Кулинария", group: "IRL", viewers: 7_000, tone: .peach),
        StreamCategory(id: "shooters", name: "Шутеры", group: "Игры", viewers: 64_000, tone: .butter),
    ]

    // MARK: Чат и прогноз

    static let chatHistory: [ChatEntry] = [
        .message(ChatMessage(id: "c1", author: "Аня", tone: .rose, badge: .subscriber(months: 12), text: "этот камбэк войдёт в историю")),
        .message(ChatMessage(id: "c2", author: "Дмитрий", tone: .sky, badge: .newcomer, text: "первый раз тут, атмосфера топ")),
        .message(ChatMessage(id: "c3", author: "Ильдар", tone: .lavender, badge: .moderator, text: "Прогноз открыт, ставим искры")),
        .message(ChatMessage(id: "c4", author: "Лиза", tone: .mint, badge: .vip, text: "Тимур, следи за левым флангом")),
        .message(ChatMessage(id: "c5", author: "Георгий", tone: .butter, badge: .subscriber(months: 3), text: "GG, если возьмёт эту карту")),
        .message(ChatMessage(id: "c6", author: "Катя", tone: .peach, badge: .newcomer, text: "а клип второй карты уже есть?")),
        .event(ChatEvent(id: "c7", tone: .rose, text: "Рейд: Алиса Грин и 3 200 зрителей заходят в эфир")),
    ]

    static let predictions: [LiveStream.ID: Prediction] = [
        "s-timur": Prediction(
            id: "p1",
            question: "Возьмёт ли Тимур финальную карту?",
            timeLeft: .seconds(84),
            participants: 4_812,
            outcomes: [
                .init(id: "yes", title: "Да, забирает", percent: 61, tone: .sky),
                .init(id: "no", title: "Нет, проиграет", percent: 39, tone: .peach),
            ]
        ),
    ]

    static let viewer = Viewer(name: "Ибрагим", initials: "ИА", tone: .peach, sparks: 2_480)

    // MARK: Сборка

    private static func stream(
        _ id: String,
        _ channel: Channel,
        _ title: String,
        _ category: String,
        _ tags: [String],
        _ viewers: Int,
        _ seconds: Int,
        _ status: String,
        _ tone: Tone
    ) -> LiveStream {
        LiveStream(
            id: id,
            channel: channel,
            title: title,
            category: category,
            tags: tags,
            viewers: viewers,
            duration: .seconds(seconds),
            quality: "1080p60",
            latency: .milliseconds(1_200),
            status: status,
            tone: tone,
            playbackURL: nil
        )
    }
}
