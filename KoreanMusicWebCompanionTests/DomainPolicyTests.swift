import XCTest
@testable import KoreanMusicWebCompanion

final class DomainPolicyTests: XCTestCase {
    private let policy = DomainPolicy(allowedHosts: ["juchify.com", "listen.juchify.com"])

    func testAllowsJuchifyRootDomainURL() {
        XCTAssertEqual(policy.decision(for: makeURL("https://juchify.com")), .allowInApp)
        XCTAssertEqual(policy.decision(for: makeURL("https://juchify.com/")), .allowInApp)
    }

    func testAllowsApprovedSubdomainOnlyWhenConfigured() {
        XCTAssertEqual(policy.decision(for: makeURL("https://listen.juchify.com")), .allowInApp)
    }

    func testBlocksHTTP() {
        XCTAssertEqual(policy.decision(for: makeURL("http://juchify.com")), .block(.insecureHTTP))
    }

    func testUnrecognizedHTTPSDomainRequiresExternalHandoff() {
        XCTAssertEqual(
            policy.decision(for: makeURL("https://example.com/music")),
            .openExternally(.externalHTTPSHost("example.com"))
        )
    }

    func testMailtoRequiresSystemHandoff() {
        XCTAssertEqual(
            policy.decision(for: makeURL("mailto:listener@example.com")),
            .openExternally(.systemScheme("mailto"))
        )
    }

    func testTelephoneRequiresSystemHandoff() {
        XCTAssertEqual(
            policy.decision(for: makeURL("tel:+15555550123")),
            .openExternally(.systemScheme("tel"))
        )
    }

    func testMalformedURLsAreBlocked() {
        XCTAssertEqual(policy.decision(for: nil), .block(.missingURL))
        XCTAssertEqual(policy.decision(for: makeURL("not a url")), .block(.malformedURL))
    }

    func testPunycodeAndLookalikeHostnamesAreBlocked() {
        XCTAssertEqual(
            policy.decision(for: makeURL("https://xn--juchify-9ib.com")),
            .block(.lookalikeHost("xn--juchify-9ib.com"))
        )

        XCTAssertEqual(
            policy.decision(for: makeURL("https://juchify.com.example.com")),
            .block(.lookalikeHost("juchify.com.example.com"))
        )
    }

    func testRedirectChainChangesAreReevaluated() {
        XCTAssertEqual(policy.decision(for: makeURL("https://juchify.com/start")), .allowInApp)
        XCTAssertEqual(
            policy.decisionForRedirect(to: makeURL("https://example.com/landing")),
            .openExternally(.externalHTTPSHost("example.com"))
        )
    }

    func testTargetBlankUsesSamePolicy() {
        XCTAssertEqual(
            policy.decision(for: makeURL("https://example.com/new"), context: .newWindow),
            .openExternally(.externalHTTPSHost("example.com"))
        )

        XCTAssertEqual(
            policy.decision(for: makeURL("https://juchify.com/new"), context: .newWindow),
            .allowInApp
        )
    }

    private func makeURL(_ string: String) -> URL? {
        URL(string: string)
    }
}
