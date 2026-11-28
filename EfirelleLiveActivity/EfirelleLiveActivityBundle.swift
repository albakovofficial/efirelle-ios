import SwiftUI
import WidgetKit

/// Расширение с Live Activity: эфир отслеживаемого канала на экране блокировки и в Dynamic Island.
@main
struct EfirelleLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        LiveStreamActivityWidget()
    }
}
