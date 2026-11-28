import Foundation
import Observation

/// Студия автора: подключение OBS, настройки эфира, прогнозы, моменты, рейд, запреты писать.
/// После каждого действия студия перезагружается — экран всегда совпадает с сервером.
@MainActor
@Observable
final class StudioViewModel {
    static let predictionDurations: [Duration] = [.seconds(60), .seconds(120), .seconds(300), .seconds(600)]
    static let banDurations: [Int?] = [10, 60, 1_440, nil]

    private(set) var state: LoadState<Studio> = .idle
    private(set) var categories: [StreamCategory] = []
    private(set) var isBusy = false
    /// Итог последнего действия: «Сохранено», текст ошибки.
    private(set) var notice: String?

    // Поля форм.
    var settings = Studio.Settings(title: "", categoryId: "talk", tags: [])
    var tagsText = ""
    var question = ""
    var outcomes = ["", ""]
    var predictionDuration: Duration = .seconds(120)
    var momentText = ""
    var raidTarget = ""
    var banUsername = ""
    var banMinutes: Int? = 10
    var about = ChannelAbout(description: "", links: [], bannerUrl: nil)
    var avatarURL: URL?
    var scheduleTitle = ""
    var scheduleCategory = "talk"
    var scheduleDate = Date.now.addingTimeInterval(3_600)
    var emoteCode = ""

    var canStartPrediction: Bool {
        state.value?.stream != nil && !question.isBlank && outcomes.allSatisfy { !$0.isBlank }
    }

    func load(from repository: any StreamRepository) async {
        if state.value == nil { state = .loading }
        if categories.isEmpty {
            categories = (try? await repository.categories()) ?? []
        }
        guard let result = await LoadState<Studio>.result(of: { try await repository.studio() }) else { return }
        state = result
        if let studio = result.value {
            settings = studio.settings
            tagsText = studio.settings.tags.joined(separator: ", ")
            about = studio.about
            avatarURL = studio.channel.avatarURL
            if scheduleTitle.isEmpty { scheduleCategory = studio.settings.categoryId }
        }
    }

