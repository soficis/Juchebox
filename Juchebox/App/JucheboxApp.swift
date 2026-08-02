import SwiftUI

@main
struct JucheboxApp: App {
    init() {
        if CommandLine.arguments.contains("--reset-onboarding") {
            UserDefaults.standard.set(false, forKey: AppStorageKey.hasAcceptedUnofficialDisclaimer)
        }

        if CommandLine.arguments.contains("--accept-onboarding") {
            UserDefaults.standard.set(true, forKey: AppStorageKey.hasAcceptedUnofficialDisclaimer)
        }
    }

    @StateObject private var appState = AppState()
    @StateObject private var audioSessionController = AudioSessionController()
    @StateObject private var diagnosticsLog = DiagnosticsLog()
    @StateObject private var privacySettings = PrivacySettings()
    private let jsBridge = JSPlayerBridge()
    private let playerController = AVPlayerController()

    private let domainPolicy = DomainPolicy.bundled()

    var body: some Scene {
        WindowGroup {
            RootView(
                appState: appState,
                audioSessionController: audioSessionController,
                diagnosticsLog: diagnosticsLog,
                domainPolicy: domainPolicy,
                privacySettings: privacySettings,
                jsBridge: jsBridge,
                playerController: playerController
            )
            .preferredColorScheme(.dark)
            .onAppear {
                audioSessionController.start()
                audioSessionController.configure(player: playerController)
                appState.configurePlayer(controller: playerController, bridge: jsBridge)
            }
        }
    }
}
