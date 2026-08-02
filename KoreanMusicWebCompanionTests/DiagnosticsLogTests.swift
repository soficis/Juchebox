import XCTest
@testable import KoreanMusicWebCompanion

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
}
