import SwiftUI

/// Логотип Efirelle: двойная «ll» нарисована как индикатор громкости.
struct LogoView: View {
    var size: CGFloat = 24

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("efire")
            LevelBar(height: size * 0.74, width: size * 0.12, color: Palette.accent)
                .padding(.leading, size * 0.05)
                .padding(.trailing, size * 0.03)
            LevelBar(height: size * 0.46, width: size * 0.12, color: Palette.wave)
                .padding(.leading, size * 0.03)
                .padding(.trailing, size * 0.06)
            Text("e")
        }
        .font(.system(size: size, weight: .heavy))
        .kerning(-size * 0.045)
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Efirelle")
    }
}

private struct LevelBar: View {
    let height: CGFloat
    let width: CGFloat
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: height)
    }
}

#Preview {
    LogoView(size: 48)
        .padding()
}
