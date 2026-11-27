import SwiftUI

extension EnvironmentValues {
    /// Источник данных для всех экранов. Подменяется в превью и при подключении API.
    @Entry var streamRepository: any StreamRepository = MockStreamRepository()
}
