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
        case copyUrlButton
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
        case errorTitleBlocked(String)
        case errorTitleDownloadUnsupported
        case errorTitleWebProcessTerminated
        case errorTitleOther
        case errorMessageNoNetwork
        case errorMessageServerUnavailable
        case errorMessageTlsFailure
        case errorMessageCancelled
        case errorMessageBlocked(String)
        case errorMessageDownloadUnsupported
        case errorMessageWebProcessTerminated
        case errorReloadButton
        case toastUrlCopied
        case toastUrlUnavailable
        case toastDataCleared

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
            case .clearDataButton: return "Purge Web Data & Sign Out"
            case .clearDataFooter: return "This clears local Juchify website data held by this app and reloads the home page."
            case .diagnosticsTitle: return "Inspection Settings"
            case .diagnosticsButton: return "Export Inspection Report"
            case .diagnosticsFooter: return "Exports include app version, iOS version, generic device class, timestamp, sanitized host names, numeric error codes, and session mode only."
            case .privacySummaryTitle: return "People's Security Summary"
            case .privacySummaryFooter: return "No analytics, no advertising SDK, no backend, no proxy, no JavaScript bridge, no injected scripts, and no automatic diagnostics upload."
            case .licensesTitle: return "Open Source Licenses"
            case .licensesFooter: return "No third-party dependencies are used in this MVP."
            case .versionTitle: return "Version"
            case .copyUrlButton: return "Copy Current URL"
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
            case .errorTitleBlocked(let reason): return reason
            case .errorTitleDownloadUnsupported: return "Downloads Are Not Supported"
            case .errorTitleWebProcessTerminated: return "Web Content Restarted"
            case .errorTitleOther: return "Page Could Not Load"
            case .errorMessageNoNetwork: return "Connect to a network and reload the page."
            case .errorMessageServerUnavailable: return "The website did not respond successfully. Try again in a moment."
            case .errorMessageTlsFailure: return "iOS could not establish a trusted HTTPS connection."
            case .errorMessageCancelled: return "The page stopped loading before it finished."
            case .errorMessageBlocked(let reason): return reason
            case .errorMessageDownloadUnsupported: return "This companion does not download, save, or expose website files."
            case .errorMessageWebProcessTerminated: return "iOS closed the web process. Reload to start a fresh web view."
            case .errorReloadButton: return "Reload"
            case .toastUrlCopied: return "Current URL copied."
            case .toastUrlUnavailable: return "No page URL is available."
            case .toastDataCleared: return "Website data cleared."
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
            case .clearDataButton: return "자료 정화 및 퇴장"
            case .clearDataFooter: return "이 조작은 응용프로그람에 보관된 국부자료들을 완전히 소거하고 첫 홈페지로 되돌아갑네다."
            case .diagnosticsTitle: return "검열보고"
            case .diagnosticsButton: return "검열보고서 수출"
            case .diagnosticsFooter: return "보고서에는 단말기체계 판호, 요일정보, 소거된 호스트명칭, 오유부호만이 기재됩네다."
            case .privacySummaryTitle: return "인민보안 요약"
            case .privacySummaryFooter: return "선전광고체계 없음, 보이지 않는 대리서버 없음, 그물속임장치 없음, 자동기록송신 없음."
            case .licensesTitle: return "공개원천 프로그램 기여록"
            case .licensesFooter: return "본 체계에는 외부 기여 프로그램이 사용되지 않았습네다."
            case .versionTitle: return "판호"
            case .copyUrlButton: return "현재 그물주소 복사"
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
            case .errorTitleBlocked(let reason): return reason
            case .errorTitleDownloadUnsupported: return "내리적재 미지원"
            case .errorTitleWebProcessTerminated: return "그물열람 처리계통 돌발정지"
            case .errorTitleOther: return "페지 적재 실패"
            case .errorMessageNoNetwork: return "통신망상태를 재검침하고 다시 적재하십시요."
            case .errorMessageServerUnavailable: return "원격 봉사기가 응답하지 않습네다. 잠시후 다시 읽기를 시도하십시요."
            case .errorMessageTlsFailure: return "신뢰할수 있는 암호화통신련결을 수립할수 없습네다."
            case .errorMessageCancelled: return "그물페지 읽어오기가 도중에 중단되었습네다."
            case .errorMessageBlocked(let reason): return reason
            case .errorMessageDownloadUnsupported: return "본 그물열람기는 어떠한 자료의 내리적재나 외부에로의 전송도 지원하지 않습네다."
            case .errorMessageWebProcessTerminated: return "조작계통이 그물열람공정을 강제종료하였습네다. 페지를 다시읽으십시요."
            case .errorReloadButton: return "다시읽기"
            case .toastUrlCopied: return "그물주소가 복제되었습니다."
            case .toastUrlUnavailable: return "유효한 주소가 존재하지 않습네다."
            case .toastDataCleared: return "자료청소가 완료되었습니다."
            }
        }
    }
}

extension View {
    func t(_ key: Translation.Key, language: AppLanguage) -> String {
        Translation.string(for: key, language: language)
    }
}
