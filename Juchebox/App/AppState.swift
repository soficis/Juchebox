import Foundation
import Combine

/// Central app state for the native catalog player.
/// Holds player state, navigation, and wires the API client + auth.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Player

    @Published var playerState: PlayerState = .empty
    @Published var isPlayerBarVisible: Bool = false
    @Published var nowPlayingQueue: [Song] = []
    @Published var queueIndex: Int = 0

    // MARK: - Catalog navigation

    @Published var selectedTab: Int = 0
    @Published var navigationPath: [CatalogRoute] = []
    @Published var showSettings = false

    // MARK: - Dependencies

    let apiClient: JuchifyAPIClient
    let authStore: AuthStore

    private var playerController: (any PlayerControllerProtocol)?
    private var playerStateCancellable: AnyCancellable?

    init(
        apiClient: JuchifyAPIClient = JuchifyAPIClient(),
        authStore: AuthStore = AuthStore()
    ) {
        self.apiClient = apiClient
        self.authStore = authStore
    }

    // MARK: - Player wiring

    func configurePlayer(controller: any PlayerControllerProtocol) {
        guard playerController == nil else { return }
        playerController = controller
        playerStateCancellable = controller.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playerState = state
            }
        isPlayerBarVisible = true
    }

    /// Plays a song through the native player (direct MP3 stream).
    func play(song: Song, from queue: [Song]? = nil) {
        let fullQueue = queue ?? nowPlayingQueue
        if fullQueue.isEmpty {
            nowPlayingQueue = [song]
            queueIndex = 0
        } else {
            nowPlayingQueue = fullQueue
            queueIndex = fullQueue.firstIndex(where: { $0.id == song.id }) ?? 0
        }
        playCurrent()
    }

    /// Plays a whole album/playlist as a queue.
    func play(queue: [Song], startAt index: Int = 0) {
        guard !queue.isEmpty else { return }
        nowPlayingQueue = queue
        queueIndex = min(index, queue.count - 1)
        playCurrent()
    }

    func playNext() {
        guard !nowPlayingQueue.isEmpty else { return }
        queueIndex = (queueIndex + 1) % nowPlayingQueue.count
        playCurrent()
    }

    func playPrevious() {
        guard !nowPlayingQueue.isEmpty else { return }
        queueIndex = (queueIndex - 1 + nowPlayingQueue.count) % nowPlayingQueue.count
        playCurrent()
    }

    private func playCurrent() {
        guard nowPlayingQueue.indices.contains(queueIndex) else { return }
        let song = nowPlayingQueue[queueIndex]

        // Immediate feedback: mini-player + now-playing show the track now.
        playerController?.setTrack(song.trackInfo)

        if let url = song.streamURL {
            playerController?.setStream(url: url, startTime: 0)
        } else {
            // Feed/search songs lack file_path; the album endpoint is the only
            // place that exposes it. Fetch the album and locate the full song.
            Task {
                guard let enriched = try? await enrichedSong(song) else { return }
                guard nowPlayingQueue.indices.contains(queueIndex) else { return }
                nowPlayingQueue[queueIndex] = enriched
                if let url = enriched.streamURL {
                    playerController?.setStream(url: url, startTime: 0)
                }
            }
        }
    }

    /// Resolves a streamable song from a feed/search stub via its album.
    private func enrichedSong(_ song: Song) async throws -> Song {
        guard let albumID = song.albumID else { return song }
        let album = try await apiClient.album(id: albumID)
        guard let full = album.songs?.first(where: { $0.id == song.id }) else { return song }
        return full
    }

    func playerCommand(_ command: PlayerCommand) {
        switch command {
        case .play, .pause, .togglePlayPause, .seek:
            playerController?.apply(command)
        case .nextTrack:
            playNext()
        case .previousTrack:
            playPrevious()
        }
    }
}

/// Navigation routes within the catalog (used by the native UI).
enum CatalogRoute: Hashable, Sendable {
    case album(Int)
    case artist(Int)
}

extension PlayerControllerProtocol {
    /// Routes a `PlayerCommand` to the matching protocol method.
    func apply(_ command: PlayerCommand) {
        switch command {
        case .play: play()
        case .pause: pause()
        case .togglePlayPause: togglePlayPause()
        case .seek(let time): seek(to: time)
        case .nextTrack: nextTrack()
        case .previousTrack: previousTrack()
        }
    }
}
