import Combine
import Foundation

@MainActor
protocol PlayerControllerProtocol: AnyObject {
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
    var onTrackEnded: (() -> Void)? { get set }
    var onPreviousRequested: (() -> Void)? { get set }
    var onStreamFailed: (() -> Void)? { get set }
    func currentState() -> PlayerState
    func play()
    func pause()
    func togglePlayPause()
    func seek(to time: TimeInterval)
    func nextTrack()
    func previousTrack()
    func setStream(url: URL, startTime: TimeInterval)
    func setTrack(_ track: TrackInfo)
    func reportStreamUnavailable()
    /// Shows `message` to the user WITHOUT firing `onStreamFailed`. Distinct from
    /// `reportStreamUnavailable` because the owner calls that from inside its own
    /// failure handler, so reusing it here would re-enter that handler and retry a
    /// request the server has already refused.
    func reportStreamError(_ message: String)
    func stop()
}
