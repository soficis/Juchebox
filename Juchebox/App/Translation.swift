import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"

    var id: String { rawValue }

    func displayName(currentLanguage: AppLanguage = .english) -> String {
        "English"
    }
}

enum Translation {
    static func string(for key: Key, language: AppLanguage = .english) -> String {
        key.englishValue
    }

    enum Key: Equatable, Sendable {
        case appName
        case subtitle
        case acceptButton
        case disclaimer1Title
        case disclaimer1Message
        case disclaimer2Title
        case disclaimer2Message
        case disclaimer3Title
        case disclaimer3Message
        case disclaimer4Title
        case disclaimer4Message
        case settingsTitle
        case aboutSection
        case securitySection
        case licensesTitle
        case licensesFooter
        case versionTitle
        case languageSelectTitle
        case cancel
        case doneButton
        case searchPlaceholder

        case playerPlayButton
        case playerPauseButton
        case playerNextTrackButton
        case playerPreviousTrackButton
        case playerSeekForward
        case playerSeekBackward
        case playerMiniNowPlaying
        case playerNoTrackPlaying
        case playerUnknownArtist
        case playerUnknownTitle
        case tabNowPlaying
        case playerNowPlayingTab
        case playerQueueTab
        case playerShuffle
        case playerRepeat
        case playerRepeatOne
        case playerUpNext
        case playerPlayHistory
        case playerQueueEmpty
        case playerHistoryEmpty
        case playerSeekLabel
        case playerDurationLabel
        case playerAirplayLabel
        case playerLockscreenPaused
        case playerArtworkAccessibility

        case tabHome
        case tabBrowse
        case tabSearch
        case tabLibrary
        case homePopularSongs
        case homeNewReleases
        case homeNewTracks
        case homePopularAlbums
        case homeSongCount
        case homeLoadError
        case retry
        case searchSongs
        case searchAlbums
        case searchArtists
        case searchPrompt
        case clearSearch
        case playAlbum
        case librarySignInPrompt
        case librarySignInButton
        case libraryLikedSongs
        case libraryRecentlyPlayed
        case libraryPlaylists
        case signInTitle
        case usernamePlaceholder
        case passwordPlaceholder
        case signInSubmit
        case signInFailed
        case signOutButton

        case like
        case unlike
        case playNext
        case addToQueue
        case goToAlbum
        case moreActions
        case songLocked

        case seeAll
        case recentSearches
        case clearRecents

        case libraryEmpty
        case libraryEmptyHint
        case signOutConfirmTitle

        case searchNoResults
        case searchNoResultsHint

        var englishValue: String {
            switch self {
            case .appName: return "Juchebox"
            case .subtitle: return "The People's Revolutionary Music Explorer"
            case .acceptButton: return "Forward!"
            case .disclaimer1Title: return "Self-Reliant & Independent App"
            case .disclaimer1Message: return "This app is not affiliated with or endorsed by Juchify, Chollima Front, or any music rightsholder."
            case .disclaimer2Title: return "Native Catalog Access"
            case .disclaimer2Message: return "Connects directly to the public catalog API without WebKit or embedded browsers."
            case .disclaimer3Title: return "Material Protection"
            case .disclaimer3Message: return "Does not download or store audio tracks."
            case .disclaimer4Title: return "People's Security"
            case .disclaimer4Message: return "No analytics, no telemetry, and no independent backend servers."
            case .settingsTitle: return "Party Directives"
            case .aboutSection: return "About the Explorer"
            case .securitySection: return "Security Settings"
            case .licensesTitle: return "License"
            case .licensesFooter: return "No third-party dependencies are used. Juchebox itself is released under the GNU General Public License v3.0 (GPLv3)."
            case .versionTitle: return "Version"
            case .languageSelectTitle: return "Language Selection"
            case .cancel: return "Cancel"
            case .doneButton: return "Done"
            case .searchPlaceholder: return "Search songs, albums, artists"
            case .playerPlayButton: return "Play"
            case .playerPauseButton: return "Pause"
            case .playerNextTrackButton: return "Next Track"
            case .playerPreviousTrackButton: return "Previous Track"
            case .playerSeekForward: return "Seek Forward"
            case .playerSeekBackward: return "Seek Backward"
            case .playerMiniNowPlaying: return "Now Playing"
            case .playerNoTrackPlaying: return "No track playing"
            case .playerUnknownArtist: return "Unknown Artist"
            case .playerUnknownTitle: return "Unknown Title"
            case .tabNowPlaying: return "Now Playing"
            case .playerNowPlayingTab: return "Now Playing"
            case .playerQueueTab: return "Queue"
            case .playerShuffle: return "Shuffle"
            case .playerRepeat: return "Repeat"
            case .playerRepeatOne: return "Repeat One"
            case .playerUpNext: return "Up Next"
            case .playerPlayHistory: return "History"
            case .playerQueueEmpty: return "Queue is empty"
            case .playerHistoryEmpty: return "No play history"
            case .playerSeekLabel: return "Seek"
            case .playerDurationLabel: return "Duration"
            case .playerAirplayLabel: return "AirPlay"
            case .playerLockscreenPaused: return "Paused"
            case .playerArtworkAccessibility: return "Album artwork"
            case .tabHome: return "Home"
            case .tabBrowse: return "Browse"
            case .tabSearch: return "Search"
            case .tabLibrary: return "Library"
            case .homePopularSongs: return "Popular Songs"
            case .homeNewReleases: return "New Releases"
            case .homeNewTracks: return "New Tracks"
            case .homePopularAlbums: return "Popular Albums"
            case .homeSongCount: return "songs"
            case .homeLoadError: return "Could not load the catalog."
            case .retry: return "Retry"
            case .searchSongs: return "Songs"
            case .searchAlbums: return "Albums"
            case .searchArtists: return "Artists"
            case .searchPrompt: return "Search songs, albums, and artists"
            case .clearSearch: return "Clear search"
            case .playAlbum: return "Play Album"
            case .librarySignInPrompt: return "Sign in to sync likes, playlists, and history."
            case .librarySignInButton: return "Sign In"
            case .libraryLikedSongs: return "Liked Songs"
            case .libraryRecentlyPlayed: return "Recently Played"
            case .libraryPlaylists: return "Playlists"
            case .signInTitle: return "Sign In to Juchify"
            case .usernamePlaceholder: return "Username"
            case .passwordPlaceholder: return "Password"
            case .signInSubmit: return "Sign In"
            case .signInFailed: return "Sign-in failed. Check your credentials."
            case .signOutButton: return "Sign Out"
            case .like: return "Like"
            case .unlike: return "Unlike"
            case .playNext: return "Play Next"
            case .addToQueue: return "Add to Queue"
            case .goToAlbum: return "Go to Album"
            case .moreActions: return "More Actions"
            case .songLocked: return "Locked"
            case .seeAll: return "See All"
            case .recentSearches: return "Recent Searches"
            case .clearRecents: return "Clear"
            case .libraryEmpty: return "Your Library is Empty"
            case .libraryEmptyHint: return "Songs and albums you like will appear here."
            case .signOutConfirmTitle: return "Are you sure you want to sign out?"
            case .searchNoResults: return "No Results Found"
            case .searchNoResultsHint: return "Try searching for another song, album, or artist."
            }
        }
    }
}

extension View {
    func t(_ key: Translation.Key, language: AppLanguage = .english) -> String {
        Translation.string(for: key, language: language)
    }
}
