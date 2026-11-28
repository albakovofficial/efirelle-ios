import SwiftUI
import UIKit

/// Студия автора. Эфир ведётся из OBS или другого приложения с RTMP — здесь его адрес и ключ,
/// настройки эфира и инструменты: прогнозы, моменты, рейд, запреты писать в чат.
struct StudioView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model = StudioViewModel()
    @State private var showsKey = false
    @State private var confirmsNewKey = false

    var body: some View {
        LoadStateView(state: model.state, retry: { await model.load(from: repository) }) { studio in
            form(studio)
        }
        .background(Palette.background)
        .navigationTitle("Студия")
        .task { await model.load(from: repository) }
        .task(id: model.notice) {
            guard model.notice != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            model.clearNotice()
        }
        .safeAreaInset(edge: .bottom) {
            if let notice = model.notice {
                Text(notice)
                    .font(.brandCallout)
                    .foregroundStyle(.white)
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity)
                    .background(Palette.ink, in: .rect(cornerRadius: Radius.m))
                    .padding(Spacing.m)
            }
        }
        .confirmationDialog("Создать новый ключ?", isPresented: $confirmsNewKey, titleVisibility: .visible) {
            Button("Создать") { Task { await model.rotateKey(using: repository) } }
        } message: {
            Text("Старый ключ сразу перестанет работать — его нужно будет заменить в OBS.")
        }
    }

    private func form(_ studio: Studio) -> some View {
        @Bindable var bindable = model
        return Form {
            Section {
                LabeledContent("Статус", value: studio.stream == nil ? "Не в эфире" : "В эфире")
                if let stream = studio.stream {
                    LabeledContent("Зрители", value: Formatters.number(stream.viewers))
                }
                NavigationLink("Открыть мой канал", value: studio.channel)
            }

            Section {
                copyRow("Сервер", value: studio.ingest.server, shown: true)
                copyRow("Ключ потока", value: studio.ingest.streamKey, shown: showsKey)
                Button(showsKey ? "Скрыть ключ" : "Показать ключ") { showsKey.toggle() }
                Button("Создать новый ключ", role: .destructive) { confirmsNewKey = true }
            } header: {
                Text("Подключение OBS")
            } footer: {
                Text("OBS → Настройки → Трансляция: сервис «Настраиваемый», вставьте сервер и ключ. Ключ никому не показывайте. Рекомендуем 720p или 1080p, 3000–6000 Кбит/с, ключевой кадр каждые 2 с.")
            }

            Section("Об эфире") {
                TextField("Название", text: $bindable.settings.title)
                Picker("Категория", selection: $bindable.settings.categoryId) {
                    ForEach(model.categories) { category in
                        Text(category.name).tag(category.id)
                    }
                }
                TextField("Теги через запятую, до пяти", text: $bindable.tagsText)
                Button("Сохранить") { Task { await model.saveSettings(using: repository) } }
                    .disabled(model.isBusy || model.settings.title.isBlank)
            }

            predictionSection(studio.prediction, isLive: studio.stream != nil)

            if studio.stream != nil {
                Section {
                    TextField("Что происходит", text: $bindable.momentText)
                    Button("Отметить момент") { Task { await model.addMoment(using: repository) } }
                        .disabled(model.isBusy || model.momentText.isBlank)
                } header: {
                    Text("Момент")
                } footer: {
                    Text("Зрители увидят его в ленте «Живые моменты».")
                }
                Section {
                    TextField("Адрес канала", text: $bindable.raidTarget)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Отправить рейд") { Task { await model.raid(using: repository) } }
                        .disabled(model.isBusy || model.raidTarget.isBlank)
                } header: {
                    Text("Рейд")
                } footer: {
                    Text("Предложите зрителям перейти к другому автору в конце эфира.")
                }
            }

            Section("Запрет писать в чат") {
                ForEach(studio.bans) { ban in
                    LabeledContent(ban.name, value: ban.until.map(Self.untilText) ?? "навсегда")
                        .swipeActions {
                            Button("Снять") { Task { await model.unban(ban, using: repository) } }
                        }
                }
                TextField("Адрес канала пользователя", text: $bindable.banUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("Срок", selection: $bindable.banMinutes) {
                    ForEach(StudioViewModel.banDurations, id: \.self) { minutes in
                        Text(Self.banTitle(minutes)).tag(minutes)
                    }
                }
                Button("Запретить", role: .destructive) { Task { await model.ban(using: repository) } }
                    .disabled(model.isBusy || model.banUsername.isBlank)
            }
        }
        .refreshable { await model.load(from: repository) }
    }

    @ViewBuilder
    private func predictionSection(_ prediction: Prediction?, isLive: Bool) -> some View {
        @Bindable var bindable = model
        if let prediction, prediction.isActive {
            Section {
                Text("«\(prediction.question)»").font(.brandHeadline)
                ForEach(prediction.outcomes) { outcome in
                    Button("Верно: \(outcome.label) · \(outcome.percent)%") {
                        Task { await model.resolve(prediction, outcome: outcome, using: repository) }
                    }
                    .disabled(model.isBusy)
                }
                Button("Отменить прогноз", role: .destructive) {
                    Task { await model.cancel(prediction, using: repository) }
                }
            } header: {
                Text("Прогноз идёт")
            } footer: {
                Text("Каждый, кто угадал, получит \(Prediction.reward) искр. Искры нельзя купить или вывести.")
            }
        } else {
            Section {
                TextField("Вопрос", text: $bindable.question)
                ForEach(bindable.outcomes.indices, id: \.self) { index in
                    TextField("Вариант \(index + 1)", text: $bindable.outcomes[index])
                }
                HStack {
                    Button("Добавить вариант") { model.addOutcome() }
                        .disabled(model.outcomes.count >= 4)
                    Spacer()
                    Button("Убрать") { model.removeOutcome() }
                        .disabled(model.outcomes.count <= 2)
                }
                .buttonStyle(.borderless)
                Picker("Приём ответов", selection: $bindable.predictionDuration) {
                    ForEach(StudioViewModel.predictionDurations, id: \.self) { duration in
                        Text("\(duration.components.seconds / 60) мин").tag(duration)
                    }
                }
                Button(isLive ? "Запустить прогноз" : "Прогноз запускается во время эфира") {
                    Task { await model.startPrediction(using: repository) }
                }
                .disabled(model.isBusy || !model.canStartPrediction)
            } header: {
                Text("Прогноз для зрителей")
            } footer: {
                Text("Бесплатный: зрители угадывают исход, за верный ответ — \(Prediction.reward) искр. Никаких ставок и денег.")
            }
        }
    }

    private func copyRow(_ title: String, value: String, shown: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.brandCaption).foregroundStyle(Palette.muted)
                Text(shown ? value : String(repeating: "•", count: 20))
                    .font(.brandCallout.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
            Spacer()
            Button("Копировать") {
                UIPasteboard.general.string = value
                model.announce("\(title): скопировано")
            }
            .buttonStyle(.borderless)
        }
    }

    private static func banTitle(_ minutes: Int?) -> String {
        switch minutes {
        case .none: "Навсегда"
        case .some(let minutes) where minutes >= 1_440: "\(minutes / 1_440) дн."
        case .some(let minutes) where minutes >= 60: "\(minutes / 60) ч"
        case .some(let minutes): "\(minutes) мин"
        }
    }

    private static func untilText(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = parser.date(from: iso) else { return "временно" }
        return "до \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
}
