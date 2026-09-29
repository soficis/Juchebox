import SwiftUI

@main
struct JucheboxApp: App {
    @StateObject private var authStore: AuthStore
    @StateObject private var appState: AppState
    @StateObject private var audioSessionController = AudioSessionController()
    @StateObject private var catalog: CatalogStore
    private let playerController = AVPlayerController()

    init() {
        if CommandLine.arguments.contains("--reset-onboarding") {
            UserDefaults.standard.set(false, forKey: AppStorageKey.hasAcceptedUnofficialDisclaimer)
        }

        if CommandLine.arguments.contains("--accept-onboarding") {
            UserDefaults.standard.set(true, forKey: AppStorageKey.hasAcceptedUnofficialDisclaimer)
        }

        let auth = AuthStore()
        _authStore = StateObject(wrappedValue: auth)

        let api = JuchifyAPIClient(tokenProvider: { auth.tokenProvider() })
        _appState = StateObject(wrappedValue: AppState(apiClient: api, authStore: auth))
        _catalog = StateObject(wrappedValue: CatalogStore(apiClient: api))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                appState: appState,
                audioSessionController: audioSessionController,
                catalog: catalog,
                authStore: authStore
            )
            .preferredColorScheme(.dark)
            .onAppear {
                audioSessionController.start()
                audioSessionController.configure(player: playerController)
                appState.configurePlayer(controller: playerController)
                // Bind the store to a local before capturing: a weak capture of the
                // StateObject property itself would retain a temporary, so the weak
                // reference could be nil before the closure ever runs.
                let store = authStore
                playerController.tokenProvider = { [weak store] in
                    store?.tokenProvider()
                }
            }
        }
    }
}
