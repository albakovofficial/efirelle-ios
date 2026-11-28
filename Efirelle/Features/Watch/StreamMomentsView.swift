import SwiftUI

/// Отмеченные моменты текущего эфира: пики чата, рейды, прогнозы, отметки автора.
struct StreamMomentsView: View {
    let markers: [Moment]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Моменты эфира", subtitle: "Отмечаются автоматически и автором эфира")
            ForEach(markers) { marker in
                HStack(spacing: Spacing.s) {
                    Circle()
                        .fill(marker.kind.tone.ink)
                        .frame(width: 12, height: 12)
                    Text(marker.text)
                        .font(.brandCallout)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("на \(Formatters.clock(marker.offset))")
                        .font(.brandCaption.monospacedDigit())
                        .foregroundStyle(Palette.muted)
                }
                .padding(Spacing.s)
                .frame(minHeight: TapTarget.minimum)
                .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
