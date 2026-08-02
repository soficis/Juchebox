import SwiftUI

/// Home tab: hero sections from the API feed (popular, new, releases).
struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                if let feed = catalog.homeFeed {
                    heroSection

                    if !feed.popularSongs.isEmpty {
                        songSection(
                            title: t(.homePopularSongs),
                            songs: feed.popularSongs
                        )
                    }

                    if !feed.newReleases.isEmpty {
                        albumSection(
                            title: t(.homeNewReleases),
                            albums: feed.newReleases
                        )
                    }

                    if !feed.newTracks.isEmpty {
                        songSection(
                            title: t(.homeNewTracks),
                            songs: feed.newTracks
                        )
                    }

                    if !feed.popularAlbums.isEmpty {
                        albumSection(
                            title: t(.homePopularAlbums),
                            albums: feed.popularAlbums
                        )
                    }
                } else if catalog.errorMessage == nil {
                    ProgressView()
                        .tint(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xl)
                } else {
                    errorView
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppTheme.background)
        .task {
            catalog.loadHomeIfNeeded()
        }
        .refreshable {
            await catalog.refreshHome()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(t(.appName))
                    .font(.system(.largeTitle, design: .serif).weight(.black))
                    .foregroundStyle(AppTheme.secondaryText)

                if let count = catalog.homeFeed?.totalSongCount {
                    Text("\(count) \(t(.homeSongCount))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }

            Spacer()

            Button {
                appState.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier(AccessibilityID.settingsTab)
            .sheet(isPresented: $appState.showSettings) {
                SettingsView(appState: appState, authStore: appState.authStore)
                    .presentationDetents([.medium, .large])
            }
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if let hero = catalog.homeFeed?.newTracks.first {
            Button {
                appState.play(song: hero, from: catalog.homeFeed?.newTracks)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: hero.artworkURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        AppTheme.surface
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, AppTheme.background.opacity(0.9)],
                        startPoint: .center, endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(hero.displayTitle)
                            .font(.system(.title2, design: .serif).weight(.black))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(hero.displayArtist)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(AppSpacing.md)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sections

    private func songSection(title: String, songs: [Song]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(songs.prefix(6)) { song in
                SongRow(song: song) {
                    appState.play(song: song, from: songs)
                }
            }
        }
    }

    private func albumSection(title: String, albums: [AlbumSummary]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    ForEach(albums.prefix(12), id: \.id) { album in
                        NavigationLink(value: CatalogRoute.album(album.id)) {
                            AlbumCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.warning)
            Text(catalog.errorMessage ?? t(.homeLoadError))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
            Button(t(.retry)) {
                Task { await catalog.refreshHome() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}

// MARK: - Row / Card components

/// Single song row: artwork, title, artist, play on tap.
struct SongRow: View {
    let song: Song
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: AppSpacing.md) {
                AsyncImage(url: song.artworkURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    AppTheme.surface
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.displayTitle)
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Text(song.displayArtist)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .lineLimit(1)
                }

                Spacer()

                Text(song.durationFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.mutedText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Horizontal album card used in home sections and artist pages.
struct AlbumCard: View {
    let album: AlbumSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AsyncImage(url: albumCoverURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            Text(album.displayTitle)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2, reservesSpace: true)
                .frame(width: 140, alignment: .leading)

            Text(album.artistName ?? album.artistNames?.en ?? "")
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }

    private var albumCoverURL: URL? {
        guard let path = album.coverPath, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }
}
