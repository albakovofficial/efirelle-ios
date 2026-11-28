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
