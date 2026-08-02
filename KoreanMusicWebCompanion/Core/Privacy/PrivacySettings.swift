import Foundation

@MainActor
final class PrivacySettings: ObservableObject {
    enum SessionMode: String {
        case persistent
        case ephemeral
    }

    @Published var isEphemeralSession: Bool {
        didSet {
            defaults.set(isEphemeralSession, forKey: Self.ephemeralSessionKey)
        }
    }

    var sessionMode: SessionMode {
        isEphemeralSession ? .ephemeral : .persistent
    }

    private static let ephemeralSessionKey = "isEphemeralSession"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEphemeralSession = defaults.bool(forKey: Self.ephemeralSessionKey)
    }
}

