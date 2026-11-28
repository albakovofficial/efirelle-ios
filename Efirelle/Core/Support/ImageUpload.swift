import UIKit

/// Подготовка картинок к загрузке: уменьшаем на устройстве, чтобы не гонять мегабайты по сети
/// и уложиться в лимиты сервера (фото 2 МБ, баннер 4 МБ, эмодзи 256 КБ).
enum ImageUpload {
    /// Фото и баннер — JPEG, длинная сторона не больше `maxSide` пикселей.
    static func jpeg(_ data: Data, maxSide: CGFloat, quality: CGFloat = 0.85) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return resized(image, toFit: CGSize(width: maxSide, height: maxSide), opaque: true).jpegData(compressionQuality: quality)
    }

    /// Эмодзи — квадратный PNG с прозрачностью.
    static func squarePNG(_ data: Data, side: CGFloat = 112) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).pngData { _ in
            let scale = min(side / image.size.width, side / image.size.height)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(x: (side - size.width) / 2, y: (side - size.height) / 2, width: size.width, height: size.height))
        }
    }

    private static func resized(_ image: UIImage, toFit bounds: CGSize, opaque: Bool) -> UIImage {
        let scale = min(1, bounds.width / image.size.width, bounds.height / image.size.height)
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = opaque
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
