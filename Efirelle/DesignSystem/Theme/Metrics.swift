import CoreGraphics

/// Шаг отступов: всё кратно 4.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Радиусы скругления.
enum Radius {
    static let s: CGFloat = 10
    static let m: CGFloat = 14
    static let l: CGFloat = 20
    static let xl: CGFloat = 28
}

/// Минимальный размер области нажатия по HIG.
enum TapTarget {
    static let minimum: CGFloat = 44
}
