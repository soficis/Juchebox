import SwiftUI

/// Home tab: hero sections from the API feed (popular, new, releases).
struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    /// Section currently shown in the "See All" sheet (nil = no sheet).
    @State private var expandedSection: ExpandedSection?

    /// Which home section's full item list the "See All" sheet presents.
    private enum ExpandedSection: Identifiable {
        case songs(title: String, songs: [Song])
        case albums(title: String, albums: [AlbumSummary])

        var id: String {
            switch self {
            case .songs(let title, _): return "songs-\(title)"
            case .albums(let title, _): return "albums-\(title)"
            }
        }

        var title: String {
            switch self {
            case .songs(let title, _): return title
            case .albums(let title, _): return title
            }
        }
    }

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
            .sheet(item: $expandedSection) { section in
                expandedSectionSheet(section)
                    .presentationDetents([.large])
            }
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

    // MARK: - See All sheet

    private func expandedSectionSheet(_ section: ExpandedSection) -> some View {
        NavigationStack {
            Group {
                switch section {
                case .songs(_, let songs):
                    List {
                        ForEach(songs) { song in
                            songRow(for: song, in: songs)
                                .listRowBackground(AppTheme.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                case .albums(_, let albums):
                    List {
                        ForEach(albums, id: \.id) { album in
                            Button {
                                expandedSection = nil
                                appState.navigationPath.append(.album(album.id))
                            } label: {
                                AlbumRow(album: album)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(AppTheme.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background)
            .navigationTitle(section.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        expandedSection = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(t(.cancel))
                }
            }
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
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                if songs.count > 6 {
                    Button(t(.seeAll)) {
                        expandedSection = .songs(title: title, songs: songs)
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .buttonStyle(.plain)
                }
            }

            ForEach(songs.prefix(6)) { song in
                songRow(for: song, in: songs)
            }
        }
    }

    private func songRow(for song: Song, in songs: [Song]) -> some View {
        let onGoToAlbum: (() -> Void)?
        if let albumID = song.albumID {
            onGoToAlbum = { appState.navigationPath.append(.album(albumID)) }
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
            appState.play(song: song, from: songs)
        }
    }

    private func albumSection(title: String, albums: [AlbumSummary]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                if albums.count > 12 {
                    Button(t(.seeAll)) {
                        expandedSection = .albums(title: title, albums: albums)
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .buttonStyle(.plain)
                }
            }

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

/// Single song row: artwork, title, artist, like heart, play on tap.
///
/// `onPlay` stays the LAST stored property so the trailing-closure form
/// `SongRow(song: song) { ... }` keeps binding to it; every other parameter
/// has a default and sits before it.
struct SongRow: View {
    let song: Song
    var coverPathOverride: String? = nil
    var coverAlbumIDOverride: Int? = nil
    var isLiked: Bool = false
    var onToggleLike: (() -> Void)? = nil
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    var trackNumber: Int? = nil
    var onPlayNext: (() -> Void)? = nil
    var onAddToQueue: (() -> Void)? = nil
    var onGoToAlbum: (() -> Void)? = nil
    let onPlay: () -> Void

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    private var artworkURL: URL? {
        if let coverPathOverride {
            return JuchifyMediaURL.coverURL(path: coverPathOverride, albumID: coverAlbumIDOverride, size: 320)
        }
        return song.artworkURL
    }

    private var artworkFallbackURL: URL? {
        if let coverPathOverride {
            let full = coverPathOverride.hasPrefix("/") ? coverPathOverride : "/" + coverPathOverride
            return URL(string: "https://juchify.com\(full)")
        }
        return song.artworkFallbackURL
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let trackNumber {
                Text(String(format: "%02d", trackNumber))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.mutedText)
                    .frame(width: 24, alignment: .leading)
            }

            Button(action: onPlay) {
                HStack(spacing: AppSpacing.md) {
                    artwork
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.displayTitle)
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundStyle(isCurrent ? AppTheme.accentOnDark : AppTheme.primaryText)
                            .lineLimit(1)
                        Text(song.displayArtist)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                            .lineLimit(1)
                    }

                    Spacer()

                    if song.isLocked == true {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.mutedText)
                            .accessibilityLabel("Locked")
                    }

                    Text(song.durationFormatted)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.mutedText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let onPlayNext {
                    Button(action: onPlayNext) {
                        Label(t(.playNext), systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                }
                if let onAddToQueue {
                    Button(action: onAddToQueue) {
                        Label(t(.addToQueue), systemImage: "text.badge.plus")
                    }
                }
                if song.albumID != nil, let onGoToAlbum {
                    Button(action: onGoToAlbum) {
                        Label(t(.goToAlbum), systemImage: "square.stack")
                    }
                }
                if let onToggleLike {
                    Button(action: onToggleLike) {
                        Label(
                            isLiked ? t(.unlike) : t(.like),
                            systemImage: isLiked ? "heart.fill" : "heart"
                        )
                    }
                }
            }

            if let onToggleLike {
                Button(action: onToggleLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 17))
                        .foregroundStyle(isLiked ? AppTheme.accentOnDark : AppTheme.mutedText)
                        .frame(width: 32, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isLiked ? t(.unlike) : t(.like))
            }
        }
    }

    private var artwork: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: artworkURL,
                fallbackURL: artworkFallbackURL
            ) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }

            if isCurrent {
                Image(systemName: isPlaying ? "waveform" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.accentOnDark)
                    .padding(3)
                    .background(Circle().fill(AppTheme.elevatedSurface.opacity(0.9)))
                    .padding(2)
            }
        }
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
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
        .task {
            await load()
        }
    }

    private func load() async {
        NSLog("[CachedAsyncImage] candidates: %@", candidates.map(\.absoluteString))
        for target in candidates {
            if let cached = ImageCache.shared.image(for: target) {
                NSLog("[CachedAsyncImage] cache hit: %@", target.absoluteString)
                image = cached
                return
            }
            NSLog("[CachedAsyncImage] fetching: %@", target.absoluteString)
            guard let data = try? await URLSession.shared.data(from: target).0,
                  let decoded = UIImage(data: data) else {
                NSLog("[CachedAsyncImage] failed: %@", target.absoluteString)
                continue
            }
            NSLog("[CachedAsyncImage] success: %@ (%d bytes)", target.absoluteString, data.count)
            ImageCache.shared.insert(decoded, for: target)
            image = decoded
            return
        }
    }
}
