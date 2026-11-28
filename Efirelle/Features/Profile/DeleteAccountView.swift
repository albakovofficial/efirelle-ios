import SwiftUI

/// Удаление аккаунта прямо в приложении (App Review 5.1.1): пароль и подтверждение.
struct DeleteAccountView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @State private var password = ""
    @State private var isConfirming = false
    @State private var isBusy = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Text("Аккаунт, канал, сообщения, подписки и искры удалятся сразу и навсегда. Отменить это нельзя.")
                    .font(.brandBody)
                SecureField("Пароль для подтверждения", text: $password)
                    .textContentType(.password)
            }
            if let error {
                Section { Text(error).foregroundStyle(Palette.live) }
            }
            Section {
                Button(role: .destructive) {
                    isConfirming = true
                } label: {
                    HStack {
                        Spacer()
                        if isBusy { ProgressView() } else { Text("Удалить аккаунт навсегда").fontWeight(.bold) }
                        Spacer()
                    }
                }
                .disabled(password.isEmpty || isBusy)
            }
        }
        .navigationTitle("Удаление аккаунта")
        .confirmationDialog("Удалить аккаунт навсегда?", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { Task { await delete() } }
        }
    }

    private func delete() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await session.deleteAccount(password: password, using: repository)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
