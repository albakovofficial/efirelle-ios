import SwiftUI

/// Категория строкой: маленькая обложка со значком, название, группа и сколько смотрят сейчас.
struct CategoryRowView: View {
    let category: StreamCategory

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: category.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(category.tone.ink)
                .frame(width: 40, height: 50)
                .background(category.tone.surface, in: .rect(cornerRadius: Radius.s))
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.brandBody)
                    .foregroundStyle(Palette.ink)
                Text(category.liveCount > 0 ? "\(category.group) · \(Formatters.count(category.liveCount, .channels))" : category.group)
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            if category.liveCount > 0 {
                HStack(spacing: 5) {
                    Circle().fill(Palette.live).frame(width: 6, height: 6)
                    Text(Formatters.compact(category.viewers))
                        .font(.brandCaption)
                        .foregroundStyle(Palette.live)
                }
            } else {
                Text("не в эфире")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
            }
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
