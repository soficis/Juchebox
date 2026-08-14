import SwiftUI

struct MiniPlayerBar: View {
    @ObservedObject var appState: AppState
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onTap: () -> Void

    private let feedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                // Gold hairline top border
                Rectangle()
                    .fill(AppTheme.secondaryText.opacity(0.3))
                    .frame(height: 1)

                // Progress hairline overlay (2pt accent, above the gold line)
                GeometryReader { geo in
                    Rectangle()
                        .fill(AppTheme.accent)
                        .frame(width: geo.size.width * progressFraction, height: 2)
                }
                .frame(height: 2)
                .allowsHitTesting(false)

                // Track info layer
                HStack(spacing: AppSpacing.sm) {
                    if appState.playerState.currentTrack != nil {
                        artworkThumb
                    }
                    trackInfo
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 47)
                .offset(y: 1)

                // Control buttons overlaid on top for hit-test priority
                HStack(spacing: AppSpacing.xs) {
                    Spacer()
                    playPauseButton
                    nextButton
                }
                .padding(.trailing, AppSpacing.md)
                .frame(height: 47)
                .offset(y: 1)
            }
        }
        .buttonStyle(.plain)
        .background(AppTheme.elevatedSurface)
        .frame(height: appState.isPlayerBarVisible ? 48 : 0)
        .opacity(appState.isPlayerBarVisible ? 1 : 0)
        .animation(
            reduceMotion ? .none : .easeInOut(duration: AppMotion.defaultDuration),
            value: appState.isPlayerBarVisible
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(playerAccessibilityLabel)
    }

    // MARK: - Artwork

    private var artworkThumb: some View {
        CachedAsyncImage(
            url: appState.playerState.currentTrack?.artworkURL,
            fallbackURL: appState.playerState.currentTrack?.artworkFallbackURL
        ) { image in
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
    }

    private var progressFraction: Double {
        let duration = appState.playerState.duration
        guard duration > 0 else { return 0 }
        return min(max(appState.playerState.currentTime / duration, 0), 1)
    }

    // MARK: - Track Info

    @ViewBuilder
    private var trackInfo: some View {
        if let track = appState.playerState.currentTrack {
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title ?? t(.playerUnknownTitle, language: appLanguage))
                    .font(.system(.callout, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                Text(track.artist ?? t(.playerUnknownArtist, language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }
        } else {
            Text(t(.playerNoTrackPlaying, language: appLanguage))
                .font(.system(.callout, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)
        }
    }

    // MARK: - Controls

    private var playPauseButton: some View {
        Button {
            feedback.impactOccurred()
            appState.playerCommand(.togglePlayPause)
        } label: {
            Image(systemName: appState.playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundStyle(AppTheme.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            appState.playerState.isPlaying
                ? t(.playerPauseButton, language: appLanguage)
                : t(.playerPlayButton, language: appLanguage)
        )
    }

    private var nextButton: some View {
        Button {
            feedback.impactOccurred()
            appState.playerCommand(.nextTrack)
        } label: {
            Image(systemName: "forward.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t(.playerNextTrackButton, language: appLanguage))
    }

    // MARK: - Accessibility

    private var playerAccessibilityLabel: String {
        let prefix = t(.playerMiniNowPlaying, language: appLanguage)
        if let track = appState.playerState.currentTrack {
            let title = track.title ?? t(.playerUnknownTitle, language: appLanguage)
            let artist = track.artist ?? t(.playerUnknownArtist, language: appLanguage)
            return "\(prefix), \(title), \(artist)"
        }
        return t(.playerNoTrackPlaying, language: appLanguage)
    }
}
