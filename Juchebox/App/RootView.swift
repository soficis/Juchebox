import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    let domainPolicy: DomainPolicy
    @ObservedObject var privacySettings: PrivacySettings

    @AppStorage(AppStorageKey.hasAcceptedUnofficialDisclaimer) private var hasAcceptedUnofficialDisclaimer = false
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if hasAcceptedUnofficialDisclaimer {
                TabView(selection: $selectedTab) {
                    WebScreen(
                        appState: appState,
                        audioSessionController: audioSessionController,
                        diagnosticsLog: diagnosticsLog,
                        domainPolicy: domainPolicy,
                        privacySettings: privacySettings
                    )
                    .tabItem {
                        Label(
                            t(.toolbarHome, language: appLanguage),
                            systemImage: selectedTab == 0 ? "globe.americas.fill" : "globe"
                        )
                    }
                    .tag(0)

                    SettingsView(
                        appState: appState,
                        diagnosticsLog: diagnosticsLog,
                        privacySettings: privacySettings
                    )
                    .tabItem {
                        Label(
                            t(.toolbarSettings, language: appLanguage),
                            systemImage: selectedTab == 1 ? "gearshape.fill" : "gearshape"
                        )
                    }
                    .tag(1)
                }
                .tint(AppTheme.secondaryText)
                .toolbarBackground(AppTheme.surface, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            } else {
                OnboardingView {
                    hasAcceptedUnofficialDisclaimer = true
                }
            }
        }
        .background(AppTheme.background)
    }
}


