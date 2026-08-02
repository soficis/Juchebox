import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    let domainPolicy: DomainPolicy
    @ObservedObject var privacySettings: PrivacySettings
    let jsBridge: JSPlayerBridge
    let playerController: AVPlayerController

    @AppStorage(AppStorageKey.hasAcceptedUnofficialDisclaimer) private var hasAcceptedUnofficialDisclaimer = false
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if hasAcceptedUnofficialDisclaimer {
                VStack(spacing: 0) {
                    ZStack {
                        WebScreen(
                            appState: appState,
                            audioSessionController: audioSessionController,
                            diagnosticsLog: diagnosticsLog,
                            domainPolicy: domainPolicy,
                            privacySettings: privacySettings,
                            jsBridge: jsBridge,
                            playerController: playerController
                        )
                        .opacity(selectedTab == 0 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 0)

                        NowPlayingView(appState: appState)
                            .opacity(selectedTab == 1 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 1)

                        SettingsView(
                            appState: appState,
                            diagnosticsLog: diagnosticsLog,
                            privacySettings: privacySettings
                        )
                        .opacity(selectedTab == 2 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 2)
                    }

                    MiniPlayerBar(appState: appState) {
                        selectedTab = 1
                    }

                    ChollimaTabBar(selectedTab: $selectedTab, language: appLanguage)
                }
                .overlay(alignment: .topLeading) {
                    if CommandLine.arguments.contains("--online-player-probe") {
                        OnlineBridgeProbe(bridge: jsBridge)
                    }
                }
                .background(AppTheme.background)
            } else {
                OnboardingView {
                    hasAcceptedUnofficialDisclaimer = true
                }
            }
        }
        .background(AppTheme.background)
    }
}

/// Test-only overlay (launch arg `--online-player-probe`) rendering the player
/// bridge's REAL connection status and parsed state — the online UI test reads
/// its label. Never shows fabricated data: `waiting` until the injected script
/// posts its first message, then `connected` with the site's actual state.
private struct OnlineBridgeProbe: View {
    @ObservedObject var bridge: JSPlayerBridge

    var body: some View {
        Text(probeText)
            .font(.caption2)
            .monospaced()
            .foregroundStyle(AppTheme.mutedText)
            .padding(6)
            .background(AppTheme.surface)
            .accessibilityIdentifier(AccessibilityID.onlineBridgeProbe)
            .allowsHitTesting(false)
    }

    private var probeText: String {
        guard bridge.messageCount > 0 else { return "bridge:waiting" }
        let state = bridge.latestState
        let title = state.currentTrack?.title ?? "none"
        return "bridge:connected:msgs=\(bridge.messageCount):playing=\(state.isPlaying):title=\(title)"
    }
}

private struct ChollimaTabBar: View {
    @Binding var selectedTab: Int
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: t(.toolbarHome, language: language),
                systemImage: selectedTab == 0 ? "globe.americas.fill" : "globe",
                isSelected: selectedTab == 0,
                accessibilityIdentifier: AccessibilityID.homeTab
            ) {
                selectedTab = 0
            }

            tabButton(
                title: t(.tabNowPlaying, language: language),
                systemImage: selectedTab == 1 ? "music.note.list.fill" : "music.note.list",
                isSelected: selectedTab == 1,
                accessibilityIdentifier: AccessibilityID.nowPlayingTab
            ) {
                selectedTab = 1
            }

            tabButton(
                title: t(.toolbarSettings, language: language),
                systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape",
                isSelected: selectedTab == 2,
                accessibilityIdentifier: AccessibilityID.settingsTab
            ) {
                selectedTab = 2
            }
        }
        .frame(height: 56)
        .background(AppTheme.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.3))
                .frame(height: 1)
        }
    }

    private func tabButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .foregroundStyle(isSelected ? AppTheme.secondaryText : AppTheme.mutedText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}
