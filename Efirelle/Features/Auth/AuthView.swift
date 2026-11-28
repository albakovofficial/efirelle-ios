import SwiftUI

/// Окно входа и регистрации. Открывается листом там, где нужен аккаунт.
struct AuthView: View {
    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var model: AuthViewModel

    init(mode: AuthViewModel.Mode = .login) {
        _model = State(initialValue: AuthViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Form {
                if model.mode != .reset {
                    @Bindable var bindable = model
                    Picker("Режим", selection: $bindable.mode) {
                        Text("Вход").tag(AuthViewModel.Mode.login)
                        Text("Регистрация").tag(AuthViewModel.Mode.register)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                fields

                if let error = model.error {
                    Section {
                        Text(error)
                            .font(.brandCallout)
                            .foregroundStyle(Palette.live)
                    }
                }

                Section {
                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if model.isBusy { ProgressView() } else { Text(submitTitle).fontWeight(.bold) }
                            Spacer()
                        }
                    }
                    .disabled(!model.canSubmit)
                }

                links
            }
            .onChange(of: model.mode) { model.clearMessages() }
            .navigationTitle(model.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var fields: some View {
        @Bindable var bindable = model
        switch model.mode {
        case .login:
            Section {
                emailField
                SecureField("Пароль", text: $bindable.password)
                    .textContentType(.password)
            }
        case .register:
            Section {
                TextField("Имя — так вас увидят в чате", text: $bindable.displayName)
                    .textContentType(.nickname)
                TextField("Адрес канала (латиница, цифры, _)", text: $bindable.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                emailField
                SecureField("Пароль — не меньше 8 знаков", text: $bindable.password)
                    .textContentType(.newPassword)
            }
            Section {
                Toggle(isOn: $bindable.acceptsRules) {
                    Text("Принимаю [правила сообщества](https://efirelle.ru/rules) и [политику конфиденциальности](https://efirelle.ru/privacy). За оскорбления и недопустимый контент аккаунт блокируется.")
                        .font(.brandCaption)
                }
            }
        case .reset:
            Section {
                emailField
                    .disabled(model.isCodeSent)
                if model.isCodeSent {
                    TextField("Код из письма", text: $bindable.code)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                    SecureField("Новый пароль", text: $bindable.password)
                        .textContentType(.newPassword)
                }
            } footer: {
                Text(model.isCodeSent
                    ? "Если аккаунт с этой почтой есть, мы отправили на неё код. Он действует 30 минут."
                    : "Пришлём код на почту, указанную при регистрации.")
            }
        }
    }

    private var emailField: some View {
        @Bindable var bindable = model
        return TextField("Почта", text: $bindable.email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    @ViewBuilder
    private var links: some View {
        Section {
            switch model.mode {
            case .login:
                Button("Забыли пароль?") { model.mode = .reset }
            case .register:
                EmptyView()
            case .reset:
                Button("Вспомнили пароль? Войти") { model.mode = .login }
            }
        }
    }

    private var submitTitle: String {
        switch model.mode {
        case .login: "Войти"
        case .register: "Создать аккаунт"
        case .reset: model.isCodeSent ? "Сохранить и войти" : "Получить код"
        }
    }

    private func submit() {
        Task {
            if let viewer = await model.submit(using: repository) {
                session.signIn(viewer)
                dismiss()
            }
        }
    }
}

extension View {
    /// Лист входа — для действий, которым нужен аккаунт.
    func signInSheet(isPresented: Binding<Bool>, mode: AuthViewModel.Mode = .login) -> some View {
        sheet(isPresented: isPresented) {
            AuthView(mode: mode)
        }
    }
}

#Preview {
    AuthView(mode: .register)
        .environment(Session())
}
