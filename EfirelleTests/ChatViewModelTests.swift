import Testing
@testable import Efirelle

@MainActor
@Suite("Чат")
struct ChatViewModelTests {
    private let repository = MockStreamRepository.instant

    private func loadedModel() -> ChatViewModel {
        let model = ChatViewModel(channelID: MockData.Channels.timur.id)
        model.reset(messages: MockData.chat, prediction: MockData.prediction, isOwner: false)
        return model
    }

    private var anyMessage: ChatMessage { MockData.chat[0] }

    @Test("Сообщения от сервера добавляются один раз")
    func appliesMessages() {
        let model = loadedModel()
        let message = ChatMessage(id: "new", author: "Оля", authorSlug: "olya", authorId: "u-olya", tone: .sky, badge: nil, text: "привет")
        model.apply(.message(message))
        model.apply(.message(message))
        #expect(model.entries.count == MockData.chat.count + 1)
    }

    @Test("Удалённое сообщение пропадает")
    func appliesDeletion() {
        let model = loadedModel()
        model.apply(.deleted(id: anyMessage.id))
        #expect(!model.entries.contains { $0.id == anyMessage.id })
    }

    @Test("«Важное» показывает только автора эфира, модераторов и события")
    func importantScope() {
        let model = loadedModel()
        model.apply(.raid(target: "mira", targetName: "Мира"))
        model.scope = .important
        let visible = model.visibleEntries
        #expect(visible.count > 0)
        #expect(visible.allSatisfy(\.isImportant))
    }

    @Test("Отправка очищает поле, пустое сообщение не отправляется")
    func send() async {
        let model = loadedModel()
        model.draft = "   "
        #expect(!model.canSend)
        model.draft = "  привет  "
        await model.send(using: repository)
        #expect(model.draft.isEmpty)
    }

    @Test("Ошибка отправки остаётся в поле и показывается")
    func sendFailure() async {
        let model = loadedModel()
        var failing = repository
        failing.failure = APIError(status: 400, code: "profanity", message: "Сообщение нарушает правила чата")
        model.draft = "текст"
        await model.send(using: failing)
        #expect(model.draft == "текст")
        #expect(model.notice == "Сообщение нарушает правила чата")
    }

    @Test("Скрытие автора убирает все его сообщения")
    func hideAuthor() async {
        let model = loadedModel()
        await model.hideAuthor(of: anyMessage, using: repository)
        #expect(!model.entries.contains { entry in
            if case .message(let message) = entry { message.authorId == anyMessage.authorId } else { false }
        })
        #expect(model.notice != nil)
    }

    @Test("Голос в прогнозе принимается один раз")
    func vote() async throws {
        let model = loadedModel()
        #expect(model.isPredictionOpen)
        await model.vote(for: "yes", using: repository)
        #expect(model.prediction?.myOutcomeId == "yes")
        await model.vote(for: "no", using: repository)
        #expect(model.prediction?.myOutcomeId == "yes")
    }

    @Test("Рассылка прогноза не сбрасывает свой выбор")
    func keepsOwnVote() async {
        let model = loadedModel()
        await model.vote(for: "yes", using: repository)
        model.apply(.prediction(MockData.prediction))
        #expect(model.prediction?.myOutcomeId == "yes")
    }

    @Test("Отменённый прогноз пропадает")
    func cancelledPrediction() {
        let model = loadedModel()
        let cancelled = Prediction(
            id: MockData.prediction.id, question: "", status: .cancelled, endsInSeconds: 0,
            participants: 0, outcomes: [], myOutcomeId: nil, winningOutcomeId: nil
        )
        model.apply(.prediction(cancelled))
        #expect(model.prediction == nil)
    }

    @Test("Обратный отсчёт закрывает прогноз")
    func countdown() async {
        let model = loadedModel()
        await model.runPredictionCountdown(interval: .zero)
        #expect(model.predictionTimeLeft == .zero)
        #expect(!model.isPredictionOpen)
    }
}
