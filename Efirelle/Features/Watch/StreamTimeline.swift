import SwiftUI

/// Шкала перемотки эфира с отметками моментов. Основа — системный `Slider`, поэтому работает VoiceOver.
struct StreamTimeline: View {
    let position: Duration
    let duration: Duration
    let markers: [Moment]
    let onSeek: (Duration) -> Void

    private let markerSize: CGFloat = 14

    var body: some View {
        Slider(value: positionBinding, in: 0...max(duration.inSeconds, 1)) {
            Text("Перемотка эфира")
        }
        .tint(Palette.ink)
        .accessibilityValue(Formatters.clock(position))
        .overlay {
            GeometryReader { proxy in
                ForEach(markers) { marker in
                    Button {
                        onSeek(marker.offset)
                    } label: {
                        Circle()
                            .fill(marker.kind.tone.ink)
                            .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
                            .frame(width: markerSize, height: markerSize)
                            .frame(width: TapTarget.minimum, height: TapTarget.minimum)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .position(x: proxy.size.width * fraction(of: marker.offset), y: proxy.size.height / 2)
                    .accessibilityLabel("\(marker.text), \(Formatters.clock(marker.offset))")
                }
            }
        }
    }

    private var positionBinding: Binding<Double> {
        Binding(
            get: { position.inSeconds },
            set: { onSeek(.seconds($0)) }
        )
    }

    private func fraction(of offset: Duration) -> CGFloat {
        guard duration > .zero else { return 0 }
        return min(1, max(0, offset.inSeconds / duration.inSeconds))
    }
}