    func saveSettings(using repository: any StreamRepository) async {
        var settings = self.settings
        settings.title = settings.title.trimmingCharacters(in: .whitespaces)
        settings.tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0 }
        await run(success: "Сохранено", repository: repository) {
            try await repository.updateStudio(settings)
        }
    }

    func rotateKey(using repository: any StreamRepository) async {
        await run(success: "Новый ключ создан — замените его в OBS", repository: repository) {
            _ = try await repository.rotateStreamKey()
        }
    }

    func startPrediction(using repository: any StreamRepository) async {
        let question = self.question.trimmingCharacters(in: .whitespaces)
        let outcomes = self.outcomes.map { $0.trimmingCharacters(in: .whitespaces) }
        let duration = predictionDuration
        let started = await run(success: "Прогноз запущен", repository: repository) {
            try await repository.createPrediction(question: question, outcomes: outcomes, duration: duration)
        }
        if started {
            self.question = ""
            self.outcomes = ["", ""]
        }
    }

    func resolve(_ prediction: Prediction, outcome: Prediction.Outcome, using repository: any StreamRepository) async {
        await run(success: "Итог подведён: верно «\(outcome.label)»", repository: repository) {
            try await repository.resolvePrediction(prediction.id, outcome: outcome.id)
        }
    }

    func cancel(_ prediction: Prediction, using repository: any StreamRepository) async {
        await run(success: "Прогноз отменён", repository: repository) {
            try await repository.cancelPrediction(prediction.id)
        }
    }

    func addMoment(using repository: any StreamRepository) async {
        let text = momentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        if await run(success: "Момент отмечен", repository: repository, action: { try await repository.addMoment(text) }) {
            momentText = ""
        }
    }

    func raid(using repository: any StreamRepository) async {
        let target = raidTarget.trimmingCharacters(in: .whitespaces).lowercased()
        guard !target.isEmpty else { return }
        var viewers = 0
        let done = await run(success: nil, repository: repository) {
            viewers = try await repository.raid(target: target)
        }
        if done {
            notice = "Рейд отправлен: зрителей — \(viewers)"
            raidTarget = ""
        }
    }

    func ban(using repository: any StreamRepository) async {
        let username = banUsername.trimmingCharacters(in: .whitespaces).lowercased()
        guard !username.isEmpty else { return }
        let minutes = banMinutes
        if await run(success: "Готово", repository: repository, action: { try await repository.ban(username: username, minutes: minutes) }) {
            banUsername = ""
        }
    }

    func unban(_ ban: Studio.Ban, using repository: any StreamRepository) async {
        await run(success: "Запрет снят", repository: repository) {
            try await repository.unban(username: ban.slug)
        }
    }

    // MARK: Оформление, расписание, эмодзи

    func uploadAvatar(_ data: Data, using repository: any StreamRepository) async {
        guard let jpeg = ImageUpload.jpeg(data, maxSide: 512) else { return announce("Не удалось прочитать картинку") }
        await run(success: "Фото обновлено", repository: repository) { _ = try await repository.uploadAvatar(jpeg) }
    }

    func removeAvatar(using repository: any StreamRepository) async {
        await run(success: "Фото убрано", repository: repository) { try await repository.removeAvatar() }
    }

    func uploadBanner(_ data: Data, using repository: any StreamRepository) async {
        guard let jpeg = ImageUpload.jpeg(data, maxSide: 1_600) else { return announce("Не удалось прочитать картинку") }
        await run(success: "Баннер обновлён", repository: repository) { _ = try await repository.uploadBanner(jpeg) }
    }

    func removeBanner(using repository: any StreamRepository) async {
        await run(success: "Баннер убран", repository: repository) { try await repository.removeBanner() }
    }

    func saveAbout(using repository: any StreamRepository) async {
        let description = about.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let links = about.links
            .map { ChannelAbout.Link(title: $0.title.trimmingCharacters(in: .whitespaces), url: $0.url.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.title.isEmpty || !$0.url.isEmpty }
        await run(success: "Сохранено", repository: repository) {
            try await repository.updateAbout(description: description, links: links)
        }
    }

    func addLink() {
        if about.links.count < 5 { about.links.append(.init(title: "", url: "https://")) }
    }

    func removeLink(at offsets: IndexSet) {
        about.links.remove(atOffsets: offsets)
    }

    func createScheduled(using repository: any StreamRepository) async {
        let title = scheduleTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let category = scheduleCategory
        let date = scheduleDate
        if await run(success: "Анонс опубликован", repository: repository, action: {
            try await repository.scheduleStream(title: title, categoryId: category, startsAt: date)
        }) {
            scheduleTitle = ""
        }
    }

    func deleteScheduled(_ item: ScheduledStream, using repository: any StreamRepository) async {
        await run(success: "Анонс удалён", repository: repository) { try await repository.deleteScheduled(item.id) }
    }

    func addEmote(_ data: Data, using repository: any StreamRepository) async {
        let code = emoteCode.trimmingCharacters(in: .whitespaces).lowercased()
        guard !code.isEmpty else { return announce("Сначала введите код эмодзи") }
        guard let png = ImageUpload.squarePNG(data) else { return announce("Не удалось прочитать картинку") }
        if await run(success: "Эмодзи :\(code): добавлено", repository: repository, action: {
            try await repository.addEmote(code: code, png: png)
        }) {
            emoteCode = ""
        }
    }

    func removeEmote(_ emote: Emote, using repository: any StreamRepository) async {
        await run(success: "Эмодзи удалено", repository: repository) { try await repository.removeEmote(code: emote.code) }
    }

    func addOutcome() {
        if outcomes.count < 4 { outcomes.append("") }
    }

    func removeOutcome() {
        if outcomes.count > 2 { outcomes.removeLast() }
    }

    func announce(_ text: String) {
        notice = text
    }

    func clearNotice() {
        notice = nil
    }

    @discardableResult
    private func run(
        success: String?,
        repository: any StreamRepository,
        action: () async throws -> Void
    ) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        do {
            try await action()
            notice = success
            await load(from: repository)
            return true
        } catch {
            notice = error.localizedDescription
            return false
        }
    }
}
