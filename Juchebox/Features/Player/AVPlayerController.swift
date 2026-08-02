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
        publishStalled(true)
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.publishStalled(false)
        }
    }

    func nextTrack() {
        stop()
    }

    func previousTrack() {
        stop()
    }

    func setStream(url: URL, startTime: TimeInterval) {
        stop()
        setupBackgroundObservers()

        let item = AVPlayerItem(url: url)
        playerItem = item

        startTimeObserver()

        // Stall detection via KVO publisher
        player.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                guard let self else { return }
                var state = self.stateSubject.value
                state.isStalled = (status == .waitingToPlayAtSpecifiedRate)
                self.stateSubject.send(state)
            }
            .store(in: &cancellables)

        // Track end detection
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.nextTrack()
            }
            .store(in: &cancellables)

        player.replaceCurrentItem(with: item)

        var state = stateSubject.value
        state.streamURL = url
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

    func stop() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        cancellables.removeAll()
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        stateSubject.send(.empty)
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
