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
        let versionValue = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '0.2'")).firstMatch
        for _ in 0..<4 where !versionValue.exists {
            app.swipeUp()
        }
        XCTAssertTrue(versionValue.waitForExistence(timeout: 3), "Version value not reachable by scrolling")
    }

    private func launchAcceptedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding"]
        app.launch()
        return app
    }
}
