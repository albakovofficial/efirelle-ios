import Foundation
import SwiftUI

/// Плеер прямого эфира: видео с метками поверх и кнопки управления.
struct PlayerView: View {
    let stream: LiveStream
    /// Зрители из чата в реальном времени.
    let viewers: Int

    @State private var isPlaying = true
    @State private var isMuted = false
    /// Зритель ставил на паузу — смотрит с отставанием.
    @State private var isBehindLive = false
    /// Увеличивается, когда нужно вернуться к прямому эфиру.
    @State private var liveRequest = 0
    /// Когда начался эфир — для тикающей длительности.
    @State private var startedAt: Date
    @State private var showsClipPrompt = false
    @State private var clipTitle = ""
    @State private var createdClip: Clip?
    @State private var clipError: String?
    @State private var showsClipError = false
    @State private var showsSignIn = false
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session

    init(stream: LiveStream, viewers: Int) {
        self.stream = stream
        self.viewers = viewers
        _startedAt = State(initialValue: Date.now.addingTimeInterval(-Double(stream.duration.components.seconds)))
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            VideoSurface(
                url: stream.playbackURL,
                tone: stream.tone,
                isPlaying: isPlaying,
                isMuted: isMuted,
                liveRequest: liveRequest
            )
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
                isPlaying: isPlaying,
                isMuted: isMuted,
                isBehindLive: isBehindLive,
                startedAt: startedAt,
                onTogglePlay: togglePlay,
                onToggleMute: { isMuted.toggle() },
                onReturnToLive: returnToLive,
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

    private func togglePlay() {
        isPlaying.toggle()
        if !isPlaying { isBehindLive = true }
    }

    private func returnToLive() {
        liveRequest += 1
        isPlaying = true
        isBehindLive = false
    }
}
