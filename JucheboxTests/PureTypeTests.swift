import XCTest
@testable import Juchebox

final class PureTypeTests: XCTestCase {
    func testAccessibilityIdentifiersAreNonEmptyAndUnique() {
        let identifiers: [String] = [
            AccessibilityID.onboardingAcceptButton,
            AccessibilityID.nowPlayingTab,
            AccessibilityID.homeTab,
            AccessibilityID.searchTab,
            AccessibilityID.libraryTab,
            AccessibilityID.settingsTab,
            AccessibilityID.searchField,
            AccessibilityID.signInButton,
            AccessibilityID.usernameField,
            AccessibilityID.passwordField,
            AccessibilityID.signInSubmitButton,
            AccessibilityID.playAlbumButton,
        ]

        XCTAssertEqual(identifiers.count, Set(identifiers).count, "Accessibility identifiers must be unique")
        for identifier in identifiers {
            XCTAssertFalse(identifier.isEmpty)
        }
    }

    func testAppLanguageRawValues() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.allCases.count, 1)
    }

    func testAppLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName(currentLanguage: .english), "English")
    }

    func testAppStorageKeysExist() {
        XCTAssertFalse(AppStorageKey.hasAcceptedUnofficialDisclaimer.isEmpty)
        XCTAssertFalse(AppStorageKey.appLanguage.isEmpty)
        XCTAssertNotEqual(AppStorageKey.hasAcceptedUnofficialDisclaimer, AppStorageKey.appLanguage)
    }

    func testAppStorageRecentSearchesKeyValue() {
        XCTAssertEqual(AppStorageKey.recentSearches, "recentSearches")
    }

    func testSongDurationFormatted() {
        let song = Song(id: 1, title: "T", trackNumber: nil, duration: 247,
                        filePath: nil, hlsPath: nil, artistID: nil, artistName: nil,
                        artistNames: nil, albumID: nil, albumTitle: nil, albumNames: nil,
                        coverPath: nil, titles: nil, playCount: nil, artists: nil)
        XCTAssertEqual(song.durationFormatted, "4:07")

        let zero = Song(id: 2, title: "Z", trackNumber: nil, duration: nil,
                        filePath: nil, hlsPath: nil, artistID: nil, artistName: nil,
                        artistNames: nil, albumID: nil, albumTitle: nil, albumNames: nil,
                        coverPath: nil, titles: nil, playCount: nil, artists: nil)
        XCTAssertEqual(zero.durationFormatted, "--:--")
    }

    func testSongStreamURLBuildsFromFilePath() {
        let song = Song(id: 3, title: "S", trackNumber: nil, duration: 100,
                        filePath: "/uploads/audio-123.mp3", hlsPath: nil,
                        artistID: nil, artistName: nil, artistNames: nil,
                        albumID: nil, albumTitle: nil, albumNames: nil,
                        coverPath: nil, titles: nil, playCount: nil, artists: nil)
        XCTAssertEqual(song.streamURL?.absoluteString, "https://juchify.com/uploads/audio-123.mp3")
    }

    func testMediaURLProxiedPath() {
        XCTAssertEqual(JuchifyMediaURL.proxiedPath("/album/650"), "/api/proxy/album/650")
        XCTAssertEqual(JuchifyMediaURL.proxiedPath("album/650"), "/api/proxy/album/650")
        XCTAssertEqual(JuchifyMediaURL.proxiedPath("/api/playlist/8654"), "/api/proxy/playlist/8654")
    }

    func testMediaURLCoverUploadsConvertsToWebp() {
        let url = JuchifyMediaURL.coverURL(path: "/uploads/album_715_0bda5b01.png", albumID: 715, size: 320)
        XCTAssertEqual(url?.absoluteString, "https://juchify.com/uploads/album_715_0bda5b01.webp?w=320")
    }

    func testMediaURLCoverLegacySongCoverUsesAlbumCoversPattern() {
        let url = JuchifyMediaURL.coverURL(path: "storage/track_image_media/afcf8ceb.png", albumID: 29)
        XCTAssertEqual(url?.absoluteString, "https://juchify.com/storage/album_covers/album_29_afcf8ceb.webp")
    }

    func testMediaURLCoverStorageConvertsToWebp() {
        let url = JuchifyMediaURL.coverURL(path: "storage/artist_photos/photo.jpg")
        XCTAssertEqual(url?.absoluteString, "https://juchify.com/storage/artist_photos/photo.webp")
    }

    func testMediaURLCoverJpegExtension() {
        let url = JuchifyMediaURL.coverURL(path: "/uploads/cover.jpeg")
        XCTAssertEqual(url?.absoluteString, "https://juchify.com/uploads/cover.webp")
    }

    func testMediaURLAudioURL() {
        XCTAssertEqual(
            JuchifyMediaURL.audioURL(filePath: "storage/track_media/abc.mp3")?.absoluteString,
            "https://juchify.com/storage/track_media/abc.mp3"
        )
        XCTAssertEqual(
            JuchifyMediaURL.audioURL(filePath: "/uploads/audio-1.mp3")?.absoluteString,
            "https://juchify.com/uploads/audio-1.mp3"
        )
        XCTAssertNil(JuchifyMediaURL.audioURL(filePath: nil))
        XCTAssertNil(JuchifyMediaURL.audioURL(filePath: ""))
    }

    func testMediaURLHLSURL() {
        XCTAssertEqual(
            JuchifyMediaURL.hlsURL(hlsPath: "/api/playlist/8654")?.absoluteString,
            "https://juchify.com/api/proxy/playlist/8654"
        )
        XCTAssertNil(JuchifyMediaURL.hlsURL(hlsPath: nil))
    }

    func testLocalizedNamesValueForLanguage() {
        let names = LocalizedNames(en: "We Are Koreans", kp: "우리는 조선사람")
        XCTAssertEqual(names.value(for: .english), "We Are Koreans")

        let fallbackNames = LocalizedNames(en: nil, kp: "우리는 조선사람")
        XCTAssertEqual(fallbackNames.value(for: .english), "우리는 조선사람")
    }

    func testSearchURLPercentEncodesQuerySpecialCharacters() {
        // A query containing "&" must stay a single q= value (%26), not split
        // into extra URL parameters (SECURITY-AUDIT F3).
        let url = JuchifyAPIClient.searchURL(query: "rock & roll", language: .english, page: 1)
        XCTAssertEqual(
            url?.absoluteString,
            "https://juchify.com/api/proxy/search?q=rock%20%26%20roll&lang=en&page=1"
        )
    }

    func testSearchURLQueryCannotOverridePageOrLanguage() {
        // Crafted query content like "&lang=kp&page=999" stays inside q; the
        // client's lang/page values win.
        let url = JuchifyAPIClient.searchURL(query: "x&lang=kp&page=999", language: .english, page: 1)
        XCTAssertEqual(
            url?.absoluteString,
            "https://juchify.com/api/proxy/search?q=x%26lang%3Dkp%26page%3D999&lang=en&page=1"
        )
    }

    func testMediaURLCoverAllowsJuchifyAbsoluteHost() {
        let url = JuchifyMediaURL.coverURL(path: "https://juchify.com/storage/album_covers/album_29_afcf8ceb.webp", albumID: 29)
        XCTAssertEqual(url?.absoluteString, "https://juchify.com/storage/album_covers/album_29_afcf8ceb.webp")
    }

    func testMediaURLCoverRejectsForeignAbsoluteHost() {
        XCTAssertNil(JuchifyMediaURL.coverURL(path: "https://evil.example/tracker.png"))
        XCTAssertNil(JuchifyMediaURL.coverURL(path: "https://juchify.com.evil.example/tracker.png"))
    }
}
