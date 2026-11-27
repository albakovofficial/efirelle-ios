import SwiftUI

/// Шрифты бренда. Построены на текстовых стилях, поэтому поддерживают Dynamic Type.
/// Чтобы перейти на фирменный Manrope, достаточно поменять реализацию здесь.
extension Font {
    static let brandTitle = Font.system(.title2, weight: .heavy)
    static let brandHeadline = Font.system(.headline, weight: .bold)
    static let brandBody = Font.system(.body, weight: .medium)
    static let brandCallout = Font.system(.callout, weight: .semibold)
    static let brandCaption = Font.system(.caption, weight: .semibold)
    static let brandMicro = Font.system(.caption2, weight: .heavy)
}
