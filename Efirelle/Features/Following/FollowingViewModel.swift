import Observation

/// Отслеживаемые каналы: сначала те, кто в эфире.
@MainActor
@Observable
final class FollowingViewModel {
    private(set) var state: LoadState<[ChannelStatus]> = .idle

    func load(from repository: any StreamRepository) async {
        if state.value == nil {
            state = .loading
        }
        if let result = await LoadState<[ChannelStatus]>.result(of: { try await repository.followedChannels() }) {
            state = result
        }
    }
}
