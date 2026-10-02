import XCTest

@MainActor
final class JucheboxUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstRunDisclaimerAcceptance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding"]
        app.launch()

        let acceptButton = app.buttons["onboardingAcceptButton"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))
        acceptButton.tap()

        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 10))
    }

    func testTabBarExposesAllTabs() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["searchTab"].exists)
        XCTAssertTrue(app.buttons["libraryTab"].exists)
        XCTAssertTrue(app.buttons["nowPlayingTab"].exists)
    }

    func testSearchFieldExistsAndAcceptsInput() throws {
        let app = launchAcceptedApp()

        app.buttons["searchTab"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("arirang")
        XCTAssertEqual(field.value as? String, "arirang")
    }

    func testLibraryShowsSignInPromptWhenSignedOut() throws {
        let app = launchAcceptedApp()

        app.buttons["libraryTab"].tap()
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 5))
    }

    func testNowPlayingShowsEmptyState() throws {
        let app = launchAcceptedApp()

        app.buttons["nowPlayingTab"].tap()
        XCTAssertTrue(app.staticTexts["No track playing"].waitForExistence(timeout: 5))
    }

    func testSettingsExposesLanguageAndVersion() throws {
        let app = launchAcceptedApp()

        app.buttons["settingsTab"].tap()
        XCTAssertTrue(app.staticTexts["Language Selection"].waitForExistence(timeout: 5))
        let versionValue = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", "^[0-9]+\\.[0-9]+\\.[0-9]+.*")
        ).firstMatch
        for _ in 0..<4 where !versionValue.exists {
            app.swipeUp()
        }
        XCTAssertTrue(versionValue.waitForExistence(timeout: 3), "Version value not reachable by scrolling")
    }

    func testCaptureScreenshotsForReadme() throws {
        let app = launchAcceptedApp()
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // 1. Home tab
        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2.0)
        let homeImg = XCUIScreen.main.screenshot().pngRepresentation
        try homeImg.write(to: documents.appendingPathComponent("home.png"))

        // 2. Start playback to reveal Mini Player
        if app.staticTexts["We Are Koreans"].waitForExistence(timeout: 3) {
            app.staticTexts["We Are Koreans"].tap()
        } else if app.staticTexts["Mother"].exists {
            app.staticTexts["Mother"].tap()
        }
        Thread.sleep(forTimeInterval: 2.0)

        // Capture Home with Mini Player visible
        let miniImg = XCUIScreen.main.screenshot().pngRepresentation
        try miniImg.write(to: documents.appendingPathComponent("mini-player.png"))

        // 3. Now Playing tab (with active playing track)
        app.buttons["nowPlayingTab"].tap()
        Thread.sleep(forTimeInterval: 2.0)
        let npImg = XCUIScreen.main.screenshot().pngRepresentation
        try npImg.write(to: documents.appendingPathComponent("now-playing.png"))

        // 4. Search tab (type query and show results without keyboard)
        app.buttons["searchTab"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("arirang\n")
        if app.keyboards.buttons["Search"].exists {
            app.keyboards.buttons["Search"].tap()
        } else if app.keyboards.buttons["search"].exists {
            app.keyboards.buttons["search"].tap()
        }
        Thread.sleep(forTimeInterval: 2.5)
        let searchImg = XCUIScreen.main.screenshot().pngRepresentation
        try searchImg.write(to: documents.appendingPathComponent("search.png"))

        // 5. Library tab (clean sign-in state, no keyboard)
        app.buttons["libraryTab"].tap()
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.5)
        let libImg = XCUIScreen.main.screenshot().pngRepresentation
        try libImg.write(to: documents.appendingPathComponent("library.png"))
    }

    private func launchAcceptedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding"]
        app.launch()
        return app
    }
}
