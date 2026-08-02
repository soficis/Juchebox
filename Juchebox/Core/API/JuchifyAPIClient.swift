import Foundation

/// Errors thrown by the Juchify API layer.
enum JuchifyAPIError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case transport(Int) // HTTP status
    case server(String) // {"error": "..."} payload
    case decoding
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid request URL."
        case .transport(let code): "Server responded \(code)."
        case .server(let message): message
        case .decoding: "Could not read the server response."
        case .notAuthenticated: "You need to sign in for this."
        }
    }
}

/// Thin client for the Juchify public API.
///
/// All catalog endpoints go through the same-origin `/api/proxy/...` reverse
/// proxy the website itself uses — no private backend host is needed. Catalog
/// reads (home, song, album, artist, search, releases) work without auth;
/// user-scoped endpoints require a Bearer token obtained from `/api/auth/login`.
final class JuchifyAPIClient: Sendable {
    static let baseURL = URL(string: "https://juchify.com")!
    static let proxyPath = "/api/proxy"

    private let session: URLSession
    private let tokenProvider: @Sendable () -> String?

    init(
        session: URLSession = .shared,
        tokenProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    // MARK: - Catalog (no auth)

    func home(language: AppLanguage = .english) async throws -> HomeFeed {
        try await get("\(Self.proxyPath)/home-fast?lang=\(language.rawValue)")
    }

    func song(id: Int, language: AppLanguage = .english) async throws -> Song {
        try await get("\(Self.proxyPath)/song/\(id)?lang=\(language.rawValue)")
    }

    func album(id: Int) async throws -> Album {
        try await get("\(Self.proxyPath)/album/\(id)")
    }

    func artist(id: Int, language: AppLanguage = .english) async throws -> Artist {
        try await get("\(Self.proxyPath)/artist/\(id)?lang=\(language.rawValue)")
    }

    func search(_ query: String, language: AppLanguage = .english, page: Int = 1) async throws -> SearchResults {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get("\(Self.proxyPath)/search?q=\(encoded)&lang=\(language.rawValue)&page=\(page)")
    }

    func newReleases(limit: Int = 50) async throws -> [NewRelease] {
        try await get("\(Self.proxyPath)/releases/new?limit=\(limit)")
    }

    func randomSong() async throws -> Song {
        try await get("\(Self.proxyPath)/random-song")
    }

    // MARK: - User scoped (auth)

    func likedSongs() async throws -> [Song] {
        try await get("\(Self.proxyPath)/user/liked-songs")
    }

    func recentlyPlayed(language: AppLanguage = .english) async throws -> [Song] {
        try await get("\(Self.proxyPath)/user/recently-played?lang=\(language.rawValue)")
    }

    func userPlaylists() async throws -> [Playlist] {
        try await get("\(Self.proxyPath)/user/playlists")
    }

    func playlist(id: Int) async throws -> Playlist {
        try await get("\(Self.proxyPath)/playlists/\(id)")
    }

    func like(songID: Int) async throws {
        try await post("\(Self.proxyPath)/songs/\(songID)/like", body: EmptyBody())
    }

    // MARK: - Auth

    /// Login returns the token directly (not through the proxy).
    func login(username: String, password: String) async throws -> AuthResponse {
        try await post("/api/auth/login", body: ["username": username, "password": password])
    }

    // MARK: - Core plumbing

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "GET", body: nil)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        return try await request(path: path, method: "POST", body: data)
    }

    private func post<B: Encodable>(_ path: String, body: B) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        let _: EmptyResponse = try await request(path: path, method: "POST", body: data)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: Data?
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: Self.baseURL) else {
            throw JuchifyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw JuchifyAPIError.transport(-1)
        }

        guard let http = response as? HTTPURLResponse else {
            throw JuchifyAPIError.decoding
        }

        guard (200..<300).contains(http.statusCode) else {
            if let errorObject = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                throw JuchifyAPIError.server(errorObject.error)
            }
            if http.statusCode == 401 {
                throw JuchifyAPIError.notAuthenticated
            }
            throw JuchifyAPIError.transport(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw JuchifyAPIError.decoding
        }
    }
}

// MARK: - Supporting types

struct AuthResponse: Decodable, Sendable {
    let token: String
    let user: AuthUser?
}

struct AuthUser: Decodable, Sendable {
    let id: Int?
    let username: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct Playlist: Decodable, Equatable, Sendable {
    let id: Int
    let title: String?
    let songCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title
        case songCount = "song_count"
    }
}

private struct APIErrorEnvelope: Decodable {
    let error: String
}

private struct EmptyBody: Encodable {}
private struct EmptyResponse: Decodable {}
