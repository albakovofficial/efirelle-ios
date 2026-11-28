import SwiftUI
import UIKit

/// Эфир с iPhone: камера во весь экран, сверху — статус и длительность, снизу — микрофон, «В эфир» и смена камеры.
/// Название и категория эфира берутся из студии, как и для OBS. Во время эфира экран можно свернуть —
/// эфир продолжится, вернуться можно кнопкой в нижней панели.
struct BroadcastView: View {
    let session: BroadcastSession
    let ingest: Studio.Ingest

    @State private var confirmsEnd = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: session).ignoresSafeArea()
            if session.state == .denied {
                deniedMessage
            }
            VStack {
                topBar
                Spacer()
                if case .failed(let message) = session.state {
                    notice(message)
                }
                bottomBar
            }
            .padding(Spacing.m)
        }
        .statusBarHidden()
        .task { await session.prepare() }
        // Свёрнутый эфир продолжается; без эфира камера и микрофон выключаются.
        .onDisappear {
            if !session.isLive { Task { await session.shutdown() } }
        }
        .confirmationDialog("Завершить эфир?", isPresented: $confirmsEnd, titleVisibility: .visible) {
            Button("Завершить", role: .destructive) {
                Task { await session.stop() }
            }
        }
        .sensoryFeedback(.success, trigger: session.isLive) { _, live in live }
    }

    private var topBar: some View {
        HStack {
            RoundButton(
                systemImage: session.isLive ? "chevron.down" : "xmark",
                label: session.isLive ? "Свернуть, эфир продолжится" : "Закрыть"
            ) {
                dismiss()
            }
            Spacer()
            status
        }
    }

    @ViewBuilder
    private var status: some View {
        switch session.state {
        case .live(let since):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: Spacing.xs) {
                    BadgeView.live()
                    Text(Formatters.clock(.seconds(context.date.timeIntervalSince(since))))
                        .font(.brandCaption)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: 32)
                .background(.black.opacity(0.45), in: .capsule)
            }
        case .connecting:
            statusText("Подключаемся…")
        default:
            statusText("Не в эфире")
        }
    }

    private var bottomBar: some View {
        HStack {
            RoundButton(
                systemImage: session.isMuted ? "mic.slash.fill" : "mic.fill",
                label: session.isMuted ? "Включить микрофон" : "Выключить микрофон"
            ) {
                Task { await session.toggleMute() }
            }
            Spacer()
            liveButton
            Spacer()
            RoundButton(systemImage: "arrow.triangle.2.circlepath.camera.fill", label: "Сменить камеру") {
                Task { await session.flipCamera() }
            }
        }
        .disabled(session.state == .preparing || session.state == .denied)
    }

    private var liveButton: some View {
        Button {
            if session.isLive {
                confirmsEnd = true
            } else {
                Task { await session.start(server: ingest.server, streamKey: ingest.streamKey) }
            }
        } label: {
            Text(session.isLive ? "Завершить" : "В эфир")
                .font(.brandHeadline)
                .foregroundStyle(.white)
                .frame(width: 150, height: 56)
                .background(session.isLive ? Palette.inkSurface : Palette.live, in: .capsule)
                .overlay {
                    if session.state == .connecting {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Palette.live, in: .capsule)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(session.state == .connecting)
    }

    private var deniedMessage: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 40))
            Text("Нет доступа к камере или микрофону")
                .font(.brandHeadline)
            Text("Разрешите их для Efirelle в Настройках, чтобы вести эфир с iPhone.")
                .font(.brandBody)
                .multilineTextAlignment(.center)
            Button("Открыть Настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
        .padding(Spacing.xl)
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.brandCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: 32)
            .background(.black.opacity(0.45), in: .capsule)
    }

    private func notice(_ message: String) -> some View {
        Text(message)
            .font(.brandCallout)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(Spacing.s)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.6), in: .rect(cornerRadius: Radius.m))
            .padding(.bottom, Spacing.s)
    }
}

/// Круглая полупрозрачная кнопка поверх видео.
private struct RoundButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.black.opacity(0.45), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
