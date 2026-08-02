import XCTest
@testable import Juchebox

final class DiagnosticsLogTests: XCTestCase {
    func testDiagnosticsExportUsesSanitizedHostOnly() throws {
        let log = DiagnosticsLog()
        let url = try XCTUnwrap(URL(string: "https://juchify.com/private/path?token=secret#fragment"))

        log.record(error: .noNetwork, url: url, sessionMode: .persistent)
        let export = log.exportText(sessionMode: .persistent)

        XCTAssertTrue(export.contains("host=juchify.com"))
        XCTAssertFalse(export.contains("private"))
        XCTAssertFalse(export.contains("token"))
        XCTAssertFalse(export.contains("secret"))
        XCTAssertFalse(export.contains("fragment"))
    }

    func testDiagnosticsExportHandlesMissingURLWithoutSensitivePlaceholder() {
        let log = DiagnosticsLog()

        log.record(error: .blocked(.missingURL), url: nil, sessionMode: .ephemeral)
        let export = log.exportText(sessionMode: .ephemeral)

        XCTAssertTrue(export.contains("host=none"))
        XCTAssertTrue(export.contains("session=ephemeral"))
    }

    func testBreadcrumbRecordingAppearsInExport() throws {
        let log = DiagnosticsLog()
        let url = try XCTUnwrap(URL(string: "https://juchify.com/songs/123"))

        log.recordBreadcrumb(.navigateStarted, url: url, sessionMode: .persistent)
        log.recordBreadcrumb(.didCommit, url: url, sessionMode: .persistent)
        log.recordBreadcrumb(.didFinish, url: url, sessionMode: .persistent)

        let export = log.exportText(sessionMode: .persistent)

        XCTAssertTrue(export.contains("Navigation Timeline"))
        XCTAssertTrue(export.contains("event=navigateStarted host=juchify.com"))
        XCTAssertTrue(export.contains("event=didCommit host=juchify.com"))
        XCTAssertTrue(export.contains("event=didFinish host=juchify.com"))
        XCTAssertFalse(export.contains("/songs/123"))
    }

    func testBreadcrumbRingBufferEviction() {
        let log = DiagnosticsLog()

        for _ in 0..<60 {
            log.recordBreadcrumb(.navigateStarted, url: URL(string: "https://juchify.com"), sessionMode: .persistent)
        }

        XCTAssertEqual(log.breadcrumbs.count, 50)
    }

    func testFailureBreadcrumbRecordsSanitizedDomainAndCode() throws {
        let log = DiagnosticsLog()
        let url = try XCTUnwrap(URL(string: "https://juchify.com"))

        log.recordBreadcrumb(.didFail(domain: NSURLErrorDomain, code: -1009), url: url, sessionMode: .persistent)
        let export = log.exportText(sessionMode: .persistent)

        XCTAssertTrue(export.contains("event=didFail domain=NSURLErrorDomain code=-1009"))
        XCTAssertTrue(export.contains("host=juchify.com"))
    }
}
