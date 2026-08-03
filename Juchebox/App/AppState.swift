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
        controller.onTrackEnded = { [weak self] in
            self?.playNext()
        }
        controller.onPreviousRequested = { [weak self] in
            self?.playPrevious()
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
        prefetchStreamURLs(for: nowPlayingQueue)
    }

    /// Plays a whole album/playlist as a queue.
    func play(queue: [Song], startAt index: Int = 0) {
        guard !queue.isEmpty else { return }
        nowPlayingQueue = queue
        queueIndex = min(index, queue.count - 1)
        playCurrent()
        prefetchStreamURLs(for: nowPlayingQueue)
    }

    /// Pre-enriches every queued song that lacks a stream URL so next/previous
    /// switches don't wait on per-track fetches. Stale-guarded per song.
    private func prefetchStreamURLs(for queue: [Song]) {
        let stubs = queue.enumerated().filter { $0.element.streamURL == nil }
        guard !stubs.isEmpty else { return }
        Task {
            for (offset, stub) in stubs {
                guard let enriched = try? await enrichedSong(stub) else { continue }
                guard nowPlayingQueue.indices.contains(offset),
                      nowPlayingQueue[offset].id == stub.id else { continue }
                nowPlayingQueue[offset] = enriched
            }
        }
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
            playerController?.setTrack(song.trackInfo)
        } else {
            // Feed/search songs lack file_path; the album endpoint is the only
            // place that exposes it. Fetch the album and locate the full song.
            // Guard against staleness: if the user taps another track while
            // this fetch is in flight, discard the result.
            let requestedSongID = song.id
            Task {
                guard let enriched = try? await enrichedSong(song) else { return }
                guard nowPlayingQueue.indices.contains(queueIndex),
                      nowPlayingQueue[queueIndex].id == requestedSongID else { return }
                nowPlayingQueue[queueIndex] = enriched
                guard let url = enriched.streamURL else { return }
                playerController?.setStream(url: url, startTime: 0)
                playerController?.setTrack(enriched.trackInfo)
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
