import SwiftUI

/// Правила чата. Показываются перед первым сообщением (их нужно принять) и по кнопке «i» в чате.
/// Здесь же контакт поддержки и список заблокированных — требования App Review 1.2.
struct ChatRulesView: View {
    let isAccepted: Bool
    let blockedAuthors: [String]
    let onAccept: () -> Void
    let onUnblock: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let forbidden = [
        "оскорбления, травля, угрозы",
        "разжигание ненависти",
        "откровенный контент и всё, что связано с сексуализацией несовершеннолетних",
        "чужие личные данные",
        "спам, реклама и мошенничество",
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("У нас нулевая терпимость к нарушениям: сообщения удаляются, а нарушители теряют доступ к чату.")
                        .font(.brandBody)
                    ForEach(forbidden, id: \.self) { item in
                        Label(item, systemImage: "xmark.circle")
                            .font(.brandCallout)
                            .foregroundStyle(Palette.inkSoft)
                    }
                } header: {
                    Text("В чате запрещено")
                }

                Section {
                    Label("Нажмите на сообщение и удерживайте, чтобы пожаловаться или заблокировать автора.", systemImage: "hand.tap")
                    Label("Жалобы рассматриваются в течение 24 часов.", systemImage: "clock")
                    Label("Прогнозы бесплатные. Искры — только награда: их нельзя купить или вывести.", systemImage: "sparkle")
                } header: {
                    Text("Как это работает")
                }
                .font(.brandCallout)

                Section {
                    Link(destination: AppLinks.supportMail) {
                        Label(AppLinks.supportEmail, systemImage: "envelope")
                    }
                    Link(destination: AppLinks.rules) {
                        Label("Правила сообщества", systemImage: "doc.text")
                    }
                    Link(destination: AppLinks.privacy) {
                        Label("Политика конфиденциальности", systemImage: "hand.raised")
                    }
                } header: {
                    Text("Связаться с нами")
                }

                if !blockedAuthors.isEmpty {
                    Section {
                        ForEach(blockedAuthors, id: \.self) { author in
                            HStack {
                                Text(author)
                                Spacer()
                                Button("Разблокировать") { onUnblock(author) }
                                    .buttonStyle(.borderless)
                            }
                        }
                    } header: {
                        Text("Заблокированные")
                    }
                }
            }
            .navigationTitle("Правила чата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isAccepted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") { dismiss() }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Принимаю", action: onAccept)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

#Preview {
    ChatRulesView(isAccepted: false, blockedAuthors: ["Георгий"], onAccept: {}, onUnblock: { _ in })
}
