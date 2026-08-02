import XCTest

final class KoreanMusicWebCompanionUITests: XCTestCase {
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

        XCTAssertTrue(app.webViews["mainWebView"].waitForExistence(timeout: 10))
    }

    func testNativeNavigationControlsExposeAccessibilityIdentifiers() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.webViews["mainWebView"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["backButton"].exists)
        XCTAssertTrue(app.buttons["forwardButton"].exists)
        XCTAssertTrue(app.buttons["reloadButton"].exists)
        XCTAssertTrue(app.buttons["homeButton"].exists)
        XCTAssertTrue(app.buttons["shareButton"].exists)
        XCTAssertTrue(app.buttons["settingsButton"].exists)
    }

    func testReloadAndChromeVisibilityControls() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.buttons["reloadButton"].waitForExistence(timeout: 10))
        app.buttons["reloadButton"].tap()

        app.buttons["hideControlsButton"].tap()
        XCTAssertTrue(app.buttons["showControlsButton"].waitForExistence(timeout: 3))
        app.buttons["showControlsButton"].tap()
        XCTAssertTrue(app.buttons["reloadButton"].waitForExistence(timeout: 3))
    }

    func testSettingsPrivacyControls() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()

        XCTAssertTrue(app.switches["ephemeralSessionToggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["clearWebsiteDataButton"].exists)
        XCTAssertTrue(app.buttons["copyCurrentURLButton"].exists)
        XCTAssertTrue(app.buttons["exportDiagnosticsButton"].exists)
    }

    func testClearWebsiteDataConfirmation() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["clearWebsiteDataButton"].tap()

        XCTAssertTrue(app.buttons["Clear and Sign Out"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
    }

    func testExternalLinkConfirmation() throws {
        let app = launchAcceptedApp(extraArguments: ["--show-external-link-confirmation"])

        XCTAssertTrue(app.buttons["Open in Safari"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Copy Link"].exists)
        app.buttons["Cancel"].tap()
    }

    func testNetworkErrorPresentation() throws {
        let app = launchAcceptedApp(extraArguments: ["--show-network-error"])

        XCTAssertTrue(app.staticTexts["webErrorTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["webErrorReloadButton"].exists)
    }

    private func launchAcceptedApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding"] + extraArguments
        app.launch()
        return app
    }
}

