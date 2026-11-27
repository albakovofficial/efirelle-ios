import Observation

/// Отслеживаемые каналы, которые сейчас в эфире.
@MainActor
@Observable
final class FollowingViewModel {
    private(set) var state: LoadState<[LiveStream]> = .idle

    func load(from repository: any StreamRepository) async {
        if state.value == nil {
            state = .loading
        }
        if let result = await LoadState<[LiveStream]>.result(of: { try await repository.followingLive() }) {
            state = result
        }
    }
}
