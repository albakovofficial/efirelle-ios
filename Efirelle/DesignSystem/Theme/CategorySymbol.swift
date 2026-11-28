/// Значок на обложке категории (SF Symbols). Неизвестная категория получает нейтральный значок.
extension StreamCategory {
    var symbol: String {
        switch id {
        case "talk": "bubble.left.and.bubble.right.fill"
        case "games": "gamecontroller.fill"
        case "strategy": "crown.fill"
        case "shooters": "scope"
        case "music": "music.note"
        case "art": "paintpalette.fill"
        case "food": "fork.knife"
        case "travel": "airplane"
        case "education": "graduationcap.fill"
        case "sport": "figure.run"
        default: "sparkles"
        }
    }
}
