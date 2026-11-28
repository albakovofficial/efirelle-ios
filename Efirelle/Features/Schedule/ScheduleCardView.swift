import SwiftUI

/// Анонс эфира: когда, о чём, кнопка «Напомнить» (push за 5 минут до начала).
struct ScheduleCardView: View {
    let item: ScheduledStream
    /// На странице самого канала имя автора не повторяем.
    var showsChannel = true

    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @Environment(PushNotifications.self) private var push
    @State private var isReminded: Bool?
    @State private var showsSignIn = false

    private var reminded: Bool { isReminded ?? item.isReminded }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(item.startsAt.formatted(.dateTime.weekday(.abbreviated).day().month(.wide).hour().minute()).uppercased())
                .font(.brandMicro)
                .foregroundStyle(Palette.accent)
            Text(item.title)
                .font(.brandHeadline)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
            if showsChannel {
                NavigationLink(value: item.channel) {
                    HStack(spacing: Spacing.xs) {
                        AvatarView(channel: item.channel, size: .small)
                        Text("\(item.channel.name) · \(item.category)")
                            .font(.brandCaption)
                            .foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(item.category).font(.brandCaption).foregroundStyle(Palette.muted)
            }
            Button(action: toggle) {
                Label(reminded ? "Напомним за 5 минут" : "Напомнить", systemImage: reminded ? "bell.fill" : "bell")
                    .font(.brandCaption)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(reminded ? Palette.ink : Palette.accent)
            .sensoryFeedback(.selection, trigger: reminded)
        }
        .padding(Spacing.m)
        .frame(width: 260, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .signInSheet(isPresented: $showsSignIn)
    }

    private func toggle() {
        guard session.viewer != nil else {
            showsSignIn = true
            return
        }
        let target = !reminded
        isReminded = target
        Task {
            do {
                isReminded = try await repository.setReminder(target, for: item.id).isReminded
                // Напоминание приходит уведомлением — подходящий момент спросить разрешение.
                if target, push.authorization == .notDetermined {
                    await push.requestAuthorization(using: repository)
                }
            } catch {
                isReminded = !target
            }
        }
    }
}

/// Горизонтальная лента анонсов — для главной и страницы канала.
struct ScheduleStripView: View {
    let items: [ScheduledStream]
    var showsChannel = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.s) {
                ForEach(items) { item in
                    ScheduleCardView(item: item, showsChannel: showsChannel)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .padding(.horizontal, -Spacing.m)
    }
}
