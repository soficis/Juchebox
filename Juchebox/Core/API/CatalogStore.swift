import Foundation
import Combine

/// Loads catalog data from the Juchify API and exposes it to SwiftUI.
@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var homeFeed: HomeFeed?
    @Published private(set) var searchResults: SearchResults?
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let apiClient: JuchifyAPIClient
    private var homeTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    init(apiClient: JuchifyAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Home

    func loadHomeIfNeeded() {
        guard homeFeed == nil, homeTask == nil else { return }
        homeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let feed = try await self.apiClient.home()
                self.homeFeed = feed
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.homeTask = nil
        }
    }

    func refreshHome() async {
        do {
            homeFeed = try await apiClient.home()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = nil
            return
        }
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            self.isSearching = true
            do {
                let results = try await self.apiClient.search(trimmed)
                guard !Task.isCancelled else { return }
                self.searchResults = results
                self.errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
            }
            self.isSearching = false
            self.searchTask = nil
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchResults = nil
        isSearching = false
    }

    // MARK: - Detail loads (fire-and-forget helpers for views)

    func loadAlbum(id: Int) async throws -> Album {
        try await apiClient.album(id: id)
    }

    func loadArtist(id: Int) async throws -> Artist {
        try await apiClient.artist(id: id)
    }
}
