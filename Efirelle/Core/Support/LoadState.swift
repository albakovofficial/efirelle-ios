import Foundation

/// Состояние загрузки данных экрана.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(message: String)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }
}

extension LoadState {
    /// Выполняет загрузку и возвращает итоговое состояние.
    /// `nil` — задачу отменили (например, экран закрыли), текущее состояние менять не нужно.
    @MainActor
    static func result(of operation: () async throws -> Value) async -> LoadState? {
        do {
            return .loaded(try await operation())
        } catch is CancellationError {
            return nil
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }
}
