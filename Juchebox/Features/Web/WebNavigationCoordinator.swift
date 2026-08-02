import UIKit
import WebKit

@MainActor
final class WebNavigationCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let appState: AppState
    private let diagnosticsLog: DiagnosticsLog
    private let domainPolicy: DomainPolicy
    private let privacySettings: PrivacySettings
    private weak var webView: WKWebView?
    private var observations: [NSKeyValueObservation] = []

    init(
        appState: AppState,
        diagnosticsLog: DiagnosticsLog,
        domainPolicy: DomainPolicy,
        privacySettings: PrivacySettings
    ) {
        self.appState = appState
        self.diagnosticsLog = diagnosticsLog
        self.domainPolicy = domainPolicy
        self.privacySettings = privacySettings
    }

    func attach(_ webView: WKWebView) {
        self.webView = webView

        observations = [
            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                self?.updateState(from: webView)
            },
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                self?.updateState(from: webView)
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                self?.updateState(from: webView)
            },
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                self?.updateState(from: webView)
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                self?.updateState(from: webView)
            }
        ]
    }

    @objc func refreshWebView(_ sender: UIRefreshControl) {
        webView?.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        let isMainFrameNavigation = navigationAction.targetFrame?.isMainFrame ?? true

        guard isMainFrameNavigation else {
            decisionHandler(.allow)
            return
        }

        let context: NavigationContext = navigationAction.targetFrame == nil ? .newWindow : .standard
        let decision = domainPolicy.decision(for: navigationAction.request.url, context: context)
        handlePolicyDecision(decision, url: navigationAction.request.url, decisionHandler: decisionHandler)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
    ) {
        if let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 500 {
            showAndRecord(.serverUnavailable, url: response.url)
            decisionHandler(.cancel)
            return
        }

        guard navigationResponse.canShowMIMEType else {
            showAndRecord(.downloadUnsupported, url: navigationResponse.response.url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateState(from: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        appState.clearError()
        updateState(from: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
        appState.clearError()
        updateState(from: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        showFailureIfNeeded(error, webView: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        showFailureIfNeeded(error, webView: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        showAndRecord(.webProcessTerminated, url: webView.url)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let decision = domainPolicy.decision(for: navigationAction.request.url, context: .newWindow)

        switch decision {
        case .allowInApp:
            webView.load(navigationAction.request)
        case .openExternally(let reason):
            if let url = navigationAction.request.url {
                appState.presentExternalLink(url: url, reason: reason)
            }
        case .block(let reason):
            showAndRecord(.blocked(reason), url: navigationAction.request.url)
        }

        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        let alert = UIAlertController(title: "Website Message", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, fallback: completionHandler)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        let alert = UIAlertController(title: "Website Confirmation", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert) {
            completionHandler(false)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
    ) {
        let alert = UIAlertController(title: "Website Input", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert) {
            completionHandler(nil)
        }
    }

    private func handlePolicyDecision(
        _ decision: DomainPolicyDecision,
        url: URL?,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        switch decision {
        case .allowInApp:
            appState.clearError()
            decisionHandler(.allow)
        case .openExternally(let reason):
            if let url {
                appState.presentExternalLink(url: url, reason: reason)
            }
            decisionHandler(.cancel)
        case .block(let reason):
            showAndRecord(.blocked(reason), url: url)
            decisionHandler(.cancel)
        }
    }

    private func showFailureIfNeeded(_ error: Error, webView: WKWebView) {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorCancelled,
           webView.url != nil {
            updateState(from: webView)
            return
        }

        let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL ?? webView.url
        showAndRecord(WebContentError.from(error: error, failingURL: failingURL), url: failingURL)
    }

    private func showAndRecord(_ error: WebContentError, url: URL?) {
        appState.showError(error)
        diagnosticsLog.record(error: error, url: url, sessionMode: privacySettings.sessionMode)
    }

    nonisolated private func updateState(from webView: WKWebView) {
        DispatchQueue.main.async { [weak self, weak webView] in
            guard let self, let webView else { return }
            Task { @MainActor in
                self.appState.updateNavigationState(from: webView)
            }
        }
    }

    private func present(_ alert: UIAlertController, fallback: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let presenter = Self.topViewController() else {
                fallback()
                return
            }

            presenter.present(alert, animated: true)
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        let root = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        return topViewController(from: root)
    }

    private static func topViewController(from root: UIViewController?) -> UIViewController? {
        if let navigationController = root as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = root as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }

        return root
    }
}

