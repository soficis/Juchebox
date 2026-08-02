import SwiftUI
import UIKit

struct WebScreen: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    let domainPolicy: DomainPolicy
    @ObservedObject var privacySettings: PrivacySettings
    let jsBridge: JSPlayerBridge
    var playerController: AVPlayerController?

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isChromeVisible = true
    @State private var sharedItems: [Any] = []
    @State private var isSharePresented = false
    @State private var searchQuery = ""
    @State private var isSearchPresented = false

    private var showSplash: Bool {
        appState.isLoading && appState.estimatedProgress < 0.5 && appState.webContentError == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            LoadingProgressView(
                isLoading: appState.isLoading,
                progress: appState.estimatedProgress
            )

            ZStack(alignment: .bottom) {
                WebViewContainer(
                    appState: appState,
                    diagnosticsLog: diagnosticsLog,
                    domainPolicy: domainPolicy,
                    privacySettings: privacySettings,
                    jsBridge: jsBridge
                )
                .id(privacySettings.isEphemeralSession)
                .background(Color.black)

                ChollimaSplash(language: appLanguage)
                    .transition(.opacity)
                    .opacity(showSplash ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: AppMotion.defaultDuration), value: showSplash)
                    .allowsHitTesting(showSplash)

                if let error = appState.webContentError {
                    WebErrorView(error: error, language: appLanguage) {
                        appState.reload()
                    }
                }

                VStack(spacing: 8) {
                    Spacer()

                    if let notice = audioSessionController.notice {
                        NoticeBanner(message: notice, actionTitle: t(.dismissButton, language: appLanguage)) {
                            audioSessionController.notice = nil
                        }
                        .padding(.horizontal, 12)
                    }

                    if let toast = appState.toastMessage {
                        NoticeBanner(message: toast, actionTitle: t(.okButton, language: appLanguage)) {
                            appState.toastMessage = nil
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.bottom, 12)
            }

            if isChromeVisible {
                WebToolbar(
                    canGoBack: appState.canGoBack,
                    canGoForward: appState.canGoForward,
                    goBack: appState.goBack,
                    goForward: appState.goForward,
                    reload: appState.reload,
                    home: appState.loadHome,
                    search: presentSearch,
                    share: shareCurrentPage,
                    savePage: saveCurrentPage,
                    hideControls: { isChromeVisible = false }
                )
            } else {
                HStack {
                    Spacer()
                    ToolbarIconButton(
                        systemName: "rectangle.bottomthird.inset.filled",
                        accessibilityLabel: t(.showControlsLabel, language: appLanguage),
                        accessibilityIdentifier: AccessibilityID.showControlsButton,
                        action: { isChromeVisible = true }
                    )
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 8)
            }
        }
        .alert(
            t(.externalLinkTitle, language: appLanguage),
            isPresented: externalLinkBinding
        ) {
            if let request = appState.externalLinkRequest {
                Button(Translation.string(for: request.primaryActionKey, language: appLanguage)) {
                    openURL(request.url)
                    appState.externalLinkRequest = nil
                }

                Button(t(.copyLink, language: appLanguage)) {
                    UIPasteboard.general.url = request.url
                    appState.showToast(t(.toastUrlCopied, language: appLanguage))
                    appState.externalLinkRequest = nil
                }
            }

            Button(t(.cancel, language: appLanguage), role: .cancel) {
                appState.externalLinkRequest = nil
            }
        } message: {
            if let request = appState.externalLinkRequest {
                Text(Translation.string(for: request.messageKey, language: appLanguage))
            }
        }
        .sheet(isPresented: $isSharePresented) {
            ActivityView(activityItems: sharedItems)
        }
        .alert(t(.searchButton, language: appLanguage), isPresented: $isSearchPresented) {
            TextField(t(.searchPlaceholder, language: appLanguage), text: $searchQuery)
            Button(t(.searchGo, language: appLanguage)) {
                submitSearch()
            }
            Button(t(.cancel, language: appLanguage), role: .cancel) {
                searchQuery = ""
            }
        }
        .onAppear {
            applyUITestLaunchScenarios()
        }
    }

    private func applyUITestLaunchScenarios() {
        let arguments = CommandLine.arguments

        if arguments.contains("--show-network-error") {
            appState.showError(.noNetwork)
        }

        if arguments.contains("--show-external-link-confirmation"),
           let url = URL(string: "https://example.com") {
            appState.presentExternalLink(url: url, reason: .externalHTTPSHost("example.com"))
        }

        if arguments.contains("--show-player-bar") {
            appState.isPlayerBarVisible = true
        }

        if arguments.contains("--player-state-playing") {
            let track = TrackInfo(
                id: "test-id",
                title: "Test Song",
                artist: "Test Artist",
                album: nil,
                albumId: nil,
                artistId: nil,
                duration: 180,
                artworkURL: nil
            )
            appState.playerState = PlayerState(
                currentTrack: track,
                isPlaying: true,
                currentTime: 30,
                duration: 180,
                isStalled: false,
                streamURL: nil
            )
        }
    }

    private var externalLinkBinding: Binding<Bool> {
        Binding(
            get: { appState.externalLinkRequest != nil },
            set: { isPresented in
                if !isPresented {
                    appState.externalLinkRequest = nil
                }
            }
        )
    }

    private func shareCurrentPage() {
        guard let currentURL = appState.currentURL else {
            appState.showToast(t(.toastUrlUnavailable, language: appLanguage))
            return
        }

        sharedItems = [currentURL]
        isSharePresented = true
    }

    private func presentSearch() {
        isSearchPresented = true
    }

    private func submitSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var urlString = trimmed
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }
        if let url = URL(string: urlString), url.host != nil {
            appState.load(url)
        } else if let url = URL(string: trimmed) {
            appState.load(url)
        }
        searchQuery = ""
    }

    private func saveCurrentPage() {
        guard let url = appState.currentURL else {
            appState.showToast(t(.toastNoPageToSave, language: appLanguage))
            return
        }
        var saved = UserDefaults.standard.stringArray(forKey: "savedPages") ?? []
        if !saved.contains(url.absoluteString) {
            saved.append(url.absoluteString)
            UserDefaults.standard.set(saved, forKey: "savedPages")
        }
        appState.showToast(t(.toastPageSaved, language: appLanguage))
    }
}

