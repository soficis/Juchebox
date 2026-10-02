import SwiftUI

/// Album detail: cover, metadata, full track list with play-all.
struct AlbumView: View {
    @ObservedObject var appState: AppState
    let albumID: Int
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var album: Album?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(AppTheme.secondaryText)
            } else if let album {
                content(album)
            } else {
                errorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle(album?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func content(_ album: Album) -> some View {
        List {
            header(album)
                .listRowBackground(AppTheme.background)

            if let songs = album.songs, !songs.isEmpty {
                Section {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                        songRow(for: song, at: index, in: songs, coverPath: album.coverPath)
                            .listRowBackground(AppTheme.background)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func header(_ album: Album) -> some View {
        VStack(spacing: AppSpacing.md) {
            CachedAsyncImage(
                url: JuchifyMediaURL.coverURL(path: album.coverPath, albumID: albumID, size: 640),
                fallbackURL: rawCoverURL(album.coverPath)
            ) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                AppTheme.surface
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )

            VStack(spacing: 4) {
                Text(album.title)
                    .font(.system(.title2, design: .serif).weight(.black))
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(album.artistName ?? "")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if let songs = album.songs {
                    Text("\(songs.count) \(t(.homeSongCount))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }

            Button {
                if let songs = album.songs, !songs.isEmpty {
                    appState.play(queue: songs, startAt: 0)
                }
            } label: {
                Label(t(.playAlbum), systemImage: "play.fill")
                    .font(.system(.subheadline).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityIdentifier(AccessibilityID.playAlbumButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    private func songRow(
        for song: Song,
        at index: Int,
        in songs: [Song],
        coverPath: String?
    ) -> some View {
        let onGoToAlbum: (() -> Void)?
        if let albumID = song.albumID {
            onGoToAlbum = { appState.navigate(to: .album(albumID)) }
        } else {
            onGoToAlbum = nil
        }
        return SongRow(
            song: song,
            coverPathOverride: coverPath,
            coverAlbumIDOverride: albumID,
            isLiked: appState.isLiked(song.id),
            onToggleLike: { Task { await appState.toggleLike(songID: song.id) } },
            isCurrent: appState.currentSongID == song.id,
            isPlaying: appState.playerState.isPlaying,
            trackNumber: index + 1,
            onPlayNext: { appState.addToQueueNext(song) },
            onAddToQueue: { appState.addToQueue(song) },
            onGoToAlbum: onGoToAlbum
        ) {
            appState.play(queue: songs, startAt: index)
        }
    }

    private var errorView: some View {
        VStack(spacing: AppSpacing.md) {
            Text(errorMessage ?? t(.homeLoadError))
                .foregroundStyle(AppTheme.mutedText)
            Button(t(.retry)) {
                Task { await load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            album = try await appState.apiClient.album(id: albumID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rawCoverURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}
