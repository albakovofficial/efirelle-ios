import Foundation
import Testing
@testable import Efirelle

/// Ответы API в том виде, в каком их отдаёт сервер (api/src/modules), должны читаться без ошибок.
@Suite("Разбор ответов API")
struct APIDecodingTests {
    private let channel = #"{"slug":"mira","name":"Мира","initials":"МИ","tone":"mint","followers":3,"verified":false}"#

    @Test("Эфир с каналом и адресом видео")
    func stream() throws {
        let json = """
        {"id":"7","channel":\(channel),"title":"Рояль","category":"Музыка","categoryId":"music","tags":["Живое"],
         "viewers":12,"durationSeconds":95,"quality":"Источник","latencySeconds":3,"status":"Рояль","tone":"lavender",
         "playbackUrl":"https://efirelle.ru/hls/live/mira/index.m3u8"}
        """
        let stream = try JSONDecoder().decode(LiveStream.self, from: Data(json.utf8))
        #expect(stream.channel.id == "mira")
        #expect(stream.duration == .seconds(95))
        #expect(stream.playbackURL?.lastPathComponent == "index.m3u8")
    }

    @Test("События чата")
    func events() throws {
        let message = """
        {"type":"message","message":{"kind":"message","id":"1","author":"Мира","authorSlug":"mira","authorId":"u1",
         "tone":"mint","badge":{"type":"broadcaster"},"text":"привет","createdAt":"2026-11-28T10:00:00.000Z"}}
        """
        let decoded = try JSONDecoder().decode(ChatServerEvent.self, from: Data(message.utf8))
        guard case .message(let chat) = decoded else {
            Issue.record("Ожидалось сообщение")
            return
        }
        #expect(chat.badge == .broadcaster)

        let viewers = try JSONDecoder().decode(ChatServerEvent.self, from: Data(#"{"type":"viewers","count":4}"#.utf8))
        #expect(viewers == .viewers(4))
    }

    @Test("Неизвестный тон не ломает разбор")
    func unknownTone() throws {
        let tone = try JSONDecoder().decode([Tone].self, from: Data(#"["mint","neon"]"#.utf8))
        #expect(tone == [.mint, .lavender])
    }
}
