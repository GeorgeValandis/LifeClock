import SwiftUI
import WidgetKit

@main
struct LifeClockMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
