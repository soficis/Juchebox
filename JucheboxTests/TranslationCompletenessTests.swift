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

    func testAssociatedValueKeysHaveBothLanguages() {
        XCTAssertFalse(Translation.string(for: .externalLinkMessage("example.com"), language: .english).isEmpty)
        XCTAssertFalse(Translation.string(for: .externalLinkMessage("example.com"), language: .korean).isEmpty)
        XCTAssertFalse(Translation.string(for: .systemSchemeMessage("mailto"), language: .english).isEmpty)
        XCTAssertFalse(Translation.string(for: .systemSchemeMessage("mailto"), language: .korean).isEmpty)
        XCTAssertFalse(Translation.string(for: .blockedMessageUnsupportedScheme("ftp"), language: .english).isEmpty)
        XCTAssertFalse(Translation.string(for: .blockedMessageUnsupportedScheme("ftp"), language: .korean).isEmpty)
        XCTAssertFalse(Translation.string(for: .blockedMessageLookalike("juchify-fake.com"), language: .english).isEmpty)
        XCTAssertFalse(Translation.string(for: .blockedMessageLookalike("juchify-fake.com"), language: .korean).isEmpty)
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
        .ephemeralToggle, .ephemeralFooter,
        .ephemeralConfirmationTitle, .ephemeralConfirmationMessage, .ephemeralConfirmAction,
        .clearDataButton, .clearDataFooter,
        .diagnosticsTitle, .diagnosticsButton, .diagnosticsFooter,
        .privacySummaryTitle, .privacySummaryFooter,
        .licensesTitle, .licensesFooter,
        .versionTitle,
        .openInBrowserButton, .languageSelectTitle, .externalLinkTitle,
        .copyLink, .cancel,
        .errorTitleNoNetwork, .errorTitleServerUnavailable, .errorTitleTlsFailure,
        .errorTitleCancelled, .errorTitleDownloadUnsupported, .errorTitleWebProcessTerminated,
        .errorTitleLoadTimeout, .errorTitleOther,
        .errorMessageNoNetwork, .errorMessageServerUnavailable, .errorMessageTlsFailure,
        .errorMessageCancelled, .errorMessageDownloadUnsupported, .errorMessageWebProcessTerminated,
        .errorMessageLoadTimeout,
        .errorReloadButton,
        .toastUrlCopied, .toastUrlUnavailable, .toastDataCleared,
        .dismissButton, .okButton, .doneButton, .showControlsLabel,
        .toolbarBack, .toolbarForward, .toolbarReload, .toolbarHome,
        .toolbarShare, .toolbarSettings, .toolbarHideControls,
        .systemSchemeAction,
        .blockedLinkCannotOpen, .blockedTitleInsecureHTTP, .blockedTitleUnsupportedScheme,
        .blockedTitleLookalike, .blockedTitleDownloadUnsupported,
        .blockedMessageMissingURL, .blockedMessageMalformedURL, .blockedMessageInsecureHTTP,
        .blockedMessageDownloadUnsupported,
        .searchButton, .searchPlaceholder, .searchGo,
        .saveButton, .toastPageSaved, .toastNoPageToSave,
    ]
}
