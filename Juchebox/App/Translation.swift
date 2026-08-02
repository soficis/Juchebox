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
        case ephemeralToggle
        case ephemeralFooter
        case ephemeralConfirmationTitle
        case ephemeralConfirmationMessage
        case ephemeralConfirmAction
        case clearDataButton
        case clearDataFooter
        case diagnosticsTitle
        case diagnosticsButton
        case diagnosticsFooter
        case privacySummaryTitle
        case privacySummaryFooter
        case licensesTitle
        case licensesFooter
        case versionTitle
        case openInBrowserButton
        case languageSelectTitle
        case externalLinkTitle
        case externalLinkMessage(String)
        case copyLink
        case cancel
        case errorTitleNoNetwork
        case errorTitleServerUnavailable
        case errorTitleTlsFailure
        case errorTitleCancelled
        case errorTitleDownloadUnsupported
        case errorTitleWebProcessTerminated
        case errorTitleLoadTimeout
        case errorTitleOther
        case errorMessageNoNetwork
        case errorMessageServerUnavailable
        case errorMessageTlsFailure
        case errorMessageCancelled
        case errorMessageDownloadUnsupported
        case errorMessageWebProcessTerminated
        case errorMessageLoadTimeout
        case errorReloadButton
        case toastUrlCopied
        case toastUrlUnavailable
        case toastDataCleared
        case dismissButton
        case okButton
        case doneButton
        case showControlsLabel
        case toolbarBack
        case toolbarForward
        case toolbarReload
        case toolbarHome
        case toolbarShare
        case toolbarSettings
        case toolbarHideControls
        case systemSchemeAction
        case systemSchemeMessage(String)
        case blockedLinkCannotOpen
        case blockedTitleInsecureHTTP
        case blockedTitleUnsupportedScheme
        case blockedTitleLookalike
        case blockedTitleDownloadUnsupported
        case blockedMessageMissingURL
        case blockedMessageMalformedURL
        case blockedMessageInsecureHTTP
        case blockedMessageUnsupportedScheme(String)
        case blockedMessageLookalike(String)
        case blockedMessageDownloadUnsupported
        case searchButton
        case searchPlaceholder
        case searchGo
        case saveButton
        case toastPageSaved
        case toastNoPageToSave

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

        var englishValue: String {
            switch self {
            case .appName: return "Juchebox"
            case .subtitle: return "The People's Revolutionary Music Explorer"
            case .acceptButton: return "Forward!"
            case .disclaimer1Title: return "Self-Reliant & Independent App"
            case .disclaimer1Message: return "This app is not affiliated with or endorsed by Juchify, Chollima Front, or any music rightsholder."
            case .disclaimer2Title: return "Revolutionary Web Exploration"
            case .disclaimer2Message: return "Opens the public website in WebKit without changing its behavior."
            case .disclaimer3Title: return "Material Protection"
            case .disclaimer3Message: return "Does not download, record, extract, cache, or redistribute tracks."
            case .disclaimer4Title: return "People's Security"
            case .disclaimer4Message: return "No analytics SDK, backend, proxy, JavaScript bridge, or trackers."
            case .settingsTitle: return "Party Directives"
            case .aboutSection: return "About the Explorer"
            case .securitySection: return "Security Settings"
            case .ephemeralToggle: return "Use Ephemeral Session"
            case .ephemeralFooter: return "Persistent sessions can keep you signed in through WebKit. Ephemeral sessions may not keep sign-in or website data after the app closes."
            case .ephemeralConfirmationTitle: return "Sign Out of Juchify?"
            case .ephemeralConfirmationMessage: return "Switching to an ephemeral session signs you out of Juchify and stops any playing audio. Continue?"
            case .ephemeralConfirmAction: return "Use Ephemeral Session"
            case .clearDataButton: return "Purge Web Data & Sign Out"
            case .clearDataFooter: return "This clears local Juchify website data held by this app and reloads the home page."
            case .diagnosticsTitle: return "Inspection Settings"
            case .diagnosticsButton: return "Export Inspection Report"
            case .diagnosticsFooter: return "Exports include app version, iOS version, generic device class, timestamp, sanitized host names, numeric error codes, and session mode only."
            case .privacySummaryTitle: return "People's Security Summary"
            case .privacySummaryFooter: return "No analytics, no advertising SDK, no backend, no proxy, no JavaScript bridge, no injected scripts, and no automatic diagnostics upload."
            case .licensesTitle: return "License"
            case .licensesFooter: return "No third-party dependencies are used. Juchebox itself is released under the GNU General Public License v3.0 (GPLv3)."
            case .versionTitle: return "Version"
            case .openInBrowserButton: return "Open in External Web Browser"
            case .languageSelectTitle: return "Language Selection"
            case .externalLinkTitle: return "Open Outside App?"
            case .externalLinkMessage(let host): return "\(host) is outside the in-app allowlist."
            case .copyLink: return "Copy Link"
            case .cancel: return "Cancel"
            case .errorTitleNoNetwork: return "No Network Connection"
            case .errorTitleServerUnavailable: return "Website Unavailable"
            case .errorTitleTlsFailure: return "Secure Connection Failed"
            case .errorTitleCancelled: return "Navigation Canceled"
            case .errorTitleDownloadUnsupported: return "Downloads Are Not Supported"
            case .errorTitleWebProcessTerminated: return "Web Content Restarted"
            case .errorTitleLoadTimeout: return "Page Load Timed Out"
            case .errorTitleOther: return "Page Could Not Load"
            case .errorMessageNoNetwork: return "Connect to a network and reload the page."
            case .errorMessageServerUnavailable: return "The website did not respond successfully. Try again in a moment."
            case .errorMessageTlsFailure: return "iOS could not establish a trusted HTTPS connection."
            case .errorMessageCancelled: return "The page stopped loading before it finished."
            case .errorMessageDownloadUnsupported: return "This companion does not download, save, or expose website files."
            case .errorMessageWebProcessTerminated: return "iOS closed the web process. Reload to start a fresh web view."
            case .errorMessageLoadTimeout: return "The page took too long to load. Check your connection and try again."
            case .errorReloadButton: return "Reload"
            case .toastUrlCopied: return "Current URL copied."
            case .toastUrlUnavailable: return "No page URL is available."
            case .toastDataCleared: return "Website data cleared."
            case .dismissButton: return "Dismiss"
            case .okButton: return "OK"
            case .doneButton: return "Done"
            case .showControlsLabel: return "Show Controls"
            case .toolbarBack: return "Back"
            case .toolbarForward: return "Forward"
            case .toolbarReload: return "Reload"
            case .toolbarHome: return "Home"
            case .toolbarShare: return "Share Current Page"
            case .toolbarSettings: return "Settings"
            case .toolbarHideControls: return "Hide Controls"
            case .systemSchemeAction: return "Open with System"
            case .systemSchemeMessage(let scheme): return "\(scheme): links open outside the companion."
            case .blockedLinkCannotOpen: return "This Link Cannot Open"
            case .blockedTitleInsecureHTTP: return "Insecure Link Blocked"
            case .blockedTitleUnsupportedScheme: return "Unsupported Link Blocked"
            case .blockedTitleLookalike: return "Lookalike Site Blocked"
            case .blockedTitleDownloadUnsupported: return "Downloads Are Not Supported"
            case .blockedMessageMissingURL: return "The website tried to open a link without a valid address."
            case .blockedMessageMalformedURL: return "The website tried to open a malformed address."
            case .blockedMessageInsecureHTTP: return "This companion only allows secure HTTPS browsing."
            case .blockedMessageUnsupportedScheme(let scheme): return "\(scheme): links are not supported by this companion."
            case .blockedMessageLookalike(let host): return "\(host) resembles the allowed site but is not approved."
            case .blockedMessageDownloadUnsupported: return "This companion does not download, save, or expose website files."
            case .searchButton: return "Search"
            case .searchPlaceholder: return "Search or enter address"
            case .searchGo: return "Go"
            case .saveButton: return "Save Page"
            case .toastPageSaved: return "Page saved."
            case .toastNoPageToSave: return "No page to save."
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
            }
        }

        var koreanValue: String {
            switch self {
            case .appName: return "주체박스 (주체음악)"
            case .subtitle: return "인민의 혁명적 음악 탐색기"
            case .acceptButton: return "리해하였으며 전진합네다!"
            case .disclaimer1Title: return "자주적이며 독립적인 응용프로그람"
            case .disclaimer1Message: return "본 프로그람은 주체음악 보급을 위한 자주적이며 독립적인 응용프로그람올시다."
            case .disclaimer2Title: return "그물페지 직접열람"
            case .disclaimer2Message: return "본 프로그람은 외부 콤퓨터망 페지를 직접 화면에 띄우며, 어떠한 조작행위도 가하지 않습네다."
            case .disclaimer3Title: return "자료 내리적재 금지"
            case .disclaimer3Message: return "곡이나 화상자료를 보관하거나 배포하지 않습네다."
            case .disclaimer4Title: return "인민보안"
            case .disclaimer4Message: return "자료 보관기능이나 자동적인 진단 전송 기능은 존재하지 않습네다."
            case .settingsTitle: return "조절부 (당지침)"
            case .aboutSection: return "탐색기에 관하여"
            case .securitySection: return "보안 설정"
            case .ephemeralToggle: return "일시적접속 사용"
            case .ephemeralFooter: return "지속적접속에서는 누리망을 통하여 자동접속 상태를 유지할수 있습네다. 일시적접속에서는 프로그램이 닫긴 후에 어떠한 접속기록이나 조작자료도 남지 않습네다."
            case .ephemeralConfirmationTitle: return "주체음악에서 퇴장하시겠습니까?"
            case .ephemeralConfirmationMessage: return "일시적접속으로 전환하면 주체음악에서 퇴장되며 재생중인 음악이 중지됩네다. 계속하시겠습니까?"
            case .ephemeralConfirmAction: return "일시적접속 사용"
            case .clearDataButton: return "자료 정화 및 퇴장"
            case .clearDataFooter: return "이 조작은 응용프로그람에 보관된 국부자료들을 완전히 소거하고 첫 홈페지로 되돌아갑네다."
            case .diagnosticsTitle: return "검열보고"
            case .diagnosticsButton: return "검열보고서 수출"
            case .diagnosticsFooter: return "보고서에는 단말기체계 판호, 요일정보, 소거된 호스트명칭, 오유부호만이 기재됩네다."
            case .privacySummaryTitle: return "인민보안 요약"
            case .privacySummaryFooter: return "선전광고체계 없음, 보이지 않는 대리서버 없음, 그물속임장치 없음, 자동기록송신 없음."
            case .licensesTitle: return "허가증"
            case .licensesFooter: return "외부 기여 프로그램은 사용되지 않습네다. 주체박스 자체는 GNU 일반공공허가증 3.0판(GPLv3)에 따라 배포됩네다."
            case .versionTitle: return "판호"
            case .openInBrowserButton: return "외부 그물열람기에서 열기"
            case .languageSelectTitle: return "조선말 / 외부어 선택"
            case .externalLinkTitle: return "응용 외부에서 열기?"
            case .externalLinkMessage(let host): return "\(host) 주소는 내부 허용명단에 등록되어있지 않습네다."
            case .copyLink: return "주소 복제"
            case .cancel: return "취소"
            case .errorTitleNoNetwork: return "통신망 련결 오유"
            case .errorTitleServerUnavailable: return "콤퓨터망 봉사기 련결실패"
            case .errorTitleTlsFailure: return "보안성련결 구축 실패"
            case .errorTitleCancelled: return "사용자에 의한 적재 중지"
            case .errorTitleDownloadUnsupported: return "내리적재 미지원"
            case .errorTitleWebProcessTerminated: return "그물열람 처리계통 돌발정지"
            case .errorTitleLoadTimeout: return "페지 적재 시간초과"
            case .errorTitleOther: return "페지 적재 실패"
            case .errorMessageNoNetwork: return "통신망상태를 재검침하고 다시 적재하십시요."
            case .errorMessageServerUnavailable: return "원격 봉사기가 응답하지 않습네다. 잠시후 다시 읽기를 시도하십시요."
            case .errorMessageTlsFailure: return "신뢰할수 있는 암호화통신련결을 수립할수 없습네다."
            case .errorMessageCancelled: return "그물페지 읽어오기가 도중에 중단되었습네다."
            case .errorMessageDownloadUnsupported: return "본 그물열람기는 어떠한 자료의 내리적재나 외부에로의 전송도 지원하지 않습네다."
            case .errorMessageWebProcessTerminated: return "조작계통이 그물열람공정을 강제종료하였습네다. 페지를 다시읽으십시요."
            case .errorMessageLoadTimeout: return "페지 적재 시간이 초과되었습네다. 련결상태를 검침하고 다시 시도하십시요."
            case .errorReloadButton: return "다시읽기"
            case .toastUrlCopied: return "그물주소가 복제되었습니다."
            case .toastUrlUnavailable: return "유효한 주소가 존재하지 않습네다."
            case .toastDataCleared: return "자료청소가 완료되었습니다."
            case .dismissButton: return "소거"
            case .okButton: return "확인"
            case .doneButton: return "완료"
            case .showControlsLabel: return "조절기 표시"
            case .toolbarBack: return "뒤로가기"
            case .toolbarForward: return "앞으로가기"
            case .toolbarReload: return "다시읽기"
            case .toolbarHome: return "홈페지"
            case .toolbarShare: return "페지 공동리용"
            case .toolbarSettings: return "조절부"
            case .toolbarHideControls: return "조절기 숨기기"
            case .systemSchemeAction: return "조작체계에서 열기"
            case .systemSchemeMessage(let scheme): return "\(scheme): 주소는 응용 외부에서 열기 전용올시다."
            case .blockedLinkCannotOpen: return "그물주소 개방 실패"
            case .blockedTitleInsecureHTTP: return "불안전한 련결 차단됨"
            case .blockedTitleUnsupportedScheme: return "미지원 련결 차단됨"
            case .blockedTitleLookalike: return "위장 그물페지 차단됨"
            case .blockedTitleDownloadUnsupported: return "내리적재 미지원"
            case .blockedMessageMissingURL: return "그물주소가 존재하지 않거나 유효하지 않습네다."
            case .blockedMessageMalformedURL: return "그물주소 구성 형식이 올바르지 않습네다."
            case .blockedMessageInsecureHTTP: return "본 그물열람기는 오직 안전한 HTTPS 암호화련결만을 허용합네다."
            case .blockedMessageUnsupportedScheme(let scheme): return "\(scheme): 련결방식은 지원되지 않습네다."
            case .blockedMessageLookalike(let host): return "\(host) 주소는 위장된 위조페지일 위험이 존재합네다."
            case .blockedMessageDownloadUnsupported: return "본 열람기에서는 곡이나 화상자료를 보관하거나 배포하지 않습네다."
            case .searchButton: return "검색"
            case .searchPlaceholder: return "검색 또는 주소 입력"
            case .searchGo: return "이동"
            case .saveButton: return "페지 보관"
            case .toastPageSaved: return "페지가 보관되었습니다."
            case .toastNoPageToSave: return "보관할 페지가 없습네다."
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
            }
        }
    }
}

extension View {
    func t(_ key: Translation.Key, language: AppLanguage) -> String {
        Translation.string(for: key, language: language)
    }
}
