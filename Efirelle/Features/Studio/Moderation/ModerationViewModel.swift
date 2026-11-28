import Observation

/// Настройки модерации чата своего канала. Изменения сохраняются сразу.
@MainActor
@Observable
final class ModerationViewModel {
    private(set) var settings: ModerationSettings
    private(set) var notice: String?
    var newWord = ""

    init(settings: ModerationSettings) {
        self.settings = settings
    }

    /// Защита включена, если работает хотя бы одно правило.
    var isProtected: Bool {
        settings.slowModeSeconds > 0 || settings.followersOnly || !settings.blockedWords.isEmpty
    }

    func setSlowMode(_ seconds: Int, using repository: any StreamRepository) async {
        await save(ModerationPatch(slowModeSeconds: seconds), using: repository)
    }

    func setFollowersOnly(_ enabled: Bool, using repository: any StreamRepository) async {
        await save(ModerationPatch(followersOnly: enabled), using: repository)
    }

    func addWord(using repository: any StreamRepository) async {
        let word = newWord.trimmingCharacters(in: .whitespaces).lowercased()
        guard word.count >= 2, !settings.blockedWords.contains(word) else { return }
        newWord = ""
        await save(ModerationPatch(blockedWords: settings.blockedWords + [word]), using: repository)
    }

    func removeWord(_ word: String, using repository: any StreamRepository) async {
        await save(ModerationPatch(blockedWords: settings.blockedWords.filter { $0 != word }), using: repository)
    }

    private func save(_ patch: ModerationPatch, using repository: any StreamRepository) async {
        do {
            settings = try await repository.updateModeration(patch)
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }
}
