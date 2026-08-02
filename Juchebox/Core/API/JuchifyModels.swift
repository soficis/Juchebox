import Foundation

// MARK: - Localized names

/// Bilingual title/name container as served by the API (`{"EN": "...", "KP": "..."}`).
/// Some endpoints also return flat `title_en`/`title_ko` fields; those are handled
/// by per-model tolerances below.
struct LocalizedNames: Codable, Equatable, Sendable {
    var en: String?
    var kp: String?

    enum CodingKeys: String, CodingKey {
        case en = "EN"
        case kp = "KP"
    }

    func value(for language: AppLanguage) -> String? {
        switch language {
        case .english: en ?? kp
        case .korean: kp ?? en
        }
    }
}

// MARK: - Artist

/// Minimal artist reference embedded in songs and albums.
struct ArtistRef: Codable, Equatable, Sendable {
    let id: Int?
    let name: String?
    let role: String?
    let orderIndex: Int?
    let names: LocalizedNames?

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case orderIndex = "order_index"
        case names
    }
}

/// Full artist profile with biography and album list.
struct Artist: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let bio: String?
    let photoURL: String?
    let backgroundPhoto: String?
    let names: LocalizedNames?
    let albums: [AlbumSummary]?

    enum CodingKeys: String, CodingKey {
        case id, name, bio, names, albums
        case photoURL = "photo_url"
        case backgroundPhoto = "background_photo"
    }
}

/// Compact artist result inside search responses.
struct ArtistSearchResult: Codable, Equatable, Sendable {
    let id: Int
    let name: String?
    let names: LocalizedNames?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, names
        case photoURL = "photo_url"
    }
}

// MARK: - Album

/// Compact album summary (home sections, artist pages, search).
struct AlbumSummary: Codable, Equatable, Sendable {
    let id: Int
    let title: String?
    let coverPath: String?
    let albumType: String?
    let artistID: Int?
    let artistName: String?
    let artistNames: LocalizedNames?
    let names: LocalizedNames?
    let totalPlays: Int?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, names
        case coverPath = "cover_path"
        case albumType = "album_type"
        case artistID = "artist_id"
        case artistName = "artist_name"
        case artistNames = "artist_names"
        case totalPlays = "total_plays"
        case releaseDate = "release_date"
    }

    var displayTitle: String { title ?? names?.en ?? names?.kp ?? "Unknown Album" }
}

/// Full album with its track list.
struct Album: Codable, Equatable, Sendable {
    let id: Int
    let title: String
    let coverPath: String?
    let releaseDate: String?
    let artistID: Int?
    let artistName: String?
    let artistNames: LocalizedNames?
    let names: LocalizedNames?
    let albumType: String?
    let songs: [Song]?

    enum CodingKeys: String, CodingKey {
        case id, title, names, songs
        case coverPath = "cover_path"
        case releaseDate = "release_date"
        case artistID = "artist_id"
        case artistName = "artist_name"
        case artistNames = "artist_names"
        case albumType = "album_type"
    }
}

// MARK: - Song

/// A track in every context: song detail, album track list, search, home sections.
struct Song: Codable, Equatable, Sendable {
    let id: Int
    let title: String?
    let trackNumber: Int?
    let duration: Int?
    let filePath: String?
    let hlsPath: String?
    let artistID: Int?
    let artistName: String?
    let artistNames: LocalizedNames?
    let albumID: Int?
    let albumTitle: String?
    let albumNames: LocalizedNames?
    let coverPath: String?
    let titles: LocalizedNames?
    let playCount: Int?
    let artists: [ArtistRef]?

    enum CodingKeys: String, CodingKey {
        case id, title, titles, artists, duration
        case trackNumber = "track_number"
        case filePath = "file_path"
        case hlsPath = "hls_path"
        case artistID = "artist_id"
        case artistName = "artist_name"
        case artistNames = "artist_names"
        case albumID = "album_id"
        case albumTitle = "album_title"
        case albumNames = "album_names"
        case coverPath = "cover_path"
        case playCount = "play_count"
    }

