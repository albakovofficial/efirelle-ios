import ActivityKit
import SwiftUI
import WidgetKit

/// Как выглядит эфир канала на экране блокировки и в Dynamic Island.
struct LiveStreamActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveStreamAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Palette.surface)
                .activitySystemActionForegroundColor(Palette.ink)
                .widgetURL(context.attributes.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveMark(isLive: context.state.isLive)
                        .padding(.leading, Spacing.xxs)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ViewersLabel(viewers: context.state.viewers, isLive: context.state.isLive)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.name)
                            .font(.brandHeadline)
                            .foregroundStyle(.white)
                        Text(subtitle(context.state))
                            .font(.brandCaption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                LiveDot(isLive: context.state.isLive)
            } compactTrailing: {
                ViewersLabel(viewers: context.state.viewers, isLive: context.state.isLive)
                    .foregroundStyle(.white)
            } minimal: {
                LiveDot(isLive: context.state.isLive)
            }
            .widgetURL(context.attributes.url)
            .keylineTint(Palette.live)
        }
    }

    private func subtitle(_ state: LiveStreamAttributes.ContentState) -> String {
        guard state.isLive else { return "Эфир закончился" }
        return state.title.isEmpty ? "В эфире" : state.title
    }
}

private struct LockScreenView: View {
    let attributes: LiveStreamAttributes
    let state: LiveStreamAttributes.ContentState

    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                LiveMark(isLive: state.isLive)
                Text(attributes.name)
                    .font(.brandHeadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(state.isLive ? (state.title.isEmpty ? "Заходите в эфир" : state.title) : "Эфир закончился — спасибо, что смотрели")
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            ViewersLabel(viewers: state.viewers, isLive: state.isLive)
                .foregroundStyle(Palette.ink)
        }
        .padding(Spacing.m)
    }
}

/// Бейдж «В ЭФИРЕ» или «ЗАВЕРШЁН».
private struct LiveMark: View {
    let isLive: Bool

    var body: some View {
        Text(isLive ? "В ЭФИРЕ" : "ЗАВЕРШЁН")
            .font(.brandMicro)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isLive ? Palette.live : Palette.muted, in: .capsule)
    }
}

private struct LiveDot: View {
    let isLive: Bool

    var body: some View {
        Circle()
            .fill(isLive ? Palette.live : Palette.muted)
            .frame(width: 10, height: 10)
    }
}

/// Число зрителей; после эфира не показывается.
private struct ViewersLabel: View {
    let viewers: Int
    let isLive: Bool

    var body: some View {
        if isLive {
            Label {
                Text(viewers.formatted(.number.notation(.compactName)))
                    .monospacedDigit()
            } icon: {
                Image(systemName: "eye.fill")
            }
            .font(.brandCaption)
            .labelStyle(.titleAndIcon)
            .contentTransition(.numericText())
        }
    }
}
