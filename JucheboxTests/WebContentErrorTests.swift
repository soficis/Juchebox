import XCTest
@testable import Juchebox

final class WebContentErrorTests: XCTestCase {
    func testNotConnectedToInternetMapsToNoNetwork() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .noNetwork
        )
    }

    func testNetworkConnectionLostMapsToNoNetwork() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .noNetwork
        )
    }

    func testTimedOutMapsToServerUnavailable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .serverUnavailable
        )
    }

    func testCannotConnectToHostMapsToServerUnavailable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .serverUnavailable
        )
    }

    func testSecureConnectionFailedMapsToTlsFailure() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorSecureConnectionFailed)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .tlsFailure
        )
    }

    func testCancelledMapsToNavigationCancelled() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: nil),
            .navigationCancelled
        )
    }

    func testLoginPathMapsToLoginPageFailure() throws {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let failingURL = try XCTUnwrap(URL(string: "https://juchify.com/login"))
        XCTAssertEqual(
            WebContentError.from(error: error, failingURL: failingURL),
            .loginPageFailure
        )
    }

    func testNonURLErrorDomainMapsToOther() {
        let error = NSError(domain: "CustomDomain", code: 42)
        let result = WebContentError.from(error: error, failingURL: nil)
        guard case .other = result else {
            return XCTFail("Expected .other, got \(result)")
        }
    }

    func testUnknownURLErrorMapsToOther() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)
        let result = WebContentError.from(error: error, failingURL: nil)
        guard case .other = result else {
            return XCTFail("Expected .other, got \(result)")
        }
    }

    func testLoadTimeoutDiagnosticMetadata() {
        XCTAssertEqual(WebContentError.loadTimeout.diagnosticCode, 201)
        XCTAssertEqual(WebContentError.loadTimeout.diagnosticDomain, "Navigation")
        XCTAssertFalse(WebContentError.loadTimeout.title(language: .english).isEmpty)
        XCTAssertFalse(WebContentError.loadTimeout.title(language: .korean).isEmpty)
        XCTAssertFalse(WebContentError.loadTimeout.message(language: .english).isEmpty)
        XCTAssertFalse(WebContentError.loadTimeout.message(language: .korean).isEmpty)
    }

    func testBlockedErrorCarriesDomainPolicyDomain() {
        XCTAssertEqual(WebContentError.blocked(.insecureHTTP).diagnosticDomain, "DomainPolicy")
        XCTAssertEqual(WebContentError.blocked(.lookalikeHost("x")).diagnosticCode, 104)
    }

    func testEveryBlockedReasonHasDiagnosticCodeAndNonEmptyStrings() {
        let reasons: [BlockedNavigationReason] = [
            .missingURL,
            .malformedURL,
            .insecureHTTP,
            .unsupportedScheme("ftp"),
            .lookalikeHost("juchify-fake.com"),
            .downloadUnsupported,
        ]

        for reason in reasons {
            XCTAssertFalse(
                Translation.string(for: reason.titleKey, language: .english).isEmpty,
                "\(reason) has empty English title"
            )
            XCTAssertFalse(
                Translation.string(for: reason.titleKey, language: .korean).isEmpty,
                "\(reason) has empty Korean title"
            )
            XCTAssertFalse(
                Translation.string(for: reason.messageKey, language: .english).isEmpty,
                "\(reason) has empty English message"
            )
            XCTAssertFalse(
                Translation.string(for: reason.messageKey, language: .korean).isEmpty,
                "\(reason) has empty Korean message"
            )
        }
    }
}
