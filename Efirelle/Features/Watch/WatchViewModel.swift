import Observation

/// Экран канала: загрузка, события в реальном времени (зрители, начало и конец эфира, моменты),
/// отслеживание. Чатом занимается `ChatViewModel`, ему передаются события чата.
@MainActor
@Observable
final class WatchViewModel {
    /// Пауза между попытками переподключиться к чату растёт до этого предела.
    static let maxReconnectDelay: Duration = .seconds(15)

    let channel: Channel
    let chat: ChatViewModel
    private(set) var state: LoadState<ChannelWatch> = .idle
    private(set) var viewers = 0
    private(set) var markers: [Moment] = []
    private(set) var isFollowing = false
    private(set) var followers = 0
    private(set) var isUpdatingFollow = false

    init(channel: Channel) {
        self.channel = channel
        chat = ChatViewModel(channelID: channel.id)
    }

    var stream: LiveStream? { state.value?.stream }

    func load(from repository: any StreamRepository) async {
        if state.value == nil {
            state = .loading
        }
        guard let result = await LoadState<ChannelWatch>.result(of: { try await repository.watch(channel: channel.id) }) else { return }
        state = result
        if let watch = result.value {
            viewers = watch.stream?.viewers ?? 0
            markers = watch.markers
            isFollowing = watch.isFollowing
            followers = watch.channel.followers
            chat.reset(messages: watch.chat, prediction: watch.prediction, isOwner: watch.isOwner, emotes: watch.emotes, rules: watch.chatRules)
        }
    }

    /// Слушает события канала, пока экран открыт. При обрыве переподключается с растущей паузой.
    func listen(to repository: any StreamRepository) async {
        var delay: Duration = .seconds(1)
        while !Task.isCancelled {
            for await event in repository.chatEvents(channel: channel.id) {
                delay = .seconds(1)
                await handle(event, repository: repository)
            }
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            delay = min(delay * 2, Self.maxReconnectDelay)
        }
    }

    func handle(_ event: ChatServerEvent, repository: any StreamRepository) async {
        switch event {
        case .viewers(let count):
            viewers = count
        case .live:
            // Эфир начался или закончился — берём свежие данные канала целиком.
            await load(from: repository)
        case .moment(let moment):
            markers.removeAll { $0.id == moment.id }
            markers.append(moment)
        default:
            chat.apply(event)
        }
    }

    /// Сразу меняет кнопку; при ошибке сервера возвращает как было.
    func toggleFollow(using repository: any StreamRepository) async {
        guard !isUpdatingFollow else { return }
        let target = !isFollowing
        isFollowing = target
        isUpdatingFollow = true
        defer { isUpdatingFollow = false }
        do {
            let result = try await repository.setFollowing(target, channel: channel.id)
            isFollowing = result.isFollowing
            followers = result.followers
        } catch {
            isFollowing = !target
        }
    }
}
