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

    func primaryActionTitle(language: AppLanguage) -> String {
        switch self {
        case .externalHTTPSHost:
            return language == .korean ? "외부 그물열람기에서 열기" : "Open in External Web Browser"
        case .systemScheme:
            return language == .korean ? "조작체계에서 열기" : "Open with System"
        }
    }

    func message(language: AppLanguage) -> String {
        switch self {
        case .externalHTTPSHost(let host):
            return language == .korean ? "\(host) 주소는 내부 허용명단에 등록되어있지 않습네다." : "\(host) is outside the in-app allowlist."
        case .systemScheme(let scheme):
            return language == .korean ? "\(scheme): 주소는 응용 외부에서 열기 전용올시다." : "\(scheme): links open outside the companion."
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

    func title(language: AppLanguage) -> String {
        switch self {
        case .missingURL, .malformedURL:
            return language == .korean ? "그물주소 개방 실패" : "This Link Cannot Open"
        case .insecureHTTP:
            return language == .korean ? "불안전한 련결 차단됨" : "Insecure Link Blocked"
        case .unsupportedScheme:
            return language == .korean ? "미지원 련결 차단됨" : "Unsupported Link Blocked"
        case .lookalikeHost:
            return language == .korean ? "위장 그물페지 차단됨" : "Lookalike Site Blocked"
        case .downloadUnsupported:
            return language == .korean ? "내리적재 미지원" : "Downloads Are Not Supported"
        }
    }

    func message(language: AppLanguage) -> String {
        switch self {
        case .missingURL:
            return language == .korean ? "그물주소가 존재하지 않거나 유효하지 않습네다." : "The website tried to open a link without a valid address."
        case .malformedURL:
            return language == .korean ? "그물주소 구성 형식이 올바르지 않습네다." : "The website tried to open a malformed address."
        case .insecureHTTP:
            return language == .korean ? "본 그물열람기는 오직 안전한 HTTPS 암호화련결만을 허용합네다." : "This companion only allows secure HTTPS browsing."
        case .unsupportedScheme(let scheme):
            return language == .korean ? "\(scheme): 련결방식은 지원되지 않습네다." : "\(scheme): links are not supported by this companion."
        case .lookalikeHost(let host):
            return language == .korean ? "\(host) 주소는 위장된 위조페지일 위험이 존재합네다." : "\(host) resembles the allowed site but is not approved."
        case .downloadUnsupported:
            return language == .korean ? "본 열람기에서는 곡이나 화상자료를 보관하거나 배포하지 않습네다." : "This companion does not download, save, or expose website files."
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

