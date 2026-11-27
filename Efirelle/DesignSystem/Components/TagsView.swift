import SwiftUI

/// Теги эфира, переносятся на новую строку, если не помещаются.
struct TagsView: View {
    let tags: [String]
    /// Первый тег (категория) можно подсветить тоном.
    var leadingTone: Tone?

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                let tone = index == 0 ? leadingTone : nil
                Text(tag)
                    .font(.brandCaption)
                    .foregroundStyle(tone?.ink ?? Palette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(tone?.surface ?? Palette.surfaceMuted, in: .capsule)
            }
        }
    }
}

/// Раскладка «в строку с переносом».
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, maxWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, maxWidth: bounds.width)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if cursor.x > 0, cursor.x + size.width > maxWidth {
                cursor = CGPoint(x: 0, y: cursor.y + rowHeight + spacing)
                rowHeight = 0
            }
            origins.append(cursor)
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, cursor.x - spacing)
        }
        return (CGSize(width: width, height: cursor.y + rowHeight), origins)
    }
}

#Preview {
    TagsView(tags: ["Стратегии", "Русский", "Соревновательно", "Финал"], leadingTone: .sky)
        .frame(width: 220)
        .padding()
}
