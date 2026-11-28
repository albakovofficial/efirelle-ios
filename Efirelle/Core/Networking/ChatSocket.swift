import Foundation

/// Подключение к чату канала. Поток событий заканчивается, когда связь рвётся, —
/// переподключается тот, кто слушает (см. `WatchViewModel.listen`).
enum ChatSocket {
    static func events(for request: URLRequest, session: URLSession = .shared) -> AsyncStream<ChatServerEvent> {
        AsyncStream { continuation in
            let task = session.webSocketTask(with: request)
            let receiver = Task {
                let decoder = JSONDecoder()
                while !Task.isCancelled {
                    let message: URLSessionWebSocketTask.Message
                    do {
                        message = try await task.receive()
                    } catch {
                        break
                    }
                    let data: Data? = switch message {
                    case .string(let text): Data(text.utf8)
                    case .data(let data): data
                    @unknown default: nil
                    }
                    // Незнакомое событие пропускаем: сервер мог обновиться раньше приложения.
                    if let data, let event = try? decoder.decode(ChatServerEvent.self, from: data) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                receiver.cancel()
                task.cancel(with: .goingAway, reason: nil)
            }
            task.resume()
        }
    }
}
