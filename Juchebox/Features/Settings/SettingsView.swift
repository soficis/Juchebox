import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var authStore: AuthStore

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue
    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        NavigationStack {
            List {
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
                } header: {
                    Text(t(.aboutSection, language: appLanguage))
                }

                Section {
                    Text(t(.licensesFooter, language: appLanguage))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                } header: {
                    Text(t(.licensesTitle, language: appLanguage))
                }
                .listRowBackground(AppTheme.surface)

                Section {
                    Text(versionText)
                        .foregroundStyle(AppTheme.primaryText.opacity(0.8))
                } header: {
                    Text(t(.versionTitle, language: appLanguage))
                }
                .listRowBackground(AppTheme.surface)

                if authStore.isAuthenticated {
                    Section {
                        Button(t(.signOutButton, language: appLanguage), role: .destructive) {
                            authStore.signOut()
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(t(.settingsTitle, language: appLanguage))
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
