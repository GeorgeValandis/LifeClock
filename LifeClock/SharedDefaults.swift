import Foundation

enum SharedDefaults {
    static let suiteName = "group.com.GA.LifeClock"
    static let store = UserDefaults(suiteName: suiteName) ?? .standard

    static let keyBirthDate = "birthDateTimestamp"
    static let keySelectedUnit = "selectedUnitRaw"
    static let keyLifeExpectancy = "lifeExpectancyYears"
    static let keyClockTheme = "clockThemeRaw"
    static let keyTrialStartTimestamp = "trialStartTimestamp"
    static let keyLifetimeUnlocked = "lifetimeUnlocked"
}
