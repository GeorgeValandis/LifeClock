import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test01Home() throws {
        let app = launchApp(
            scenario: "home",
            theme: "aurora",
            unit: "days"
        )

        XCTAssertTrue(app.staticTexts["Your Time"].waitForExistence(timeout: 12))
        try saveScreenshot(named: "01-home", app: app)
    }

    @MainActor
    func test02Grid() throws {
        let app = launchApp(
            scenario: "grid",
            theme: "deepSea",
            unit: "years"
        )

        XCTAssertTrue(app.staticTexts["Current"].waitForExistence(timeout: 12))
        try saveScreenshot(named: "02-grid", app: app)
    }

    @MainActor
    func test03Settings() throws {
        let app = launchApp(
            scenario: "settings",
            theme: "solar",
            unit: "weeks"
        )

        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 12))
        try saveScreenshot(named: "03-settings", app: app)
    }

    @MainActor
    func test04Onboarding() throws {
        let app = launchApp(
            scenario: "onboarding",
            theme: "aurora",
            unit: "days",
            onboardingStep: 4
        )

        XCTAssertTrue(app.staticTexts["Theme"].waitForExistence(timeout: 12))
        try saveScreenshot(named: "04-onboarding", app: app)
    }

    @MainActor
    func test05PaywallReview() throws {
        let app = launchApp(
            scenario: "paywall",
            theme: "solar",
            unit: "days"
        )

        XCTAssertTrue(app.staticTexts["Unlock LifeClock"].waitForExistence(timeout: 12))
        try saveScreenshot(named: "05-paywall", app: app)
    }

    @discardableResult
    private func launchApp(
        scenario: String,
        theme: String,
        unit: String,
        onboardingStep: Int? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["LIFECLOCK_STORE_PREVIEW"] = "1"
        app.launchEnvironment["LIFECLOCK_PREVIEW_SCENARIO"] = scenario
        app.launchEnvironment["LIFECLOCK_PREVIEW_THEME"] = theme
        app.launchEnvironment["LIFECLOCK_PREVIEW_UNIT"] = unit
        app.launchEnvironment["LIFECLOCK_PREVIEW_BIRTHDATE"] = "1990-08-14"
        app.launchEnvironment["LIFECLOCK_PREVIEW_LIFE_EXPECTANCY"] = "90"
        app.launchEnvironment["LIFECLOCK_PREVIEW_TYPOGRAPHY"] = "modern"

        if let onboardingStep {
            app.launchEnvironment["LIFECLOCK_PREVIEW_ONBOARDING_STEP"] = String(onboardingStep)
        }

        app.launch()
        return app
    }

    private func saveScreenshot(named name: String, app: XCUIApplication) throws {
        let url = screenshotDirectory(for: app)
            .appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let screenshot = XCUIScreen.main.screenshot()
        try screenshot.pngRepresentation.write(to: url)

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func screenshotDirectory(for app: XCUIApplication) -> URL {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let isPad = app.windows.firstMatch.frame.width >= 700
        let deviceFolder = isPad ? "ipad" : "iphone"
        return repositoryRoot
            .appendingPathComponent(".asc")
            .appendingPathComponent("test-screenshots")
            .appendingPathComponent(deviceFolder)
    }
}
