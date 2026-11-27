import Foundation
import Observation

/// Чат эфира: история, фильтр «Важное», отправка сообщений, прогноз и модерация
/// (жалобы, блокировка авторов, фильтр слов — требования App Review 1.2).
/// Сейчас сообщения живут локально; подключение к серверу (WebSocket) добавляется здесь.
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
    /// Награда за верный прогноз. Участие бесплатное — искры не списываются.
    static let predictionReward = 100

    let streamID: LiveStream.ID
    private let moderation: ModerationStore
    private(set) var entries: [ChatEntry] = []
    private(set) var viewer: Viewer?
    private(set) var prediction: Prediction?
    private(set) var predictionTimeLeft: Duration = .zero
    private(set) var selectedOutcomeID: Prediction.Outcome.ID?
    private(set) var isUnavailable = false
    /// Почему сообщение не отправилось (фильтр слов).
    private(set) var sendError: String?
    /// Короткое подтверждение действия: жалоба отправлена, автор заблокирован.
    private(set) var notice: String?
    private var hiddenMessageIDs: Set<ChatMessage.ID> = []
    var scope: Scope = .all
    var draft = ""

    init(streamID: LiveStream.ID, moderation: ModerationStore = .shared) {
        self.streamID = streamID
        self.moderation = moderation
    }

    var visibleEntries: [ChatEntry] {
        entries.filter { entry in
            guard isVisible(entry) else { return false }
            switch scope {
            case .all: return true
            case .important: return entry.isImportant
            }
        }
    }

    var canSend: Bool {
        viewer != nil && !trimmedDraft.isEmpty
    }

    var isPredictionOpen: Bool {
        prediction != nil && predictionTimeLeft > .zero
    }

    var blockedAuthors: [String] {
        moderation.blockedAuthors.sorted()
    }

    func load(from repository: any StreamRepository) async {
        do {
            async let history = repository.chatHistory(for: streamID)
            async let activePrediction = repository.activePrediction(for: streamID)
            async let currentViewer = repository.currentViewer()

            entries = try await history
            prediction = try await activePrediction
            predictionTimeLeft = prediction?.timeLeft ?? .zero
            viewer = try await currentViewer
            isUnavailable = false
        } catch is CancellationError {
            // Экран закрыли во время загрузки.
        } catch {
            isUnavailable = true
        }
    }

    func send() {
        guard canSend, let viewer else { return }
        let text = String(trimmedDraft.prefix(Self.maxMessageLength))
        guard ContentFilter.isAllowed(text) else {
            sendError = "Сообщение не отправлено: в нём есть слова, запрещённые правилами чата."
            return
        }
        let message = ChatMessage(
            id: UUID().uuidString,
            author: viewer.name,
            tone: viewer.tone,
            badge: nil,
            text: text,
            isOwn: true
        )
        entries.append(.message(message))
        draft = ""
        sendError = nil
    }

    func clearSendError() {
        sendError = nil
    }

    func clearNotice() {
        notice = nil
    }

    /// Жалоба: сообщение сразу скрывается у зрителя, жалоба уходит модераторам.
    func report(_ message: ChatMessage, reason: ReportReason, to repository: any StreamRepository) async {
        guard !message.isOwn else { return }
        hiddenMessageIDs.insert(message.id)
        do {
            try await repository.report(messageID: message.id, in: streamID, reason: reason)
            notice = "Жалоба отправлена модераторам. Сообщение скрыто."
        } catch {
            notice = "Жалобу не удалось отправить — напишите на \(AppLinks.supportEmail). Сообщение скрыто."
        }
    }

    /// Блокировка автора: его сообщения пропадают во всех чатах на этом устройстве.
    func block(author: String) {
        guard author != viewer?.name else { return }
        moderation.block(author)
        notice = "Вы больше не увидите сообщения \(author)."
    }

    func unblock(author: String) {
        moderation.unblock(author)
    }

    /// Голос принимается один раз и только пока прогноз открыт.
    func vote(for outcomeID: Prediction.Outcome.ID) {
        guard
            isPredictionOpen,
            selectedOutcomeID == nil,
            prediction?.outcomes.contains(where: { $0.id == outcomeID }) == true
        else { return }
        selectedOutcomeID = outcomeID
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

    private func isVisible(_ entry: ChatEntry) -> Bool {
        guard case .message(let message) = entry else { return true }
        return !hiddenMessageIDs.contains(message.id) && !moderation.isBlocked(message.author)
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
