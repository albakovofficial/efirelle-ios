import Foundation

/// HTTP-клиент API Efirelle: JSON туда и обратно, ключ сессии в заголовке Authorization.
/// Пути передаются как есть: адреса каналов, категорий и id в API — только латиница, цифры, «_» и «-».
struct APIClient: Sendable {
    static let production = APIClient(baseURL: "https://efirelle.ru")

    let baseURL: String
    var session: URLSession = .shared
    var tokens = TokenStore()

    /// Ответ без полезных данных (`{ "ok": true }`).
    struct Empty: Decodable, Sendable {}

    private struct ErrorBody: Decodable {
        let error: String?
        let message: String?
    }

    func get<Response: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        try await request("GET", path, query: query, body: nil)
    }

    func send<Response: Decodable>(_ method: String, _ path: String, body: some Encodable) async throws -> Response {
        try await request(method, path, query: [], body: (data: try JSONEncoder().encode(body), contentType: "application/json"))
    }

    func send<Response: Decodable>(_ method: String, _ path: String) async throws -> Response {
        try await request(method, path, query: [], body: nil)
    }

    /// Картинка телом запроса как есть (аватар, баннер, эмодзи).
    func upload<Response: Decodable>(
        _ method: String,
        _ path: String,
        query: [URLQueryItem] = [],
        image: Data,
        contentType: String
    ) async throws -> Response {
        try await request(method, path, query: query, body: (data: image, contentType: contentType))
    }

    func perform(_ method: String, _ path: String, body: some Encodable) async throws {
        let _: Empty = try await send(method, path, body: body)
    }

    func perform(_ method: String, _ path: String) async throws {
        let _: Empty = try await send(method, path)
    }

    /// Запрос на WebSocket чата с тем же ключом сессии.
    func socketRequest(_ path: String) -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        components.scheme = components.scheme == "http" ? "ws" : "wss"
        var request = URLRequest(url: components.url!)
        if let token = tokens.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func request<Response: Decodable>(
        _ method: String,
        _ path: String,
        query: [URLQueryItem],
        body: (data: Data, contentType: String)?
    ) async throws -> Response {
        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = body == nil ? 20 : 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = tokens.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body.data
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.offline
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw APIError(
                status: status,
                code: body?.error ?? "http_\(status)",
                message: body?.message ?? APIError.unexpected.message
            )
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.unexpected
        }
    }
}
