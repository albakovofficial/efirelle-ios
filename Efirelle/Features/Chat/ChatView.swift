import SwiftUI

/// Панель чата эфира.
struct ChatView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model: ChatViewModel

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
            Divider()
            ChatComposer(
                draft: $model.draft,
                canSend: model.canSend,
                sparks: model.viewer?.sparks,
                onSend: model.send
            )
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
        .task { await model.load(from: repository) }
        .task(id: model.prediction?.id) { await model.runPredictionCountdown() }
    }

    private var header: some View {
        HStack {
            Text("Чат")
                .font(.brandHeadline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Picker("Показывать", selection: $model.scope) {
                ForEach(ChatViewModel.Scope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(Spacing.m)
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
                        ChatEntryRow(entry: entry).id(entry.id)
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
