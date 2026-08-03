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
        XCTAssertEqual(AppLanguage.korean.rawValue, "kp")
        XCTAssertEqual(AppLanguage.allCases.count, 2)
    }

    func testAppLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName(currentLanguage: .english), "English")
        XCTAssertEqual(AppLanguage.korean.displayName(currentLanguage: .english), "조선말")
        XCTAssertEqual(AppLanguage.english.displayName(currentLanguage: .korean), "미제승냥이말")
    }

    func testAppStorageKeysExist() {
        XCTAssertFalse(AppStorageKey.hasAcceptedUnofficialDisclaimer.isEmpty)
        XCTAssertFalse(AppStorageKey.appLanguage.isEmpty)
        XCTAssertNotEqual(AppStorageKey.hasAcceptedUnofficialDisclaimer, AppStorageKey.appLanguage)
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
        XCTAssertEqual(names.value(for: .korean), "우리는 조선사람")
    }
}
