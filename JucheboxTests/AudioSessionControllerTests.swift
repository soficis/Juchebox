import AVFoundation
import Combine
import MediaPlayer
import XCTest
@testable import Juchebox

// AVAudioSession.interruptionNotification and .routeChangeNotification are
// process-wide: any in-process code — or a malformed userInfo from the OS —
// can deliver them. These tests treat the notification payload as untrusted
// input and pin that a bad payload cannot drive the player into a wrong state.
@MainActor
final class AudioSessionControllerAbuseTests: XCTestCase {

    // ABUSE: a rawValue outside AVAudioSession.InterruptionType's known set.
    // handleInterruption guards on init(rawValue:) returning nil, so the state
    // machine must never be entered.
    func testInterruptionWithUnknownRawValueIsIgnored() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)
        let noticeBefore = controller.notice

        postInterruption(option: 9_999)
        await settleNotificationHandlers()

        XCTAssertEqual(controller.notice, noticeBefore)
        XCTAssertEqual(player.playCallCount, 0)
        XCTAssertEqual(player.pauseCallCount, 0)
    }

    // ABUSE: type confusion — the payload is a String where a UInt is expected,
    // so the `as? UInt` cast fails and the handler must not run at all.
    func testInterruptionWithWrongTypedOptionIsIgnored() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)
        let noticeBefore = controller.notice

        postInterruption(option: "1")
        await settleNotificationHandlers()

        XCTAssertEqual(controller.notice, noticeBefore)
        XCTAssertEqual(player.playCallCount, 0)
    }

    // ABUSE: a negative value cannot bridge NSNumber -> UInt, so it must be
    // rejected before InterruptionType is ever constructed.
    func testInterruptionWithNegativeRawValueIsIgnored() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)
        let noticeBefore = controller.notice

        postInterruption(option: -1)
        await settleNotificationHandlers()

        XCTAssertEqual(controller.notice, noticeBefore)
    }

    // ABUSE: unknown route-change reason. reason resolves to nil, so the
    // .oldDeviceUnavailable guard must return before touching playback.
    func testRouteChangeWithUnknownReasonDoesNotPause() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)

        postRouteChange(reason: 9_999)
        await settleNotificationHandlers()

        XCTAssertEqual(player.pauseCallCount, 0)
        XCTAssertNotNil(controller.notice)
    }

    // ABUSE: type confusion on the reason key.
    func testRouteChangeWithWrongTypedReasonDoesNotPause() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)

        postRouteChange(reason: "2")
        await settleNotificationHandlers()

        XCTAssertEqual(player.pauseCallCount, 0)
    }

    // ABUSE: the previous-route object is replaced with a String, so the
    // `as? AVAudioSessionRouteDescription` cast fails and wasHeadphones is
    // false. Even with a genuine .oldDeviceUnavailable reason the controller
    // must not pause, because the old output was never shown to be a headset.
    func testRouteChangeWithTypeConfusedPreviousRouteDoesNotPause() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)

        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue,
                AVAudioSessionRouteChangePreviousRouteKey: "not-a-route",
            ]
        )
        await settleNotificationHandlers()

        XCTAssertEqual(player.pauseCallCount, 0)
    }
}

// MARK: - Now-playing behaviour

@MainActor
final class AudioSessionControllerBehaviorTests: XCTestCase {

