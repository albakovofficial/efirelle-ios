import AVKit
import SwiftUI

/// Лента клипов: карточки открывают клип поверх экрана.
struct ClipsStripView: View {
    let clips: [Clip]
    @State private var opened: Clip?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.s) {
                ForEach(clips) { clip in
                    Button { opened = clip } label: { ClipCardView(clip: clip) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .padding(.horizontal, -Spacing.m)
        .sheet(item: $opened) { clip in
            ClipPlayerView(clip: clip)
        }
    }
}

/// Карточка клипа: обложка канала, длительность, название и просмотры.
struct ClipCardView: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ThumbnailView(tone: clip.channel.tone, cornerRadius: Radius.l)
                .frame(width: 220, height: 124)
                .overlay {
                    Image(systemName: clip.status == .ready ? "play.fill" : "hourglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(clip.channel.tone.ink)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(verbatim: "0:\(String(format: "%02d", clip.durationSeconds))")
                        .font(.brandMicro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: .rect(cornerRadius: 6))
                        .padding(Spacing.xs)
                }
            Text(clip.title)
                .font(.brandCallout)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Text("\(clip.channel.name) · \(Formatters.count(clip.views, .views))")
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
        }
        .frame(width: 220, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Клип на весь экран: видео, «Поделиться». Пока файл готовится — проверяем раз в несколько секунд.
struct ClipPlayerView: View {
    @State private var clip: Clip
    @State private var player: AVPlayer?
    @Environment(\.streamRepository) private var repository
    @Environment(\.dismiss) private var dismiss

    init(clip: Clip) {
        _clip = State(initialValue: clip)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Group {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        ZStack {
                            ThumbnailView(tone: clip.channel.tone, cornerRadius: Radius.l)
                            Label(clip.status == .failed ? "Клип не получился" : "Клип готовится — около полуминуты", systemImage: "hourglass")
                                .font(.brandCallout)
                                .foregroundStyle(clip.channel.tone.ink)
                        }
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(.rect(cornerRadius: Radius.l))

                Text(clip.title).font(.brandTitle)
                Text("\(clip.channel.name) · \(Formatters.count(clip.views, .views))")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
                ShareLink(item: clip.shareURL) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: TapTarget.minimum)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(Spacing.m)
            .background(Palette.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .task(id: clip.status) {
            if clip.status == .processing {
                try? await Task.sleep(for: .seconds(5))
                if let fresh = try? await repository.clip(clip.id) { clip = fresh }
            } else if let url = clip.url, player == nil {
                let player = AVPlayer(url: url)
                self.player = player
                player.play()
                await repository.countClipView(clip.id)
            }
        }
        .onDisappear { player?.pause() }
    }
}

/// Записи прошлых эфиров — список, запись открывается в системном плеере.
struct RecordingsListView: View {
    let recordings: [Recording]
    @State private var opened: Recording?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Записи эфиров", subtitle: "Хранятся 3 дня после эфира")
            ForEach(recordings) { recording in
                Button { opened = recording } label: {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Palette.inkSurface, in: .rect(cornerRadius: Radius.s))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recording.title).font(.brandCallout).foregroundStyle(Palette.ink).lineLimit(1)
                            Text(subtitle(recording)).font(.brandCaption).foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.s)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
            }
        }
        .fullScreenCover(item: $opened) { recording in
            RecordingPlayerView(recording: recording)
        }
    }

    private func subtitle(_ recording: Recording) -> String {
        let date = recording.startDate?.formatted(date: .abbreviated, time: .shortened) ?? ""
        return "\(date) · \(Formatters.clock(.seconds(recording.durationSeconds))) · \(recording.category)"
    }
}

private struct RecordingPlayerView: View {
    let recording: Recording
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player).ignoresSafeArea()
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: TapTarget.minimum, height: TapTarget.minimum)
                    .background(.black.opacity(0.5), in: .circle)
            }
            .accessibilityLabel("Закрыть")
            .padding(Spacing.m)
        }
        .task {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            let player = AVPlayer(url: recording.url)
            self.player = player
            player.play()
        }
        .onDisappear { player?.pause() }
    }
}
