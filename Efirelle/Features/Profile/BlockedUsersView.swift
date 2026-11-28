import SwiftUI

/// Пользователи, чьи сообщения скрыты во всех чатах. Отсюда их можно вернуть.
struct BlockedUsersView: View {
    @Environment(\.streamRepository) private var repository
    @State private var state: LoadState<[BlockedUser]> = .idle

    var body: some View {
        LoadStateView(state: state, retry: load) { users in
            if users.isEmpty {
                ContentUnavailableView(
                    "Никого нет",
                    systemImage: "eye.slash",
                    description: Text("Скрыть автора можно долгим нажатием на его сообщение в чате.")
                )
            } else {
                List(users) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        Button("Вернуть") {
                            Task { await unblock(user) }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .background(Palette.background)
        .navigationTitle("Скрытые пользователи")
        .task { await load() }
    }

    private func load() async {
        if let result = await LoadState<[BlockedUser]>.result(of: { try await repository.blockedUsers() }) {
            state = result
        }
    }

    private func unblock(_ user: BlockedUser) async {
        guard (try? await repository.unblock(username: user.slug)) != nil else { return }
        state = .loaded((state.value ?? []).filter { $0.id != user.id })
    }
}
