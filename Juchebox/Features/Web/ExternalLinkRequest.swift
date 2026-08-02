import Foundation

struct ExternalLinkRequest: Identifiable {
    let id = UUID()
    let url: URL
    let reason: ExternalNavigationReason

    func title(language: AppLanguage) -> String {
        language == .korean ? "응용 외부에서 열기?" : "Open Outside App?"
    }

    func message(language: AppLanguage) -> String {
        reason.message(language: language)
    }

    func primaryActionTitle(language: AppLanguage) -> String {
        reason.primaryActionTitle(language: language)
    }
}

