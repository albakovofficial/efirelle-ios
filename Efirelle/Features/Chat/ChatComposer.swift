import SwiftUI

/// Поле сообщения, кнопка отправки и баланс искр.
struct ChatComposer: View {
    @Binding var draft: String
    let canSend: Bool
    let sparks: Int?
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                TextField("Сообщение в чат", text: $draft)
                    .font(.brandBody)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: TapTarget.minimum)
                    .background(Palette.background, in: .rect(cornerRadius: Radius.m))

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: TapTarget.minimum, height: TapTarget.minimum)
                        .background(canSend ? Palette.accent : Palette.line, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Отправить")
            }

            if let sparks {
                SparksBalanceView(amount: sparks)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.s)
    }
}
