import SwiftUI

/// Search tab: query the catalog (songs / albums / artists).
struct SearchView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

            if catalog.isSearching {
                Spacer()
                ProgressView().tint(AppTheme.secondaryText)
                Spacer()
            } else if let results = catalog.searchResults {
                resultsList(results)
            } else {
                emptyPrompt
            }
        }
        .background(AppTheme.background)
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
                    catalog.search(query)
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
                        SongRow(song: song) {
                            appState.play(song: song, from: results.songs)
                        }
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

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.secondaryText)
            .textCase(nil)
    }

    // MARK: - Empty

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
            AsyncImage(url: albumCoverURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.displayTitle)
                    .font(.subheadline)
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

    private var albumCoverURL: URL? {
        guard let path = album.coverPath, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }
}

struct ArtistRow: View {
    let artist: ArtistSearchResult

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AsyncImage(url: photoURL) { image in
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
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var photoURL: URL? {
        guard let path = artist.photoURL, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }
}
