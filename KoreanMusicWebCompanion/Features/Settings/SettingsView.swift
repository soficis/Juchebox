import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var diagnosticsLog: DiagnosticsLog
    @ObservedObject var privacySettings: PrivacySettings

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isClearConfirmationPresented = false
    @State private var isClearingWebsiteData = false
    @State private var diagnosticsExport: DiagnosticsExport?

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        NavigationStack {
            List {
                // Language Settings Section
                Section {
                    Picker(t(.languageSelectTitle, language: appLanguage), selection: $appLanguageRaw) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName(currentLanguage: appLanguage))
                                .tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(AppTheme.surface)
                } header: {
                    Text(t(.languageSelectTitle, language: appLanguage))
                }

                // About Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t(.appName, language: appLanguage))
                            .font(.system(.headline, design: .serif).weight(.bold))
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        Text(t(.disclaimer1Message, language: appLanguage))
                            .font(.system(.footnote, design: .default))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.surface)

                    Button(t(.openInBrowserButton, language: appLanguage)) {
                        openURL(appState.homeURL)
                    }
                    .foregroundStyle(AppTheme.warning)
                    .listRowBackground(AppTheme.surface)
                } header: {
                    Text(t(.aboutSection, language: appLanguage))
                }

                // Security/Privacy Section
                Section {
                    Toggle(t(.ephemeralToggle, language: appLanguage), isOn: $privacySettings.isEphemeralSession)
                        .accessibilityIdentifier(AccessibilityID.ephemeralSessionToggle)
                        .tint(AppTheme.accent)

                    Button(role: .destructive) {
                        isClearConfirmationPresented = true
                    } label: {
                        Label(t(.clearDataButton, language: appLanguage), systemImage: "trash")
                    }
                    .disabled(isClearingWebsiteData)
                    .accessibilityIdentifier(AccessibilityID.clearWebsiteDataButton)
                } header: {
                    Text(t(.securitySection, language: appLanguage))
                } footer: {
                    Text(t(.ephemeralFooter, language: appLanguage))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .listRowBackground(AppTheme.surface)

                // Diagnostics Section
                Section {
                    Button {
                        diagnosticsExport = DiagnosticsExport(text: diagnosticsLog.exportText(sessionMode: privacySettings.sessionMode))
                    } label: {
                        Label(t(.diagnosticsButton, language: appLanguage), systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(AppTheme.warning)
                    .accessibilityIdentifier(AccessibilityID.exportDiagnosticsButton)
                } header: {
                    Text(t(.diagnosticsTitle, language: appLanguage))
                } footer: {
                    Text(t(.diagnosticsFooter, language: appLanguage))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .listRowBackground(AppTheme.surface)

                // Privacy Summary Section
                Section {
                    Text(t(.privacySummaryFooter, language: appLanguage))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text(t(.privacySummaryTitle, language: appLanguage))
                }
                .listRowBackground(AppTheme.surface)

                // Open Source Section
                Section {
                    Text(t(.licensesFooter, language: appLanguage))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                } header: {
                    Text(t(.licensesTitle, language: appLanguage))
                }
                .listRowBackground(AppTheme.surface)

                // Version Section
                Section {
                    Text(versionText)
                        .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                } header: {
                    Text(t(.versionTitle, language: appLanguage))
                }
                .listRowBackground(AppTheme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(t(.settingsTitle, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage == .korean ? "완료" : "Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .confirmationDialog(
                t(.clearDataButton, language: appLanguage),
                isPresented: $isClearConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(t(.clearDataButton, language: appLanguage), role: .destructive) {
                    clearWebsiteData()
                }
                Button(t(.cancel, language: appLanguage), role: .cancel) {}
            } message: {
                Text(t(.clearDataFooter, language: appLanguage))
            }
            .sheet(item: $diagnosticsExport) { export in
                ActivityView(activityItems: [export.text])
            }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func clearWebsiteData() {
        isClearingWebsiteData = true

        Task {
            await WebsiteDataCleaner.clearPersistentWebsiteData()
            await MainActor.run {
                isClearingWebsiteData = false
                appState.loadHome()
                appState.showToast(t(.toastDataCleared, language: appLanguage))
            }
        }
    }
}

private struct DiagnosticsExport: Identifiable {
    let id = UUID()
    let text: String
}
