import SwiftUI
import UIKit

/// Текст сообщения: эмодзи канала картинками, @упоминания выделены.
enum ChatText {
    /// Упоминает ли сообщение пользователя — такое сообщение подсвечивается.
    static func mentions(_ text: String, username: String?) -> Bool {
        guard let username else { return false }
        return text.lowercased().matches(of: /@([a-z0-9_]{3,24})/).contains { $0.output.1 == username }
    }

    static func text(_ text: String, emoteImages: [String: UIImage]) -> Text {
        var result = Text(verbatim: "")
        var cursor = text.startIndex
        for match in text.matches(of: /:([a-z0-9_]{2,20}):|@[a-z0-9_]{3,24}/) {
            if cursor < match.range.lowerBound {
                result = Text("\(result)\(Text(verbatim: String(text[cursor..<match.range.lowerBound])))")
            }
            let token = String(text[match.range])
            if let code = match.output.1, let image = emoteImages[String(code)] {
                result = Text("\(result)\(Text(Image(uiImage: image)).accessibilityLabel(Text(verbatim: token)))")
            } else if token.hasPrefix("@") {
                result = Text("\(result)\(Text(verbatim: token).fontWeight(.heavy).foregroundStyle(Palette.accent))")
            } else {
                result = Text("\(result)\(Text(verbatim: token))")
            }
            cursor = match.range.upperBound
        }
        if cursor < text.endIndex {
            result = Text("\(result)\(Text(verbatim: String(text[cursor...])))")
        }
        return result
    }
}
