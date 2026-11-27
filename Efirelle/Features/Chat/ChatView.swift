import SwiftUI

/// Панель чата эфира.
struct ChatView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model: ChatViewModel
    /// Правила чата принимаются один раз перед первым сообщением.
    @AppStorage("chat.rulesAccepted") private var rulesAccepted = false
    @State private var showsRules = false

    init(streamID: LiveStream.ID) {
        _model = State(initialValue: ChatViewModel(streamID: streamID))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.isUnavailable {
                ContentUnavailableView("Чат недоступен", systemImage: "bubble.left.and.exclamationmark.bubble.right")
            } else {
                messages
            }
            if let text = model.sendError ?? model.notice {
                banner(text, isError: model.sendError != nil)
            }
            Divider()
            ChatComposer(
                draft: $model.draft,
                canSend: model.canSend,
                sparks: model.viewer?.sparks,
                onSend: send
            )
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .task { await model.load(from: repository) }
        .task(id: model.prediction?.id) { await model.runPredictionCountdown() }
        .task(id: model.notice) {
            guard model.notice != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            model.clearNotice()
        }
        .onChange(of: model.draft) { model.clearSendError() }
        .sheet(isPresented: $showsRules) {
            ChatRulesView(
                isAccepted: rulesAccepted,
                blockedAuthors: model.blockedAuthors,
                onAccept: {
                    rulesAccepted = true
                    showsRules = false
                    model.send()
                },
                onUnblock: model.unblock(author:)
            )
        }
    }

    /// Первое сообщение — только после принятия правил.
    private func send() {
        if rulesAccepted {
            model.send()
        } else {
            showsRules = true
        }
    }

    private var header: some View {
        HStack {
            Text("Чат")
                .font(.brandHeadline)
                .accessibilityAddTraits(.isHeader)
            Button {
                showsRules = true
            } label: {
                Image(systemName: "info.circle")
                    .frame(width: TapTarget.minimum, height: TapTarget.minimum)
            }
            .accessibilityLabel("Правила чата и поддержка")
            Spacer()
            Picker("Показывать", selection: $model.scope) {
                ForEach(ChatViewModel.Scope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.leading, Spacing.m)
        .padding([.vertical, .trailing], Spacing.s)
    }

    private func banner(_ text: String, isError: Bool) -> some View {
        Text(text)
            .font(.brandCaption)
            .foregroundStyle(isError ? Palette.live : Palette.inkSoft)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.background)
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s) {
                    if let prediction = model.prediction {
                        PredictionCardView(
                            prediction: prediction,
                            timeLeft: model.predictionTimeLeft,
                            selectedOutcomeID: model.selectedOutcomeID,
                            isOpen: model.isPredictionOpen,
                            onVote: model.vote(for:)
                        )
                    }
                    ForEach(model.visibleEntries) { entry in
                        ChatEntryRow(
                            entry: entry,
                            onReport: { message, reason in
                                Task { await model.report(message, reason: reason, to: repository) }
                            },
                            onBlock: { message in model.block(author: message.author) }
                        )
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
}

#Preview {
    ChatView(streamID: "s-timur")
        .frame(height: 600)
        .padding()
        .background(Palette.background)
        .environment(\.streamRepository, MockStreamRepository.instant)
}
