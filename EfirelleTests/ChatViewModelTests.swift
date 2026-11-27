import Testing
@testable import Efirelle

@MainActor
@Suite("Чат")
struct ChatViewModelTests {
    private func loadedModel() async -> ChatViewModel {
        let model = ChatViewModel(streamID: "s-timur")
        await model.load(from: MockStreamRepository.instant)
        return model
    }

    @Test("Загружает историю, прогноз и зрителя")
    func load() async {
        let model = await loadedModel()
        #expect(model.entries.count == MockData.chatHistory.count)
        #expect(model.prediction != nil)
        #expect(model.isPredictionOpen)
        #expect(model.viewer != nil)
    }

    @Test("Отправка добавляет сообщение и очищает поле")
    func send() async {
        let model = await loadedModel()
        model.draft = "  привет  "
        model.send()
        guard case .message(let message) = model.entries.last else {
            Issue.record("Последняя запись должна быть сообщением")
            return
        }
        #expect(message.text == "привет")
        #expect(message.author == MockData.viewer.name)
        #expect(model.draft.isEmpty)
    }

    @Test("Пустое сообщение не отправляется")
    func emptyDraftIsIgnored() async {
        let model = await loadedModel()
        let count = model.entries.count
        model.draft = "   "
        model.send()
        #expect(model.entries.count == count)
        #expect(!model.canSend)
    }

    @Test("«Важное» показывает только модераторов, VIP и события")
    func importantScope() async {
        let model = await loadedModel()
        model.scope = .important
        #expect(!model.visibleEntries.isEmpty)
        #expect(model.visibleEntries.allSatisfy(\.isImportant))
    }

    @Test("Голос принимается только один раз")
    func votesOnce() async throws {
        let model = await loadedModel()
        let outcomes = try #require(model.prediction?.outcomes)
        model.vote(for: outcomes[0].id)
        model.vote(for: outcomes[1].id)
        #expect(model.selectedOutcomeID == outcomes[0].id)
    }

    @Test("Отсчёт закрывает прогноз")
    func countdownClosesPrediction() async {
        let model = await loadedModel()
        await model.runPredictionCountdown(interval: .milliseconds(1))
        #expect(model.predictionTimeLeft == .zero)
        #expect(!model.isPredictionOpen)
    }
}
