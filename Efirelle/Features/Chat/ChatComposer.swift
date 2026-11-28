import SwiftUI
import UIKit

/// Поле сообщения: ответ на сообщение, эмодзи канала, отправка и баланс искр.
struct ChatComposer: View {
    @Binding var draft: String
    let canSend: Bool
    let sparks: Int
    var replyTarget: ChatMessage?
    var emotes: [Emote] = []
    var emoteImages: [String: UIImage] = [:]
    var onCancelReply: () -> Void = {}
    var onInsertEmote: (Emote) -> Void = { _ in }
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if let replyTarget {
                HStack(spacing: Spacing.xs) {
                    Text("Ответ \(Text(verbatim: replyTarget.author).fontWeight(.heavy)): \(replyTarget.text)")
                        .font(.brandCaption)
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: onCancelReply) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Palette.muted)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Не отвечать")
                }
                .padding(.leading, Spacing.s)
                .background(Palette.background, in: .rect(cornerRadius: Radius.s))
            }

            HStack(spacing: Spacing.xs) {
                TextField(replyTarget.map { "Ответить \($0.author)" } ?? "Сообщение в чат", text: $draft)
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

            HStack(spacing: Spacing.xs) {
                if !emotes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(emotes) { emote in
                                Button {
                                    onInsertEmote(emote)
                                    isFocused = true
                                } label: {
                                    Group {
                                        if let image = emoteImages[emote.code] {
                                            Image(uiImage: image)
                                        } else {
                                            Text(verbatim: ":\(emote.code):").font(.brandMicro)
                                        }
                                    }
                                    .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(":\(emote.code):")
                            }
                        }
                    }
                }
                SparksBalanceView(amount: sparks)
                    .frame(maxWidth: emotes.isEmpty ? .infinity : nil, alignment: .leading)
            }
        }
        .padding(Spacing.s)
        .onChange(of: replyTarget?.id) { _, id in
            if id != nil { isFocused = true }
        }
    }
}
