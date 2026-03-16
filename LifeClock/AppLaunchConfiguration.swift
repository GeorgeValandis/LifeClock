import Foundation

enum AppStorePreviewScenario: String {
    case home
    case grid
    case settings
    case paywall
    case onboarding
}

struct AppLaunchConfiguration {
    static let shared = AppLaunchConfiguration(environment: ProcessInfo.processInfo.environment)

    let isStorePreview: Bool
    let scenario: AppStorePreviewScenario
    let onboardingStep: Int?
    let selectedThemeRaw: String
    let selectedUnitRaw: String
    let birthDateTimestamp: Double
    let lifeExpectancyYears: Double
    let typographyPresetRaw: String
    let disablesMonetization: Bool

    init(environment: [String: String]) {
        isStorePreview = environment["LIFECLOCK_STORE_PREVIEW"] == "1"
        scenario = AppStorePreviewScenario(rawValue: environment["LIFECLOCK_PREVIEW_SCENARIO"] ?? "")
            ?? .home
        onboardingStep = Self.intValue(for: "LIFECLOCK_PREVIEW_ONBOARDING_STEP", in: environment)
        selectedThemeRaw = environment["LIFECLOCK_PREVIEW_THEME"] ?? "aurora"
        selectedUnitRaw = environment["LIFECLOCK_PREVIEW_UNIT"] ?? "days"
        birthDateTimestamp = Self.birthDateTimestamp(from: environment["LIFECLOCK_PREVIEW_BIRTHDATE"])
        lifeExpectancyYears = Self.doubleValue(
            for: "LIFECLOCK_PREVIEW_LIFE_EXPECTANCY",
            in: environment,
            fallback: 90
        )
        typographyPresetRaw = environment["LIFECLOCK_PREVIEW_TYPOGRAPHY"] ?? "modern"
        disablesMonetization = isStorePreview || environment["LIFECLOCK_DISABLE_MONETIZATION"] == "1"
    }

    func applyIfNeeded() {
        guard isStorePreview else { return }

        SharedDefaults.store.removeObject(forKey: SharedDefaults.keyBirthDate)
        SharedDefaults.store.removeObject(forKey: SharedDefaults.keySelectedUnit)
        SharedDefaults.store.removeObject(forKey: SharedDefaults.keyLifeExpectancy)
        SharedDefaults.store.removeObject(forKey: SharedDefaults.keyClockTheme)
        SharedDefaults.store.removeObject(forKey: SharedDefaults.keyTrialStartTimestamp)
        SharedDefaults.store.removeObject(forKey: SharedDefaults.keyLifetimeUnlocked)

        UserDefaults.standard.removeObject(forKey: "typographyPresetRaw")
        UserDefaults.standard.removeObject(forKey: "hapticsEnabled")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        SharedDefaults.store.set(birthDateTimestamp, forKey: SharedDefaults.keyBirthDate)
        SharedDefaults.store.set(selectedUnitRaw, forKey: SharedDefaults.keySelectedUnit)
        SharedDefaults.store.set(lifeExpectancyYears, forKey: SharedDefaults.keyLifeExpectancy)
        SharedDefaults.store.set(selectedThemeRaw, forKey: SharedDefaults.keyClockTheme)
        SharedDefaults.store.set(Date().timeIntervalSince1970, forKey: SharedDefaults.keyTrialStartTimestamp)
        SharedDefaults.store.set(false, forKey: SharedDefaults.keyLifetimeUnlocked)

        UserDefaults.standard.set(typographyPresetRaw, forKey: "typographyPresetRaw")
        UserDefaults.standard.set(true, forKey: "hapticsEnabled")
        UserDefaults.standard.set(scenario != .onboarding, forKey: "hasCompletedOnboarding")
    }

    private static func intValue(for key: String, in environment: [String: String]) -> Int? {
        guard let rawValue = environment[key] else { return nil }
        return Int(rawValue)
    }

    private static func doubleValue(
        for key: String,
        in environment: [String: String],
        fallback: Double
    ) -> Double {
        guard let rawValue = environment[key], let value = Double(rawValue) else {
            return fallback
        }

        return value
    }

    private static func birthDateTimestamp(from rawValue: String?) -> Double {
        let fallback = Date(timeIntervalSince1970: 650_073_600).timeIntervalSince1970
        guard let rawValue, !rawValue.isEmpty else {
            return fallback
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: rawValue) else {
            return fallback
        }

        return date.timeIntervalSince1970
    }
}