private struct LoadingProgressView: View {
    let isLoading: Bool
    let progress: Double

    var body: some View {
        ProgressView(value: isLoading ? max(progress, 0.05) : 1.0)
            .progressViewStyle(.linear)
            .tint(AppTheme.accent) // DPRK Red
            .opacity(isLoading ? 1 : 0)
            .accessibilityIdentifier(AccessibilityID.progressView)
            .frame(height: 3)
            .background(AppTheme.background.opacity(0.92))
    }
}

private struct WebToolbar: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let goBack: () -> Void
    let goForward: () -> Void
    let reload: () -> Void
    let home: () -> Void
    let search: () -> Void
    let share: () -> Void
    let savePage: () -> Void
    let hideControls: () -> Void

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        HStack(spacing: 4) {
            ToolbarIconButton(
                systemName: "chevron.left",
                accessibilityLabel: t(.toolbarBack, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.backButton,
                isEnabled: canGoBack,
                action: goBack
            )

            ToolbarIconButton(
                systemName: "chevron.right",
                accessibilityLabel: t(.toolbarForward, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.forwardButton,
                isEnabled: canGoForward,
                action: goForward
            )

            ToolbarIconButton(
                systemName: "arrow.clockwise",
                accessibilityLabel: t(.toolbarReload, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.reloadButton,
                action: reload
            )

            ToolbarIconButton(
                systemName: "house",
                accessibilityLabel: t(.toolbarHome, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.homeButton,
                action: home
            )

            Spacer(minLength: 8)

            ToolbarIconButton(
                systemName: "magnifyingglass",
                accessibilityLabel: t(.searchButton, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.searchButton,
                action: search
            )

            ToolbarIconButton(
                systemName: "square.and.arrow.up",
                accessibilityLabel: t(.toolbarShare, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.shareButton,
                action: share
            )

            ToolbarIconButton(
                systemName: "bookmark",
                accessibilityLabel: t(.saveButton, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.savePageButton,
                action: savePage
            )

            ToolbarIconButton(
                systemName: "rectangle.compress.vertical",
                accessibilityLabel: t(.toolbarHideControls, language: appLanguage),
                accessibilityIdentifier: AccessibilityID.hideControlsButton,
                action: hideControls
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85)) // Solid black for DPRK aesthetic
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.3)) // Gold hairline
                .frame(height: 1)
        }
        .background {
            Color.black.opacity(0.85)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ToolbarIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isEnabled ? AppTheme.secondaryText : AppTheme.mutedText) // Gold highlight
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct WebErrorView: View {
    let error: WebContentError
    let language: AppLanguage
    let reload: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Bold red star for DPRK themed error view
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                StarShape()
                    .fill(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .overlay {
                        StarShape()
                            .stroke(AppTheme.warning, lineWidth: 1.5)
                    }
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(error.title(language: language))
                    .font(.system(.title3, design: .serif).weight(.black))
                    .foregroundStyle(AppTheme.secondaryText) // Gold title
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(AccessibilityID.errorTitle)

                Text(error.message(language: language))
                    .font(.system(.body, design: .default))
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: reload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text(Translation.string(for: .errorReloadButton, language: language))
                        .font(.system(.body, design: .serif).weight(.black))
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.warning, lineWidth: 1)
            }
            .foregroundStyle(AppTheme.primaryText)
            .accessibilityIdentifier(AccessibilityID.errorReloadButton)
        }
        .padding(28)
        .frame(maxWidth: 340)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.warning, lineWidth: 1.5) // Gold border
        }
        .padding(24)
        .shadow(color: Color.black, radius: 20, x: 0, y: 10)
    }
}

private struct NoticeBanner: View {
    let message: String
    var actionTitle = "Dismiss"
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(.footnote, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button(actionTitle, action: action)
                .font(.system(.footnote, design: .serif).weight(.black))
                .foregroundStyle(AppTheme.warning) // Gold action button
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }
}

private struct ChollimaSplash: View {
    let language: AppLanguage

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                StarShape()
                    .fill(AppTheme.accent)
                    .frame(width: 60, height: 60)

                Text(t(.appName, language: language))
                    .font(.system(size: 34, design: .serif).weight(.black))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
