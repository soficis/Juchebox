# Juchebox UI/UX Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or superpowers:subagent-driven-development) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute comprehensive UI/UX remediation for Juchebox on iOS 17+, resolving contrast failures, player caching bugs, broken navigation hierarchy, tab bar polish, screen list ergonomics, stale copy, verify on MacBook Neo, capture new screenshots, and update the README.

**Architecture:** Implement token-driven contrast improvements in `AppTheme`, decouple tab navigation by hosting isolated `NavigationStack`s inside a persistent `RootView` `TabHost` powered by `AppState.paths`, isolate the persistent `MiniPlayerBar` and `ChollimaTabBar`, modernize strings via North Korean Munhwaŏ `Translation.Key`, verify with `xcodebuild test` on MacBook Neo, capture new screenshots, and update `README.md`.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, XCTest, iOS 17+ target, iOS 26 simulator on macOS (MacBook Neo).

**Spec:** [`docs/superpowers/specs/2026-10-01-ui-ux-remediation-design.md`](file:///v:/JuchifyIOS/KoreanMusicWebCompanion/docs/superpowers/specs/2026-10-01-ui-ux-remediation-design.md)

---

## Global Constraints

- Zero third-party dependencies; pure Swift 6 and SwiftUI.
- Preserve custom `ChollimaTabBar`; do not reintroduce SwiftUI `TabView`.
- Out of scope: streaming audio logic, `AVPlayerController`, `AudioSessionController`, `JuchifyAPIClient`, `CatalogStore`, and Keychain auth.
- Every user-facing string must be declared in `Translation.Key` with English and North Korean Munhwaŏ (`kp`), and registered in `Translation.Key.nonAssociatedCases`.
- Existing `AccessibilityID` constants must remain unchanged (`homeTab`, `searchTab`, `libraryTab`, `nowPlayingTab`, `settingsTab`, `searchField`).
- Commit style: conventional commits (`feat(ui): ...`, `fix(player): ...`, `docs: ...`), one per work package / task.
- All interactive elements must satisfy $\ge 44 \times 44\text{pt}$ touch targets.

## Review Focus

1. **Stale Artwork:** When transitioning from a track with cached artwork to one without artwork, foreground must render placeholder, never previous cover.
2. **Navigation Isolation:** Pushing an album/artist must preserve `MiniPlayerBar` and `ChollimaTabBar`; switching tabs and returning must retain scroll position, search query, and library loaded state.
3. **Mini-Player Visibility:** Cold launch with no track must keep mini-player completely hidden; switching to Now Playing tab must hide mini-player.
4. **Resilient Library Loading:** Failure of either `likedSongs()` or `recentlyPlayed()` must not discard the other's result; retry banner must be displayed.
5. **Search Recents Cleanliness:** Typing queries must not pollute recent searches on debounce; only Return key, recent item tap, or selecting a result must record a recent query.

---

### Task 1: Establish Remote Validation Baseline on MacBook Neo

**Files:**
- Test target: MacBook Neo `/Users/nathan/Juchebox`
- Output: Baseline test count

**Interfaces:**
- Remote execution over SSH (`plink.exe -ssh -batch -hostkey "SHA256:EQQRITq5aG5oTVc1s90t5Ml91REzrgZdw2v5/gdr7NM=" -pw "2422" nathan@192.168.0.227`)

- [ ] **Step 1: Check existing test status on MacBook Neo**
  Run: `xcodebuild test -project Juchebox.xcodeproj -scheme Juchebox -destination 'platform=iOS Simulator,name=iPhone 17'`
- [ ] **Step 2: Record baseline test count**
  Verify test summary (README expects 79 unit + 6 UI tests).

---

### Task 2: WP-A Contrast Tokens & Relative Luminance Unit Test

**Files:**
- Modify: `Juchebox/App/AppTheme.swift`
- Create: `JucheboxTests/AppThemeContrastTests.swift`
- Modify: `Juchebox/Features/Catalog/HomeView.swift`
- Modify: `Juchebox/Features/Player/MiniPlayerBar.swift`
- Modify: `Juchebox/Features/Player/NowPlayingView.swift`
- Modify: `Juchebox/Features/Library/LibraryView.swift`

**Interfaces:**
- Consumes: `AppTheme.background`, `AppTheme.surface`, `AppTheme.elevatedSurface`
- Produces: `AppTheme.accentOnDark`, `AppTheme.RGBComponents`

- [ ] **Step 1: Write failing contrast unit test in `AppThemeContrastTests.swift`**
  Assert WCAG relative luminance: `accentOnDark` vs `background` $\ge 4.5$, `accentOnDark` vs `elevatedSurface` $\ge 3.0$, `mutedText` vs `background` $\ge 4.5$, `secondaryText` vs `background` $\ge 4.5$.
- [ ] **Step 2: Implement `accentOnDark` and `RGBComponents` in `AppTheme.swift`**
  Add `static let accentOnDark = Color(red: 0.93, green: 0.30, blue: 0.32)` and corresponding RGB component accessors.
- [ ] **Step 3: Migrate foreground color usage sites**
  Replace `foregroundStyle(AppTheme.accent)` with `AppTheme.accentOnDark` on dark backgrounds (`SongRow`, `MiniPlayerBar`, `NowPlayingView`, `LibraryView`).
  In `NowPlayingView`, change album line to un-attenuated `AppTheme.mutedText`.
- [ ] **Step 4: Verify test passes and audit for remaining dark accent foregrounds**
  Run grep audit: zero instances of `foregroundStyle(AppTheme.accent)` on dark surfaces.
- [ ] **Step 5: Commit**
  `git commit -m "feat(tokens): add accentOnDark color token and verify WCAG contrast ratios"`

---

### Task 3: WP-B Player & MiniPlayerBar Stabilization

**Files:**
- Modify: `Juchebox/Features/Player/NowPlayingView.swift`
- Modify: `Juchebox/Features/Player/MiniPlayerBar.swift`
- Modify: `Juchebox/Features/Catalog/HomeView.swift`

**Interfaces:**
- Consumes: `AppTheme.accentOnDark`, `AppState.playerState`, `AppState.selectedTab`
- Produces: Clean foreground artwork in `NowPlayingView`, contained accessibility & conditional visibility in `MiniPlayerBar`

- [ ] **Step 1: Fix stale artwork in `NowPlayingView.swift`**
  Remove `@State private var artworkImage`, `loadArtworkSync`, `loadArtworkAsync`, and manual cache lookups. Render `CachedAsyncImage(url: track?.artworkURL, fallbackURL: track?.artworkFallbackURL)` with `.id(track?.id)`.
- [ ] **Step 2: Wrap `NSLog` in `HomeView.swift` (`CachedAsyncImage`) with `#if DEBUG`**
  Enclose verbose log statements inside `#if DEBUG ... #endif`.
- [ ] **Step 3: Update `MiniPlayerBar.swift` visibility, accessibility, and hit targets**
  - Compute visible condition: `appState.isPlayerBarVisible && appState.playerState.currentTrack != nil && appState.selectedTab != 3`.
  - Change `.accessibilityElement(children: .ignore)` to `.accessibilityElement(children: .contain)`.
  - Fix next button icon: `.resizable().scaledToFit().frame(width: 26, height: 26)` inside 44×44 frame.
  - Apply `AppTheme.accentOnDark` to play/pause button.
- [ ] **Step 4: Commit**
  `git commit -m "fix(player): resolve stale artwork caching and stabilize mini-player bar"`

---

### Task 4: WP-C Navigation Architecture & Tab Isolation

**Files:**
- Modify: `Juchebox/App/AppState.swift`
- Modify: `Juchebox/App/RootView.swift`
- Modify: `Juchebox/Features/Catalog/HomeView.swift`
- Modify: `Juchebox/Features/Catalog/SearchView.swift`
- Modify: `Juchebox/Features/Library/LibraryView.swift`
- Modify: `Juchebox/Features/Catalog/AlbumView.swift`

**Interfaces:**
- Consumes: `CatalogRoute`
- Produces: `AppState.paths: [Int: [CatalogRoute]]`, `AppState.pathBinding(for:)`, `AppState.navigate(to:)`, `AppState.popToRoot(for:)`

- [ ] **Step 1: Refactor `AppState.swift` navigation routing**
  Replace `@Published var navigationPath` with `@Published var paths: [Int: [CatalogRoute]] = [:]`, `pathBinding(for tab: Int) -> Binding<[CatalogRoute]>`, `navigate(to route: CatalogRoute)`, and `popToRoot(for tab: Int)`.
- [ ] **Step 2: Update all 6 navigation call sites**
  Replace `.navigationPath.append(...)` in `AlbumView:111`, `HomeView:114` & `HomeView:263`, `SearchView:239`, and `LibraryView:142` with `appState.navigate(to:)`.
- [ ] **Step 3: Restructure `RootView.swift` with `TabHost`**
  - Place `MiniPlayerBar` and `ChollimaTabBar` outside all navigation stacks.
  - Maintain `@State private var visited: Set<Int> = [0]`.
  - Embed tabs 0, 1, 2 in per-tab `NavigationStack(path: appState.pathBinding(for: n))`.
  - Apply `.toolbar(.hidden, for: .navigationBar)` on root views of stacks.
  - Wire tab re-selection to `popToRoot(for: tab)`.
- [ ] **Step 4: Verify zero remaining references to `navigationPath`**
  Grep search confirming `appState.navigationPath` is completely gone.
- [ ] **Step 5: Commit**
  `git commit -m "feat(navigation): isolate per-tab navigation stacks and preserve tab state"`

---

### Task 5: WP-D Tab Bar Polish & SF Symbol Validation

**Files:**
- Modify: `Juchebox/App/RootView.swift` (`ChollimaTabBar`)
- Modify: `Juchebox/App/Translation.swift`
- Create: `JucheboxTests/TabBarSymbolsTests.swift`

**Interfaces:**
- Consumes: `Translation.Key.tabHome`, `AppTheme.accentOnDark`
- Produces: Polished `ChollimaTabBar` with Dynamic Type scaling and state dot

- [ ] **Step 1: Write SF Symbol unit test in `TabBarSymbolsTests.swift`**
  Verify all symbol names used in `ChollimaTabBar` resolve non-nil from `UIImage(systemName:)`.
- [ ] **Step 2: Update tab 0 identity to Home**
  Change tab 0 to `house` / `house.fill` with title `t(.tabHome)`.
- [ ] **Step 3: Refine tab bar state encoding and typography**
  - Selected tab: gold (`AppTheme.secondaryText`); unselected: `AppTheme.mutedText`.
  - Replace repeating crimson pulse with 6pt `accentOnDark` playing dot over Now Playing icon.
  - Apply `@ScaledMetric` to 56pt bar height and icon sizes.
  - Add `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap and `.accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(ui): polish ChollimaTabBar with dynamic type and validate SF symbols"`

---

### Task 6: WP-E Screens & Lists Refinement

**Files:**
- Modify: `Juchebox/Features/Player/NowPlayingView.swift`
- Modify: `Juchebox/Features/Catalog/HomeView.swift`
- Modify: `Juchebox/Features/Library/LibraryView.swift`
- Modify: `Juchebox/Features/Catalog/SearchView.swift`
- Modify: `Juchebox/Features/Settings/SettingsView.swift`

**Interfaces:**
- Consumes: `Translation.Key` additions (`moreActions`, `songLocked`, `libraryEmpty`, `signOutConfirmTitle`, `searchNoResults`)

- [ ] **Step 1: Now Playing ergonomics (E1)**
  - Ensure shuffle, queue, repeat buttons have 44×44 frames with `contentShape(Rectangle())` and accessibility values.
  - Add accessibility label/value to scrubber and format time labels with `@ScaledMetric` and "−" prefix.
  - Move Like button to transport area so title is properly centered.
- [ ] **Step 2: SongRow, Hero, and Catalog cards (E2, E3)**
  - Expand Like button width to 44pt.
  - Add overflow `Menu` with `moreActions` label and same options as context menu.
  - Replace hardcoded `"Locked"` with `t(.songLocked)`.
  - Add `.accessibilityAddTraits(.isHeader)` to section headers.
  - Ensure "See All" buttons have 44pt touch regions.
  - In `HomeView`, drop hero track from "New Tracks" (`dropFirst()`) and add play overlay glyph.
- [ ] **Step 3: Library Tab resiliency & empty states (E4)**
  - Remove `.prefix(20)` restriction.
  - Load `likedSongs()` and `recentlyPlayed()` independently; surface retry banner on failure.
  - Add `.refreshable { await loadLibrary() }`.
  - Merge liked songs play button into section header.
  - Add `confirmationDialog` before `authStore.signOut()` (LibraryView and SettingsView).
  - Add textContentTypes, submitLabel, and cancel button to `SignInView`.
- [ ] **Step 4: Search Tab zero-results & recents fix (E5)**
  - Show zero-results view when results are empty.
  - Remove `onChange(of: catalog.searchResults)` recents pollution; record only on return key, recent tap, or result selection.
  - Auto-focus search field on appear and tab selection when empty.
- [ ] **Step 5: Commit**
  `git commit -m "feat(ui): refine screen layouts, list ergonomics, and search interactions"`

---

### Task 7: WP-F Copy Modernization, Translations & Documentation

**Files:**
- Modify: `Juchebox/App/Translation.swift`
- Modify: `JucheboxTests/TranslationCompletenessTests.swift`
- Modify: `docs/DESIGN.md`

**Interfaces:**
- Produces: Complete, verified English and North Korean Munhwaŏ translations; accurate native design spec

- [ ] **Step 1: Add new translation keys and modernize WebKit copy**
  - Add `tabHome`, `moreActions`, `songLocked`, `libraryEmpty`, `libraryEmptyHint`, `signOutConfirmTitle`, `searchNoResults`, `searchNoResultsHint`.
  - Update `searchPlaceholder`, `disclaimer2Title/Message`, `disclaimer3Message`, `disclaimer4Message` to accurately describe native API client.
  - Register all new keys in `Translation.Key.nonAssociatedCases`.
- [ ] **Step 2: Verify `TranslationCompletenessTests`**
  Confirm every key has non-empty English and Korean translations.
- [ ] **Step 3: Rewrite `docs/DESIGN.md`**
  Document native 4-tab app, tokens with `accentOnDark`, mini-player visibility, and navigation rules. Purge old WebKit/browser sections.
- [ ] **Step 4: Commit**
  `git commit -m "docs: modernize translations, update design system documentation, and register translation keys"`

---

### Task 8: Full Remote Validation on MacBook Neo & Simulator Verification

**Files:**
- MacBook Neo repo sync and build verification

- [ ] **Step 1: Push changes to remote or sync to MacBook Neo**
- [ ] **Step 2: Run full unit and UI test suite on MacBook Neo**
  `xcodebuild test -project Juchebox.xcodeproj -scheme Juchebox -destination 'platform=iOS Simulator,name=iPhone 17'`
- [ ] **Step 3: Confirm test suite passes with zero warnings**
  Verify test count $\ge \text{baseline} + \text{new tests}$.

---

### Task 9: UI Screenshot Capture on iPhone 17 Simulator & README Update

**Files:**
- Create: `Screenshots/Home.png`, `Screenshots/NowPlaying.png`, `Screenshots/Search.png`, `Screenshots/Library.png`
- Modify: `README.md`

- [ ] **Step 1: Capture updated screenshots from booted iPhone 17 Simulator**
  Use `xcrun simctl io booted screenshot` to capture native app states (Home, Now Playing, Search, Library).
- [ ] **Step 2: Sync screenshots back to `Screenshots/` directory**
- [ ] **Step 3: Update `README.md`**
  Reference new screenshots, update test counts, and reflect native UI/UX improvements.
- [ ] **Step 4: Commit**
  `git commit -m "docs(readme): update screenshots and documentation for UI remediation"`
