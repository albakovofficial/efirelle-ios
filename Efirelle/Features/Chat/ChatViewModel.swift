import Foundation
import Observation

/// Чат эфира: история, фильтр «Важное», отправка сообщений и прогноз со ставкой.
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
    static let predictionStake = 100

    let streamID: LiveStream.ID
    private(set) var entries: [ChatEntry] = []
    private(set) var viewer: Viewer?
    private(set) var prediction: Prediction?
    private(set) var predictionTimeLeft: Duration = .zero
    private(set) var selectedOutcomeID: Prediction.Outcome.ID?
    private(set) var isUnavailable = false
    var scope: Scope = .all
    var draft = ""

    init(streamID: LiveStream.ID) {
        self.streamID = streamID
    }

    var visibleEntries: [ChatEntry] {
        switch scope {
        case .all: entries
        case .important: entries.filter(\.isImportant)
        }
    }

    var canSend: Bool {
        viewer != nil && !trimmedDraft.isEmpty
    }

    var isPredictionOpen: Bool {
        prediction != nil && predictionTimeLeft > .zero
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
        let message = ChatMessage(
            id: UUID().uuidString,
            author: viewer.name,
            tone: viewer.tone,
            badge: nil,
            text: String(trimmedDraft.prefix(Self.maxMessageLength))
        )
        entries.append(.message(message))
        draft = ""
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

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
