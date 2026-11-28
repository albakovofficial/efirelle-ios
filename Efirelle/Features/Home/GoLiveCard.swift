import SwiftUI

/// Когда никто не в эфире: приглашение начать свой эфир прямо с камеры iPhone.
struct GoLiveCard: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Сейчас тихо")
                    .font(.brandHeadline)
                Text("Начните эфир прямо с камеры iPhone")
                    .font(.brandCaption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 0)
            Button(action: action) {
                Label("В эфир", systemImage: "video.fill")
                    .font(.brandCallout)
                    .padding(.horizontal, 14)
                    .frame(minHeight: TapTarget.minimum)
                    .background(Palette.live, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(Spacing.m)
        .background(Palette.ink, in: .rect(cornerRadius: Radius.l))
    }
}

#Preview {
    GoLiveCard {}
        .padding()
}
