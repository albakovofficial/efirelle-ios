import Foundation
import SwiftUI
import UIKit

/// Плеер прямого эфира: видео с метками поверх и кнопки управления.
/// Полный экран — кнопкой или поворотом iPhone; картинка в картинке — в меню «Ещё» и сама при сворачивании.
struct PlayerView: View {
    let stream: LiveStream
    /// Зрители из чата в реальном времени.
    let viewers: Int
    /// Чат канала — выдвигается сбоку в полном экране.
    var chat: ChatViewModel?

    @State private var playback = StreamPlayback()
    @State private var showsFullscreen = false
    /// Когда начался эфир — для тикающей длительности.
    @State private var startedAt: Date
    @State private var showsClipPrompt = false
    @State private var clipTitle = ""
    @State private var createdClip: Clip?
    @State private var clipError: String?
    @State private var showsClipError = false
    @State private var showsSignIn = false
    /// Выбранное качество; `nil` — исходное.
    @State private var selectedQuality: URL?
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session

    init(stream: LiveStream, viewers: Int, chat: ChatViewModel? = nil) {
        self.stream = stream
        self.viewers = viewers
        self.chat = chat
        _startedAt = State(initialValue: Date.now.addingTimeInterval(-Double(stream.duration.components.seconds)))
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            VideoSurface(playback: playback, tone: stream.tone, hasVideo: stream.playbackURL != nil, isActive: !showsFullscreen)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: Radius.l))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    BadgeView.live()
                    BadgeView(text: Formatters.count(viewers, .viewers, compact: false))
                }
                .padding(Spacing.s)
            }

            PlayerControls(
                playback: playback,
                startedAt: startedAt,
                qualities: stream.qualities,
                selectedQuality: source,
                onSelectQuality: { selectedQuality = $0 },
                onFullscreen: { showsFullscreen = true },
                onClip: {
                    if session.viewer == nil {
                        showsSignIn = true
                    } else {
                        showsClipPrompt = true
                    }
                }
            )
            .padding(.horizontal, Spacing.xxs)
        }
        .task(id: source) { playback.load(source) }
        .onDisappear {
            if !showsFullscreen { playback.stopIfNotInPictureInPicture() }
        }
        // Повернули iPhone горизонтально — сразу полный экран.
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation.isLandscape { showsFullscreen = true }
        }
        .fullScreenCover(isPresented: $showsFullscreen) {
            FullscreenPlayerView(
                stream: stream,
                viewers: viewers,
                startedAt: startedAt,
                playback: playback,
                chat: chat,
                qualities: stream.qualities,
                selectedQuality: source,
                onSelectQuality: { selectedQuality = $0 }
            )
        }
        .alert("Клип последних 30 секунд", isPresented: $showsClipPrompt) {
            TextField("Название клипа", text: $clipTitle)
            Button("Сделать клип") { Task { await createClip() } }
            Button("Отмена", role: .cancel) {}
        }
        .alert("Клип не получился", isPresented: $showsClipError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(clipError ?? "")
        }
        .sheet(item: $createdClip) { clip in
            ClipPlayerView(clip: clip)
        }
        .signInSheet(isPresented: $showsSignIn)
        .padding(Spacing.xs)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .shadow(color: Palette.accent.opacity(0.12), radius: 30, y: 16)
    }

    /// Адрес потока: выбранное качество, пока оно доступно, иначе исходное.
    private var source: URL? {
        if let selectedQuality, stream.qualities.contains(where: { $0.url == selectedQuality }) {
            return selectedQuality
        }
        return stream.playbackURL
    }

    private func createClip() async {
        let title = clipTitle.trimmingCharacters(in: .whitespaces)
        do {
            createdClip = try await repository.createClip(title: title.isEmpty ? "Момент эфира" : title, channel: stream.channel.id)
            clipTitle = ""
        } catch {
            clipError = error.localizedDescription
            showsClipError = true
        }
    }
}
