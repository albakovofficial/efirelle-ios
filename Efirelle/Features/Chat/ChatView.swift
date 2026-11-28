import SwiftUI

/// Панель чата эфира.
struct ChatView: View {
    let model: ChatViewModel

    @Environment(\.streamRepository) private var repository
    @Environment(Session.self) private var session
    @State private var showsSignIn = false

    var body: some View {
        @Bindable var bindable = model
        VStack(spacing: 0) {
            header
            Divider()
            messages
            if let notice = model.notice {
                Text(notice)
                    .font(.brandCaption)
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.background)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            Divider()
            if let viewer = session.viewer {
                ChatComposer(
                    draft: $bindable.draft,
                    canSend: model.canSend,
                    sparks: viewer.sparks,
                    onSend: { Task { await model.send(using: repository) } }
                )
            } else {
                Button {
                    showsSignIn = true
                } label: {
                    Text("Войдите, чтобы писать в чат и участвовать в прогнозах")
                        .font(.brandCallout)
                        .frame(maxWidth: .infinity, minHeight: TapTarget.minimum)
                }
                .buttonStyle(.borderedProminent)
                .padding(Spacing.s)
            }
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .task(id: model.prediction?.id) { await model.runPredictionCountdown() }
        .task(id: model.notice) {
            guard model.notice != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            model.clearNotice()
        }
        // Верный прогноз начисляет искры — обновляем баланс.
        .onChange(of: model.prediction?.status) { _, status in
            if status == .resolved { Task { await session.refresh(using: repository) } }
        }
        .signInSheet(isPresented: $showsSignIn)
    }

    private var header: some View {
        @Bindable var bindable = model
        return HStack {
            Text("Чат")
                .font(.brandHeadline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Picker("Показывать", selection: $bindable.scope) {
                ForEach(ChatViewModel.Scope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s) {
                    if let prediction = model.prediction {
                        PredictionCardView(
                            prediction: prediction,
                            timeLeft: model.predictionTimeLeft,
                            isOpen: model.isPredictionOpen,
                            canVote: session.viewer != nil && !model.isOwner,
                            onVote: { outcome in Task { await model.vote(for: outcome, using: repository) } }
                        )
                    }
                    if model.visibleEntries.isEmpty {
                        Text("Сообщений пока нет — напишите первым")
                            .font(.brandCaption)
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(model.visibleEntries) { entry in
                        ChatEntryRow(entry: entry, actions: actions(for: entry))
                            .id(entry.id)
                    }
                }
                .padding(Spacing.m)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.visibleEntries.last?.id) { _, lastID in
                guard let lastID else { return }
                withAnimation(.snappy) { proxy.scrollTo(lastID, anchor: .bottom) }
            }
        }
    }

    /// Действия доступны вошедшему зрителю и только с чужими сообщениями.
    private func actions(for entry: ChatEntry) -> ChatEntryRow.Actions? {
        guard
            let viewer = session.viewer,
            case .message(let message) = entry,
            message.authorId != viewer.id
        else { return nil }
        return ChatEntryRow.Actions(
            canDelete: model.isOwner || viewer.role == .admin,
            canBan: model.isOwner,
            report: { reason in Task { await model.report(message, reason: reason, using: repository) } },
            hideAuthor: { Task { await model.hideAuthor(of: message, using: repository) } },
            delete: { Task { await model.delete(message, using: repository) } },
            ban: { minutes in Task { await model.ban(message, minutes: minutes, using: repository) } }
        )
    }
}

#Preview {
    ChatView(model: ChatViewModel(channelID: "timur"))
        .frame(height: 600)
        .padding()
        .background(Palette.background)
        .environment(Session())
}
