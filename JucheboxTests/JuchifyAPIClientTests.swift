import Foundation
import XCTest
@testable import Juchebox

// The API layer is where the server decides whether this client is served or
// refused, so its status-code mapping and its identifying header are the two
// places a server-side policy can act on. These tests pin both: every request is
// intercepted by a stub URLProtocol, so the suite performs no network I/O.

// MARK: - StubURLProtocol

/// Answers every request from a canned response and records what was sent. Being
/// registered in a session's `protocolClasses` means the request never reaches
/// the loading system's network path, so a test cannot leak a real request even
/// if a URL is wrong.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub: Sendable {
        var statusCode = 200
        var body = Data()
        var headers: [String: String] = [:]
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var stub = Stub()
    private nonisolated(unsafe) static var recorded: [URLRequest] = []

    /// Installs the canned response and returns a session bound to this protocol.
    static func install(_ stub: Stub) -> URLSession {
        lock.lock()
        Self.stub = stub
        recorded = []
        lock.unlock()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return recorded.last
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.recorded.append(request)
        let stub = Self.stub
        Self.lock.unlock()

        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: stub.statusCode,
                  httpVersion: "HTTP/1.1",
                  headerFields: stub.headers
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func makeClient(status: Int, body: String = "", headers: [String: String] = [:], token: String? = nil) -> JuchifyAPIClient {
    JuchifyAPIClient(
        session: StubURLProtocol.install(.init(statusCode: status, body: Data(body.utf8), headers: headers)),
        tokenProvider: { token }
    )
}

/// Runs `operation` and returns the `JuchifyAPIError` it threw, or nil if it
/// succeeded. A non-Juchify throw is a test failure, not a nil result.
private func apiError(
    from operation: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async -> JuchifyAPIError? {
    do {
        try await operation()
        return nil
    } catch let error as JuchifyAPIError {
        return error
    } catch {
        XCTFail("threw a non-Juchify error: \(error)", file: file, line: line)
        return nil
    }
}

final class JuchifyAPIClientAbuseTests: XCTestCase {

    // ABUSE: a 403 that also carries a JSON error body. Status has to win over the
    // envelope, or every refusal is flattened into .server and the caller can no
    // longer tell "you are blocked" from "that song does not exist".
    func testForbiddenBecomesBlockedEvenWithAnErrorBody() async {
        let client = makeClient(status: 403, body: #"{"error":"geo blocked"}"#)
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .blocked)
    }

    // ABUSE: a 401 carrying a body. Previously the envelope won and this surfaced
    // as .server(message); it must be .notAuthenticated or the app never re-auths.
    func testUnauthorizedWithABodyStillReadsAsNotAuthenticated() async {
        let client = makeClient(status: 401, body: #"{"error":"token expired"}"#)
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .notAuthenticated)
    }

    func testRateLimitCarriesTheServersBackoffHint() async {
        let client = makeClient(status: 429, headers: ["Retry-After": "7"])
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .rateLimited(retryAfter: 7))
    }

    // ABUSE: a hostile or buggy server asking us to wait for a week. The hint is
    // clamped so it cannot become an unusable wait.
    func testHostileRetryAfterIsClampedToAMinute() async {
        let client = makeClient(status: 429, headers: ["Retry-After": "99999"])
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .rateLimited(retryAfter: 60))
    }

    func testRateLimitWithoutAHeaderReportsNoHint() async {
        let client = makeClient(status: 429)
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .rateLimited(retryAfter: nil))
    }

    // ABUSE: the HTTP-date form of Retry-After. It is deliberately not parsed —
    // returning no hint is safe, returning a misread number is not.
    func testDateFormedRetryAfterIsIgnoredRatherThanMisread() async {
        let client = makeClient(status: 429, headers: ["Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT"])
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .rateLimited(retryAfter: nil))
    }

    func testZeroRetryAfterIsIgnored() async {
        let client = makeClient(status: 429, headers: ["Retry-After": "0"])
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .rateLimited(retryAfter: nil))
    }
}

final class JuchifyAPIClientBehaviorTests: XCTestCase {

    func testEveryRequestAnnouncesTheClientIdentifier() async {
        let client = makeClient(status: 200, body: #"{"liked":false}"#)
        _ = try? await client.isLiked(songID: 1)
        XCTAssertEqual(
            StubURLProtocol.lastRequest?.value(forHTTPHeaderField: JuchifyAPIClient.clientHeaderField),
            JuchifyAPIClient.clientIdentifier
        )
    }

    // The header is only useful to the operator if it is on every request shape,
    // not just the GETs that happen to be easiest to observe.
    func testPostRequestsAlsoAnnounceTheClientIdentifier() async {
        let client = makeClient(status: 200, body: #"{"liked":true}"#)
        let liked = try? await client.toggleLike(songID: 1)
        XCTAssertEqual(liked, true)
        XCTAssertEqual(
            StubURLProtocol.lastRequest?.value(forHTTPHeaderField: JuchifyAPIClient.clientHeaderField),
            JuchifyAPIClient.clientIdentifier
        )
    }

    func testTokenProviderIsSentAsABearerHeader() async {
        let client = makeClient(status: 200, body: #"{"liked":false}"#, token: "abc123")
        _ = try? await client.isLiked(songID: 1)
        XCTAssertEqual(
            StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer abc123"
        )
    }

    // The stream-token mint has to carry the exact User-Agent/Accept-Language the
    // segment endpoints later validate the token against, so the client's own
    // header must not be added there — an extra header can break playback.
    func testStreamTokenMintSendsContractHeadersAndNoClientHeader() async {
        let client = makeClient(status: 200, body: #"{"token":"jwt"}"#)
        let token = try? await client.getStreamToken(songID: 1)
        XCTAssertEqual(token, "jwt")

        let request = try? XCTUnwrap(StubURLProtocol.lastRequest)
        for (field, value) in JuchifyMediaURL.streamHeaders {
            XCTAssertEqual(request?.value(forHTTPHeaderField: field), value)
        }
        XCTAssertNil(
            JuchifyMediaURL.streamHeaders[JuchifyAPIClient.clientHeaderField],
            "media headers must stay exactly what the token was minted with"
        )
    }

    func testSuccessfulResponseDecodes() async {
        let client = makeClient(status: 200, body: #"{"liked":true}"#)
        let liked = try? await client.isLiked(songID: 42)
        XCTAssertEqual(liked, true)
    }

    func testServerErrorBodyIsSurfacedAsTheServersOwnMessage() async {
        let client = makeClient(status: 500, body: #"{"error":"upstream exploded"}"#)
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .server("upstream exploded"))
    }

    func testErrorStatusWithoutABodyFallsBackToTheStatusCode() async {
        let client = makeClient(status: 503)
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .transport(503))
    }

    func testMalformedSuccessBodyBecomesADecodingError() async {
        let client = makeClient(status: 200, body: "not json at all")
        let error = await apiError { _ = try await client.isLiked(songID: 1) }
        XCTAssertEqual(error, .decoding)
    }

    // AppState shows errorDescription straight to the listener, so every case needs
    // its own text — a duplicate or empty string would show the wrong advice.
    func testEveryErrorCaseHasADistinctUserFacingDescription() {
        let descriptions = [
            JuchifyAPIError.invalidURL,
            .transport(-1),
            .transport(500),
            .server("upstream exploded"),
            .decoding,
            .notAuthenticated,
            .blocked,
            .rateLimited(retryAfter: 30),
        ].compactMap(\.errorDescription)

        XCTAssertEqual(descriptions.count, 8)
        XCTAssertEqual(Set(descriptions).count, descriptions.count)
    }
}
