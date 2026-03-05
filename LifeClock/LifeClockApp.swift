import SwiftUI
import RevenueCat

@main
struct LifeClockApp: App {
    init() {
        configureRevenueCat()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureRevenueCat() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }

        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PUBLIC_SDK_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !apiKey.isEmpty else {
            #if DEBUG
                print("RevenueCat disabled: missing REVENUECAT_PUBLIC_SDK_KEY")
            #endif
            return
        }

        #if DEBUG
            Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }
}
