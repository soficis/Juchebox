import XCTest
@MainActor
final class SettingsDiagUITests: XCTestCase {
    func testDumpSettingsTree() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["settingsTab"].waitForExistence(timeout: 10))
        app.buttons["settingsTab"].tap()
        XCTAssertTrue(app.staticTexts["Language Selection"].waitForExistence(timeout: 5))
        print("=== TREE BEFORE SCROLL ===")
        print(app.debugDescription)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        start.press(forDuration: 0.05, thenDragTo: end)
        sleep(1)
        print("=== TREE AFTER SCROLL ===")
        print(app.debugDescription)
    }
}
