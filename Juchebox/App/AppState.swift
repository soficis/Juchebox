import Foundation
import Combine
import SwiftUI

/// Central app state for the native catalog player.
/// Holds player state, navigation, and wires the API client + auth.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Player

    @Published var playerState: PlayerState = .empty
    @Published var isPlayerBarVisible: Bool = false
    @Published var nowPlayingQueue: [Song] = []
    @Published var queueIndex: Int = 0
    @Published var isShuffleOn = false
    @Published var repeatMode: RepeatMode = .off
    @Published private(set) var likedSongIDs: Set<Int> = []

    /// ID of the currently loaded track, when `TrackInfo.id` parses as an Int.
    var currentSongID: Int? {
        guard let raw = playerState.currentTrack?.id else { return nil }
        return Int(raw)
    }

    // MARK: - Catalog navigation

    @Published var selectedTab: Int = 0
    @Published var paths: [Int: [CatalogRoute]] = [:]
    @Published var showSettings = false

    func pathBinding(for tab: Int) -> Binding<[CatalogRoute]> {
        Binding(
            get: { self.paths[tab, default: []] },
            set: { self.paths[tab] = $0 }
        )
    }

    func navigate(to route: CatalogRoute) {
        paths[selectedTab, default: []].append(route)
    }

    func popToRoot(for tab: Int) {
        paths[tab] = []
    }

    // MARK: - Dependencies

    let apiClient: JuchifyAPIClient
    let authStore: AuthStore

    private var playerController: (any PlayerControllerProtocol)?
    private var playerStateCancellable: AnyCancellable?

    private var pendingStreamSongID: Int?
    private var hlsFallbackUsedForSongID: Int?
    private var failedInCycle: Set<Int> = []
    private var consecutiveFailures = 0

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
                if state.isPlaying {
                    self?.consecutiveFailures = 0
                }
            }
        controller.onTrackEnded = { [weak self] in
            self?.handleTrackEnded()
        }
        controller.onPreviousRequested = { [weak self] in
            self?.playPrevious()
        }
        controller.onStreamFailed = { [weak self] in
            Task { @MainActor in
                await self?.handleStreamFailure()
            }
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
        failedInCycle.removeAll()
        consecutiveFailures = 0
        playCurrent()
        prefetchStreamURLs(for: nowPlayingQueue)
    }

    /// Plays a whole album/playlist as a queue.
    func play(queue: [Song], startAt index: Int = 0) {
        guard !queue.isEmpty else { return }
        nowPlayingQueue = queue
        queueIndex = min(index, queue.count - 1)
        failedInCycle.removeAll()
        consecutiveFailures = 0
        playCurrent()
        prefetchStreamURLs(for: nowPlayingQueue)
    }

    /// Pre-enriches the next few queued songs that lack a stream URL so the
    /// immediate next/previous switches don't wait on a per-track fetch.
    ///
    /// Capped and paced deliberately. Uncapped, this is one album request per queued
    /// song — a long queue becomes a burst, which is the shape a rate limiter exists
    /// to reject, and a rejection here surfaces as a track that will not play. Only
    /// the next few are ever needed; anything past the window falls back to the
    /// on-demand fetch in `playCurrent()`, which is the pre-existing path for a song
    /// that was never enriched. Stale-guarded per song.
    private func prefetchStreamURLs(for queue: [Song]) {
        let prefetchWindow = 5
        let prefetchPacing = Duration.milliseconds(400)
        let stubs = queue.enumerated().filter { $0.element.streamURL == nil }.prefix(prefetchWindow)
        guard !stubs.isEmpty else { return }
        Task {
            for (index, stub) in stubs.enumerated() {
                if index > 0 {
                    try? await Task.sleep(for: prefetchPacing)
                }
                let song = stub.element
                guard let enriched = try? await enrichedSong(song) else { continue }
                guard nowPlayingQueue.indices.contains(stub.offset),
                      nowPlayingQueue[stub.offset].id == song.id else { continue }
                nowPlayingQueue[stub.offset] = enriched
            }
        }
    }

    func playNext() {
        guard !nowPlayingQueue.isEmpty else { return }
        if isShuffleOn, nowPlayingQueue.count > 1 {
            var nextIndex = queueIndex
            while nextIndex == queueIndex {
                nextIndex = Int.random(in: 0..<nowPlayingQueue.count)
            }
            queueIndex = nextIndex
            playCurrent()
            return
        }
        if queueIndex == nowPlayingQueue.count - 1, repeatMode == .off {
            playerController?.pause()
            return
        }
        queueIndex = (queueIndex + 1) % nowPlayingQueue.count
        playCurrent()
    }

    func playPrevious() {
        guard !nowPlayingQueue.isEmpty else { return }
        if isShuffleOn, nowPlayingQueue.count > 1 {
            var nextIndex = queueIndex
            while nextIndex == queueIndex {
                nextIndex = Int.random(in: 0..<nowPlayingQueue.count)
            }
            queueIndex = nextIndex
            playCurrent()
            return
        }
        queueIndex = (queueIndex - 1 + nowPlayingQueue.count) % nowPlayingQueue.count
        playCurrent()
    }

    func toggleShuffle() {
        isShuffleOn.toggle()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    private func handleTrackEnded() {
        if repeatMode == .one {
            playerController?.seek(to: 0)
            playerController?.play()
        } else {
            playNext()
        }
    }

    private func playCurrent() {
        guard nowPlayingQueue.indices.contains(queueIndex) else { return }
        let song = nowPlayingQueue[queueIndex]
        pendingStreamSongID = song.id
        if hlsFallbackUsedForSongID != song.id {
            hlsFallbackUsedForSongID = nil
        }

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
                guard let enriched = try? await enrichedSong(song) else {
                    await attemptStreamTokenPlayback(song)
                    return
                }
                guard nowPlayingQueue.indices.contains(queueIndex),
                      nowPlayingQueue[queueIndex].id == requestedSongID else { return }
                nowPlayingQueue[queueIndex] = enriched
                guard let url = enriched.streamURL else {
                    await attemptStreamTokenPlayback(enriched)
                    return
                }
                playerController?.setStream(url: url, startTime: 0)
                playerController?.setTrack(enriched.trackInfo)
            }
        }
    }

    /// The engine reports a dead stream (404/403/decode). Try the stream-token
    /// encrypted HLS fallback once per song; if that also fails, auto-advance
    /// through the queue until every queued track has been attempted.
    private func handleStreamFailure() async {
        guard let songID = pendingStreamSongID,
              let index = nowPlayingQueue.firstIndex(where: { $0.id == songID }) else {
            return
        }
        let song = nowPlayingQueue[index]

        // Why the user should be told, if this queue runs out. Mid-queue we
        // auto-advance instead, because one refused track is not worth an error.
        var refusal: String?

        if hlsFallbackUsedForSongID != songID {
            hlsFallbackUsedForSongID = songID
            // Try stream-token + encrypted HLS
            if let hlsPath = song.hlsPath {
                do {
                    let token = try await apiClient.getStreamToken(songID: song.id)
                    if let playlistURL = JuchifyMediaURL.playlistURL(hlsPath: hlsPath, token: token) {
                        playerController?.setStream(url: playlistURL, startTime: 0)
                        return
                    }
                    refusal = "The server would not issue a stream for this track."
                } catch {
                    #if DEBUG
                    print("[AppState] stream-token fallback failed for song \(songID): \(error)")
                    #endif
                    // transport(-1) is "no HTTP response at all"; its description
                    // ("Server responded -1.") means nothing to a listener.
                    refusal = (error as? JuchifyAPIError) == .transport(-1)
                        ? "Could not reach the stream service."
                        : (error as? JuchifyAPIError)?.errorDescription ?? "Could not reach the stream service."
                }
            }
        }

        hlsFallbackUsedForSongID = nil
        failedInCycle.insert(songID)
        consecutiveFailures += 1

        if consecutiveFailures >= 3 {
            failedInCycle.removeAll()
            consecutiveFailures = 0
            playerController?.pause()
            if let refusal { playerController?.reportStreamError(refusal) }
            return
        }

        if nowPlayingQueue.count > 1, failedInCycle.count < nowPlayingQueue.count {
            playNext()
        } else {
            failedInCycle.removeAll()
            playerController?.pause()
            if let refusal { playerController?.reportStreamError(refusal) }
        }
    }

    /// Resolves a streamable song from a feed/search stub via its album.
    private func enrichedSong(_ song: Song) async throws -> Song {
        guard let albumID = song.albumID else { return song }
        let album = try await apiClient.album(id: albumID)
        guard let full = album.songs?.first(where: { $0.id == song.id }) else { return song }
        // Album endpoints omit per-song cover paths; the stub from the feed
        // carries the artwork, so inherit it when the album song lacks one.
        return Song(
            id: full.id,
            title: full.title,
            trackNumber: full.trackNumber,
            duration: full.duration,
            filePath: full.filePath,
            hlsPath: full.hlsPath ?? song.hlsPath,
            artistID: full.artistID,
            artistName: full.artistName,
            artistNames: full.artistNames,
            albumID: full.albumID,
            albumTitle: full.albumTitle,
            albumNames: full.albumNames,
            coverPath: full.coverPath ?? song.coverPath,
            titles: full.titles,
            playCount: full.playCount,
            artists: full.artists
        )
    }

    /// Attempts playback via the stream-token → encrypted HLS flow.
    /// Falls through to reportStreamUnavailable on failure.
    private func attemptStreamTokenPlayback(_ song: Song) async {
        guard let hlsPath = song.hlsPath, !hlsPath.isEmpty else {
            playerController?.reportStreamUnavailable()
            return
        }
        do {
            let token = try await apiClient.getStreamToken(songID: song.id)
            guard let playlistURL = JuchifyMediaURL.playlistURL(hlsPath: hlsPath, token: token) else {
                playerController?.reportStreamUnavailable()
                return
            }
            playerController?.setStream(url: playlistURL, startTime: 0)
        } catch {
            #if DEBUG
            print("[AppState] stream-token failed for song \(song.id): \(error)")
            #endif
            playerController?.reportStreamUnavailable()
        }
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

    // MARK: - Likes

    func isLiked(_ songID: Int) -> Bool {
        likedSongIDs.contains(songID)
    }

    /// Optimistically toggles a like, then reconciles with the server's
    /// authoritative `{liked}` response; reverts on network failure.
    func toggleLike(songID: Int) async {
        guard authStore.isAuthenticated else { return }
        let wasLiked = likedSongIDs.contains(songID)
        if wasLiked {
            likedSongIDs.remove(songID)
        } else {
            likedSongIDs.insert(songID)
        }
        do {
            let nowLiked = try await apiClient.toggleLike(songID: songID)
            if nowLiked {
                likedSongIDs.insert(songID)
            } else {
                likedSongIDs.remove(songID)
            }
        } catch {
            if wasLiked {
                likedSongIDs.insert(songID)
            } else {
                likedSongIDs.remove(songID)
            }
        }
    }

    /// Refreshes the liked set from the server. No-op when signed out.
    func loadLikedSongIDs() {
        guard authStore.isAuthenticated else { return }
        Task {
            let songs = try? await apiClient.likedSongs()
            likedSongIDs = Set(songs?.map(\.id) ?? [])
        }
    }

    func resetLikedSongIDs() {
        likedSongIDs.removeAll()
    }

    // MARK: - Queue building

    /// Inserts a song directly after the current track (Spotify's "Play Next").
    /// Does not auto-play; the queued track becomes the next one on advance.
    func addToQueueNext(_ song: Song) {
        if nowPlayingQueue.isEmpty {
            nowPlayingQueue = [song]
            queueIndex = 0
        } else {
            let insertIndex = min(queueIndex + 1, nowPlayingQueue.count)
            nowPlayingQueue.insert(song, at: insertIndex)
        }
        isPlayerBarVisible = true
    }

    /// Appends a song to the end of the queue. Does not auto-play.
    func addToQueue(_ song: Song) {
        nowPlayingQueue.append(song)
        isPlayerBarVisible = true
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
