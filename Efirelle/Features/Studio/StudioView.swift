import PhotosUI
import SwiftUI
import UIKit

/// Студия автора. Эфир ведётся прямо с камеры iPhone или из OBS — здесь адрес и ключ для OBS,
/// настройки эфира и инструменты: прогнозы, моменты, рейд, запреты писать в чат.
struct StudioView: View {
    @Environment(\.streamRepository) private var repository
    @State private var model = StudioViewModel()
    @State private var showsKey = false
    @State private var confirmsNewKey = false
    @State private var avatarItem: PhotosPickerItem?
    @State private var bannerItem: PhotosPickerItem?
    @State private var emoteItem: PhotosPickerItem?
    @Environment(BroadcastLauncher.self) private var launcher

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
                    .background(Palette.inkSurface, in: .rect(cornerRadius: Radius.m))
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
                Button {
                    Task { await launcher.open(signedIn: true, repository: repository) }
                } label: {
                    Label("Эфир с камеры iPhone", systemImage: "video.fill")
                        .font(.brandHeadline)
                }
                .disabled(studio.stream != nil)
            } footer: {
                Text(studio.stream == nil
                    ? "Без OBS: камера и микрофон iPhone, вертикальное видео 720p. Название и категория — из раздела «Об эфире»."
                    : "Эфир уже идёт из другого приложения.")
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

            appearanceSection(studio)

            predictionSection(studio.prediction, isLive: studio.stream != nil)

            scheduleSection(studio)

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

            emotesSection(studio)

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
        .onChange(of: avatarItem) { _, item in pick(item) { await model.uploadAvatar($0, using: repository) } }
        .onChange(of: bannerItem) { _, item in pick(item) { await model.uploadBanner($0, using: repository) } }
        .onChange(of: emoteItem) { _, item in pick(item) { await model.addEmote($0, using: repository) } }
    }

    /// Выбранная в «Фото» картинка → данные → действие. Выбор сбрасывается, чтобы ту же картинку можно было выбрать снова.
    private func pick(_ item: PhotosPickerItem?, then action: @escaping @MainActor (Data) async -> Void) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await action(data)
            } else {
                model.announce("Не удалось открыть картинку")
            }
            avatarItem = nil
            bannerItem = nil
            emoteItem = nil
        }
    }

    private func appearanceSection(_ studio: Studio) -> some View {
        @Bindable var bindable = model
        return Section {
            HStack(spacing: Spacing.m) {
                AvatarView(initials: studio.channel.initials, tone: studio.channel.tone, size: .extraLarge, imageURL: model.avatarURL)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    PhotosPicker("Загрузить фото", selection: $avatarItem, matching: .images)
                    if model.avatarURL != nil {
                        Button("Убрать фото", role: .destructive) { Task { await model.removeAvatar(using: repository) } }
                    }
                }
                .buttonStyle(.borderless)
            }
            if let banner = model.about.bannerUrl {
                AsyncImage(url: banner) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    studio.channel.tone.surface
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: Radius.m))
            }
            HStack {
                PhotosPicker(model.about.bannerUrl == nil ? "Загрузить баннер" : "Заменить баннер", selection: $bannerItem, matching: .images)
                Spacer()
                if model.about.bannerUrl != nil {
                    Button("Убрать", role: .destructive) { Task { await model.removeBanner(using: repository) } }
                }
            }
            .buttonStyle(.borderless)
            TextField("Описание канала", text: $bindable.about.description, axis: .vertical)
                .lineLimit(3...8)
            ForEach(bindable.about.links.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Подпись, например Telegram", text: $bindable.about.links[index].title)
                    TextField("https://…", text: $bindable.about.links[index].url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Palette.muted)
                }
            }
            .onDelete { model.removeLink(at: $0) }
            if model.about.links.count < 5 {
                Button("Добавить ссылку") { model.addLink() }
            }
            Button("Сохранить описание и ссылки") { Task { await model.saveAbout(using: repository) } }
                .disabled(model.isBusy)
        } header: {
            Text("Оформление канала")
        } footer: {
            Text("Фото, баннер, описание и ссылки видны на странице канала. Ссылку можно удалить свайпом.")
        }
    }

    private func scheduleSection(_ studio: Studio) -> some View {
        @Bindable var bindable = model
        return Section {
            ForEach(studio.schedule) { item in
                LabeledContent(item.title, value: item.startsAt.formatted(date: .abbreviated, time: .shortened))
                    .swipeActions {
                        Button("Удалить", role: .destructive) { Task { await model.deleteScheduled(item, using: repository) } }
                    }
            }
            TextField("Название эфира", text: $bindable.scheduleTitle)
            Picker("Категория", selection: $bindable.scheduleCategory) {
                ForEach(model.categories) { category in
                    Text(category.name).tag(category.id)
                }
            }
            DatePicker("Начало", selection: $bindable.scheduleDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
            Button("Опубликовать анонс") { Task { await model.createScheduled(using: repository) } }
                .disabled(model.isBusy || model.scheduleTitle.isBlank)
        } header: {
            Text("Расписание")
        } footer: {
            Text("Анонс появится на главной и странице канала. Зрители, нажавшие «Напомнить», получат уведомление за 5 минут.")
        }
    }

    private func emotesSection(_ studio: Studio) -> some View {
        @Bindable var bindable = model
        return Section {
            ForEach(studio.emotes) { emote in
                HStack(spacing: Spacing.s) {
                    AsyncImage(url: emote.url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Color.clear
                    }
                    .frame(width: 32, height: 32)
                    Text(verbatim: ":\(emote.code):")
                }
                .swipeActions {
                    Button("Удалить", role: .destructive) { Task { await model.removeEmote(emote, using: repository) } }
                }
            }
            TextField("Код, например wave", text: $bindable.emoteCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            PhotosPicker("Выбрать картинку и добавить", selection: $emoteItem, matching: .images)
                .disabled(model.isBusy || model.emoteCode.isBlank)
        } header: {
            Text("Эмодзи канала")
        } footer: {
            Text("До 30 эмодзи. В чате пишутся как :код: или вставляются кнопкой под полем ввода.")
        }
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
        guard let date = ISODate.parse(iso) else { return "временно" }
        return "до \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
    .environment(BroadcastLauncher())
}
