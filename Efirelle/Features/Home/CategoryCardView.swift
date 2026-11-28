import SwiftUI

/// Вертикальная обложка категории, как в Twitch: значок и название на обложке,
/// под ней — сколько смотрят сейчас и группа.
struct CategoryCardView: View {
    let category: StreamCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ThumbnailView(tone: category.tone)
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(category.tone.ink)
                        .padding(Spacing.s)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(category.name)
                        .font(.brandHeadline)
                        .foregroundStyle(category.tone.ink)
                        .lineLimit(2)
                        .padding(Spacing.s)
                }
                .padding(.bottom, 6)
            if category.liveCount > 0 {
                Label {
                    Text(Formatters.count(category.viewers, .viewers))
                } icon: {
                    Circle().fill(Palette.live).frame(width: 6, height: 6)
                }
                .labelStyle(LiveCountLabelStyle())
                .font(.brandCaption)
                .foregroundStyle(Palette.ink)
            } else {
                Text("Не в эфире")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
            }
            Text(category.group)
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
        .frame(width: 116)
        .accessibilityElement(children: .combine)
    }
}

/// Красная точка вплотную к числу зрителей.
private struct LiveCountLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview {
    CategoryCardView(category: MockData.categories[0])
        .padding()
}
