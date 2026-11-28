import UIKit

/// На iPhone приложение вертикальное; лёжа — только полноэкранный эфир. На iPad — любые ориентации.
@MainActor
enum OrientationLock {
    private(set) static var mask: UIInterfaceOrientationMask = defaultMask

    private static var defaultMask: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }

    /// Полный экран: поворачиваем в горизонталь (по умолчанию — динамиком вправо, как держат для видео).
    static func landscape() {
        update(UIDevice.current.userInterfaceIdiom == .pad ? .all : .landscape, preferred: .landscapeRight)
    }

    static func reset() {
        update(defaultMask, preferred: .portrait)
    }

    private static func update(_ newMask: UIInterfaceOrientationMask, preferred: UIInterfaceOrientationMask) {
        mask = newMask
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        scene?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene?.requestGeometryUpdate(.iOS(interfaceOrientations: UIDevice.current.userInterfaceIdiom == .pad ? .all : preferred))
    }
}
