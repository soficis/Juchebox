import AVFoundation
import Combine
import Foundation
import MediaPlayer

@MainActor
final class AudioSessionController: ObservableObject {
    @Published var notice: String?

    nonisolated(unsafe) private var observers: [any NSObjectProtocol] = []
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

        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = state.isPlaying ? .playing : .paused
        }
    }

    // MARK: - Remote commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.playerController?.play()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.playerController?.pause()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.playerController?.togglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.playerController?.nextTrack()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.playerController?.previousTrack()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.playerController?.seek(to: positionEvent.positionTime)
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        center.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, let player = self.playerController else {
                return .commandFailed
            }
            let currentTime = player.currentState().currentTime
            player.seek(to: currentTime + 15)
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, let player = self.playerController else {
                return .commandFailed
            }
            let currentTime = player.currentState().currentTime
            player.seek(to: max(0, currentTime - 15))
            return .success
        }
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

    private func handleInterruption(rawType: UInt) {
        guard let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = playerController?.currentState().isPlaying ?? false
            notice = "Audio was interrupted by iOS."

            if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            if #available(iOS 13.0, *) {
                MPNowPlayingInfoCenter.default().playbackState = .interrupted
            }

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

            if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            if #available(iOS 13.0, *) {
                MPNowPlayingInfoCenter.default().playbackState = .paused
            }
        }
    }

    // MARK: - Cleanup

    // Only touches the thread-safe MPRemoteCommandCenter singleton — safe from deinit.
    nonisolated private func removeRemoteCommandTargets() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)
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
