import XCTest
@testable import Juchebox

final class PureTypeTests: XCTestCase {
    func testAccessibilityIdentifiersAreNonEmptyAndUnique() {
        let identifiers: [String] = [
            AccessibilityID.webView,
            AccessibilityID.progressView,
            AccessibilityID.backButton,
            AccessibilityID.forwardButton,
            AccessibilityID.reloadButton,
            AccessibilityID.homeButton,
            AccessibilityID.shareButton,
            AccessibilityID.hideControlsButton,
            AccessibilityID.showControlsButton,
            AccessibilityID.errorTitle,
            AccessibilityID.errorReloadButton,
            AccessibilityID.onboardingAcceptButton,
            AccessibilityID.ephemeralSessionToggle,
            AccessibilityID.clearWebsiteDataButton,
            AccessibilityID.exportDiagnosticsButton,
            AccessibilityID.searchButton,
            AccessibilityID.savePageButton,
            AccessibilityID.nowPlayingTab,
            AccessibilityID.homeTab,
            AccessibilityID.settingsTab,
        ]

        XCTAssertEqual(identifiers.count, Set(identifiers).count, "Accessibility identifiers must be unique")
        for identifier in identifiers {
            XCTAssertFalse(identifier.isEmpty)
        }
    }

    func testAppLanguageRawValues() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.korean.rawValue, "kp")
        XCTAssertEqual(AppLanguage.allCases.count, 2)
    }

    func testAppLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName(currentLanguage: .english), "English")
        XCTAssertEqual(AppLanguage.korean.displayName(currentLanguage: .english), "조선말")
        XCTAssertEqual(AppLanguage.english.displayName(currentLanguage: .korean), "미제승냥이말")
    }

    func testAppStorageKeysExist() {
        XCTAssertFalse(AppStorageKey.hasAcceptedUnofficialDisclaimer.isEmpty)
        XCTAssertFalse(AppStorageKey.appLanguage.isEmpty)
        XCTAssertNotEqual(AppStorageKey.hasAcceptedUnofficialDisclaimer, AppStorageKey.appLanguage)
    }

    func testExternalLinkRequestRoutesThroughTranslationKeys() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let request = ExternalLinkRequest(url: url, reason: .externalHTTPSHost("example.com"))

        XCTAssertEqual(request.titleKey, .externalLinkTitle)
        XCTAssertEqual(request.messageKey, .externalLinkMessage("example.com"))
        XCTAssertEqual(request.primaryActionKey, .openInBrowserButton)
    }

    func testSystemSchemeReasonKeys() {
        let reason = ExternalNavigationReason.systemScheme("mailto")

        XCTAssertEqual(reason.primaryActionKey, .systemSchemeAction)
        XCTAssertEqual(reason.messageKey, .systemSchemeMessage("mailto"))
    }

    func testSanitizedHostRejectsFullURLs() throws {
        let url = try XCTUnwrap(URL(string: "https://juchify.com/private/path?token=secret#frag"))
        let host = try XCTUnwrap(SanitizedHost(from: url))

        XCTAssertEqual(host.value, "juchify.com")
        XCTAssertEqual(host.description, "juchify.com")
        XCTAssertFalse(host.value.contains("private"))
        XCTAssertFalse(host.value.contains("token"))
    }

    func testSanitizedHostRejectsMissingHosts() {
        XCTAssertNil(SanitizedHost(from: nil))
        XCTAssertNil(SanitizedHost(from: URL(string: "not a url")))
    }

    func testBlockedReasonDiagnosticCodesAreInRange() {
        let reasons: [BlockedNavigationReason] = [
            .missingURL,
            .malformedURL,
            .insecureHTTP,
            .unsupportedScheme("ftp"),
            .lookalikeHost("x"),
            .downloadUnsupported,
        ]

        for reason in reasons {
            XCTAssertTrue((100...105).contains(reason.diagnosticCode), "\(reason) code out of range")
        }
    }
}
