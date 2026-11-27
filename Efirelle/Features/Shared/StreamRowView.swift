import SwiftUI

/// Компактная строка эфира: маленькое превью, название, канал и зрители.
struct StreamRowView: View {
    let stream: LiveStream

    var body: some View {
        HStack(spacing: Spacing.s) {
            ThumbnailView(tone: stream.tone, cornerRadius: Radius.m)
                .frame(width: 112, height: 68)
                .overlay(alignment: .bottomLeading) {
                    BadgeView.live(short: true, size: .small)
                        .padding(6)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(stream.title)
                    .font(.brandCallout)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                Text("\(stream.channel.name) · \(Formatters.compact(stream.viewers))")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Открыть эфир")
    }
}

#Preview {
    StreamRowView(stream: MockData.streams[0])
        .padding()
}
