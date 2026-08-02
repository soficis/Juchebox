import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    let domainPolicy: DomainPolicy
    @ObservedObject var privacySettings: PrivacySettings

    @AppStorage(AppStorageKey.hasAcceptedUnofficialDisclaimer) private var hasAcceptedUnofficialDisclaimer = false

    var body: some View {
        Group {
            if hasAcceptedUnofficialDisclaimer {
                WebScreen(
                    appState: appState,
                    audioSessionController: audioSessionController,
                    diagnosticsLog: diagnosticsLog,
                    domainPolicy: domainPolicy,
                    privacySettings: privacySettings
                )
            } else {
                OnboardingView {
                    hasAcceptedUnofficialDisclaimer = true
                }
            }
        }
        .background(AppTheme.background)
    }
}


