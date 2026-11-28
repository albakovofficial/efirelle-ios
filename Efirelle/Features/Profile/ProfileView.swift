import SwiftUI

/// Вкладка «Профиль»: вход для гостя; для вошедшего — канал, студия, скрытые пользователи, документы, выход и удаление аккаунта.
struct ProfileView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @Environment(PushNotifications.self) private var push
    @State private var authMode: AuthViewModel.Mode?

    var body: some View {
        NavigationStack {
            List {
                if let viewer = session.viewer {
                    account(viewer)
                    NotificationsSection()
                } else {
                    guest
                }
                documents
                if session.viewer != nil {
                    Section {
                        Button("Выйти") {
                            Task {
                                await push.signOut()
                                await session.signOut(using: repository)
                            }
                        }
                        NavigationLink("Удалить аккаунт") { DeleteAccountView() }
                            .foregroundStyle(Palette.live)
                    }
                }
            }
            .navigationTitle("Профиль")
            .refreshable { await session.refresh(using: repository) }
            .appDestinations()
            .sheet(item: $authMode) { mode in AuthView(mode: mode) }
        }
    }

    private func account(_ viewer: Viewer) -> some View {
        Section {
            HStack(spacing: Spacing.s) {
                AvatarView(viewer: viewer, size: .extraLarge)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(viewer.displayName).font(.brandHeadline)
                    Text("@\(viewer.username) · \(viewer.email)")
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                    SparksBalanceView(amount: viewer.sparks)
                }
            }
            .padding(.vertical, Spacing.xxs)
            NavigationLink(value: Channel(id: viewer.username, name: viewer.displayName, initials: viewer.initials, tone: viewer.tone, followers: 0, avatarURL: viewer.avatarUrl)) {
                Label("Мой канал", systemImage: "person.crop.square")
            }
            NavigationLink { StudioView() } label: {
                Label("Студия", systemImage: "dot.radiowaves.left.and.right")
            }
            NavigationLink { BlockedUsersView() } label: {
                Label("Скрытые пользователи", systemImage: "eye.slash")
            }
        }
    }

    private var guest: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Войдите, чтобы писать в чат, отслеживать каналы и вести эфиры")
                    .font(.brandBody)
                HStack {
                    Button("Войти") { authMode = .login }
                        .buttonStyle(.borderedProminent)
                    Button("Регистрация") { authMode = .register }
                        .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var documents: some View {
        Section("Помощь и документы") {
            Link(destination: AppLinks.rules) { Label("Правила сообщества", systemImage: "doc.text") }
            Link(destination: AppLinks.privacy) { Label("Политика конфиденциальности", systemImage: "hand.raised") }
            Link(destination: AppLinks.support) { Label("Поддержка", systemImage: "questionmark.circle") }
            Link(destination: AppLinks.supportMail) { Label(AppLinks.supportEmail, systemImage: "envelope") }
            Label("Искры — награда за верные прогнозы. Их нельзя купить или вывести.", systemImage: "sparkle")
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
    }
}

#Preview {
    ProfileView()
        .environment(Session())
        .environment(PushNotifications())
}
