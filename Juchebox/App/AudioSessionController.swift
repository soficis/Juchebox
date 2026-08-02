import AVFoundation
import Foundation

@MainActor
final class AudioSessionController: ObservableObject {
    @Published var notice: String?

    nonisolated(unsafe) private var observers: [any NSObjectProtocol] = []

    func start() {
        configureForWebPlayback()
        observeInterruptions()
    }

    private func configureForWebPlayback() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            notice = "Audio may be limited until iOS allows the web session to play."
        }
    }

    private func observeInterruptions() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self else { return }
                if let userInfo = notification.userInfo,
                   let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt {
                    Task { @MainActor in
                        self.handleInterruption(rawType: rawType)
                    }
                }
            }
        )

        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.notice = "Audio route changed. Use the website controls if playback paused."
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
            notice = "Audio was interrupted by iOS."
        case .ended:
            notice = "Audio interruption ended. Resume from the website controls if needed."
        @unknown default:
            notice = "Audio session changed. Foreground playback remains available."
        }
    }

    deinit {
        let observersToClean = observers
        observers = []
        // Remove observers on the main queue safely
        DispatchQueue.main.async {
            let center = NotificationCenter.default
            for observer in observersToClean {
                center.removeObserver(observer)
            }
        }
    }
}
