import Charts
import SwiftUI

/// Статистика канала: «Сводка» — четыре главные цифры и график последнего эфира, ниже «Лента эфиров».
struct StatsView: View {
    @State private var model = StatsViewModel()
    @Environment(\.streamRepository) private var repository

    var body: some View {
        LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { stats in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    summary(stats.summary)
                    if let last = stats.streams.first {
                        lastStream(last)
                    }
                    SectionHeader(title: "Эфиры", subtitle: stats.streams.isEmpty ? nil : "Последние \(stats.streams.count)")
                    if stats.streams.isEmpty {
                        EmptyHistoryCard()
                    } else {
                        ForEach(stats.streams) { StreamStatsRow(stream: $0) }
                    }
                }
                .padding(Spacing.m)
            }
        }
        .background(Palette.background)
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(from: repository) }
        .refreshable { await model.load(from: repository) }
    }

    private func summary(_ summary: ChannelStats.Summary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible())], spacing: Spacing.xs) {
            MetricTile(
                title: "Средне зрителей",
                value: Formatters.number(summary.avgViewers.week),
                note: StatsViewModel.change(Double(summary.avgViewers.week), from: Double(summary.avgViewers.previousWeek))
            )
            MetricTile(
                title: "Рекорд зрителей",
                value: Formatters.number(summary.peak.viewers),
                note: summary.peak.at.flatMap(ISODate.parse).map { $0.formatted(.dateTime.day().month(.wide)) }
            )
            MetricTile(
                title: "Новых подписчиков",
                value: "+\(Formatters.number(summary.newFollowers.week))",
                note: "всего \(Formatters.count(summary.followers, .subscribers))"
            )
            MetricTile(
                title: "Часов в эфире",
                value: summary.hoursLive.week.formatted(.number.precision(.fractionLength(0...1))),
                note: StatsViewModel.change(summary.hoursLive.week, from: summary.hoursLive.previousWeek) ?? "за 7 дней"
            )
        }
    }

    private func lastStream(_ stream: ChannelStats.Stream) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Последний эфир · зрители")
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
            ViewersChart(points: stream.points)
                .frame(height: 120)
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
    }
}

/// Одна цифра сводки с пояснением под ней.
private struct MetricTile: View {
    let title: String
    let value: String
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
            Text(value)
                .font(.system(.title2, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
            if let note {
                Text(note)
                    .font(.brandCaption)
                    .foregroundStyle(note.hasPrefix("−") ? Palette.live : note.hasPrefix("+") ? Palette.accent : Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }
}

/// График зрителей по ходу эфира: линия и мягкая заливка под ней.
private struct ViewersChart: View {
    let points: [Int]
    var showsAxis = true

    var body: some View {
        Chart(Array(points.enumerated()), id: \.offset) { index, viewers in
            AreaMark(x: .value("Время", index), y: .value("Зрители", viewers))
                .foregroundStyle(Palette.accent.opacity(0.12))
                .interpolationMethod(.catmullRom)
            LineMark(x: .value("Время", index), y: .value("Зрители", viewers))
                .foregroundStyle(Palette.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(showsAxis ? .automatic : .hidden)
        .accessibilityLabel("Зрители: от \(points.min() ?? 0) до \(points.max() ?? 0)")
    }
}

/// Эфир в ленте: название, дата, длительность, пик, новые подписчики и мини-график.
private struct StreamStatsRow: View {
    let stream: ChannelStats.Stream

    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stream.title.isEmpty ? "Эфир без названия" : stream.title)
                    .font(.brandHeadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(details)
                    .font(.brandCaption)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if stream.points.count > 1 {
                ViewersChart(points: stream.points, showsAxis: false)
                    .frame(width: 72, height: 32)
            }
        }
        .padding(Spacing.s)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }

    private var details: String {
        let date = stream.startDate?.formatted(.dateTime.day().month(.abbreviated)) ?? ""
        let duration = Formatters.clock(.seconds(stream.durationSeconds))
        return "\(date) · \(duration) · пик \(stream.peakViewers) · +\(Formatters.count(stream.newFollowers, .subscribers))"
    }
}

/// Сохранённых эфиров нет: пунктирный «призрачный» график на месте будущей кривой.
private struct EmptyHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            GhostLine()
                .stroke(Palette.accent.opacity(0.3), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 6]))
                .frame(height: 56)
            Text("Пока нечего сравнивать")
                .font(.brandHeadline)
                .foregroundStyle(Palette.ink)
            Text("Каждый эфир будет сохраняться здесь с графиком зрителей, пиком и новыми подписчиками — и вы увидите, какой прошёл лучше.")
                .font(.brandCaption)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }
}

/// Плавно растущая линия для пустой истории.
private struct GhostLine: Shape {
    func path(in rect: CGRect) -> Path {
        let heights: [CGFloat] = [0.85, 0.72, 0.76, 0.52, 0.6, 0.36, 0.44, 0.15]
        var path = Path()
        for (index, height) in heights.enumerated() {
            let point = CGPoint(x: rect.width * CGFloat(index) / CGFloat(heights.count - 1), y: rect.height * height)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

#Preview {
    NavigationStack { StatsView() }
}
