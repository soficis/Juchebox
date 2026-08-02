import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var appState: AppState
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }

    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false
    @State private var isShuffleOn = false
    @State private var repeatMode: RepeatMode = .off

    enum RepeatMode { case off, all, one }

    private var track: TrackInfo? { appState.playerState.currentTrack }
    private var duration: Double { max(appState.playerState.duration, 1) }
    private var elapsed: String { formatTime(scrubValue) }
    private var remaining: String { formatTime(max(duration - scrubValue, 0)) }

    var body: some View {
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
        .transition(.opacity)
        .onChange(of: appState.playerState.currentTime) { _, new in
            guard !isScrubbing else { return }
            scrubValue = new
        }
    }

    // MARK: - Player Content

    private var playerContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            artworkView
            trackInfoView
            progressView
            transportControls
            shuffleRepeatRow
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(
            RadialGradient(
                colors: [AppTheme.accent.opacity(0.08), AppTheme.background],
                center: .center, startRadius: 60, endRadius: 300
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Artwork

    private var artworkView: some View {
        Group {
            if let url = track?.artworkURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderArtwork
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            } else {
                placeholderArtwork
            }
        }
        .frame(width: 200, height: 200)
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
            Text(track?.title ?? t(.playerUnknownTitle))
                .font(.system(.title2, design: .serif).weight(.black))
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(track?.artist ?? t(.playerUnknownArtist))
                .font(.system(.body))
                .foregroundColor(AppTheme.mutedText)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            if let album = track?.album {
                Text(album)
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.mutedText.opacity(0.7))
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
            Button { appState.playerCommand(.previousTrack) } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .accessibilityLabel(t(.playerPreviousTrackButton))

            Button { appState.playerCommand(.togglePlayPause) } label: {
                Image(systemName: appState.playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.accent)
            }
            .accessibilityLabel(appState.playerState.isPlaying
                ? t(.playerPauseButton) : t(.playerPlayButton))

            Button { appState.playerCommand(.nextTrack) } label: {
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
            Button { isShuffleOn.toggle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(isShuffleOn ? AppTheme.secondaryText : AppTheme.mutedText)
            }
            .accessibilityLabel(t(.playerShuffle))

            Spacer()

            Button { cycleRepeatMode() } label: {
                Image(systemName: repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 20))
                    .foregroundColor(repeatMode == .off ? AppTheme.mutedText : AppTheme.secondaryText)
            }
            .accessibilityLabel(repeatMode == .one ? t(.playerRepeatOne) : t(.playerRepeat))
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    private func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
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
