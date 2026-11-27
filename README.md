# Efirelle для iOS

Нативное приложение платформы живых трансляций Efirelle.
SwiftUI, Swift 6 (строгая проверка конкурентности), iOS 17+, iPhone и iPad.

## Запуск

Нужны Xcode 16 или новее и [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate        # создаёт Efirelle.xcodeproj из project.yml
open Efirelle.xcodeproj
```

Перед первым запуском на устройстве:

1. В `project.yml` укажите `DEVELOPMENT_TEAM` (Team ID из Apple Developer) и при необходимости поменяйте `PRODUCT_BUNDLE_IDENTIFIER` (сейчас `com.efirelle.app`).
2. Снова выполните `xcodegen generate`.

Тесты: `⌘U` в Xcode или
`xcodebuild test -scheme Efirelle -destination 'platform=iOS Simulator,name=iPhone 16'`.

`Efirelle.xcodeproj` в репозиторий не коммитится — он всегда генерируется из `project.yml`, поэтому не бывает конфликтов слияния.

## Сборки в GitHub Actions

- **CI** (`.github/workflows/ci.yml`) — на каждый пуш в `main` и пулл-реквест: генерирует проект, собирает и прогоняет тесты на симуляторе iPhone.
- **TestFlight** (`.github/workflows/testflight.yml`) — запуск вручную (Actions → TestFlight → Run workflow): архив, подпись и загрузка в TestFlight. Номер сборки — номер запуска.

Для TestFlight один раз нужно:

1. App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → создать ключ с ролью **App Manager**, скачать `.p8`.
2. В репозитории Settings → Secrets and variables → Actions:
   - секреты `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY` (всё содержимое `.p8`);
   - переменная `APPLE_TEAM_ID` (Team ID из developer.apple.com → Membership).
3. В App Store Connect создать приложение с Bundle ID `com.efirelle.app`.

Общие шаги сборок вынесены в `.github/actions/prepare`.

## Правила App Store

Что уже сделано, чтобы сборка проходила проверку Apple:

- **Чат (правило 1.2, пользовательский контент):** фильтр слов при отправке (`Core/Moderation/ContentFilter`), жалоба на сообщение с причиной (долгое нажатие → «Пожаловаться», сообщение сразу скрывается), блокировка автора (`ModerationStore`, сохраняется на устройстве), правила с нулевой терпимостью принимаются перед первым сообщением, контакт поддержки — в правилах чата (кнопка «i»).
- **Прогнозы (правило 5.3):** участие бесплатное, искры только начисляются за верный ответ, не покупаются и не выводятся. Слова «ставка» в интерфейсе нет.
- **Манифест конфиденциальности** `Resources/PrivacyInfo.xcprivacy`: без отслеживания и сбора данных, UserDefaults — причина CA92.1.
- **Шифрование:** `ITSAppUsesNonExemptEncryption = false` — только стандартный HTTPS.
- **SDK:** сборка в Actions идёт на Xcode 26 (требование Apple с 28.04.2026).

Ссылки для App Store Connect: политика — https://efirelle.ru/privacy, поддержка — https://efirelle.ru/support, почта поддержки — support@efirelle.ru.

Перед публикацией в App Store (не для внутреннего TestFlight) нужен настоящий бэкенд: приложение на тестовых данных Apple отклонит по правилу 2.1. Жалобы из чата должны доходить до модераторов и рассматриваться в течение 24 часов.

## Архитектура

MVVM на `@Observable`. Экран — `View` без логики, состояние и действия — во `ViewModel` (`@MainActor`).
Данные приходят только через протокол `StreamRepository`, который подставляется через `Environment`.

```
Efirelle/
  App/                      точка входа, вкладки, внедрение репозитория
  Core/
    Models/                 доменные модели (Sendable, без SwiftUI)
    Data/                   StreamRepository, MockStreamRepository, MockData
    Formatting/             числа, склонения, длительность по-русски
    Support/                LoadState, расширения Duration
  DesignSystem/
    Theme/                  Palette (цвета «Океан» и тона), Typography, Metrics
    Components/             LogoView, AvatarView, BadgeView, TagsView, ThumbnailView,
                            SectionHeader, SparksBalanceView, LoadStateView
  Features/
    Home/                   главная: витрина, моменты, категории, лента с фильтрами
    Watch/                  эфир: плеер, перемотка с отметками, канал, моменты
    Chat/                   чат, «Важное», прогноз, правила чата, жалобы и блокировка
    Following/              отслеживаемые в эфире
    Shared/                 общие для нескольких экранов строки
  Resources/                Assets: иконка, AccentColor, фон заставки
EfirelleTests/              Swift Testing: форматирование и ViewModel'и
```

## Правила кода

- **Один тип — один файл**, имя файла совпадает с типом.
- **Без дублей.** Цвета — только `Palette`, шрифты — только `Font.brand…`, отступы — `Spacing`/`Radius`, числа и время — `Formatters`, переход на эфир — `.watchDestination()`, загрузка с обработкой ошибок — `LoadState.result`.
- **Swift 6**: модели `Sendable`, ViewModel'и `@MainActor`, никакого `@unchecked Sendable` и `nonisolated(unsafe)`.
- **Доступность**: подписи у кнопок-иконок, объединённые элементы карточек, Dynamic Type, области нажатия от 44 pt.
- **Превью** у каждого экрана работают на `MockStreamRepository.instant`.

## Как подключить настоящий бэкенд

1. Создать `APIStreamRepository: StreamRepository` в `Core/Data`.
2. Заменить реализацию в `EfirelleApp.repository`.

Экраны при этом не меняются.

## Следующие шаги

- Видео: у `LiveStream.playbackURL` указать HLS-адрес — `VideoSurface` уже умеет его играть.
- Чат в реальном времени: WebSocket внутри `ChatViewModel.load`.
- Вход в аккаунт, искры и прогнозы на сервере.
- Клипы и мультиэфир, обзор категорий, поиск.
- Шрифт Manrope: добавить файлы шрифта и поменять `Typography.swift`.
