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
                VStack(spacing: 0) {
                    switch selectedTab {
                    case 0:
                        WebScreen(
                            appState: appState,
                            audioSessionController: audioSessionController,
                            diagnosticsLog: diagnosticsLog,
                            domainPolicy: domainPolicy,
                            privacySettings: privacySettings
                        )
                    default:
                        SettingsView(
                            appState: appState,
                            diagnosticsLog: diagnosticsLog,
                            privacySettings: privacySettings
                        )
                    }

                    ChollimaTabBar(selectedTab: $selectedTab, language: appLanguage)
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

private struct ChollimaTabBar: View {
    @Binding var selectedTab: Int
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: t(.toolbarHome, language: language),
                systemImage: selectedTab == 0 ? "globe.americas.fill" : "globe",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            tabButton(
                title: t(.toolbarSettings, language: language),
                systemImage: selectedTab == 1 ? "gearshape.fill" : "gearshape",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
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
    }
}
