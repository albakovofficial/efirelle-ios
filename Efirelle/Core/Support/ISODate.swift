import Foundation

/// Даты API: ISO 8601 с миллисекундами («2026-11-28T10:00:00.000Z»), как их пишет `toISOString()`.
enum ISODate {
    private static let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    static func parse(_ value: String) -> Date? {
        if let date = try? Date(value, strategy: withFraction) { return date }
        return try? Date(value, strategy: .iso8601)
    }
}
