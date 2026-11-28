import SwiftUI

extension EnvironmentValues {
    /// Источник данных для всех экранов. В приложении — API, в превью и тестах — тестовые данные.
    @Entry var streamRepository: any StreamRepository = MockStreamRepository.instant
}
