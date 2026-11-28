import SwiftUI

/// Прогноз зрителей: вопрос, таймер, варианты с долей голосов, итог.
struct PredictionCardView: View {
    let prediction: Prediction
    let timeLeft: Duration
    let isOpen: Bool
    /// Голосовать могут вошедшие зрители, но не автор эфира.
    let canVote: Bool
    let onVote: (Prediction.Outcome.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("ПРОГНОЗ")
                Spacer()
                Text(headStatus).monospacedDigit()
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
        .sensoryFeedback(.success, trigger: prediction.myOutcomeId)
    }

    private var headStatus: String {
        switch prediction.status {
        case .resolved: "итог подведён"
        case .open where isOpen: "ещё \(Formatters.clock(timeLeft))"
        default: "приём прогнозов закрыт"
        }
    }

    private var footer: String {
        let reward = "+\(Prediction.reward) искр"
        if prediction.status == .resolved {
            guard let mine = prediction.myOutcomeId else {
                return "Прогноз завершён · \(Formatters.count(prediction.participants, .participants, compact: false))"
            }
            return mine == prediction.winningOutcomeId ? "Верно! \(reward)" : "В этот раз не угадали"
        }
        if prediction.myOutcomeId != nil {
            return "Прогноз принят · за верный ответ \(reward)"
        }
        return "Бесплатно · за верный ответ \(reward) · \(Formatters.count(prediction.participants, .participants, compact: false))"
    }

    private func outcomeButton(_ outcome: Prediction.Outcome) -> some View {
        let isSelected = outcome.id == prediction.myOutcomeId || outcome.id == prediction.winningOutcomeId
        let fraction = CGFloat(outcome.percent) / 100
        let isEnabled = isOpen && canVote && prediction.myOutcomeId == nil

        return Button {
            onVote(outcome.id)
        } label: {
            HStack {
                Text(outcome.id == prediction.winningOutcomeId ? "\(outcome.label) ✓" : outcome.label)
                    .font(.brandCallout)
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
        .disabled(!isEnabled)
        .opacity(isEnabled || isSelected || prediction.myOutcomeId == nil ? 1 : 0.55)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
