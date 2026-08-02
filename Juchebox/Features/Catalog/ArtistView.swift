import SwiftUI

/// Artist detail: bio, photo, album discography.
struct ArtistView: View {
    @ObservedObject var appState: AppState
    let artistID: Int
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var artist: Artist?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(AppTheme.secondaryText)
            } else if let artist {
                content(artist)
            } else {
                errorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle(artist?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func content(_ artist: Artist) -> some View {
        List {
            header(artist)
                .listRowBackground(AppTheme.background)

            if let albums = artist.albums, !albums.isEmpty {
                Section {
                    ForEach(albums, id: \.id) { album in
                        NavigationLink(value: CatalogRoute.album(album.id)) {
                            AlbumRow(album: album)
                        }
                        .listRowBackground(AppTheme.background)
                    }
                } header: {
                    Text(t(.searchAlbums))
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func header(_ artist: Artist) -> some View {
        VStack(spacing: AppSpacing.md) {
            AsyncImage(url: photoURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    AppTheme.surface
                    StarShape().fill(AppTheme.secondaryText.opacity(0.5))
                        .frame(width: 60, height: 60)
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppTheme.hairline, lineWidth: 1))

            Text(artist.name)
                .font(.system(.title2, design: .serif).weight(.black))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            if let bio = artist.bio, !bio.isEmpty {
                Text(bio)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
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
            artist = try await appState.apiClient.artist(id: artistID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var photoURL: URL? {
        guard let path = artist?.photoURL, !path.isEmpty else { return nil }
        let full = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "https://juchify.com\(full)")
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}
