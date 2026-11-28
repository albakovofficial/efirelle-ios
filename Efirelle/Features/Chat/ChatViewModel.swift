import Foundation
import Observation
import UIKit

/// Чат эфира: лента в реальном времени, фильтр «Важное», отправка, прогноз и модерация
/// (жалобы, скрытие авторов, удаление, запрет писать — требования App Review 1.2).
/// Отправка идёт запросом к API, сообщение возвращается в ленту событием `message` — как у всех.
@MainActor
@Observable
final class ChatViewModel {
    enum Scope: String, CaseIterable, Identifiable {
        case all
        case important

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "Все"
            case .important: "Важное"
            }
        }
    }

    static let maxMessageLength = 500
    static let maxEntries = 200

    let channelID: Channel.ID
    private(set) var entries: [ChatEntry] = []
    private(set) var prediction: Prediction?
    private(set) var predictionTimeLeft: Duration = .zero
    /// Зритель — автор этого канала: может удалять сообщения и запрещать писать.
    private(set) var isOwner = false
    /// Медленный режим и «только подписчики» — подсказка в поле ввода; автор меняет их щитом.
    private(set) var rules: ChatRules = .none
    private(set) var isSending = false
    /// Короткое сообщение под лентой: ошибка отправки или подтверждение действия.
    private(set) var notice: String?
    var scope: Scope = .all
    var draft = ""
    /// Сообщение, на которое отвечает зритель; `nil` — обычное сообщение.
    var replyTarget: ChatMessage?
    /// Эмодзи канала и их картинки, уже уменьшенные под строку текста.
    private(set) var emotes: [Emote] = []
    private(set) var emoteImages: [String: UIImage] = [:]

    init(channelID: Channel.ID) {
        self.channelID = channelID
    }

    var visibleEntries: [ChatEntry] {
        switch scope {
        case .all: entries
        case .important: entries.filter(\.isImportant)
        }
    }

    var canSend: Bool {
        !isSending && !draft.isBlank
    }

    var isPredictionOpen: Bool {
        prediction?.status == .open && predictionTimeLeft > .zero
    }

    /// Новые данные экрана: история, прогноз, права зрителя.
    func reset(messages: [ChatMessage], prediction: Prediction?, isOwner: Bool, emotes: [Emote] = [], rules: ChatRules = .none) {
        entries = messages.map(ChatEntry.message)
        self.emotes = emotes
        self.isOwner = isOwner
        self.rules = rules
        update(prediction)
    }

    /// События сервера, которые касаются чата.
    func apply(_ event: ChatServerEvent) {
        switch event {
        case .message(let message):
            guard !entries.contains(where: { $0.id == message.id }) else { return }
            entries.append(.message(message))
            if entries.count > Self.maxEntries {
                entries.removeFirst(entries.count - Self.maxEntries)
            }
        case .deleted(let id):
            entries.removeAll { $0.id == id }
        case .prediction(let incoming):
            update(incoming)
        case .raid(let target, let targetName):
            entries.append(.event(ChatEvent(
                id: UUID().uuidString,
                tone: .rose,
                text: "Рейд: эфир продолжается у \(targetName)",
                channel: target
            )))
        case .rules(let rules):
            self.rules = rules
        case .error(let message):
            notice = message
        case .viewers, .live, .moment:
            break
        }
    }

    func send(using repository: any StreamRepository) async {
        guard canSend else { return }
        let text = String(draft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxMessageLength))
        isSending = true
        defer { isSending = false }
        do {
            try await repository.sendMessage(text, replyTo: replyTarget?.id, channel: channelID)
            draft = ""
            replyTarget = nil
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }

    /// Щит автора: медленный режим и «только подписчики» прямо из чата во время эфира.
    func updateRules(_ patch: ModerationPatch, using repository: any StreamRepository) async {
        do {
            rules = try await repository.updateModeration(patch).rules
        } catch {
            notice = error.localizedDescription
        }
    }

    func report(_ message: ChatMessage, reason: ReportReason, using repository: any StreamRepository) async {
        await perform(
            { try await repository.report(message: message.id, reason: reason) },
            success: "Жалоба отправлена — модераторы рассмотрят её в течение 24 часов"
        )
    }

    /// Скрыть все сообщения автора — во всех чатах, на всех устройствах.
    func hideAuthor(of message: ChatMessage, using repository: any StreamRepository) async {
        let done = await perform(
            { try await repository.block(username: message.authorSlug) },
            success: "Сообщения \(message.author) скрыты. Вернуть можно в Профиле"
        )
        if done { removeMessages(by: message.authorId) }
    }

    func delete(_ message: ChatMessage, using repository: any StreamRepository) async {
        let done = await perform({ try await repository.deleteMessage(message.id) }, success: "Сообщение удалено")
        if done { entries.removeAll { $0.id == message.id } }
    }

    /// Запрет писать в чате канала. `minutes == nil` — навсегда.
    func ban(_ message: ChatMessage, minutes: Int?, using repository: any StreamRepository) async {
        let done = await perform(
            { try await repository.ban(username: message.authorSlug, minutes: minutes) },
            success: minutes.map { "\(message.author) не сможет писать \($0) минут" } ?? "\(message.author) больше не сможет писать в вашем чате"
        )
        if done { removeMessages(by: message.authorId) }
    }

    /// Голос принимается один раз и только пока прогноз открыт.
    func vote(for outcomeID: Prediction.Outcome.ID, using repository: any StreamRepository) async {
        guard isPredictionOpen, let prediction, prediction.myOutcomeId == nil else { return }
        do {
            update(try await repository.vote(prediction: prediction.id, outcome: outcomeID))
        } catch {
            notice = error.localizedDescription
        }
    }

    func clearNotice() {
        notice = nil
    }

    /// Вставляет эмодзи в поле ввода.
    func insert(_ emote: Emote) {
        let separator = draft.isEmpty || draft.hasSuffix(" ") ? "" : " "
        draft = String("\(draft)\(separator):\(emote.code): ".prefix(Self.maxMessageLength))
    }

    /// Загружает картинки эмодзи канала. Неудачные просто показываются текстом :код:.
    func loadEmoteImages(session: URLSession = .shared) async {
        for emote in emotes where emoteImages[emote.code] == nil {
            guard
                let (data, _) = try? await session.data(from: emote.url),
                let image = UIImage(data: data)
            else { continue }
            emoteImages[emote.code] = Self.inlineImage(image)
        }
    }

    /// Картинка под высоту строки: Text не умеет масштабировать вставленные изображения.
    private static func inlineImage(_ image: UIImage, side: CGFloat = 22) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            let scale = min(side / image.size.width, side / image.size.height)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(x: (side - size.width) / 2, y: (side - size.height) / 2, width: size.width, height: size.height))
        }
    }

    /// Обратный отсчёт прогноза: раз в `interval` убавляет секунду. Останавливается при отмене задачи.
    func runPredictionCountdown(interval: Duration = .seconds(1)) async {
        while predictionTimeLeft > .zero {
            do {
                try await Task.sleep(for: interval)
            } catch {
                return
            }
            predictionTimeLeft = max(.zero, predictionTimeLeft - .seconds(1))
        }
    }

    // MARK: Внутреннее

    /// Рассылка сервера одна на всех и не знает, за что голосовал этот зритель, — свой выбор сохраняем.
    private func update(_ incoming: Prediction?) {
        guard var incoming, incoming.status != .cancelled else {
            prediction = nil
            predictionTimeLeft = .zero
            return
        }
        if incoming.myOutcomeId == nil, prediction?.id == incoming.id {
            incoming.myOutcomeId = prediction?.myOutcomeId
        }
        prediction = incoming
        predictionTimeLeft = incoming.status == .open ? .seconds(incoming.endsInSeconds) : .zero
    }

    private func removeMessages(by authorID: String) {
        entries.removeAll { entry in
            if case .message(let message) = entry { message.authorId == authorID } else { false }
        }
    }

    @discardableResult
    private func perform(_ action: () async throws -> Void, success: String) async -> Bool {
        do {
            try await action()
            notice = success
            return true
        } catch {
            notice = error.localizedDescription
            return false
        }
    }
}
