import XCTest

/// Online integration tests for the player bridge.
///
/// These deliberately do NOT pass `--ui-testing-offline`: the app loads the
/// real juchify.com, the read-only WKUserScript runs against the live page,
/// and the native bridge must parse its messages. They are the only tests
/// that verify the bridge against the actual site (not mocks).
///
/// They require network access to juchify.com and will fail while the site
/// is unreachable or in maintenance mode — that is the point.
final class OnlinePlayerBridgeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// End-to-end bridge check: launch without --ui-testing-offline, wait for
    /// the probe to report `bridge:connected` — i.e. the injected script ran,
    /// posted state via WKScriptMessageHandler, and parseState produced a
    /// non-default message count. `bridge:waiting` after the timeout means the
    /// bridge never heard from the page (script blocked, page never loaded,
    /// or JS error) — a genuine failure, not a skip.
    func testOnlinePlayerBridgeConnectsToLiveSite() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--accept-onboarding", "--online-player-probe"]
        app.launch()

        let probe = app.staticTexts["onlineBridgeProbe"]
        XCTAssertTrue(probe.waitForExistence(timeout: 30), "online bridge probe did not appear")

        let connected = NSPredicate(format: "label CONTAINS 'bridge:connected'")
        let expectation = XCTNSPredicateExpectation(predicate: connected, object: probe)
        let result = XCTWaiter().wait(for: [expectation], timeout: 120)

        XCTAssertEqual(result, .completed, "bridge never connected to the live site. Probe label: '\(probe.label)'")
    }
}
