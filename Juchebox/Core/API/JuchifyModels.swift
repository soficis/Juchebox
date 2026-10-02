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

    func value(for language: AppLanguage = .english) -> String? {
        en ?? kp
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

    var coverURL: URL? {
        JuchifyMediaURL.coverURL(path: coverPath, albumID: id, size: 320)
    }

    var coverFallbackURL: URL? {
        guard let coverPath, !coverPath.isEmpty else { return nil }
        let full = coverPath.hasPrefix("/") ? coverPath : "/" + coverPath
        return URL(string: "https://juchify.com\(full)")
    }
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
struct Song: Codable, Equatable, Identifiable, Sendable {
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
    let isLocked: Bool? = nil
    let unlockDate: String? = nil

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
        case isLocked = "is_locked"
        case unlockDate = "unlock_date"
    }

    var displayTitle: String { title ?? titles?.en ?? titles?.kp ?? "Unknown Track" }
    var displayArtist: String { artistName ?? artistNames?.en ?? artistNames?.kp ?? "Unknown Artist" }

    /// Direct MP3 stream URL built from `file_path` (no auth required for `/uploads/` files).
    var streamURL: URL? {
        JuchifyMediaURL.audioURL(filePath: filePath)
    }

    /// Proxied HLS playlist URL built from `hls_path` (needs the Bearer auth header).
    var hlsStreamURL: URL? {
        JuchifyMediaURL.hlsURL(hlsPath: hlsPath)
    }

    /// Canonical cover URL — `.webp` form with CDN `w=` resize, exactly as the
    /// website's own image builder produces it. Needs `albumID` to construct the
    /// `storage/album_covers/album_{id}_{name}.webp` pattern for legacy covers.
    var artworkURL: URL? {
        JuchifyMediaURL.coverURL(path: coverPath, albumID: albumID, size: 320)
    }

    /// Raw cover URL fallback (original extension) for when the canonical webp
    /// variant is missing on the server.
    var artworkFallbackURL: URL? {
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
            artworkURL: artworkURL,
            artworkFallbackURL: artworkFallbackURL
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

// MARK: - Media URL construction

/// Builds Juchify media URLs exactly the way the website's client does, so
/// artwork and streams resolve to the same canonical resources the site serves.
enum JuchifyMediaURL {
    static let baseURL = URL(string: "https://juchify.com")!

    /// Browser-like headers the stream-token/segment endpoints validate against.
    /// The stream-token mint request AND every HLS media request must carry the
    /// SAME User-Agent + Accept-Language, or segment/key requests 404
    /// (fingerprint mismatch — verified live 2026-08-04).
    static let streamUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    static let streamAcceptLanguage = "en-US,en;q=0.9"

    static var streamHeaders: [String: String] {
        ["User-Agent": streamUserAgent, "Accept-Language": streamAcceptLanguage]
    }

    /// The only host permitted to receive a Bearer token. Callers all build from
    /// `baseURL`, but the player engine attaches the credential and is the right
    /// place to fail closed — without this note it reads as redundant and gets
    /// deleted (SECURITY-AUDIT F5, the same rule `coverURL` enforces below).
    static func isTrustedMediaHost(_ url: URL) -> Bool {
        url.host == baseURL.host
    }

    /// The web client's proxy builder (`module 64799`): any path becomes
    /// `/api/proxy/...`; paths already starting with `/api/` lose that prefix
    /// first (`/api/playlist/1` → `/api/proxy/playlist/1`).
    static func proxiedPath(_ path: String) -> String {
        var p = path.hasPrefix("/") ? path : "/" + path
        if p.hasPrefix("/api/") {
            p.removeFirst(4)
        }
        return "/api/proxy" + p
    }

    /// Cover URL as the web client's image builder (`module 58149`) produces it:
    /// `.webp` conversion, `storage/album_covers/album_{id}_{name}.webp` for
    /// legacy song covers, and an optional CDN `w=` resize param.
    static func coverURL(path: String?, albumID: Int? = nil, size: Int? = nil) -> URL? {
        guard let path, !path.isEmpty, !path.contains("placeholder") else { return nil }
        if path == "/kcbs-logo.png" {
            return URL(string: "https://juchify.com/kcbs-logo.png")
        }
        // Absolute covers are honored only when they point at juchify.com; a
        // server-supplied cover_path must not redirect image loads to arbitrary
        // third-party HTTPS hosts (SECURITY-AUDIT F5). Any other absolute URL
        // is rejected (nil → caller falls back to the placeholder).
        if path.hasPrefix("http") {
            guard let url = URL(string: path), isTrustedMediaHost(url) else { return nil }
            return url
        }
        let base = "https://juchify.com"
        var result: String
        if path.hasPrefix("/uploads/") || path.hasPrefix("/storage/") {
            result = base + path.webpConverted
        } else if path.hasPrefix("storage/track_image_media/") {
            let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            result = "\(base)/storage/album_covers/album_\(albumID ?? 0)_\(name).webp"
        } else if path.hasPrefix("uploads/") || path.hasPrefix("storage/") {
            result = base + "/" + path.webpConverted
        } else {
            result = base + "/" + path
        }
        if let size, size > 0 {
            result += (result.contains("?") ? "&" : "?") + "w=\(size)"
        }
        return URL(string: result)
    }

    /// Direct MP3 URL from `file_path`. `/uploads/` files stream without auth.
    static func audioURL(filePath: String?) -> URL? {
        guard let filePath, !filePath.isEmpty else { return nil }
        let full = filePath.hasPrefix("/") ? filePath : "/" + filePath
        return URL(string: "https://juchify.com\(full)")
    }

    /// Proxied HLS playlist URL from `hls_path`. The server expects the Bearer
    /// header on media requests (injected by the player engine).
    static func hlsURL(hlsPath: String?) -> URL? {
        guard let hlsPath, !hlsPath.isEmpty else { return nil }
        return URL(string: "https://juchify.com" + proxiedPath(hlsPath))
    }

    /// Encrypted HLS playlist URL with stream token: /api/proxy/playlist/{id}?token={jwt}.
    /// AVPlayer natively handles the m3u8's EXT-X-KEY (AES-128) and fetches
    /// the decryption key from /api/hls-key/{id}/{jwt} automatically.
    static func playlistURL(hlsPath: String, token: String) -> URL? {
        let base = URL(string: "https://juchify.com" + proxiedPath(hlsPath))
        guard var components = URLComponents(url: base!, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        return components.url
    }
}

private extension String {
    /// `uploads/x.png` → `uploads/x.webp` — the CDN serves webp cover variants.
    var webpConverted: String {
        replacingOccurrences(of: #"\.(png|jpe?g)$"#, with: ".webp", options: .regularExpression)
    }
}