    var displayTitle: String { title ?? titles?.en ?? titles?.kp ?? "Unknown Track" }
    var displayArtist: String { artistName ?? artistNames?.en ?? artistNames?.kp ?? "Unknown Artist" }

    /// Resolved streaming URL (direct MP3, no auth required).
    var streamURL: URL? {
        guard let filePath, !filePath.isEmpty else { return nil }
        return URL(string: "https://juchify.com\(filePath.hasPrefix("/") ? filePath : "/" + filePath)")
    }

    var artworkURL: URL? {
        guard let coverPath, !coverPath.isEmpty else { return nil }
        let path = coverPath.hasPrefix("/") ? coverPath : "/" + coverPath
        return URL(string: "https://juchify.com\(path)")
    }

    /// Formatted duration "4:07" or "--:--".
    var durationFormatted: String {
        guard let duration, duration > 0 else { return "--:--" }
        return String(format: "%d:%02d", duration / 60, duration % 60)
    }

    /// Player-state representation consumed by the native player engine.
    var trackInfo: TrackInfo {
        TrackInfo(
            id: String(id),
            title: displayTitle,
            artist: displayArtist,
            album: albumTitle ?? albumNames?.en,
            albumId: albumID.map(String.init),
            artistId: artistID.map(String.init),
            duration: duration.map(TimeInterval.init),
            artworkURL: artworkURL
        )
    }
}

// MARK: - Home feed

struct HomeFeed: Codable, Equatable, Sendable {
    let popularAlbums: [AlbumSummary]
    let newTracks: [Song]
    let newReleases: [AlbumSummary]
    let popularSongs: [Song]
    let upcomingRelease: AlbumSummary?
    let totalSongCount: Int?

    enum CodingKeys: String, CodingKey {
        case popularAlbums = "popularAlbums"
        case newTracks = "newTracks"
        case newReleases = "newReleases"
        case popularSongs = "popularSongs"
        case upcomingRelease = "upcomingRelease"
        case totalSongCount = "totalSongCount"
    }
}

// MARK: - Search

struct SearchPagination: Codable, Equatable, Sendable {
    let page: Int?
    let limit: Int?
    let hasMore: HasMore?
    let totals: Totals?

    struct HasMore: Codable, Equatable, Sendable {
        let songs: Bool?
        let albums: Bool?
        let artists: Bool?
    }

    struct Totals: Codable, Equatable, Sendable {
        let songs: Int?
        let albums: Int?
        let artists: Int?
    }
}

struct SearchResults: Codable, Equatable, Sendable {
    let songs: [Song]
    let albums: [AlbumSummary]
    let artists: [ArtistSearchResult]
    let pagination: SearchPagination?
}

// MARK: - New releases

/// `GET /releases/new` returns a bare song array (some fields differ by song type).
struct NewRelease: Codable, Equatable, Sendable {
    let id: Int
    let title: String?
    let duration: Int?
    let releaseDate: String?
    let albumID: Int?
    let albumTitle: String?
    let albumNames: LocalizedNames?
    let coverPath: String?
    let albumType: String?
    let artistID: Int?
    let artistName: String?
    let artistNames: LocalizedNames?
    let titles: LocalizedNames?

    enum CodingKeys: String, CodingKey {
        case id, title, titles, duration
        case releaseDate = "release_date"
        case albumID = "album_id"
        case albumTitle = "album_title"
        case albumNames = "album_names"
        case coverPath = "cover_path"
        case albumType = "album_type"
        case artistID = "artist_id"
        case artistName = "artist_name"
        case artistNames = "artist_names"
    }
}

// MARK: - CMS sections

struct CMSSection: Codable, Equatable, Sendable {
    let section: CMSHeader?
    let data: [Song]?

    struct CMSHeader: Codable, Equatable, Sendable {
        let id: Int?
        let title: String?
        let sectionType: String?
        let limitItems: Int?

        enum CodingKeys: String, CodingKey {
            case id, title
            case sectionType = "section_type"
            case limitItems = "limit_items"
        }
    }
}
