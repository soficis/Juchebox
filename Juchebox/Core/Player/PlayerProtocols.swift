import Combine
import Foundation
import WebKit

@MainActor
protocol PlayerControllerProtocol: AnyObject {
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
    func currentState() -> PlayerState
    func play()
    func pause()
    func togglePlayPause()
    func seek(to time: TimeInterval)
    func nextTrack()
    func previousTrack()
    func setStream(url: URL, startTime: TimeInterval)
    func setTrack(_ track: TrackInfo)
    func stop()
}

@MainActor
protocol JSExtractorProtocol: AnyObject {
    func extractState() async -> PlayerState
    func sendCommand(_ command: PlayerCommand) async
    func attach(to webView: WKWebView)
}
