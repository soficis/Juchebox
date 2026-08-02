import Foundation

struct DomainPolicy: Equatable, Sendable {
    private let allowedHosts: Set<String>

    init(allowedHosts: Set<String>) {
        let normalizedHosts = allowedHosts.compactMap(Self.normalizedHost)
        self.allowedHosts = Set(normalizedHosts)
    }

    func decision(for url: URL?, context: NavigationContext = .standard) -> DomainPolicyDecision {
        guard let url else {
            return .block(.missingURL)
        }

        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else {
            return .block(.malformedURL)
        }

        switch scheme {
        case "https":
            return decisionForHTTPS(url)
        case "http":
            return .block(.insecureHTTP)
        case "mailto", "tel", "sms", "maps", "facetime", "facetime-audio":
            return .openExternally(.systemScheme(scheme))
        default:
            return .block(.unsupportedScheme(scheme))
        }
    }

    func decisionForRedirect(to url: URL?) -> DomainPolicyDecision {
        decision(for: url, context: .redirect)
    }

    private func decisionForHTTPS(_ url: URL) -> DomainPolicyDecision {
        guard let host = Self.normalizedHost(url.host) else {
            return .block(.malformedURL)
        }

        if allowedHosts.contains(host) {
            return .allowInApp
        }

        // Subdomains of allowed hosts (e.g. www.juchify.com) load in-app.
        // This must run BEFORE the deception filter, which would otherwise
        // classify any non-allowlisted host containing "juchify" as a lookalike.
        if allowedHosts.contains(where: { host.hasSuffix(".\($0)") }) {
            return .allowInApp
        }

        if Self.isDeceptiveJuchifyHost(host) {
            return .block(.lookalikeHost(host))
        }

        return .openExternally(.externalHTTPSHost(host))
    }

    static func bundled(bundle: Bundle = .main) -> DomainPolicy {
        do {
            return try loadBundled(bundle: bundle)
        } catch {
            fatalError("Invalid domain policy configuration: \(error.localizedDescription)")
        }
    }

    static func loadBundled(bundle: Bundle = .main) throws -> DomainPolicy {
        guard let url = bundle.url(forResource: "domain-allowlist", withExtension: "json") else {
            throw DomainPolicyConfigurationError.missingAllowlist
        }

        let data = try Data(contentsOf: url)
        let configuration = try JSONDecoder().decode(DomainPolicyConfiguration.self, from: data)
        let hosts = Set(configuration.allowedHosts)

        guard !hosts.isEmpty else {
            throw DomainPolicyConfigurationError.emptyAllowlist
        }

        return DomainPolicy(allowedHosts: hosts)
    }

    static func normalizedHost(_ host: String?) -> String? {
        guard var host = host?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !host.isEmpty
        else {
            return nil
        }

        if host.hasSuffix(".") {
            host.removeLast()
        }

        guard !host.isEmpty else {
            return nil
        }

        return host
    }

    private static func isDeceptiveJuchifyHost(_ host: String) -> Bool {
        if host.split(separator: ".").contains(where: { $0.hasPrefix("xn--") }) {
            return true
        }

        return host.contains("juchify")
    }
}

enum NavigationContext: Equatable, Sendable {
    case standard
    case newWindow
    case redirect
}

enum DomainPolicyDecision: Equatable, Sendable {
    case allowInApp
    case openExternally(ExternalNavigationReason)
    case block(BlockedNavigationReason)
}

enum ExternalNavigationReason: Equatable, Sendable {
    case externalHTTPSHost(String)
    case systemScheme(String)

    var primaryActionKey: Translation.Key {
        switch self {
        case .externalHTTPSHost:
            return .openInBrowserButton
        case .systemScheme:
            return .systemSchemeAction
        }
    }

    var messageKey: Translation.Key {
        switch self {
        case .externalHTTPSHost(let host):
            return .externalLinkMessage(host)
        case .systemScheme(let scheme):
            return .systemSchemeMessage(scheme)
        }
    }
}

enum BlockedNavigationReason: Equatable, Sendable {
    case missingURL
    case malformedURL
    case insecureHTTP
    case unsupportedScheme(String)
    case lookalikeHost(String)
    case downloadUnsupported

    var diagnosticCode: Int {
        switch self {
        case .missingURL:
            return 100
        case .malformedURL:
            return 101
        case .insecureHTTP:
            return 102
        case .unsupportedScheme:
            return 103
        case .lookalikeHost:
            return 104
        case .downloadUnsupported:
            return 105
        }
    }

    var titleKey: Translation.Key {
        switch self {
        case .missingURL, .malformedURL:
            return .blockedLinkCannotOpen
        case .insecureHTTP:
            return .blockedTitleInsecureHTTP
        case .unsupportedScheme:
            return .blockedTitleUnsupportedScheme
        case .lookalikeHost:
            return .blockedTitleLookalike
        case .downloadUnsupported:
            return .blockedTitleDownloadUnsupported
        }
    }

    var messageKey: Translation.Key {
        switch self {
        case .missingURL:
            return .blockedMessageMissingURL
        case .malformedURL:
            return .blockedMessageMalformedURL
        case .insecureHTTP:
            return .blockedMessageInsecureHTTP
        case .unsupportedScheme(let scheme):
            return .blockedMessageUnsupportedScheme(scheme)
        case .lookalikeHost(let host):
            return .blockedMessageLookalike(host)
        case .downloadUnsupported:
            return .blockedMessageDownloadUnsupported
        }
    }
}

private struct DomainPolicyConfiguration: Decodable {
    let allowedHosts: [String]
}

enum DomainPolicyConfigurationError: LocalizedError {
    case missingAllowlist
    case emptyAllowlist

    var errorDescription: String? {
        switch self {
        case .missingAllowlist:
            return "domain-allowlist.json is missing from the app bundle."
        case .emptyAllowlist:
            return "domain-allowlist.json must contain at least one allowed host."
        }
    }
}

