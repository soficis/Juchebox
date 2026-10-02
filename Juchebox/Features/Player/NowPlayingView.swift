import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var appState: AppState
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false
    @State private var showsQueue = false

    private let feedback = UIImpactFeedbackGenerator(style: .light)

    private var track: TrackInfo? { appState.playerState.currentTrack }
    private var duration: Double { max(appState.playerState.duration, 1) }
    private var elapsed: String { formatTime(scrubValue) }
    private var remaining: String { formatTime(max(duration - scrubValue, 0)) }

    var body: some View {
        ScrollView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if track == nil {
                    emptyState
                } else {
                    playerContent
                }

                if appState.playerState.isStalled {
                    ProgressView()
                        .tint(AppTheme.secondaryText)
                        .scaleEffect(1.4)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .sheet(isPresented: $showsQueue) {
            queueSheet
        }
        .onChange(of: appState.playerState.currentTime) { _, new in
            guard !isScrubbing else { return }
            scrubValue = new
        }
    }

    // MARK: - Player Content

    private var playerContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer(minLength: 0)
            artworkView
            trackInfoView

            if let error = appState.playerState.streamError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
            }

            progressView
            transportControls
            shuffleRepeatRow
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(
            artworkBackground
                .ignoresSafeArea(.all, edges: .top)
        )
    }

    // MARK: - Artwork Background

    private var artworkBackground: some View {
        Group {
            if let url = track?.artworkURL {
                CachedAsyncImage(
                    url: url,
                    fallbackURL: track?.artworkFallbackURL
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .id(url)
                .blur(radius: 40)
                .overlay(AppTheme.background.opacity(0.75))
                .ignoresSafeArea()
            } else {
                RadialGradient(
                    colors: [AppTheme.accent.opacity(0.08), AppTheme.background],
                    center: .center, startRadius: 60, endRadius: 300
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Artwork

    private var artworkView: some View {
        CachedAsyncImage(
            url: track?.artworkURL,
            fallbackURL: track?.artworkFallbackURL
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 360, maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
        } placeholder: {
            placeholderArtwork
        }
        .id(track?.id)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel(t(.playerArtworkAccessibility))
    }

    private var placeholderArtwork: some View {
        ZStack {
            AppTheme.surface
            StarShape()
                .fill(AppTheme.secondaryText)
                .frame(width: 80, height: 80)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppTheme.secondaryText, lineWidth: 1.5)
        )
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Text(track?.title ?? t(.playerUnknownTitle))
                    .font(.system(.title2, design: .serif).weight(.black))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let songID = appState.currentSongID {
                    Button {
                        Task { await appState.toggleLike(songID: songID) }
                    } label: {
                        Image(systemName: appState.isLiked(songID) ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                            .foregroundStyle(appState.isLiked(songID) ? AppTheme.accentOnDark : AppTheme.mutedText)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appState.isLiked(songID) ? t(.unlike) : t(.like))
                }
            }

            Text(track?.artist ?? t(.playerUnknownArtist))
                .font(.system(.body))
                .foregroundColor(AppTheme.mutedText)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            if let album = track?.album {
                Text(album)
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.mutedText)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        HStack {
            Text(elapsed)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 44, alignment: .leading)

            Slider(value: $scrubValue, in: 0...duration) { editing in
                isScrubbing = editing
                if !editing {
                    appState.playerCommand(.seek(to: scrubValue))
                }
            }
            .tint(AppTheme.accent)

            Text(remaining)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Transport

    private var transportControls: some View {
        HStack(spacing: AppSpacing.lg) {
            Button {
                feedback.impactOccurred()
                appState.playerCommand(.previousTrack)
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .accessibilityLabel(t(.playerPreviousTrackButton))

            Button {
                feedback.impactOccurred()
                appState.playerCommand(.togglePlayPause)
            } label: {
                Image(systemName: appState.playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.accentOnDark)
            }
            .accessibilityLabel(appState.playerState.isPlaying
                ? t(.playerPauseButton) : t(.playerPlayButton))

            Button {
                feedback.impactOccurred()
                appState.playerCommand(.nextTrack)
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .accessibilityLabel(t(.playerNextTrackButton))
        }
    }

    // MARK: - Shuffle / Repeat

    private var shuffleRepeatRow: some View {
        HStack {
            Button { appState.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(appState.isShuffleOn ? AppTheme.secondaryText : AppTheme.mutedText)
            }
            .accessibilityLabel(t(.playerShuffle))

            Spacer()

            Button { showsQueue = true } label: {
                Image(systemName: "text.line.last.and.arrowtriangle.forward")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.mutedText)
            }
            .accessibilityLabel(t(.playerQueueTab))

            Spacer()

            Button { appState.cycleRepeatMode() } label: {
                Image(systemName: appState.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 20))
                    .foregroundColor(appState.repeatMode == .off ? AppTheme.mutedText : AppTheme.secondaryText)
            }
            .accessibilityLabel(appState.repeatMode == .one ? t(.playerRepeatOne) : t(.playerRepeat))
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    // MARK: - Queue Sheet

    private var queueSheet: some View {
        NavigationStack {
            Group {
                if appState.nowPlayingQueue.isEmpty {
                    VStack {
                        Spacer()
                        Text(t(.playerQueueEmpty))
                            .font(.system(.headline))
                            .foregroundStyle(AppTheme.mutedText)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(Array(appState.nowPlayingQueue.enumerated()), id: \.element.id) { index, song in
                            queueRow(index: index, song: song)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background)
            .navigationTitle(t(.playerQueueTab))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t(.doneButton)) {
                        showsQueue = false
                    }
                    .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func queueRow(index: Int, song: Song) -> some View {
        let isCurrent = index == appState.queueIndex
        return Button {
            feedback.impactOccurred()
            appState.play(queue: appState.nowPlayingQueue, startAt: index)
            showsQueue = false
        } label: {
            HStack(spacing: AppSpacing.sm) {
                CachedAsyncImage(url: song.artworkURL, fallbackURL: song.artworkFallbackURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        AppTheme.surface
                        StarShape().fill(AppTheme.secondaryText.opacity(0.5))
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.displayTitle)
                        .font(.system(.subheadline, design: .serif).weight(isCurrent ? .bold : .regular))
                        .foregroundStyle(isCurrent ? AppTheme.secondaryText : AppTheme.primaryText)
                        .lineLimit(1)
                    Text(song.displayArtist)
                        .font(.caption)
                        .foregroundStyle(isCurrent ? AppTheme.secondaryText.opacity(0.7) : AppTheme.mutedText)
                        .lineLimit(1)
                }

                if isCurrent {
                    Spacer(minLength: 0)
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentOnDark)
                } else {
                    Spacer()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            ZStack {
                AppTheme.surface
                StarShape()
                    .fill(AppTheme.secondaryText.opacity(0.6))
                    .frame(width: 100, height: 100)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .frame(width: 200, height: 200)

            Text(t(.playerNoTrackPlaying))
                .font(.system(.headline))
                .foregroundColor(AppTheme.mutedText)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func t(_ key: Translation.Key) -> String {
        Translation.string(for: key, language: appLanguage)
    }
}
