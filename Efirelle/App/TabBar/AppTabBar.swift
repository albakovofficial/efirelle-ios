import SwiftUI

/// Нижняя панель: плавающая капсула вкладок и отдельная круглая кнопка эфира справа.
/// У выбранной вкладки — подпись на синей «таблетке», у остальных только значок.
struct AppTabBar: View {
    @Binding var selection: AppTab
    let broadcast: BroadcastSession
    let onGoLive: () -> Void

    @Namespace private var pill

    var body: some View {
        HStack(spacing: Spacing.s) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    item(tab)
                }
            }
            .padding(6)
            .background(Palette.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(Palette.line, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)

            GoLiveButton(broadcast: broadcast, action: onGoLive)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.xxs)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func item(_ tab: AppTab) -> some View {
        let isSelected = tab == selection
        return Button {
            withAnimation(.snappy(duration: 0.3)) { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .semibold))
                if isSelected {
                    Text(tab.title)
                        .font(.brandCaption)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundStyle(isSelected ? .white : Palette.inkSoft)
            .padding(.horizontal, isSelected ? 14 : 0)
            .frame(maxWidth: isSelected ? nil : .infinity, minHeight: 48)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Palette.accent)
                        .matchedGeometryEffect(id: "selection", in: pill)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Красный круг «В эфир»; пока идёт свой эфир — тёмный, с длительностью, и возвращает к эфиру.
private struct GoLiveButton: View {
    let broadcast: BroadcastSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(broadcast.isLive ? Palette.inkSurface : Palette.live, in: .circle)
                .shadow(color: (broadcast.isLive ? Palette.inkSurface : Palette.live).opacity(0.3), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(broadcast.isLive ? "Вернуться к своему эфиру" : "Начать эфир")
    }

    @ViewBuilder
    private var label: some View {
        if case .live(let since) = broadcast.state {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 3) {
                    Circle().fill(Palette.live).frame(width: 8, height: 8)
                    Text(Formatters.clock(.seconds(context.date.timeIntervalSince(since))))
                        .font(.system(size: 11, weight: .bold))
                        .monospacedDigit()
                }
            }
        } else {
            Image(systemName: "video.fill")
                .font(.system(size: 20, weight: .semibold))
        }
    }
}
