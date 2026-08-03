import SwiftUI

/// Home tab: hero sections from the API feed (popular, new, releases).
struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
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
                    loadingSkeleton
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
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState, authStore: appState.authStore)
                .presentationDetents([.medium, .large])
        }
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppTheme.surface)
                .frame(height: 180)
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppTheme.surface)
                    .frame(height: 48)
            }
        }
        .padding(.top, AppSpacing.md)
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
                    CachedAsyncImage(
                        url: hero.artworkURL,
                        fallbackURL: hero.artworkFallbackURL
                    ) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        AppTheme.surface
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                .aspectRatio(2.06, contentMode: .fit)
                .frame(maxWidth: .infinity)
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
                CachedAsyncImage(
                    url: song.artworkURL,
                    fallbackURL: song.artworkFallbackURL
                ) { image in
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
            CachedAsyncImage(
                url: album.coverURL,
                fallbackURL: album.coverFallbackURL
            ) { image in
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
}

// MARK: - Image caching

/// In-memory image cache shared by every `CachedAsyncImage` in the app.
@MainActor
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

/// `AsyncImage` replacement with an in-memory cache and an automatic fallback
/// URL: the canonical webp cover is tried first, then the raw path, then the
/// placeholder. Loading is lazy and cancellation-safe (per-view `task(id:)`).
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    var fallbackURL: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        url: URL?,
        fallbackURL: URL? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.fallbackURL = fallbackURL
        self.content = content
        self.placeholder = placeholder
    }

    @State private var image: UIImage?
    @State private var attempt = 0

    private var candidates: [URL] {
        var result: [URL] = []
        if let url {
            result.append(url)
        }
        if let fallbackURL, fallbackURL != url {
            result.append(fallbackURL)
        }
        return result
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: attempt) {
            await load()
        }
    }

    private func load() async {
        guard candidates.indices.contains(attempt) else { return }
        let target = candidates[attempt]

        if let cached = ImageCache.shared.image(for: target) {
            image = cached
            return
        }

        guard let data = try? await URLSession.shared.data(from: target).0,
              let decoded = UIImage(data: data) else {
            attempt += 1
            return
        }
        ImageCache.shared.insert(decoded, for: target)
        image = decoded
    }
}
