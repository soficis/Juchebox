import AVFoundation
import Combine
import XCTest
@testable import Juchebox

// `setStream` and `seek` are public and convert their TimeInterval arguments
// straight into CMTime with no validation, and `tokenProvider` is an
// arbitrary closure. These tests feed each of those seams hostile input and
// pin that the published state stays coherent.

/// Builds a controller that trusts the non-resolving `.invalid` sample host, so
/// the accepted path of `setStream` can be exercised without the suite sending
/// traffic to the real site. Tests that never call `setStream` do not need it.
@MainActor
private func makeController() -> AVPlayerController {
    let controller = AVPlayerController()
    controller.trustedMediaHost = "juchify.invalid"
    return controller
}

@MainActor
final class AVPlayerControllerAbuseTests: XCTestCase {

    // `.invalid` is an RFC 2606 reserved TLD, so the asset can never resolve
    // and the suite never sends a request to the real site.
    private let sampleURL = URL(string: "https://juchify.invalid/stream.mp3")!

    // ABUSE: a stream URL pointing at a host the app never constructed. This is the
    // case the guard exists for — the Bearer token would otherwise be attached to an
    // attacker-chosen origin. Uses the production default trusted host (unlike
    // makeController) so the guard is exercised exactly as shipped.
    func testSetStreamRefusesAHostOutsideTheAllowlist() {
        let controller = AVPlayerController()
        controller.tokenProvider = { "secret-token" }

        controller.setStream(url: URL(string: "https://evil.example/stream.mp3")!, startTime: 0)

        let state = controller.currentState()
        XCTAssertNil(state.streamURL)
        XCTAssertFalse(state.isPlaying)
        XCTAssertNotNil(state.streamError)
    }

    // ABUSE: suffix confusion. "juchify.com.evil.example" contains the trusted
    // string but is an entirely different registrable domain.
    func testSetStreamRefusesASuffixConfusionHost() {
        let controller = AVPlayerController()

        controller.setStream(url: URL(string: "https://juchify.com.evil.example/s.mp3")!, startTime: 0)

        XCTAssertNil(controller.currentState().streamURL)
    }

    // ABUSE: a hostless URL, which is what a `file:` or bare-relative asset would
    // present. It must not slip through a host comparison that assumes a host exists.
    func testSetStreamRefusesAHostlessURL() {
        let controller = AVPlayerController()

        controller.setStream(url: URL(string: "file:///etc/passwd")!, startTime: 0)

        XCTAssertNil(controller.currentState().streamURL)
    }

    // ABUSE: NaN startTime. The `startTime > 0` gate is the only thing standing
    // between a hostile value and `CMTime(seconds:)` — NaN there raises an
    // Objective-C exception, which is uncatchable and would abort the process.
    // The gate is correct under IEEE 754 (NaN > 0 is false), so what is worth
    // pinning is that the call survives and leaves coherent state.
    //
    // `isStalled` is deliberately NOT the probe: the timeControlStatus KVO in
    // setStream overwrites it with the real buffering state, so it cannot
    // distinguish "seeked" from "did not seek".
    func testSetStreamWithNaNStartTimeSurvivesAndKeepsStateCoherent() {
        let controller = makeController()

        controller.setStream(url: sampleURL, startTime: .nan)

        XCTAssertEqual(controller.currentState().streamURL, sampleURL)
        XCTAssertNil(controller.currentState().streamError)
        XCTAssertTrue(controller.currentState().isPlaying)
    }

    // ABUSE: a negative start time must fail the same gate rather than seeking
    // to a position before the start of the asset.
    func testSetStreamWithNegativeStartTimeKeepsStateCoherent() {
        let controller = makeController()

        controller.setStream(url: sampleURL, startTime: -30)

        XCTAssertEqual(controller.currentState().streamURL, sampleURL)
        XCTAssertNil(controller.currentState().streamError)
        XCTAssertTrue(controller.currentState().isPlaying)
    }

    // ABUSE: a hostile token carrying CR/LF, the classic header-injection
    // payload. The Authorization header itself is NOT observable through the
    // public surface (AVPlayerController keeps `player` private), so this pins
    // the guarantee that is reachable: setStream stays coherent and survives.
    func testSetStreamToleratesHostileTokenWithoutCorruptingState() {
        let controller = makeController()
        controller.tokenProvider = { "abc\r\nX-Injected: 1" }

        controller.setStream(url: sampleURL, startTime: 0)

        XCTAssertEqual(controller.currentState().streamURL, sampleURL)
        XCTAssertNil(controller.currentState().streamError)
        XCTAssertTrue(controller.currentState().isPlaying)
    }

