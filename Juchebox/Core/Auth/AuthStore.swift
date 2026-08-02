import Foundation
import Security

/// Stores the Juchify auth token in the iOS Keychain and exposes it to the
/// API client. `@MainActor`-safe for SwiftUI binding; the token getter itself
/// is synchronous and thread-safe.
@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var user: AuthUser?

    private let service = "dev.local.Juchebox.auth"

    init() {
        token = Self.loadToken(service: service)
    }

    var isAuthenticated: Bool { token != nil }

    /// Closure handed to `JuchifyAPIClient` for the Authorization header.
    nonisolated func tokenProvider() -> String? {
        // Keychain read is thread-safe; mirror the in-memory token for hot path.
        Self.loadToken(service: service)
    }

    func setAuthenticated(token: String, user: AuthUser?) {
        self.token = token
        self.user = user
        Self.saveToken(token, service: service)
    }

    func signOut() {
        token = nil
        user = nil
        Self.deleteToken(service: service)
    }

    // MARK: - Keychain

    private static func loadToken(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToken(_ token: String, service: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func deleteToken(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
