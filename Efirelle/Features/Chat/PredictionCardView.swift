import SwiftUI

/// Прогноз зрителей: вопрос, таймер, варианты с долей голосов.
struct PredictionCardView: View {
    let prediction: Prediction
    let timeLeft: Duration
    let selectedOutcomeID: Prediction.Outcome.ID?
    let isOpen: Bool
    let onVote: (Prediction.Outcome.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("ПРОГНОЗ")
                Spacer()
                Text(isOpen ? "ещё \(Formatters.clock(timeLeft))" : "приём ставок закрыт")
                    .monospacedDigit()
            }
            .font(.brandMicro)
            .foregroundStyle(Palette.muted)

            Text(prediction.question)
                .font(.brandHeadline)
                .foregroundStyle(Palette.ink)

            ForEach(prediction.outcomes) { outcome in
                outcomeButton(outcome)
            }

            Text(footer)
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.m)
        .background(Palette.background, in: .rect(cornerRadius: Radius.l))
        .sensoryFeedback(.success, trigger: selectedOutcomeID)
    }

    private var footer: String {
        if selectedOutcomeID != nil {
            return "Ставка принята · \(ChatViewModel.predictionStake) искр"
        }
        return "Ставка в искрах · \(Formatters.count(prediction.participants, .participants, compact: false))"
    }

    private func outcomeButton(_ outcome: Prediction.Outcome) -> some View {
        let isSelected = outcome.id == selectedOutcomeID
        let fraction = CGFloat(outcome.percent) / 100

        return Button {
            onVote(outcome.id)
        } label: {
            HStack {
                Text(outcome.title).font(.brandCallout)
                Spacer()
                Text("\(outcome.percent)%").font(.brandCallout.monospacedDigit())
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: TapTarget.minimum)
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    outcome.tone.surface.frame(width: proxy.size.width * fraction)
                }
            }
            .background(Palette.surface)
            .clipShape(.rect(cornerRadius: Radius.s))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.s)
                    .strokeBorder(isSelected ? outcome.tone.ink : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isOpen || (selectedOutcomeID != nil && !isSelected))
        .opacity(!isOpen || selectedOutcomeID == nil || isSelected ? 1 : 0.55)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
