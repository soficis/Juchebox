import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioSessionController: AudioSessionController
    @ObservedObject var catalog: CatalogStore
    @ObservedObject var authStore: AuthStore

    @AppStorage(AppStorageKey.hasAcceptedUnofficialDisclaimer) private var hasAcceptedUnofficialDisclaimer = false
    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue

    @State private var visited: Set<Int> = [0]

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        Group {
            if hasAcceptedUnofficialDisclaimer {
                VStack(spacing: 0) {
                    ZStack {
                        tabHost
                    }

                    MiniPlayerBar(appState: appState) {
                        appState.selectedTab = 3
                    }

                    ChollimaTabBar(
                        selectedTab: $appState.selectedTab,
                        language: appLanguage,
                        isNowPlayingActive: appState.playerState.currentTrack != nil && appState.playerState.isPlaying,
                        onReselectTab: { tab in
                            appState.popToRoot(for: tab)
                        }
                    )
                }
                .background(AppTheme.background)
                .onChange(of: appState.selectedTab) { _, newTab in
                    visited.insert(newTab)
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
    private var tabHost: some View {
        if visited.contains(0) {
            tabStack(for: 0) {
                HomeView(appState: appState, catalog: catalog)
            }
            .opacity(appState.selectedTab == 0 ? 1 : 0)
            .allowsHitTesting(appState.selectedTab == 0)
            .accessibilityHidden(appState.selectedTab != 0)
        }

        if visited.contains(1) {
            tabStack(for: 1) {
                SearchView(appState: appState, catalog: catalog)
            }
            .opacity(appState.selectedTab == 1 ? 1 : 0)
            .allowsHitTesting(appState.selectedTab == 1)
            .accessibilityHidden(appState.selectedTab != 1)
        }

        if visited.contains(2) {
            tabStack(for: 2) {
                LibraryView(appState: appState, authStore: authStore, catalog: catalog)
            }
            .opacity(appState.selectedTab == 2 ? 1 : 0)
            .allowsHitTesting(appState.selectedTab == 2)
            .accessibilityHidden(appState.selectedTab != 2)
        }

        if visited.contains(3) {
            NowPlayingView(appState: appState)
                .opacity(appState.selectedTab == 3 ? 1 : 0)
                .allowsHitTesting(appState.selectedTab == 3)
                .accessibilityHidden(appState.selectedTab != 3)
        }
    }

    private func tabStack<Content: View>(for tabIndex: Int, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: appState.pathBinding(for: tabIndex)) {
            content()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: CatalogRoute.self) { route in
                    switch route {
                    case .album(let id):
                        AlbumView(appState: appState, albumID: id)
                    case .artist(let id):
                        ArtistView(appState: appState, artistID: id)
                    }
                }
        }
    }
}

private struct ChollimaTabBar: View {
    @Binding var selectedTab: Int
    let language: AppLanguage
    var isNowPlayingActive: Bool = false
    var onReselectTab: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: t(.tabBrowse, language: language),
                systemImage: selectedTab == 0 ? "globe.americas.fill" : "globe",
                isSelected: selectedTab == 0,
                accessibilityIdentifier: AccessibilityID.homeTab
            ) {
                if selectedTab == 0 {
                    onReselectTab?(0)
                } else {
                    selectedTab = 0
                }
            }

            tabButton(
                title: t(.tabSearch, language: language),
                systemImage: "magnifyingglass",
                isSelected: selectedTab == 1,
                accessibilityIdentifier: AccessibilityID.searchTab
            ) {
                if selectedTab == 1 {
                    onReselectTab?(1)
                } else {
                    selectedTab = 1
                }
            }

            tabButton(
                title: t(.tabLibrary, language: language),
                systemImage: selectedTab == 2 ? "music.note.list.fill" : "music.note.list",
                isSelected: selectedTab == 2,
                accessibilityIdentifier: AccessibilityID.libraryTab
            ) {
                if selectedTab == 2 {
                    onReselectTab?(2)
                } else {
                    selectedTab = 2
                }
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
            .foregroundStyle(isSelected ? AppTheme.secondaryText : AppTheme.mutedText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}
