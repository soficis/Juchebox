import Foundation
import WebKit
import Combine

@MainActor
final class AppState: ObservableObject {
    let homeURL: URL

    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress = 0.0
    @Published var currentURL: URL?
    @Published var webContentError: WebContentError?
    @Published var externalLinkRequest: ExternalLinkRequest?
    @Published var toastMessage: String?

    @Published var playerState: PlayerState = .empty
    @Published var isPlayerBarVisible: Bool = false

    private var playerController: (any PlayerControllerProtocol)?
    private var jsBridge: (any JSExtractorProtocol)?
    private var playerStateCancellable: AnyCancellable?

    private weak var webView: WKWebView?

    init(homeURL: URL = AppState.defaultHomeURL()) {
        self.homeURL = homeURL
        currentURL = homeURL
    }

    private static func defaultHomeURL() -> URL {
        guard let url = URL(string: "https://juchify.com") else {
            fatalError("The Juchify home URL constant is invalid.")
        }

        return url
    }

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }
        self.webView = webView
        updateNavigationState(from: webView)
    }

    func updateNavigationState(from webView: WKWebView) {
        let newCanGoBack = webView.canGoBack
        let newCanGoForward = webView.canGoForward
        let newIsLoading = webView.isLoading
        let newProgress = webView.estimatedProgress

        if newCanGoBack != canGoBack { canGoBack = newCanGoBack }
        if newCanGoForward != canGoForward { canGoForward = newCanGoForward }
        if newIsLoading != isLoading { isLoading = newIsLoading }
        if newProgress != estimatedProgress { estimatedProgress = newProgress }
        if let newURL = webView.url, newURL != currentURL { currentURL = newURL }
    }

    func clearError() {
        webContentError = nil
    }

    func showError(_ error: WebContentError) {
        webContentError = error
    }

    func presentExternalLink(url: URL, reason: ExternalNavigationReason) {
        externalLinkRequest = ExternalLinkRequest(url: url, reason: reason)
    }

    func goBack() {
        guard webView?.canGoBack == true else { return }
        clearError()
        webView?.goBack()
    }

    func goForward() {
        guard webView?.canGoForward == true else { return }
        clearError()
        webView?.goForward()
    }

    func reload() {
        clearError()

        if let webView {
            webView.reload()
        } else {
            loadHome()
        }
    }

    func loadHome() {
        load(homeURL)
    }

    func load(_ url: URL) {
        clearError()
        currentURL = url
        webView?.load(URLRequest(url: url))
    }

    func showToast(_ message: String) {
        toastMessage = message

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard self.toastMessage == message else { return }
            self.toastMessage = nil
        }
    }

    func configurePlayer(controller: any PlayerControllerProtocol, bridge: any JSExtractorProtocol) {
        guard playerController == nil else { return }
        playerController = controller
        jsBridge = bridge

        playerStateCancellable = controller.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playerState = state
            }

        isPlayerBarVisible = true
    }

    func playerCommand(_ command: PlayerCommand) {
        clearError()

        switch command {
        case .play:
            playerController?.play()
        case .pause:
            playerController?.pause()
        case .togglePlayPause:
            playerController?.togglePlayPause()
        case .seek(let time):
            playerController?.seek(to: time)
        case .nextTrack:
            playerController?.nextTrack()
            Task { @MainActor in
                await jsBridge?.sendCommand(command)
            }
        case .previousTrack:
            playerController?.previousTrack()
            Task { @MainActor in
                await jsBridge?.sendCommand(command)
            }
        }
    }
}


