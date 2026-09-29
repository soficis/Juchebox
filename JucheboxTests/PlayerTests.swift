import Combine
import XCTest
@testable import Juchebox

// MARK: - PlayerStateTests

final class PlayerStateTests: XCTestCase {
    func testPlayerStateEmpty() {
        let state = PlayerState.empty

        XCTAssertNil(state.currentTrack)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.currentTime, 0)
        XCTAssertEqual(state.duration, 0)
        XCTAssertFalse(state.isStalled)
        XCTAssertNil(state.streamURL)
    }

    func testPlayerStateDurationFormatted() {
        let state = PlayerState(duration: 247)

        XCTAssertEqual(state.durationFormatted, "04:07")
    }

    func testPlayerStateDurationFormattedZero() {
        let state = PlayerState(duration: 0)

        XCTAssertEqual(state.durationFormatted, "--:--")
    }

    func testTrackInfoEmpty() {
        let track = TrackInfo.empty

        XCTAssertNil(track.id)
        XCTAssertNil(track.title)
        XCTAssertNil(track.artist)
        XCTAssertNil(track.album)
        XCTAssertNil(track.albumId)
        XCTAssertNil(track.artistId)
        XCTAssertNil(track.duration)
        XCTAssertNil(track.artworkURL)
    }

    func testPlayerCommandEquality() {
        XCTAssertNotEqual(PlayerCommand.togglePlayPause, PlayerCommand.play)
        XCTAssertNotEqual(PlayerCommand.togglePlayPause, PlayerCommand.pause)
        XCTAssertNotEqual(PlayerCommand.seek(to: 30), PlayerCommand.seek(to: 15))
        XCTAssertEqual(PlayerCommand.seek(to: 30), PlayerCommand.seek(to: 30))
        XCTAssertEqual(PlayerCommand.play, PlayerCommand.play)
        XCTAssertNotEqual(PlayerCommand.nextTrack, PlayerCommand.previousTrack)
    }
}

// MARK: - QueueStateTests

final class QueueStateTests: XCTestCase {
    func testEnqueue() {
        var queue = QueueState(upcoming: [], history: [])
        let track1 = TrackInfo(id: "1", title: "Song A", artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil)
        let track2 = TrackInfo(id: "2", title: "Song B", artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil)

        queue.enqueue(track1)
        queue.enqueue(track2)

        XCTAssertEqual(queue.upcoming.count, 2)
        XCTAssertEqual(queue.upcoming[0].id, "1")
        XCTAssertEqual(queue.upcoming[1].id, "2")
    }

    func testMarkPlayed() {
        var queue = QueueState(upcoming: [], history: [])
        let track = TrackInfo(id: "1", title: "Song A", artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil)
        queue.enqueue(track)

        let played = queue.markPlayed()

        XCTAssertTrue(queue.upcoming.isEmpty)
        XCTAssertEqual(queue.history.count, 1)
        XCTAssertEqual(played?.id, "1")
    }

    func testMarkPlayedEmpty() {
        var queue = QueueState(upcoming: [], history: [])

        let played = queue.markPlayed()

        XCTAssertNil(played)
        XCTAssertTrue(queue.upcoming.isEmpty)
        XCTAssertTrue(queue.history.isEmpty)
    }

    func testClear() {
        var queue = QueueState(upcoming: [], history: [])
        let track1 = TrackInfo(id: "1", title: nil, artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil)
        let track2 = TrackInfo(id: "2", title: nil, artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil)
        queue.enqueue(track1)
        queue.enqueue(track2)
        _ = queue.markPlayed()

        queue.clear()

        XCTAssertTrue(queue.upcoming.isEmpty)
        XCTAssertTrue(queue.history.isEmpty)
    }
}

// MARK: - PlayerControllerMockTests

@MainActor
final class PlayerControllerMockTests: XCTestCase {
    func testMockControllerPlayPause() {
        let mock = MockPlayerController()

        mock.play()
        XCTAssertTrue(mock.storedState.isPlaying)
        XCTAssertEqual(mock.playCount, 1)
        XCTAssertEqual(mock.pauseCount, 0)

        mock.pause()
        XCTAssertFalse(mock.storedState.isPlaying)
        XCTAssertEqual(mock.playCount, 1)
        XCTAssertEqual(mock.pauseCount, 1)
    }

    func testMockControllerStatePublisher() {
        let mock = MockPlayerController()
        var receivedStates: [PlayerState] = []
        let cancellable = mock.statePublisher.sink { state in
            receivedStates.append(state)
        }
        defer { cancellable.cancel() }

        let testState = PlayerState(
            currentTrack: TrackInfo(id: "1", title: "Song", artist: nil, album: nil, albumId: nil, artistId: nil, duration: nil, artworkURL: nil),
            isPlaying: true,
            currentTime: 10,
            duration: 200,
            isStalled: false,
            streamURL: nil
        )
        mock.emitState(testState)

        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertTrue(receivedStates[0].isPlaying)
        XCTAssertEqual(receivedStates[0].currentTrack?.title, "Song")
    }

    func testSeekCommand() {
        let mock = MockPlayerController()

        mock.seek(to: 45.0)

        XCTAssertEqual(mock.seekTime, 45.0)
    }
}

// MARK: - MockPlayerController

@MainActor
private final class MockPlayerController: PlayerControllerProtocol {
    private let subject = PassthroughSubject<PlayerState, Never>()
    var statePublisher: AnyPublisher<PlayerState, Never> { subject.eraseToAnyPublisher() }
    var onTrackEnded: (() -> Void)?
    var onPreviousRequested: (() -> Void)?
    var onStreamFailed: (() -> Void)?

    private(set) var storedState = PlayerState.empty
    private(set) var lastCommand: PlayerCommand?
    private(set) var seekTime: TimeInterval?
    private(set) var playCount = 0
    private(set) var pauseCount = 0

    func currentState() -> PlayerState { storedState }

    func play() {
        playCount += 1
        storedState.isPlaying = true
    }

    func pause() {
        pauseCount += 1
        storedState.isPlaying = false
    }

    func togglePlayPause() {
        if storedState.isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        seekTime = time
    }

    func nextTrack() {
        lastCommand = .nextTrack
    }

    func previousTrack() {
        lastCommand = .previousTrack
    }

    func setStream(url: URL, startTime: TimeInterval) {}

    func setTrack(_ track: TrackInfo) {
        storedState.currentTrack = track
    }

    func reportStreamUnavailable() {
        storedState.streamError = "No stream available for this track."
        subject.send(storedState)
    }

    func reportStreamError(_ message: String) {
        storedState.streamError = message
        subject.send(storedState)
    }

    func stop() {}

    func emitState(_ state: PlayerState) {
        storedState = state
        subject.send(state)
    }
}
