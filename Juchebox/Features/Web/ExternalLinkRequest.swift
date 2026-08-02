import Foundation

struct ExternalLinkRequest: Identifiable {
    let id = UUID()
    let url: URL
    let reason: ExternalNavigationReason

    var titleKey: Translation.Key {
        .externalLinkTitle
    }

    var messageKey: Translation.Key {
        reason.messageKey
    }

    var primaryActionKey: Translation.Key {
        reason.primaryActionKey
    }
}

