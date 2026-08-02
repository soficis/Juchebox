import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var appState: AppState
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    let domainPolicy: DomainPolicy
    @ObservedObject var privacySettings: PrivacySettings

    func makeCoordinator() -> WebNavigationCoordinator {
        WebNavigationCoordinator(
            appState: appState,
            diagnosticsLog: diagnosticsLog,
            domainPolicy: domainPolicy,
            privacySettings: privacySettings
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.websiteDataStore = privacySettings.isEphemeralSession ? .nonPersistent() : .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.accessibilityIdentifier = AccessibilityID.webView
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(WebNavigationCoordinator.refreshWebView(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.attach(webView)
        appState.attach(webView)

        // UI tests pass --ui-testing-offline so the app stays idle and
        // native chrome is queryable without depending on the live site.
        if !CommandLine.arguments.contains("--ui-testing-offline") {
            webView.load(URLRequest(url: appState.homeURL))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        appState.attach(webView)
    }
}

