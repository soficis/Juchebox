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

        // 1. Home
        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2.0)
        let homeImg = XCUIScreen.main.screenshot().pngRepresentation
        try homeImg.write(to: documents.appendingPathComponent("home.png"))
        try? homeImg.write(to: URL(fileURLWithPath: "/tmp/home.png"))

        // 2. Search
        app.buttons["searchTab"].tap()
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.0)
        let searchImg = XCUIScreen.main.screenshot().pngRepresentation
        try searchImg.write(to: documents.appendingPathComponent("search.png"))
        try? searchImg.write(to: URL(fileURLWithPath: "/tmp/search.png"))

        // 3. Library
        app.buttons["libraryTab"].tap()
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.0)
        let libImg = XCUIScreen.main.screenshot().pngRepresentation
        try libImg.write(to: documents.appendingPathComponent("library.png"))
        try? libImg.write(to: URL(fileURLWithPath: "/tmp/library.png"))

        // 4. Now Playing
        app.buttons["nowPlayingTab"].tap()
        XCTAssertTrue(app.staticTexts["No track playing"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.0)
        let npImg = XCUIScreen.main.screenshot().pngRepresentation
        try npImg.write(to: documents.appendingPathComponent("now-playing.png"))
        try? npImg.write(to: URL(fileURLWithPath: "/tmp/now-playing.png"))

        // 5. Mini Player (switch to home)
        app.buttons["homeTab"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        let miniImg = XCUIScreen.main.screenshot().pngRepresentation
        try miniImg.write(to: documents.appendingPathComponent("mini-player.png"))
        try? miniImg.write(to: URL(fileURLWithPath: "/tmp/mini-player.png"))
    }

    private func launchAcceptedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding"]
        app.launch()
        return app
    }
}
