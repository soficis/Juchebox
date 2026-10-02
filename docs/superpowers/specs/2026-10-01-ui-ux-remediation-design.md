# Juchebox UI/UX Remediation Technical Specification

Date: 2026-10-01  
Author: Antigravity  
Status: Draft (Pending User Review)  
Target: Juchebox iOS App (`Juchebox.xcodeproj`)

---

## 1. Overview & Objectives

This specification defines the complete architectural and visual remediation of the native SwiftUI Juchebox client, addressing WCAG contrast failures, stale artwork caching, navigation/tab hierarchy destruction, mini-player life cycle issues, list ergonomics, accessibility deficiencies, and obsolete WebView-era copy.

### Architectural Constraints
- **Zero Third-Party Dependencies:** Pure Swift 6 and SwiftUI on iOS 17+.
- **Preserve Custom Shell:** Keep `ChollimaTabBar`; do not revert to system `TabView`.
- **Untouched Subsystems:** Streaming playback logic (`AppState.playCurrent`, `handleStreamFailure`, audio buffers), `AVPlayerController`, `AudioSessionController`, `JuchifyAPIClient`, `CatalogStore`, and Keychain auth.
- **Localization Rigor:** Every user-facing string must be declared in `Translation.Key` with English and Munhwaŏ Korean (`kp`), registered in `TranslationCompletenessTests`.
- **Accessibility:** Maintain all 6 existing `AccessibilityID` constants (`homeTab`, `searchTab`, `libraryTab`, `nowPlayingTab`, `settingsTab`, `searchField`). Ensure $\ge 44 \times 44\text{pt}$ touch targets.

---

## 2. Work Packages Specification

