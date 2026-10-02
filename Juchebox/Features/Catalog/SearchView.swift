import SwiftUI

/// Search tab: query the catalog (songs / albums / artists).
struct SearchView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var query = ""
    @FocusState private var isSearchFocused: Bool
    /// Pending debounce task for the live search; cancelled on every keystroke.
    @State private var searchTask: Task<Void, Never>?
    /// The trimmed query that a network search was last actually fired for,
    /// so a repeat (or trailing-space) query never triggers a duplicate call.
    @State private var lastSearchedQuery = ""
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: AppStorageKey.recentSearches) ?? []

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

            if catalog.isSearching {
                Spacer()
                ProgressView().tint(AppTheme.secondaryText)
                Spacer()
            } else if let error = catalog.errorMessage {
                errorView(error)
            } else if let results = catalog.searchResults {
                if results.songs.isEmpty && results.albums.isEmpty && results.artists.isEmpty {
                    noResultsView
                } else {
                    resultsList(results)
                }
            } else if trimmedQuery.isEmpty {
                if recentSearches.isEmpty {
                    emptyPrompt
                } else {
                    recentSearchesView
                }
            } else {
                emptyPrompt
            }
        }
        .background(AppTheme.background)
        .onAppear {
            if trimmedQuery.isEmpty {
                isSearchFocused = true
            }
        }
        .onChange(of: appState.selectedTab) { _, tab in
            if tab == 1 && trimmedQuery.isEmpty {
                isSearchFocused = true
            }
        }
        .onChange(of: query) { _, newQuery in
            scheduleSearch(for: newQuery)
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Search-as-you-type: cancel any in-flight debounce, then fire a search
    /// 350ms after the last keystroke — but only for a new, non-empty query.
    private func scheduleSearch(for rawQuery: String) {
        searchTask?.cancel()
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastSearchedQuery = ""
            catalog.clearSearch()
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let current = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !current.isEmpty, current != lastSearchedQuery else { return }
            lastSearchedQuery = current
            catalog.search(current)
        }
    }

    /// Immediate-search path (Return key / recent-search tap): cancels any
    /// pending debounce and fires the network call right away.
    private func performImmediateSearch() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recordRecent(trimmed)
        guard trimmed != lastSearchedQuery else { return }
        lastSearchedQuery = trimmed
        catalog.search(trimmed)
    }

    // MARK: - Recent searches

    private func recordRecent(_ rawQuery: String) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var recents = recentSearches.filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        recents.insert(trimmed, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        recentSearches = recents
        UserDefaults.standard.set(recents, forKey: AppStorageKey.recentSearches)
    }

    private func clearRecents() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: AppStorageKey.recentSearches)
    }

    private var recentSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(t(.recentSearches))
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Button(t(.clearRecents)) {
                        clearRecents()
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)

                ForEach(recentSearches, id: \.self) { recent in
                    Button {
                        query = recent
                        performImmediateSearch()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AppTheme.mutedText)
                            Text(recent)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryText)
                                .lineLimit(1)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.mutedText)

            TextField(t(.searchPlaceholder), text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primaryText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    performImmediateSearch()
                }
                .accessibilityIdentifier(AccessibilityID.searchField)

            if !query.isEmpty {
                Button {
                    query = ""
                    catalog.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.mutedText)
                }
                .accessibilityLabel(t(.clearSearch))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Results

    private func resultsList(_ results: SearchResults) -> some View {
        List {
            if !results.songs.isEmpty {
                Section {
                    ForEach(results.songs) { song in
                        songRow(for: song, in: results.songs)
                            .listRowBackground(AppTheme.background)
                    }
                } header: {
                    sectionHeader(t(.searchSongs))
                }
            }

            if !results.albums.isEmpty {
                Section {
                    ForEach(results.albums, id: \.id) { album in
                        NavigationLink(value: CatalogRoute.album(album.id)) {
                            AlbumRow(album: album)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            recordRecent(trimmedQuery)
                        })
                        .listRowBackground(AppTheme.background)
                    }
                } header: {
                    sectionHeader(t(.searchAlbums))
                }
            }

            if !results.artists.isEmpty {
                Section {
                    ForEach(results.artists, id: \.id) { artist in
                        NavigationLink(value: CatalogRoute.artist(artist.id)) {
                            ArtistRow(artist: artist)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            recordRecent(trimmedQuery)
                        })
                        .listRowBackground(AppTheme.background)
                    }
                } header: {
                    sectionHeader(t(.searchArtists))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func songRow(for song: Song, in songs: [Song]) -> some View {
        let onGoToAlbum: (() -> Void)?
        if let albumID = song.albumID {
            onGoToAlbum = { appState.navigate(to: .album(albumID)) }
        } else {
            onGoToAlbum = nil
        }
        return SongRow(
            song: song,
            isLiked: appState.isLiked(song.id),
            onToggleLike: { Task { await appState.toggleLike(songID: song.id) } },
            isCurrent: appState.currentSongID == song.id,
            isPlaying: appState.playerState.isPlaying,
            onPlayNext: { appState.addToQueueNext(song) },
            onAddToQueue: { appState.addToQueue(song) },
            onGoToAlbum: onGoToAlbum
        ) {
            recordRecent(trimmedQuery)
            appState.play(song: song, from: songs)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.secondaryText)
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Empty & Error States

    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.mutedText)
            Text(t(.searchNoResults))
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(t(.searchNoResultsHint))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            Button(t(.retry)) {
                performImmediateSearch()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            Spacer()
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.mutedText)
            Text(t(.searchPrompt))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            Spacer()
        }
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}

// MARK: - List rows

struct AlbumRow: View {
    let album: AlbumSummary

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            CachedAsyncImage(
                url: album.coverURL,
                fallbackURL: album.coverFallbackURL
            ) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.displayTitle)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                Text(album.artistName ?? "")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct ArtistRow: View {
    let artist: ArtistSearchResult

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            CachedAsyncImage(
                url: JuchifyMediaURL.coverURL(path: artist.photoURL, size: 320),
                fallbackURL: rawPhotoURL
            ) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    AppTheme.surface
                    StarShape().fill(AppTheme.secondaryText.opacity(0.5))
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            Text(artist.name ?? artist.names?.en ?? "")
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var rawPhotoURL: URL? {
        guard let path = artist.photoURL, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }
}
