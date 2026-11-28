import SwiftUI

/// Меню «Ещё» плеера: качество эфира и картинка в картинке. Одно и то же под видео и в полном экране.
struct PlaybackMenu<Label: View>: View {
    let playback: StreamPlayback
    let qualities: [LiveStream.Quality]
    let selectedQuality: URL?
    let onSelectQuality: (URL) -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Menu {
            if qualities.count > 1 {
                Section("Качество") {
                    ForEach(qualities, id: \.url) { quality in
                        Button {
                            onSelectQuality(quality.url)
                        } label: {
                            if quality.url == selectedQuality {
                                SwiftUI.Label(quality.label, systemImage: "checkmark")
                            } else {
                                Text(quality.label)
                            }
                        }
                    }
                }
            }
            if playback.isPictureInPictureSupported {
                Button {
                    playback.togglePictureInPicture()
                } label: {
                    SwiftUI.Label(
                        playback.isPictureInPictureActive ? "Вернуть в приложение" : "Картинка в картинке",
                        systemImage: playback.isPictureInPictureActive ? "pip.exit" : "pip.enter"
                    )
                }
            }
        } label: {
            label()
        }
        .accessibilityLabel("Ещё: качество и картинка в картинке")
    }
}
