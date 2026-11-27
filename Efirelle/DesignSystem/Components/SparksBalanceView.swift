import SwiftUI

/// Баланс искр — внутренней валюты для прогнозов и наград канала.
struct SparksBalanceView: View {
    let amount: Int

    var body: some View {
        Label {
            Text(Formatters.number(amount))
                .font(.brandCallout)
                .foregroundStyle(Palette.ink)
        } icon: {
            Image(systemName: "sparkle")
                .foregroundStyle(Palette.accent)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Искры: \(Formatters.number(amount))")
    }
}
