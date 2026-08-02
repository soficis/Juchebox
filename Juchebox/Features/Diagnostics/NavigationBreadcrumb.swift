import Foundation

/// Host name guaranteed to be sanitized at the type level.
///
/// Construction is the only place a URL may be read; the stored value is
/// always the normalized host (no scheme, path, query, or fragment), so a
/// full URL can never leak into diagnostics by accident.
struct SanitizedHost: Equatable, Sendable, CustomStringConvertible {
    let value: String

    init?(from url: URL?) {
        guard let host = DomainPolicy.normalizedHost(url?.host) else {
            return nil
        }
        value = host
    }

    var description: String { value }
}

/// A privacy-safe record of one navigation lifecycle event.
struct NavigationBreadcrumb: Identifiable, Equatable, Sendable {
    let id = UUID()
    let timestamp: Date
    let event: Event
    let sanitizedHost: SanitizedHost?
    let sessionMode: PrivacySettings.SessionMode

    enum Event: Equatable, Sendable {
        case navigateStarted
        case provisionalNavigationStarted
        case didCommit
        case didFinish
        case didFail(domain: String, code: Int)
        case webProcessTerminated
    }

    var redactedDescription: String {
        let time = ISO8601DateFormatter().string(from: timestamp)
        let hostText = sanitizedHost.map { "host=\($0.value)" } ?? "host=none"
        let sessionText = "session=\(sessionMode.rawValue)"

        switch event {
        case .navigateStarted:
            return "- \(time) event=navigateStarted \(hostText) \(sessionText)"
        case .provisionalNavigationStarted:
            return "- \(time) event=provisionalNavigationStarted \(hostText) \(sessionText)"
        case .didCommit:
            return "- \(time) event=didCommit \(hostText) \(sessionText)"
        case .didFinish:
            return "- \(time) event=didFinish \(hostText) \(sessionText)"
        case .didFail(let domain, let code):
            return "- \(time) event=didFail domain=\(domain) code=\(code) \(hostText) \(sessionText)"
        case .webProcessTerminated:
            return "- \(time) event=webProcessTerminated \(hostText) \(sessionText)"
        }
    }
}