### WP-A: Contrast Tokens & Color Science
1. **New Semantic Token:**
   Add `AppTheme.accentOnDark = Color(red: 0.93, green: 0.30, blue: 0.32)` in `AppTheme.swift`.
   - Contrast ratio vs `AppTheme.background` (#0A0A0A): ~5.4:1 (exceeds WCAG AA 4.5:1).
   - Contrast ratio vs `AppTheme.elevatedSurface` (#281214): ~4.4:1 (exceeds WCAG 3.0:1 UI control threshold).
2. **Deterministic Luminance Exposure:**
   Expose RGB component accessors in `AppTheme` so unit tests compute sRGB relative luminance mathematically without requiring UIKit runtime environments.
3. **Usage Migration:**
   - Migrate text and icon foregrounds from `AppTheme.accent` to `AppTheme.accentOnDark`:
     - `SongRow`: Active track title, liked heart, active playing badge.
     - `MiniPlayerBar`: Play/pause button icon.
     - `NowPlayingView`: Play/pause button icon, queue active track indicator, liked heart.
     - `LibraryView`: Liked songs section action button icon.
     - `ChollimaTabBar`: Now Playing active playback dot.
   - Retain `AppTheme.accent` strictly for solid fills behind light text/shapes (`StarShape`, progress bars, CTA fills).
   - In `NowPlayingView`, replace `.foregroundColor(AppTheme.mutedText.opacity(0.7))` with standard `AppTheme.mutedText` for the album name.
4. **Verification:**
   Implement `JucheboxTests/AppThemeContrastTests.swift` asserting contrast math across all tokens.

---

### WP-B: Player & Mini-Player Remediation

#### B1. Now Playing Foreground Artwork Cache
- **Problem:** `NowPlayingView.artworkImage` is stored in `@State` and never invalidated when tracks transition. When an uncached track plays after a cached track, the foreground renders the previous track's image.
- **Solution:**
  - Remove `@State private var artworkImage`, `loadArtworkSync()`, `loadArtworkAsync()`, and manual cache lookups in `artworkView`.
  - Render foreground cover using `CachedAsyncImage(url: track?.artworkURL, fallbackURL: track?.artworkFallbackURL)` with `.id(track?.id)`.
  - Placeholder: `placeholderArtwork` with 360pt maximum size, corner radius `AppRadius.lg`, and drop shadow.
  - In `HomeView.swift` (`CachedAsyncImage.load`), wrap verbose `NSLog` calls in `#if DEBUG`.

#### B2. MiniPlayerBar Ergonomics & Accessibility
- **Visibility:**
  - Show mini-player bar only when `appState.isPlayerBarVisible && appState.playerState.currentTrack != nil && appState.selectedTab != 3`.
  - Automatically hide mini-player on the Now Playing tab (`selectedTab == 3`) to avoid redundant transport controls.
  - Eliminate the dead "No track playing" branch in `trackInfo`.
- **Accessibility:**
  - Switch container trait from `.accessibilityElement(children: .ignore)` to `.accessibilityElement(children: .contain)` so VoiceOver users can access individual controls.
  - Retain container description: `"Now Playing, {title}, {artist}"`.
- **Sizing & Hierarchy:**
  - Next track button: frame glyph to $26 \times 26\text{pt}$ inside a $44 \times 44\text{pt}$ hit target with `contentShape(Rectangle())`.
  - Colors: Play/pause button uses `AppTheme.accentOnDark`; Next button uses `AppTheme.secondaryText`.
  - Preserve `reduceMotion` gating on bar transitions.

---

### WP-C: Navigation Architecture & Tab Isolation

#### Problem Statement
Currently, a single `NavigationStack(path: $appState.navigationPath)` wraps the entire screen in `RootView.swift`. When any album or artist is pushed, the tab bar and mini-player disappear. Tab switches destroy view state because `tabContent` is an ephemeral `switch`.

#### Architecture & Data Flow
1. **AppState Routing:**
   - Replace `@Published var navigationPath: [CatalogRoute] = []` with:
     ```swift
     @Published var paths: [Int: [CatalogRoute]] = [:]
     
     func pathBinding(for tab: Int) -> Binding<[CatalogRoute]> {
         Binding(
             get: { self.paths[tab, default: []] },
             set: { self.paths[tab] = $0 }
         )
     }
     
     func navigate(to route: CatalogRoute) {
         paths[selectedTab, default: []].append(route)
     }
     
     func popToRoot(for tab: Int) {
         paths[tab] = []
     }
     ```
   - Update all 6 navigation call sites (`AlbumView`, `HomeView`, `SearchView`, `LibraryView`) to use `appState.navigate(to:)`.
2. **Tab Preservation & Layout (`RootView.swift`):**
   ```
   RootView
   └─ VStack(spacing: 0)
      ├─ ZStack {
      │    Home (tab 0)     -> NavigationStack(path: pathBinding(for: 0))
      │    Search (tab 1)   -> NavigationStack(path: pathBinding(for: 1))
      │    Library (tab 2)  -> NavigationStack(path: pathBinding(for: 2))
      │    NowPlaying (3)   -> Standalone View (no NavigationStack)
      │  }
      ├─ MiniPlayerBar
      └─ ChollimaTabBar
   ```
   - Track visited tabs with `@State private var visited: Set<Int> = [0]`. Insert `selectedTab` upon change.
   - Non-active tabs remain mounted but hidden:
     `.opacity(selectedTab == n ? 1 : 0)`, `.allowsHitTesting(selectedTab == n)`, `.accessibilityHidden(selectedTab != n)`.
   - Root views declare `.toolbar(.hidden, for: .navigationBar)` so custom headers render cleanly. Pushed views (`AlbumView`, `ArtistView`) retain system headers with back navigation.
   - Tapping an already selected tab pops that tab's navigation stack to root (`popToRoot(for: tab)`).

---

### WP-D: Tab Bar Polish (`ChollimaTabBar`)

1. **Home Tab Identity:**
   - Tab 0 changes from "Browse" (`globe`) to "Home" (`house` / `house.fill`).
   - Add `Translation.Key.tabHome`. Remove obsolete references to `tabBrowse`.
2. **SF Symbol Verification:**
   - Validate that all tab SF Symbols exist on iOS 17+ (`house`, `house.fill`, `magnifyingglass`, `music.note.list`, `play.circle.fill` / `music.note`).
   - Create unit test asserting `UIImage(systemName:) != nil` for every tab symbol.
3. **State Encoding:**
   - Active tab: always `AppTheme.secondaryText` (gold).
   - Inactive tab: `AppTheme.mutedText`.
   - Active playing indicator: eliminate the infinite repeating pulse. Place a 6pt `AppTheme.accentOnDark` dot above/beside the Now Playing icon.
4. **Dynamic Type & Target Size:**
   - Bar height (56pt) and icon size use `@ScaledMetric`.
   - Labels styled with `.caption2`.
   - Bar capped at `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` to prevent layout destruction.
   - Add `.accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])`.

---

### WP-E: Screen Refinements & List Ergonomics

#### E1. Now Playing (`NowPlayingView.swift`)
- Touch targets: Shuffle, queue, and repeat buttons formatted with $\ge 44 \times 44\text{pt}$ frames and `contentShape(Rectangle())`.
- State visual indicators: Use filled icon variants or status dots so active state does not rely on color alone.
- Scrubber & Timing: Add `.accessibilityLabel(t(.playerSeekLabel))` and value `"{elapsed} of {total}"`. Prefix remaining time with "−". Use `@ScaledMetric` and `minWidth` on timing labels.
- Layout Balance: Detach the Like heart button from the centered title `HStack` (placing it trailing in the transport/action bar) so title text is centered.

#### E2. SongRow & Catalog Cards (`HomeView.swift`)
- Like button hit box expanded from 32pt to 44pt.
- Visible overflow `Menu` with `ellipsis` icon (labelled `moreActions`) exposing Play Next, Add to Queue, Go to Album, and Like.
- Accessibility: Replace hardcoded `"Locked"` string with `t(.songLocked)`. Add `.accessibilityAddTraits(.isHeader)` to all section titles.
- Hit targets: "See All" buttons given `minHeight: 44` and `contentShape(Rectangle())`.
- Typography: Unify `AlbumRow` and `ArtistRow` to match `SongRow` subheadline serif typography.

#### E3. Home Tab (`HomeView.swift`)
- Settings button: add `.accessibilityLabel(t(.settingsTitle))`, keep `AccessibilityID.settingsTab`.
- Hero Section: Drop the first track from the "New Tracks" list (`dropFirst()`) to prevent immediate visual duplication. Add an overlay play glyph (`play.fill`) and comprehensive accessibility label.

#### E4. Library Tab (`LibraryView.swift`)
- Remove `.prefix(20)` restriction on liked songs and recently played lists.
- Resilient Loading: Fetch `likedSongs()` and `recentlyPlayed()` independently so partial network errors preserve available data; surface a retry banner on failure.
- Refresh: Add `.refreshable { await loadLibrary() }`.
- Header Merge: Combine the redundant "Liked Songs" button and section header into a single header with trailing "Play" button.
- Empty State: Display `libraryEmpty` and `libraryEmptyHint` when signed in with zero items.
- Sign Out: Present a `confirmationDialog` before invoking `authStore.signOut()` (in both `LibraryView` and `SettingsView`).
- `SignInView`: Add `.textContentType(.username)` / `.textContentType(.password)`, `.submitLabel(.go)` with `.onSubmit`, and close/cancel button.

#### E5. Search Tab (`SearchView.swift`)
- Zero Results: Show `searchNoResults` state when search completes with zero songs, albums, and artists.
- Recents Pollution: Remove `onChange(of: catalog.searchResults)`. Record recent queries only on Return key submit, recent item tap, or result selection.
- Focus: Auto-focus search field on first appearance and when switching to the Search tab with an empty query.
- Error Message: Surface `catalog.errorMessage` when a search request fails.

---

### WP-F: Copy Modernization, Translations & Documentation

#### String Modernization (`Translation.swift`)
Replace obsolete WebKit-era copy with accurate native app descriptions:
- `searchPlaceholder`: `"Search songs, albums, artists"` / `"노래, 앨범, 예술가 검색"`
- `disclaimer2Title`: `"Native Catalog Access"` / `"직접 통신 체계"`
- `disclaimer2Message`: `"Connects directly to the public catalog API without WebKit or embedded browsers."` / `"웹브라우저 없이 공개 봉사기 인터페이스와 직접 통신합니다."`
- `disclaimer3Message`: `"Does not download or store audio tracks."` / `"음악 자료를 내려받거나 저장하지 않습니다."`
- `disclaimer4Message`: `"No analytics, no telemetry, and no independent backend servers."` / `"분석 도구와 추적기가 없으며 자체의 뒤선 봉사기를 두지 않습니다."`
- Add new keys: `tabHome`, `moreActions`, `songLocked`, `libraryEmpty`, `libraryEmptyHint`, `signOutConfirmTitle`, `searchNoResults`, `searchNoResultsHint`.
- Register all additions in `Translation.Key.nonAssociatedCases`.

#### Documentation Update (`docs/DESIGN.md`)
Rewrite `docs/DESIGN.md` to reflect the native 4-tab application architecture:
- Update token tables to include `AppTheme.accentOnDark`.
- Remove all references to `WKWebView`, `WebToolbar`, Save Page alerts, and splash progress tracking.
- Document tab bar navigation rules, mini-player visibility conditions, 44pt touch constraints, and Dynamic Type scaling.

---

## 3. Verification Plan

| Package | Verification Method | Pass Criteria |
|---|---|---|
| WP-A | `AppThemeContrastTests.swift` | Contrast ratios $\ge 4.5:1$ (text) and $\ge 3.0:1$ (controls). Zero `AppTheme.accent` as dark foreground. |
| WP-B | Code inspection + mock validation | `artworkImage` purged. Mini-player hidden when no track and on tab 3. Children `.contain` accessibility. |
| WP-C | Static audit + route test | Zero references to `appState.navigationPath`. Per-tab stacks isolated. Back button preserved on pushed views. |
| WP-D | `TabBarSymbolsTests.swift` | Tab symbol existence confirmed. Dot playing indicator without infinite animation. |
| WP-E | Static audit of frames & state | Touch targets $\ge 44\text{pt}$. Library independent async fetch. Search zero-results view renders. |
| WP-F | `TranslationCompletenessTests` | All non-associated keys populated in both English and Korean. `docs/DESIGN.md` updated. |
