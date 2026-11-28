import Observation

/// Статистика своего канала.
@MainActor
@Observable
final class StatsViewModel {
    private(set) var state: LoadState<ChannelStats> = .idle

    func load(from repository: any StreamRepository) async {
        if state.value == nil { state = .loading }
        if let result = await LoadState<ChannelStats>.result(of: { try await repository.channelStats() }) {
            state = result
        }
    }

    /// Изменение к прошлой неделе: «+18% к прошлой неделе», «впервые на этой неделе» или `nil`, если сравнивать не с чем.
    static func change(_ week: Double, from previous: Double) -> String? {
        guard week > 0 || previous > 0 else { return nil }
        guard previous > 0 else { return "впервые на этой неделе" }
        let percent = Int(((week - previous) / previous * 100).rounded())
        if percent == 0 { return "как на прошлой неделе" }
        return "\(percent > 0 ? "+" : "−")\(abs(percent))% к прошлой неделе"
    }
}