    func testInterruptionBeganHaltsNowPlayingAndKeepsMetadata() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)
        let track = TrackInfo(id: "1", title: "Real Title", artist: "Real Artist", duration: 247)
        player.emit(PlayerState(currentTrack: track, isPlaying: true, currentTime: 42, duration: 247))
        await settleNotificationHandlers()

        postInterruption(option: AVAudioSession.InterruptionType.began.rawValue)
        await settleNotificationHandlers()

        XCTAssertEqual(controller.notice, "Audio was interrupted by iOS.")
        XCTAssertEqual(MPNowPlayingInfoCenter.default().playbackState, .interrupted)
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 0.0)
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Real Title")
    }

    func testInterruptionEndedDoesNotResumeWhenItWasNotPlaying() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)

        postInterruption(option: AVAudioSession.InterruptionType.began.rawValue)
        await settleNotificationHandlers()
        postInterruption(option: AVAudioSession.InterruptionType.ended.rawValue)
        await settleNotificationHandlers()

        XCTAssertEqual(
            controller.notice,
            "Audio interruption ended. Resume from the website controls if needed."
        )
        XCTAssertEqual(player.playCallCount, 0)
    }

    func testInterruptionEndedResumesPlaybackAfterTheDeferredDelay() async {
        let player = RecordingPlayerController()
        let controller = startedController(player: player)
        player.emit(PlayerState(currentTrack: TrackInfo(id: "1", title: "T"), isPlaying: true))
        await settleNotificationHandlers()

        postInterruption(option: AVAudioSession.InterruptionType.began.rawValue)
        await settleNotificationHandlers()
        postInterruption(option: AVAudioSession.InterruptionType.ended.rawValue)
        // Longer than the 0.5s resume delay inside handleInterruption.
        try? await Task.sleep(for: .milliseconds(900))

        XCTAssertEqual(player.playCallCount, 1)
    }

    func testConfigureKeepsFirstPlayerAndIgnoresSecond() async {
        let controller = AudioSessionController()
        let first = RecordingPlayerController()
        let second = RecordingPlayerController()
        controller.configure(player: first)
        controller.configure(player: second)

        first.emit(PlayerState(currentTrack: TrackInfo(title: "First"), isPlaying: true))
        await settleNotificationHandlers()
        let afterFirst = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
        XCTAssertEqual(afterFirst, "First")

        second.emit(PlayerState(currentTrack: TrackInfo(title: "Second"), isPlaying: true))
        await settleNotificationHandlers()
        let afterSecond = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
        XCTAssertEqual(afterSecond, "First", "A second configure(player:) must be ignored; the first binding stays")
    }

    // The engine rebuilds nowPlayingInfo from scratch on every state, so an
    // empty title clears the lockscreen title instead of leaving a stale one.
    func testEmptyTitleIsOmittedFromNowPlayingInfo() async {
        let controller = AudioSessionController()
        let player = RecordingPlayerController()
        controller.configure(player: player)

        player.emit(
            PlayerState(currentTrack: TrackInfo(title: "Real Title", artist: "Real Artist"), isPlaying: true)
        )
        await settleNotificationHandlers()
        player.emit(
            PlayerState(currentTrack: TrackInfo(title: "", artist: "Real Artist"), isPlaying: true)
        )
        await settleNotificationHandlers()

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertNil(info?[MPMediaItemPropertyTitle])
        XCTAssertEqual(info?[MPMediaItemPropertyArtist] as? String, "Real Artist")
    }

    func testNowPlayingInfoCarriesMetadataElapsedTimeAndRate() async {
        let controller = AudioSessionController()
        let player = RecordingPlayerController()
        controller.configure(player: player)

        player.emit(
            PlayerState(
                currentTrack: TrackInfo(title: "T", artist: "A", album: "Al"),
                isPlaying: true,
                currentTime: 42,
                duration: 247
            )
        )
        await settleNotificationHandlers()

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "T")
        XCTAssertEqual(info?[MPMediaItemPropertyArtist] as? String, "A")
        XCTAssertEqual(info?[MPMediaItemPropertyAlbumTitle] as? String, "Al")
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double, 42)
        XCTAssertEqual(info?[MPMediaItemPropertyPlaybackDuration] as? Double, 247)
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.0)
        XCTAssertEqual(MPNowPlayingInfoCenter.default().playbackState, .playing)
    }
}

// MARK: - Helpers

@MainActor
private func startedController(player: RecordingPlayerController) -> AudioSessionController {
    let controller = AudioSessionController()
    controller.configure(player: player)
    controller.start()
    return controller
}

private func postInterruption(option: Any) {
    NotificationCenter.default.post(
        name: AVAudioSession.interruptionNotification,
        object: nil,
        userInfo: [AVAudioSessionInterruptionTypeKey: option]
    )
}

private func postRouteChange(reason: Any) {
    NotificationCenter.default.post(
        name: AVAudioSession.routeChangeNotification,
        object: nil,
        userInfo: [AVAudioSessionRouteChangeReasonKey: reason]
    )
}

/// The observers deliver on the main queue and then hop through a `Task`, so
/// assertions about the resulting state need a turn of the run loop first.
@MainActor
private func settleNotificationHandlers() async {
    try? await Task.sleep(for: .milliseconds(350))
}

// MARK: - RecordingPlayerController

/// Records the calls AudioSessionController makes so remote-command and
/// interruption effects are observable without a real MPRemoteCommandCenter.
@MainActor
private final class RecordingPlayerController: PlayerControllerProtocol {
    private let stateSubject = CurrentValueSubject<PlayerState, Never>(PlayerState(currentTrack: nil))

    var statePublisher: AnyPublisher<PlayerState, Never> { stateSubject.eraseToAnyPublisher() }
    var onTrackEnded: (() -> Void)?
    var onPreviousRequested: (() -> Void)?
    var onStreamFailed: (() -> Void)?

    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var seekTargets: [TimeInterval] = []
    private(set) var lastStreamURL: URL?
    private(set) var reportedUnavailable = false

    func emit(_ state: PlayerState) { stateSubject.send(state) }
    func currentState() -> PlayerState { stateSubject.value }

    func play() { playCallCount += 1 }
    func pause() { pauseCallCount += 1 }
    func togglePlayPause() { stateSubject.value.isPlaying ? pause() : play() }
    func seek(to time: TimeInterval) { seekTargets.append(time) }
    func nextTrack() { onTrackEnded?() }
    func previousTrack() { onPreviousRequested?() }
    func setStream(url: URL, startTime: TimeInterval) { lastStreamURL = url }
    func setTrack(_ track: TrackInfo) {
        var state = stateSubject.value
        state.currentTrack = track
        stateSubject.send(state)
    }
    func reportStreamUnavailable() {
        reportedUnavailable = true
        onStreamFailed?()
    }
    func stop() {}
}
