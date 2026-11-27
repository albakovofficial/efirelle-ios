import SwiftUI

/// Отмеченные моменты эфира. Нажатие перематывает плеер.
struct StreamMomentsView: View {
    let markers: [Moment]
    let onSeek: (Duration) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Моменты эфира", subtitle: "Нажмите, чтобы перемотать")
            ForEach(markers) { marker in
                Button {
                    onSeek(marker.offset)
                } label: {
                    HStack(spacing: Spacing.s) {
                        Circle()
                            .fill(marker.kind.tone.ink)
                            .frame(width: 12, height: 12)
                        Text(marker.text)
                            .font(.brandCallout)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text(Formatters.clock(marker.offset))
                            .font(.brandCaption.monospacedDigit())
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(Spacing.s)
                    .frame(minHeight: TapTarget.minimum)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Перемотать к этому моменту")
            }
        }
    }
}
