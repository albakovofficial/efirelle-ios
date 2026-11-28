import SwiftUI

/// Шапка главной: логотип и баланс искр — две белые капсулы одной высоты.
struct HomeHeader: View {
    let sparks: Int?

    var body: some View {
        HStack {
            LogoView(size: 20)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
            Spacer()
            if let sparks {
                SparksBalanceView(amount: sparks)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
            }
        }
    }
}

#Preview {
    HomeHeader(sparks: 500)
        .padding()
        .background(Palette.background)
}
