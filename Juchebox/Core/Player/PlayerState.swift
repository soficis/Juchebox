import Foundation

struct TrackInfo: Equatable, Sendable {
    let id: String? = nil
    let title: String? = nil
    let artist: String? = nil
    let album: String? = nil
    let albumId: String? = nil
    let artistId: String? = nil
    let duration: TimeInterval? = nil
    let artworkURL: URL? = nil

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
    var upcoming: [TrackInfo] = []
    var history: [TrackInfo] = []

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
