import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var catalog: CatalogStore
    @ObservedObject var authStore: AuthStore

    @AppStorage(AppStorageKey.hasAcceptedUnofficialDisclaimer) private var hasAcceptedUnofficialDisclaimer = false
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        Group {
            if hasAcceptedUnofficialDisclaimer {
                NavigationStack(path: $appState.navigationPath) {
                    VStack(spacing: 0) {
                        ZStack {
                            tabContent
                        }

                        MiniPlayerBar(appState: appState) {
                            appState.selectedTab = 3
                        }

                        ChollimaTabBar(
                            selectedTab: $appState.selectedTab,
                            language: appLanguage,
                            isNowPlayingActive: appState.playerState.currentTrack != nil && appState.playerState.isPlaying
                        )
                    }
                    .background(AppTheme.background)
                    .navigationDestination(for: CatalogRoute.self) { route in
                        switch route {
                        case .album(let id):
                            AlbumView(appState: appState, albumID: id)
                        case .artist(let id):
                            ArtistView(appState: appState, artistID: id)
                        }
                    }
                }
            } else {
                OnboardingView {
                    hasAcceptedUnofficialDisclaimer = true
                }
            }
        }
        .background(AppTheme.background)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appState.selectedTab {
        case 0:
            HomeView(appState: appState, catalog: catalog)
        case 1:
            SearchView(appState: appState, catalog: catalog)
        case 2:
            LibraryView(appState: appState, authStore: authStore, catalog: catalog)
        case 3:
            NowPlayingView(appState: appState)
        default:
            HomeView(appState: appState, catalog: catalog)
        }
    }
}

private struct ChollimaTabBar: View {
    @Binding var selectedTab: Int
    let language: AppLanguage
    var isNowPlayingActive: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: t(.tabBrowse, language: language),
                systemImage: selectedTab == 0 ? "globe.americas.fill" : "globe",
                isSelected: selectedTab == 0,
                accessibilityIdentifier: AccessibilityID.homeTab
            ) {
                selectedTab = 0
            }

            tabButton(
                title: t(.tabSearch, language: language),
                systemImage: "magnifyingglass",
                isSelected: selectedTab == 1,
                accessibilityIdentifier: AccessibilityID.searchTab
            ) {
                selectedTab = 1
            }

            tabButton(
                title: t(.tabLibrary, language: language),
                systemImage: selectedTab == 2 ? "music.note.list.fill" : "music.note.list",
                isSelected: selectedTab == 2,
                accessibilityIdentifier: AccessibilityID.libraryTab
            ) {
                selectedTab = 2
            }

            tabButton(
                title: t(.tabNowPlaying, language: language),
                systemImage: selectedTab == 3 ? "music.note.fill" : "music.note",
                isSelected: selectedTab == 3,
                accessibilityIdentifier: AccessibilityID.nowPlayingTab,
                isNowPlayingActive: isNowPlayingActive
            ) {
                selectedTab = 3
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
        isNowPlayingActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating, isActive: isNowPlayingActive)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .foregroundStyle(
                isNowPlayingActive
                    ? AppTheme.accent
                    : (isSelected ? AppTheme.secondaryText : AppTheme.mutedText)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}
