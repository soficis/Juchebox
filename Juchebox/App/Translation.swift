import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "kp" // North Korean Munhwaŏ

    var id: String { rawValue }

    func displayName(currentLanguage: AppLanguage) -> String {
        switch self {
        case .english:
            return currentLanguage == .korean ? "미제승냥이말" : "English"
        case .korean:
            return "조선말"
        }
    }
}

enum Translation {
    static func string(for key: Key, language: AppLanguage) -> String {
        switch language {
        case .english:
            return key.englishValue
        case .korean:
            return key.koreanValue
        }
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

        var koreanValue: String {
            switch self {
            case .appName: return "주체박스 (주체음악)"
            case .subtitle: return "인민의 혁명적 음악 탐색기"
            case .acceptButton: return "리해하였으며 전진합네다!"
            case .disclaimer1Title: return "자주적이며 독립적인 응용프로그람"
            case .disclaimer1Message: return "본 프로그람은 주체음악 보급을 위한 자주적이며 독립적인 응용프로그람올시다."
            case .disclaimer2Title: return "직접 통신 체계"
            case .disclaimer2Message: return "웹브라우저 없이 공개 봉사기 인터페이스와 직접 통신합니다."
            case .disclaimer3Title: return "자료 내리적재 금지"
            case .disclaimer3Message: return "음악 자료를 내려받거나 저장하지 않습니다."
            case .disclaimer4Title: return "인민보안"
            case .disclaimer4Message: return "분석 도구와 추적기가 없으며 자체의 뒤선 봉사기를 두지 않습니다."
            case .settingsTitle: return "조절부 (당지침)"
            case .aboutSection: return "탐색기에 관하여"
            case .securitySection: return "보안 설정"
            case .licensesTitle: return "허가증"
            case .licensesFooter: return "외부 기여 프로그램은 사용되지 않습네다. 주체박스 자체는 GNU 일반공공허가증 3.0판(GPLv3)에 따라 배포됩네다."
            case .versionTitle: return "판호"
            case .languageSelectTitle: return "조선말 / 외부어 선택"
            case .cancel: return "취소"
            case .doneButton: return "완료"
            case .searchPlaceholder: return "노래, 앨범, 예술가 검색"
            case .playerPlayButton: return "재생"
            case .playerPauseButton: return "중지"
            case .playerNextTrackButton: return "다음곡"
            case .playerPreviousTrackButton: return "이전곡"
            case .playerSeekForward: return "앞으로 넘기기"
            case .playerSeekBackward: return "뒤로 되돌리기"
            case .playerMiniNowPlaying: return "지금련주"
            case .playerNoTrackPlaying: return "련주하고있는 곡이 없습니다"
            case .playerUnknownArtist: return "알려지지 않은 연주자"
            case .playerUnknownTitle: return "알려지지 않은 제목"
            case .tabNowPlaying: return "지금련주"
            case .playerNowPlayingTab: return "지금련주"
            case .playerQueueTab: return "대기렬"
            case .playerShuffle: return "섞어서"
            case .playerRepeat: return "거듭재생"
            case .playerRepeatOne: return "한곡거듭"
            case .playerUpNext: return "다음대기"
            case .playerPlayHistory: return "련주력사"
            case .playerQueueEmpty: return "대기렬이 비여있습니다"
            case .playerHistoryEmpty: return "련주력사가 없습니다"
            case .playerSeekLabel: return "이동"
            case .playerDurationLabel: return "시간"
            case .playerAirplayLabel: return "에어플레이"
            case .playerLockscreenPaused: return "중지됨"
            case .playerArtworkAccessibility: return "음반화상"
            case .tabHome: return "첫페지"
            case .tabBrowse: return "탐색"
            case .tabSearch: return "검색"
            case .tabLibrary: return "음악고"
            case .homePopularSongs: return "인기 노래"
            case .homeNewReleases: return "새로 나온 음반"
            case .homeNewTracks: return "새 노래"
            case .homePopularAlbums: return "인기 음반"
            case .homeSongCount: return "곡"
            case .homeLoadError: return "음악고를 불러올수 없습네다."
            case .retry: return "다시시도"
            case .searchSongs: return "노래"
            case .searchAlbums: return "음반"
            case .searchArtists: return "연주자"
            case .searchPrompt: return "노래, 음반, 연주자 검색"
            case .clearSearch: return "검색 지우기"
            case .playAlbum: return "음반 재생"
            case .librarySignInPrompt: return "접속하면 좋아요, 재생목록, 력사가 동기화됩네다."
            case .librarySignInButton: return "접속"
            case .libraryLikedSongs: return "좋아요한 노래"
            case .libraryRecentlyPlayed: return "최근에 련주한 노래"
            case .libraryPlaylists: return "재생목록"
            case .signInTitle: return "주체음악에 접속"
            case .usernamePlaceholder: return "사용자명"
            case .passwordPlaceholder: return "비밀번호"
            case .signInSubmit: return "접속"
            case .signInFailed: return "접속 실패. 자격증명을 확인하십시요."
            case .signOutButton: return "퇴장"
            case .like: return "좋아요"
            case .unlike: return "좋아요 취소"
            case .playNext: return "다음에 재생"
            case .addToQueue: return "대기렬에 추가"
            case .goToAlbum: return "앨범 보기"
            case .moreActions: return "추가 조작"
            case .songLocked: return "잠김"
            case .seeAll: return "모두 보기"
            case .recentSearches: return "최근 검색"
            case .clearRecents: return "지우기"
            case .libraryEmpty: return "음악고가 비어있습니다"
            case .libraryEmptyHint: return "선호하는 노래와 앨범이 여기에 보존됩니다."
            case .signOutConfirmTitle: return "정말 퇴장하시겠습니까?"
            case .searchNoResults: return "검색 결과 없음"
            case .searchNoResultsHint: return "다른 노래, 음반 또는 예술가를 검색해 보십시오."
            }
        }
    }
}

extension View {
    func t(_ key: Translation.Key, language: AppLanguage) -> String {
        Translation.string(for: key, language: language)
    }
}
