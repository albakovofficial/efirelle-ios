import SwiftUI

/// Обложка в пастельном тоне. Пока у эфира нет кадра-превью, рисуем мягкую композицию из кругов.
struct ThumbnailView: View {
    let tone: Tone
    var cornerRadius: CGFloat = Radius.l

    var body: some View {
        tone.surface
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    Circle()
                        .fill(tone.shade)
                        .frame(width: width * 0.7)
                        .offset(x: width * 0.48, y: -width * 0.22)
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: width * 0.3)
                        .offset(x: width * 0.1, y: proxy.size.height - width * 0.16)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityHidden(true)
    }
}

#Preview {
    ThumbnailView(tone: .sky)
        .aspectRatio(16 / 9, contentMode: .fit)
        .padding()
}
