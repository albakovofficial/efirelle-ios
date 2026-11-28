import SwiftUI

/// Запрещённые слова канала: сообщения с ними не попадают в чат. Регистр и «ё» не важны.
struct BlockedWordsView: View {
    let model: ModerationViewModel
    @Environment(\.streamRepository) private var repository

    var body: some View {
        @Bindable var bindable = model
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.xs) {
                    TextField("Слово или часть слова", text: $bindable.newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(add)
                        .padding(.horizontal, Spacing.s)
                        .frame(minHeight: TapTarget.minimum)
                        .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
                    Button("Добавить", action: add)
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.accent)
                        .disabled(model.newWord.trimmingCharacters(in: .whitespaces).count < 2)
                }

                if model.settings.blockedWords.isEmpty {
                    Text("Добавьте слова, которые не должны появляться в чате: например, рекламу или оскорбления.")
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(model.settings.blockedWords, id: \.self) { word in
                            Button {
                                Task { await model.removeWord(word, using: repository) }
                            } label: {
                                Label(word, systemImage: "xmark")
                                    .labelStyle(TrailingIconLabelStyle())
                                    .font(.brandCaption)
                                    .foregroundStyle(Palette.inkSoft)
                                    .padding(.horizontal, 10)
                                    .frame(height: 32)
                                    .background(Palette.surface, in: .capsule)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Убрать «\(word)»")
                        }
                    }
                }
            }
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Запрещённые слова")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add() {
        Task { await model.addWord(using: repository) }
    }
}

/// Значок справа от текста — крестик у чипа слова.
private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}
