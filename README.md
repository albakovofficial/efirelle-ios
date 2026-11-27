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
    Chat/                   чат, «Важное», прогноз со ставкой, поле ввода
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
