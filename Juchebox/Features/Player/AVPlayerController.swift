import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class AVPlayerController: ObservableObject, PlayerControllerProtocol {
    private let player = AVPlayer()
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var stateSubject = CurrentValueSubject<PlayerState, Never>(.empty)
    private var cancellables = Set<AnyCancellable>()
    private var backgroundCancellables = Set<AnyCancellable>()
    private var isBackgrounded = false

    /// Called when the current track ends naturally or the user requests
    /// next/previous through remote commands — the owner (AppState) advances
    /// the queue. Keeps the engine queue-agnostic.
    var onTrackEnded: (() -> Void)?
    var onPreviousRequested: (() -> Void)?

    /// Called when the current item fails to load (HTTP 404/403, decode error).
    /// The owner (AppState) may fall back to another stream URL or advance.
    var onStreamFailed: (() -> Void)?

    /// Supplies the Bearer token attached to media requests. HLS playlist URLs
    /// (`/api/proxy/playlist/{id}`) require it server-side.
    var tokenProvider: (() -> String?)?

    var statePublisher: AnyPublisher<PlayerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func currentState() -> PlayerState {
        stateSubject.value
    }

    func play() {
        guard playerItem != nil else { return }
        player.play()
        publishIsPlaying(true)
    }

    func pause() {
        guard playerItem != nil else { return }
        player.pause()
        publishIsPlaying(false)
    }

    func togglePlayPause() {
        if stateSubject.value.isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        // A non-finite target yields an invalid CMTime that has no resolvable
        // position, so the seek is refused outright rather than handing CoreMedia
        // a value it cannot service. Negative targets clamp to the track start.
        guard time.isFinite else { return }
        let target = max(0, time)
        publishStalled(true)
        let cmTime = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.publishStalled(false)
            }
        }
    }

    func nextTrack() {
        onTrackEnded?()
    }

    func previousTrack() {
        onPreviousRequested?()
    }

    func setStream(url: URL, startTime: TimeInterval) {
        stop()
        setupBackgroundObservers()

        // The segment/key endpoints validate User-Agent + Accept-Language against
        // the stream token's fingerprint, so media requests MUST carry the same
        // stream headers used when minting the token (JuchifyMediaURL.streamHeaders).
        var headers = JuchifyMediaURL.streamHeaders
        if let token = tokenProvider?() {
            headers["Authorization"] = "Bearer \(token)"
        }
        let options: [String: Any] = [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ]
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        playerItem = item

        startTimeObserver()

        player.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                guard let self else { return }
                var state = self.stateSubject.value
                state.isStalled = (status == .waitingToPlayAtSpecifiedRate)
                self.stateSubject.send(state)
            }
            .store(in: &cancellables)

        // Load failure detection — surfaces 404/403 streams to the owner.
        item.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self, status == .failed else { return }
                var state = self.stateSubject.value
                state.streamError = "This track's stream could not be loaded."
                self.stateSubject.send(state)
                self.onStreamFailed?()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.onTrackEnded?()
            }
            .store(in: &cancellables)

        player.replaceCurrentItem(with: item)

        var state = stateSubject.value
        state.streamURL = url
        state.streamError = nil
        stateSubject.send(state)

        if startTime > 0 {
            seek(to: startTime)
        }

        player.play()
        publishIsPlaying(true)
    }

    /// Attaches track metadata (title/artist/artwork) to the current state so
    /// lockscreen Now Playing and the mini player reflect the real song.
    func setTrack(_ track: TrackInfo) {
        var state = stateSubject.value
        state.currentTrack = track
        state.duration = track.duration ?? state.duration
        stateSubject.send(state)
    }

    /// Surfaces "no stream could be resolved for this track" without an item —
    /// used when enrichment never produced a stream URL. Routes through the same
    /// failure machinery as a real load failure.
    func reportStreamUnavailable() {
        var state = stateSubject.value
        state.streamError = "No stream available for this track."
        state.isPlaying = false
        stateSubject.send(state)
        onStreamFailed?()
    }

    /// Stops playback and resets transport fields, but PRESERVES the current
    /// track metadata so the now-playing UI doesn't blank between tracks.
    func stop() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        cancellables.removeAll()
        player.replaceCurrentItem(with: nil)
        playerItem = nil

        var state = stateSubject.value
        state.streamURL = nil
        state.currentTime = 0
        state.duration = 0
        state.isStalled = false
        state.isPlaying = false
        state.streamError = nil
        stateSubject.send(state)
    }

    // MARK: - Background throttling

    private func setupBackgroundObservers() {
        guard backgroundCancellables.isEmpty else { return }

        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isBackgrounded = true
                self?.startTimeObserver()
            }
            .store(in: &backgroundCancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isBackgrounded = false
                self?.startTimeObserver()
            }
            .store(in: &backgroundCancellables)
    }

    private func startTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        let seconds = isBackgrounded ? 2.0 : 0.5
        let interval = CMTime(seconds: seconds, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, let item = self.playerItem else { return }
                var state = self.stateSubject.value
                state.currentTime = time.seconds
                let duration = item.duration
                if duration.isNumeric {
                    state.duration = duration.seconds
                }
                state.isStalled = self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.stateSubject.send(state)
            }
        }
    }

    // MARK: - Private

    private func publishIsPlaying(_ playing: Bool) {
        var state = stateSubject.value
        state.isPlaying = playing
        stateSubject.send(state)
    }

    private func publishStalled(_ stalled: Bool) {
        var state = stateSubject.value
        state.isStalled = stalled
        stateSubject.send(state)
    }
}
