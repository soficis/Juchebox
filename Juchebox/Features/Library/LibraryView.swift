import SwiftUI

/// Library tab: liked songs, playlists, recently played (auth-gated).
struct LibraryView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var authStore: AuthStore
    @ObservedObject var catalog: CatalogStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var likedSongs: [Song] = []
    @State private var recentlyPlayed: [Song] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                content
            } else {
                signInPrompt
            }
        }
        .background(AppTheme.background)
        .task {
            guard authStore.isAuthenticated else { return }
            await loadLibrary()
        }
        .onChange(of: authStore.isAuthenticated) { _, authed in
            guard authed else {
                likedSongs = []
                recentlyPlayed = []
                appState.resetLikedSongIDs()
                return
            }
            Task { await loadLibrary() }
        }
    }

    // MARK: - Signed-in content

    private var content: some View {
        List {
            Section {
                Button {
                    appState.play(queue: likedSongs, startAt: 0)
                } label: {
                    Label(t(.libraryLikedSongs), systemImage: "heart.fill")
                        .foregroundStyle(AppTheme.accent)
                }
                .listRowBackground(AppTheme.surface)
                .disabled(likedSongs.isEmpty)
            }

            if !likedSongs.isEmpty {
                Section {
                    ForEach(likedSongs.prefix(20)) { song in
                        songRow(for: song, in: likedSongs)
                            .listRowBackground(AppTheme.background)
                    }
                } header: {
                    sectionHeader(t(.libraryLikedSongs))
                }
            }

            if !recentlyPlayed.isEmpty {
                Section {
                    ForEach(recentlyPlayed.prefix(20)) { song in
                        songRow(for: song, in: recentlyPlayed)
                            .listRowBackground(AppTheme.background)
                    }
                } header: {
                    sectionHeader(t(.libraryRecentlyPlayed))
                }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(AppTheme.secondaryText)
                    Spacer()
                }
                .listRowBackground(AppTheme.background)
            }

            Section {
                Button(t(.signOutButton), role: .destructive) {
                    authStore.signOut()
                }
                .listRowBackground(AppTheme.surface)
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

    // MARK: - Signed-out prompt

    private var signInPrompt: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.secondaryText)
            Text(t(.librarySignInPrompt))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Button {
                showsSignIn = true
            } label: {
                Text(t(.librarySignInButton))
                    .font(.system(.subheadline).weight(.semibold))
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityIdentifier(AccessibilityID.signInButton)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showsSignIn) {
            SignInView(appState: appState, authStore: authStore)
                .presentationDetents([.medium, .large])
        }
    }

    @State private var showsSignIn = false

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

    private func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let liked = appState.apiClient.likedSongs()
            async let recent = appState.apiClient.recentlyPlayed()
            (likedSongs, recentlyPlayed) = try await (liked, recent)
        } catch {
            // Keep whatever loaded; individual failures are non-fatal.
        }
        appState.loadLikedSongIDs()
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}

/// Sheet-based sign-in form.
struct SignInView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var authStore: AuthStore
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var failed = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text(t(.signInTitle))
                .font(.system(.title2, design: .serif).weight(.black))
                .foregroundStyle(AppTheme.primaryText)

            VStack(spacing: AppSpacing.md) {
                TextField(t(.usernamePlaceholder), text: $username)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppTheme.hairline, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(AccessibilityID.usernameField)

                SecureField(t(.passwordPlaceholder), text: $password)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppTheme.hairline, lineWidth: 1)
                    )
                    .accessibilityIdentifier(AccessibilityID.passwordField)

                if failed {
                    Text(t(.signInFailed))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.destructive)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView().tint(AppTheme.primaryText)
                    } else {
                        Text(t(.signInSubmit))
                            .font(.system(.subheadline).weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .disabled(isSubmitting || username.isEmpty || password.isEmpty)
                .accessibilityIdentifier(AccessibilityID.signInSubmitButton)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .background(AppTheme.background)
    }

    private func submit() async {
        isSubmitting = true
        failed = false
        do {
            let response = try await appState.apiClient.login(
                username: username,
                password: password
            )
            authStore.setAuthenticated(token: response.token, user: response.user)
            dismiss()
        } catch {
            failed = true
        }
        isSubmitting = false
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}
