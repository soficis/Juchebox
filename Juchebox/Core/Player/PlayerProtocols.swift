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
    func stop()
}
