import Foundation

struct TrackInfo: Equatable, Sendable {
    let id: String?
    let title: String?
    let artist: String?
    let album: String?
    let albumId: String?
    let artistId: String?
    let duration: TimeInterval?
    let artworkURL: URL?

    init(
        id: String? = nil,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumId: String? = nil,
        artistId: String? = nil,
        duration: TimeInterval? = nil,
        artworkURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumId = albumId
        self.artistId = artistId
        self.duration = duration
        self.artworkURL = artworkURL
    }

    static let empty = TrackInfo()
}

struct PlayerState: Equatable, Sendable {
    var currentTrack: TrackInfo?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isStalled: Bool = false
    var streamURL: URL?

    static let empty = PlayerState()

    var durationFormatted: String {
        guard duration > 0 else { return "--:--" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "--:--"
    }
}

enum PlayerCommand: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    case nextTrack
    case previousTrack
    case seek(to: TimeInterval)
}

struct QueueState: Equatable, Sendable {
    var upcoming: [TrackInfo]
    var history: [TrackInfo]

    init(upcoming: [TrackInfo] = [], history: [TrackInfo] = []) {
        self.upcoming = upcoming
        self.history = history
    }

    static let empty = QueueState()

    mutating func enqueue(_ track: TrackInfo) {
        upcoming.append(track)
    }

    mutating func markPlayed() -> TrackInfo? {
        guard !upcoming.isEmpty else { return nil }
        let track = upcoming.removeFirst()
        history.append(track)
        return track
    }

    mutating func clear() {
        upcoming.removeAll()
        history.removeAll()
    }
}
