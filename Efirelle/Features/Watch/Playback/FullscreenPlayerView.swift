import SwiftUI
import UIKit

/// Полный экран лёжа «Кино»: только видео; касание показывает кнопки, через 3 секунды они прячутся.
/// Кнопка чата выдвигает чат справа. Поворот iPhone обратно вертикально — выход из полного экрана.
struct FullscreenPlayerView: View {
    let stream: LiveStream
    let viewers: Int
    let startedAt: Date
    let playback: StreamPlayback
    let chat: ChatViewModel?
    let qualities: [LiveStream.Quality]
    let selectedQuality: URL?
    let onSelectQuality: (URL) -> Void

    @State private var controlsShown = true
    @State private var showsChat = false
    /// Меняется при каждом касании — перезапускает таймер скрытия кнопок.
    @State private var activity = 0
    @Environment(\.dismiss) private var dismiss

    private let chatWidth: CGFloat = 340

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                VideoSurface(playback: playback, tone: stream.tone, hasVideo: stream.playbackURL != nil)
                if controlsShown {
                    controls.transition(.opacity)
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) { controlsShown.toggle() }
                activity += 1
            }

            if showsChat, let chat {
                ChatView(model: chat)
                    .frame(width: chatWidth)
                    .background(Palette.surface)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear(perform: OrientationLock.landscape)
        .onDisappear(perform: OrientationLock.reset)
        .task(id: activity) {
            try? await Task.sleep(for: .seconds(3))
            guard playback.isPlaying, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { controlsShown = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .portrait { dismiss() }
        }
    }

    private var controls: some View {
        VStack {
            HStack(spacing: Spacing.xs) {
                BadgeView.live()
                Text("\(stream.channel.name) · \(stream.title)")
                    .font(.brandCallout)
                    .lineLimit(1)
                Spacer()
                GlassButton(systemImage: "xmark", label: "Выйти из полного экрана", action: { dismiss() })
            }
            Spacer()
            HStack(spacing: Spacing.xxs) {
                GlassButton(systemImage: playback.isPlaying ? "pause.fill" : "play.fill", label: playback.isPlaying ? "Пауза" : "Смотреть") {
                    playback.togglePlay()
                    activity += 1
                }
                GlassButton(systemImage: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", label: playback.isMuted ? "Включить звук" : "Выключить звук") {
                    playback.toggleMute()
                    activity += 1
                }
                status.padding(.leading, Spacing.xxs)
                Spacer()
                PlaybackMenu(playback: playback, qualities: qualities, selectedQuality: selectedQuality, onSelectQuality: onSelectQuality) {
                    GlassIcon(systemImage: "gearshape.fill")
                }
                if chat != nil {
                    GlassButton(systemImage: showsChat ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right", label: showsChat ? "Скрыть чат" : "Показать чат") {
                        withAnimation(.snappy) { showsChat.toggle() }
                        activity += 1
                    }
                }
                GlassButton(systemImage: "arrow.down.right.and.arrow.up.left", label: "Выйти из полного экрана", action: { dismiss() })
            }
            .padding(Spacing.xxs)
            .background(.black.opacity(0.55), in: .rect(cornerRadius: Radius.m))
        }
        .foregroundStyle(.white)
        .padding(Spacing.m)
    }

    @ViewBuilder
    private var status: some View {
        if playback.isBehindLive {
            Button("К эфиру", action: playback.returnToLive)
                .font(.brandCaption)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: 32)
                .background(Palette.accent, in: .capsule)
                .buttonStyle(.plain)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("\(Formatters.count(viewers, .viewers)) · \(Formatters.clock(.seconds(context.date.timeIntervalSince(startedAt))))")
                    .font(.brandCaption)
                    .monospacedDigit()
            }
        }
    }
}

private struct GlassButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassIcon(systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct GlassIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: TapTarget.minimum, height: TapTarget.minimum)
            .contentShape(.rect)
    }
}
