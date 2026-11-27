import SwiftUI

/// Вертикальная обложка категории с числом зрителей.
struct CategoryCardView: View {
    let category: StreamCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ThumbnailView(tone: category.tone)
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay(alignment: .bottomLeading) {
                    Text(category.name)
                        .font(.brandHeadline)
                        .foregroundStyle(category.tone.ink)
                        .padding(Spacing.s)
                }
                .padding(.bottom, 6)
            Text(Formatters.count(category.viewers, .viewers))
                .font(.brandCaption)
                .foregroundStyle(Palette.ink)
            Text(category.group)
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
        .frame(width: 128)
        .accessibilityElement(children: .combine)
    }
}
