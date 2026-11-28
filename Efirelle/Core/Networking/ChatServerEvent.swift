import Foundation

/// Событие чата от сервера. Совпадает с `ServerEvent` в api/src/realtime/hub.ts.
enum ChatServerEvent: Sendable, Equatable, Decodable {
    case message(ChatMessage)
    case deleted(id: String)
    case viewers(Int)
    case live(Bool)
    case prediction(Prediction)
    case moment(Moment)
    case raid(target: String, targetName: String)
    case error(String)

    private enum CodingKeys: String, CodingKey {
        case type, message, id, count, live, prediction, moment, target, targetName
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "message": self = .message(try container.decode(ChatMessage.self, forKey: .message))
        case "deleted": self = .deleted(id: try container.decode(String.self, forKey: .id))
        case "viewers": self = .viewers(try container.decode(Int.self, forKey: .count))
        case "live": self = .live(try container.decode(Bool.self, forKey: .live))
        case "prediction": self = .prediction(try container.decode(Prediction.self, forKey: .prediction))
        case "moment": self = .moment(try container.decode(Moment.self, forKey: .moment))
        case "raid":
            self = .raid(
                target: try container.decode(String.self, forKey: .target),
                targetName: try container.decode(String.self, forKey: .targetName)
            )
        case "error": self = .error(try container.decode(String.self, forKey: .message))
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Неизвестное событие \(other)")
        }
    }
}
