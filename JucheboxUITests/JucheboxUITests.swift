import XCTest

final class JucheboxUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstRunDisclaimerAcceptance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding", "--ui-testing-offline"]
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
        XCTAssertTrue(app.buttons["searchButton"].exists)
        XCTAssertTrue(app.buttons["savePageButton"].exists)
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

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.switches["ephemeralSessionToggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["clearWebsiteDataButton"].exists)
        XCTAssertTrue(app.buttons["exportDiagnosticsButton"].exists)
    }

    func testClearWebsiteDataConfirmation() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["clearWebsiteDataButton"].waitForExistence(timeout: 5))
        app.buttons["clearWebsiteDataButton"].tap()

        XCTAssertTrue(app.buttons["Purge Web Data & Sign Out"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
    }

    func testExternalLinkConfirmation() throws {
        let app = launchAcceptedApp(extraArguments: ["--show-external-link-confirmation"])

        XCTAssertTrue(app.buttons["Open in External Web Browser"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Copy Link"].exists)
        app.buttons["Cancel"].tap()
    }

    func testNetworkErrorPresentation() throws {
        let app = launchAcceptedApp(extraArguments: ["--show-network-error"])

        XCTAssertTrue(app.staticTexts["webErrorTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["webErrorReloadButton"].exists)
    }

    func testNowPlayingTabAccessible() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding", "--ui-testing-offline", "--show-player-bar"]
        app.launch()

        XCTAssertTrue(app.buttons["nowPlayingTab"].waitForExistence(timeout: 10))
        app.buttons["nowPlayingTab"].tap()

        XCTAssertTrue(app.staticTexts["No track playing"].waitForExistence(timeout: 5))
    }

    func testMiniPlayerBarAppears() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding", "--ui-testing-offline", "--show-player-bar"]
        app.launch()

        XCTAssertTrue(app.buttons["No track playing"].waitForExistence(timeout: 10))
    }

    func testTabSwitchPreservesWebView() throws {
        let app = launchAcceptedApp()

        XCTAssertTrue(app.webViews["mainWebView"].waitForExistence(timeout: 10))

        app.buttons["Now Playing"].tap()
        app.buttons["Home"].tap()

        XCTAssertTrue(app.webViews["mainWebView"].exists)
    }

    private func launchAcceptedApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding", "--ui-testing-offline"] + extraArguments
        app.launch()
        return app
    }
}

