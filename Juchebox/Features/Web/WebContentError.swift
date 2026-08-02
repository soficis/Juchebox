import Foundation

enum WebContentError: Equatable, Identifiable {
    case noNetwork
    case serverUnavailable
    case tlsFailure
    case navigationCancelled
    case loginPageFailure
    case blocked(BlockedNavigationReason)
    case downloadUnsupported
    case webProcessTerminated
    case other(String)

    var id: String {
        title(language: .english) + message(language: .english)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .noNetwork:
            return Translation.string(for: .errorTitleNoNetwork, language: language)
        case .serverUnavailable:
            return Translation.string(for: .errorTitleServerUnavailable, language: language)
        case .tlsFailure:
            return Translation.string(for: .errorTitleTlsFailure, language: language)
        case .navigationCancelled:
            return Translation.string(for: .errorTitleCancelled, language: language)
        case .loginPageFailure:
            return Translation.string(for: .errorTitleOther, language: language)
        case .blocked(let reason):
            return reason.title(language: language)
        case .downloadUnsupported:
            return Translation.string(for: .errorTitleDownloadUnsupported, language: language)
        case .webProcessTerminated:
            return Translation.string(for: .errorTitleWebProcessTerminated, language: language)
        case .other:
            return Translation.string(for: .errorTitleOther, language: language)
        }
    }

    func message(language: AppLanguage) -> String {
        switch self {
        case .noNetwork:
            return Translation.string(for: .errorMessageNoNetwork, language: language)
        case .serverUnavailable:
            return Translation.string(for: .errorMessageServerUnavailable, language: language)
        case .tlsFailure:
            return Translation.string(for: .errorMessageTlsFailure, language: language)
        case .navigationCancelled:
            return Translation.string(for: .errorMessageCancelled, language: language)
        case .loginPageFailure:
            return Translation.string(for: .errorMessageServerUnavailable, language: language)
        case .blocked(let reason):
            return reason.message(language: language)
        case .downloadUnsupported:
            return Translation.string(for: .errorMessageDownloadUnsupported, language: language)
        case .webProcessTerminated:
            return Translation.string(for: .errorMessageWebProcessTerminated, language: language)
        case .other(let detail):
            return detail
        }
    }

    var diagnosticDomain: String {
        switch self {
        case .blocked:
            return "DomainPolicy"
        default:
            return NSURLErrorDomain
        }
    }

    var diagnosticCode: Int {
        switch self {
        case .noNetwork:
            return NSURLErrorNotConnectedToInternet
        case .serverUnavailable:
            return NSURLErrorCannotConnectToHost
        case .tlsFailure:
            return NSURLErrorSecureConnectionFailed
        case .navigationCancelled:
            return NSURLErrorCancelled
        case .loginPageFailure:
            return NSURLErrorCannotLoadFromNetwork
        case .blocked(let reason):
            return reason.diagnosticCode
        case .downloadUnsupported:
            return BlockedNavigationReason.downloadUnsupported.diagnosticCode
        case .webProcessTerminated:
            return 200
        case .other:
            return NSURLErrorUnknown
        }
    }

    static func from(error: Error, failingURL: URL?) -> WebContentError {
        let nsError = error as NSError

        guard nsError.domain == NSURLErrorDomain else {
            return .other("The page failed with error code \(nsError.code).")
        }

        if failingURL?.path.localizedCaseInsensitiveContains("login") == true {
            return .loginPageFailure
        }

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .noNetwork
        case NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
            return .serverUnavailable
        case NSURLErrorSecureConnectionFailed,
             NSURLErrorServerCertificateHasBadDate,
             NSURLErrorServerCertificateUntrusted,
             NSURLErrorServerCertificateHasUnknownRoot,
             NSURLErrorServerCertificateNotYetValid,
             NSURLErrorClientCertificateRejected,
             NSURLErrorClientCertificateRequired:
            return .tlsFailure
        case NSURLErrorCancelled:
            return .navigationCancelled
        default:
            return .other("The page failed with error code \(nsError.code).")
        }
    }
}

