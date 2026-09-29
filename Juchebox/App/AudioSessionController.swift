import AVFoundation
import Combine
import Foundation
import MediaPlayer

@MainActor
final class AudioSessionController: ObservableObject {
    @Published var notice: String?

    nonisolated(unsafe) private var observers: [any NSObjectProtocol] = []
    nonisolated(unsafe) private var commandTargets: [(command: MPRemoteCommand, token: Any)] = []
    private var cancellables = Set<AnyCancellable>()
    private weak var playerController: (any PlayerControllerProtocol)?
    private var wasPlayingBeforeInterruption = false

    func start() {
        configureForWebPlayback()
        observeInterruptions()
    }

    // MARK: - Player integration

    func configure(player: any PlayerControllerProtocol) {
        guard playerController == nil else { return }
        playerController = player
        setupRemoteCommands()
        subscribeToPlayerState()
    }

    private func subscribeToPlayerState() {
        guard let player = playerController else { return }
        player.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateNowPlaying(state)
            }
            .store(in: &cancellables)
    }

    private func updateNowPlaying(_ state: PlayerState) {
        var info: [String: Any] = [:]

        if let track = state.currentTrack {
            if let title = track.title, !title.isEmpty {
                info[MPMediaItemPropertyTitle] = title
            }
            if let artist = track.artist, !artist.isEmpty {
                info[MPMediaItemPropertyArtist] = artist
            }
            if let album = track.album, !album.isEmpty {
                info[MPMediaItemPropertyAlbumTitle] = album
            }
        }

        if state.currentTime > 0 {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = state.currentTime
        }

        if state.duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = state.duration
        }

        info[MPNowPlayingInfoPropertyPlaybackRate] = state.isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = state.isPlaying ? .playing : .paused
    }

    // MARK: - Remote commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        addTarget(to: center.playCommand) { [weak self] _ in
            self?.playerController?.play()
            return .success
        }

        center.pauseCommand.isEnabled = true
        addTarget(to: center.pauseCommand) { [weak self] _ in
            self?.playerController?.pause()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        addTarget(to: center.togglePlayPauseCommand) { [weak self] _ in
            self?.playerController?.togglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        addTarget(to: center.nextTrackCommand) { [weak self] _ in
            self?.playerController?.nextTrack()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        addTarget(to: center.previousTrackCommand) { [weak self] _ in
            self?.playerController?.previousTrack()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        addTarget(to: center.changePlaybackPositionCommand) { [weak self] event in
            guard let self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent,
                  let player = self.playerController else {
                return .commandFailed
            }
            let state = player.currentState()
            player.seek(to: self.clampedSeekPosition(positionEvent.positionTime, in: state))
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        addTarget(to: center.skipForwardCommand) { [weak self] _ in
            guard let self, let player = self.playerController else {
                return .commandFailed
            }
            let state = player.currentState()
            player.seek(to: self.clampedSeekPosition(state.currentTime + 15, in: state))
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        addTarget(to: center.skipBackwardCommand) { [weak self] _ in
            guard let self, let player = self.playerController else {
                return .commandFailed
            }
            let state = player.currentState()
            player.seek(to: self.clampedSeekPosition(state.currentTime - 15, in: state))
            return .success
        }
    }

    // The tokens handed back by addTarget are the only handle that identifies a
    // target as ours; MPRemoteCommandCenter is a process-wide singleton, so a
    // nil-token removal would strip handlers registered by every other component.
    private func addTarget(
        to command: MPRemoteCommand,
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) {
        commandTargets.append((command, command.addTarget(handler: handler)))
    }

    // Lock-screen events are OS-supplied and can carry negative, non-finite or
    // past-the-end positions, so every remote seek is clamped to a range the
    // player can service.
    private func clampedSeekPosition(_ requested: TimeInterval, in state: PlayerState) -> TimeInterval {
        guard requested.isFinite else { return state.currentTime }
        let lowerBounded = max(0, requested)
        guard state.duration > 0 else { return lowerBounded }
        return min(lowerBounded, state.duration)
    }

    // MARK: - Audio session

    private func configureForWebPlayback() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            notice = "Audio may be limited until iOS allows the web session to play."
        }
    }

    // MARK: - Interruptions

    nonisolated private static let headphonePorts: Set<AVAudioSession.Port> = [
        .headphones,
        .headsetMic,
        .bluetoothA2DP,
        .bluetoothHFP,
        .bluetoothLE,
    ]

    private func observeInterruptions() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt {
                    Task { @MainActor [weak self] in
                        self?.handleInterruption(rawType: rawType)
                    }
                }
            }
        )

        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let userInfo = notification.userInfo
                let reasonValue = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                let reason = reasonValue.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
                let previousRouteOutputs = userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
                let wasHeadphones = previousRouteOutputs?.outputs.contains {
                    Self.headphonePorts.contains($0.portType)
                } ?? false
                Task { @MainActor [weak self] in
                    self?.handleRouteChange(reason: reason, wasHeadphones: wasHeadphones)
                }
            }
        )
    }

    private func haltNowPlaying(_ playbackState: MPNowPlayingPlaybackState) {
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
        MPNowPlayingInfoCenter.default().playbackState = playbackState
    }

    private func handleInterruption(rawType: UInt) {
        guard let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = playerController?.currentState().isPlaying ?? false
            notice = "Audio was interrupted by iOS."
            haltNowPlaying(.interrupted)

        case .ended:
            notice = "Audio interruption ended. Resume from the website controls if needed."
            if wasPlayingBeforeInterruption {
                wasPlayingBeforeInterruption = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.playerController?.play()
                }
            }

        @unknown default:
            notice = "Audio session changed. Foreground playback remains available."
        }
    }

    private func handleRouteChange(reason: AVAudioSession.RouteChangeReason?, wasHeadphones: Bool) {
        notice = "Audio route changed. Use the website controls if playback paused."

        guard reason == .oldDeviceUnavailable else {
            return
        }

        if wasHeadphones {
            playerController?.pause()
            haltNowPlaying(.paused)
        }
    }

    // MARK: - Cleanup

    // Only touches the thread-safe MPRemoteCommandCenter singleton — safe from deinit.
    nonisolated private func removeRemoteCommandTargets() {
        let targets = commandTargets
        commandTargets = []
        for (command, token) in targets {
            command.removeTarget(token)
        }
    }

    deinit {
        removeRemoteCommandTargets()

        let observersToClean = observers
        observers = []
        DispatchQueue.main.async {
            let center = NotificationCenter.default
            for observer in observersToClean {
                center.removeObserver(observer)
            }
        }
    }
}
