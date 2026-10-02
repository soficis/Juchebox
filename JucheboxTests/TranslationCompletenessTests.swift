import XCTest
@testable import Juchebox

final class TranslationCompletenessTests: XCTestCase {
    func testAllNonAssociatedKeysHaveEnglishValue() {
        for key in Translation.Key.nonAssociatedCases {
            let value = Translation.string(for: key, language: .english)
            XCTAssertFalse(value.isEmpty, "Key \(key) has empty English value")
        }
    }

    func testAllNonAssociatedKeysHaveKoreanValue() {
        for key in Translation.Key.nonAssociatedCases {
            let value = Translation.string(for: key, language: .korean)
            XCTAssertFalse(value.isEmpty, "Key \(key) has empty Korean value")
        }
    }

    func testEnglishValuesContainNoEmptyWhitespaceOnlyStrings() {
        for key in Translation.Key.nonAssociatedCases {
            let value = Translation.string(for: key, language: .english)
            XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           "Key \(key) has whitespace-only English value")
        }
    }
}

extension Translation.Key {
    /// Every case that carries no associated value, enumerated explicitly.
    /// `CaseIterable` is not synthesized because some cases have associated values.
    static let nonAssociatedCases: [Translation.Key] = [
        .appName, .subtitle, .acceptButton,
        .disclaimer1Title, .disclaimer1Message,
        .disclaimer2Title, .disclaimer2Message,
        .disclaimer3Title, .disclaimer3Message,
        .disclaimer4Title, .disclaimer4Message,
        .settingsTitle, .aboutSection, .securitySection,
        .licensesTitle, .licensesFooter,
        .versionTitle,
        .languageSelectTitle,
        .cancel,
        .doneButton,
        .searchPlaceholder,
        .playerPlayButton, .playerPauseButton, .playerNextTrackButton, .playerPreviousTrackButton,
        .playerSeekForward, .playerSeekBackward, .playerMiniNowPlaying, .playerNoTrackPlaying,
        .playerUnknownArtist, .playerUnknownTitle,
        .tabNowPlaying, .playerNowPlayingTab, .playerQueueTab,
        .playerShuffle, .playerRepeat, .playerRepeatOne,
        .playerUpNext, .playerPlayHistory, .playerQueueEmpty, .playerHistoryEmpty,
        .playerSeekLabel, .playerDurationLabel, .playerAirplayLabel,
        .playerLockscreenPaused, .playerArtworkAccessibility,
        .tabHome, .tabBrowse, .tabSearch, .tabLibrary,
        .homePopularSongs, .homeNewReleases, .homeNewTracks, .homePopularAlbums,
        .homeSongCount, .homeLoadError, .retry,
        .searchSongs, .searchAlbums, .searchArtists, .searchPrompt,
        .clearSearch, .playAlbum,
        .librarySignInPrompt, .librarySignInButton,
        .libraryLikedSongs, .libraryRecentlyPlayed, .libraryPlaylists,
        .signInTitle, .usernamePlaceholder, .passwordPlaceholder,
        .signInSubmit, .signInFailed, .signOutButton,
        .like, .unlike, .playNext, .addToQueue, .goToAlbum, .moreActions, .songLocked,
        .seeAll, .recentSearches, .clearRecents,
        .libraryEmpty, .libraryEmptyHint, .signOutConfirmTitle,
        .searchNoResults, .searchNoResultsHint,
    ]
}