    // ABUSE: NaN reaching seek(to:) directly, which AudioSessionController's
    // changePlaybackPositionCommand can do via positionEvent.positionTime.
    // A non-finite target must be refused outright, so no seek is published.
    func testSeekWithNaNIsRefused() {
        let controller = AVPlayerController()

        controller.seek(to: .nan)

        XCTAssertFalse(controller.currentState().isStalled)
        XCTAssertEqual(controller.currentState().currentTime, 0)
    }

    // ABUSE: a negative scrub position from the lock screen.
    func testSeekWithNegativeTimeDoesNotCorruptPublishedState() {
        let controller = AVPlayerController()

        controller.seek(to: -30)

        XCTAssertTrue(controller.currentState().isStalled)
        XCTAssertEqual(controller.currentState().currentTime, 0)
    }
}

// MARK: - Transport behaviour

@MainActor
final class AVPlayerControllerBehaviorTests: XCTestCase {

    private let sampleURL = URL(string: "https://juchify.invalid/stream.mp3")!

    func testInitialStateIsEmpty() {
        XCTAssertEqual(AVPlayerController().currentState(), .empty)
    }

    // play/pause/toggle guard on `playerItem != nil`, so with no stream the
    // engine must not report itself as playing.
    func testTransportCommandsAreNoOpsWithoutAStream() {
        let controller = AVPlayerController()

        controller.play()
        XCTAssertFalse(controller.currentState().isPlaying)

        controller.pause()
        XCTAssertFalse(controller.currentState().isPlaying)

        controller.togglePlayPause()
        XCTAssertFalse(controller.currentState().isPlaying)
    }

    func testSetTrackPublishesMetadataAndDuration() {
        let controller = AVPlayerController()
        let track = TrackInfo(id: "1", title: "T", artist: "A", duration: 247)

        controller.setTrack(track)

        XCTAssertEqual(controller.currentState().currentTrack, track)
        XCTAssertEqual(controller.currentState().duration, 247)
    }

    func testSetTrackWithoutDurationPreservesExistingDuration() {
        let controller = AVPlayerController()
        controller.setTrack(TrackInfo(id: "1", title: "T", duration: 247))

        controller.setTrack(TrackInfo(id: "2", title: "T2"))

        XCTAssertEqual(controller.currentState().duration, 247)
    }

    func testSetStreamPublishesURLAndClearsPriorStreamError() {
        let controller = makeController()
        controller.reportStreamUnavailable()
        XCTAssertNotNil(controller.currentState().streamError)

        controller.setStream(url: sampleURL, startTime: 0)

        let state = controller.currentState()
        XCTAssertEqual(state.streamURL, sampleURL)
        XCTAssertNil(state.streamError)
        XCTAssertTrue(state.isPlaying)
    }

    func testSetStreamWithPositiveStartTimeSeeks() {
        let controller = makeController()

        controller.setStream(url: sampleURL, startTime: 30)

        XCTAssertTrue(controller.currentState().isStalled)
    }

    // stop() clears transport fields but must keep currentTrack, or the
    // now-playing UI blanks between tracks.
    func testStopClearsTransportButPreservesCurrentTrack() {
        let controller = makeController()
        let track = TrackInfo(id: "1", title: "T", artist: "A", duration: 247)
        controller.setStream(url: sampleURL, startTime: 0)
        controller.setTrack(track)

        controller.stop()

        let state = controller.currentState()
        XCTAssertNil(state.streamURL)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.currentTime, 0)
        XCTAssertEqual(state.duration, 0)
        XCTAssertNil(state.streamError)
        XCTAssertEqual(state.currentTrack, track)
    }

    func testReportStreamUnavailableFiresOwnerCallback() {
        let controller = AVPlayerController()
        var failureCount = 0
        controller.onStreamFailed = { failureCount += 1 }

        controller.reportStreamUnavailable()

        XCTAssertEqual(failureCount, 1)
        XCTAssertEqual(controller.currentState().streamError, "No stream available for this track.")
        XCTAssertFalse(controller.currentState().isPlaying)
    }

    func testNextAndPreviousDelegateToTheOwner() {
        let controller = AVPlayerController()
        var endedCount = 0
        var previousCount = 0
        controller.onTrackEnded = { endedCount += 1 }
        controller.onPreviousRequested = { previousCount += 1 }

        controller.nextTrack()
        controller.previousTrack()

        XCTAssertEqual(endedCount, 1)
        XCTAssertEqual(previousCount, 1)
    }
}
