import Foundation
import Testing
@testable import Efirelle

@MainActor
@Suite("Чат")
struct ChatViewModelTests {
    /// Отдельное хранилище на каждый тест, чтобы блокировки не протекали между тестами.
    private func freshModeration() -> ModerationStore {
        ModerationStore(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
    }

    private func loadedModel(moderation: ModerationStore? = nil) async -> ChatViewModel {
        let model = ChatViewModel(streamID: "s-timur", moderation: moderation ?? freshModeration())
        await model.load(from: MockStreamRepository.instant)
        return model
    }

    private func firstForeignMessage(in model: ChatViewModel) throws -> ChatMessage {
        let messages = model.visibleEntries.compactMap { entry -> ChatMessage? in
            if case .message(let message) = entry, !message.isOwn { return message }
            return nil
        }
        return try #require(messages.first)
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
        let visible = model.visibleEntries
        #expect(visible.count > 0)
        #expect(visible.allSatisfy { $0.isImportant })
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

    @Test("Своё сообщение помечено как своё")
    func ownMessageIsMarked() async {
        let model = await loadedModel()
        model.draft = "всем привет"
        model.send()
        guard case .message(let message) = model.entries.last else {
            Issue.record("Последняя запись должна быть сообщением")
            return
        }
        #expect(message.isOwn)
    }

    @Test("Фильтр не даёт отправить мат и объясняет почему")
    func filterBlocksProfanity() async {
        let model = await loadedModel()
        let count = model.entries.count
        model.draft = "ну ты и сука"
        model.send()
        #expect(model.entries.count == count)
        #expect(model.sendError != nil)
        #expect(model.draft == "ну ты и сука")
    }

    @Test("Жалоба скрывает сообщение и подтверждает отправку")
    func reportHidesMessage() async throws {
        let model = await loadedModel()
        let message = try firstForeignMessage(in: model)
        await model.report(message, reason: .insult, to: MockStreamRepository.instant)
        #expect(model.visibleEntries.contains { $0.id == message.id } == false)
        #expect(model.notice != nil)
    }

    @Test("Блокировка скрывает все сообщения автора и снимается")
    func blockHidesAuthor() async throws {
        let moderation = freshModeration()
        let model = await loadedModel(moderation: moderation)
        let author = try firstForeignMessage(in: model).author
        model.block(author: author)
        let authorVisible = model.visibleEntries.contains { entry in
            if case .message(let message) = entry { return message.author == author }
            return false
        }
        #expect(authorVisible == false)
        #expect(model.blockedAuthors == [author])

        model.unblock(author: author)
        #expect(model.blockedAuthors.isEmpty)
    }

    @Test("Блокировка сохраняется между чатами")
    func blockPersists() async throws {
        let defaults = try #require(UserDefaults(suiteName: "tests.\(UUID().uuidString)"))
        let first = await loadedModel(moderation: ModerationStore(defaults: defaults))
        let author = try firstForeignMessage(in: first).author
        first.block(author: author)

        // Новое хранилище поверх тех же настроек — как после перезапуска приложения.
        let second = await loadedModel(moderation: ModerationStore(defaults: defaults))
        #expect(second.blockedAuthors == [author])
    }
}
