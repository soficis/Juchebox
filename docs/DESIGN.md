# Juchebox — Native Design System & Architecture Specification

Product: **Juchebox** (주체박스) · Project: `Juchebox.xcodeproj`
Design direction: **Chollima Radio (천리마방송)** — Spotify's dark immersive audio grammar reconstructed in DPRK revolutionary-poster material. Crimson, gold, coal-black, serif authority. One accent, honest sovereign chrome.

---

## 1. Architectural Model & Core Principles

1. **Fully Native Catalog & Playback** — Juchebox operates exclusively through a native client communicating with the public catalog API. No `WKWebView`, embedded browsers, or JavaScript bridges exist.
2. **Authority Through Restraint** — Every surface earns its presence. The Juche visual language (crimson `#CD2027`, accessible crimson `#EC4D52`, authoritative gold `#D4A843`, coal black `#0A0A0A`, and the revolutionary StarShape) appears strictly on functional elements: primary CTAs, active audio indicators, section headers, and playback controls.
3. **Four Native Exploration Tabs** — The primary interface is organized into 4 sovereign tabs:
   - **Tab 0: Home (`t(.tabHome)`)** — Hero showcase, popular tracks, new releases, popular albums.
   - **Tab 1: Search (`t(.tabSearch)`)** — Live query debouncing, instant search, zero-results empty states, recents management.
   - **Tab 2: Library (`t(.tabLibrary)`)** — Auth-gated synced user collection: Liked Songs, Recently Played, and Playlists.
   - **Tab 3: Now Playing (`t(.tabNowPlaying)`)** — Immersive full-screen playback console with queue management.
4. **Isolated Navigation Hierarchies** — Tabs 0, 1, and 2 host dedicated, isolated `NavigationStack` instances bound to `AppState.paths[tab]`. Pushing a route on one tab does not affect other tabs, and reselecting an active tab pops its stack back to root.
5. **Persistent Shell & External Floating Controls** — `MiniPlayerBar` and `ChollimaTabBar` reside strictly outside all navigation stacks, maintaining uninterrupted playback chrome across deep drill-downs.

---

## 2. Color Tokens (`AppTheme.swift`)

All colors are defined strictly in `AppTheme.swift`. Ad-hoc hex literals or generic system colors are forbidden.

| Token | Hex / sRGB | WCAG Contrast Rationale | Usage |
|---|---|---|---|
| `AppTheme.background` | `#0A0A0A` (0.04, 0.04, 0.04) | — | Deep immersive background canvas. |
| `AppTheme.surface` | `#1A0D0D` (0.10, 0.05, 0.05) | — | Primary container surfaces: cards, lists, tab bar. |
| `AppTheme.elevatedSurface` | `#281214` (0.16, 0.07, 0.08) | — | Elevated surfaces: MiniPlayerBar, modal sheets, dialogs. |
| `AppTheme.hairline` | Gold @ 20% | — | Subtle borders, dividers, card outlines. |
| `AppTheme.primaryText` | `#F5F2EA` (0.96, 0.95, 0.92) | 16.9:1 on canvas | Primary text, titles, song names. |
| `AppTheme.secondaryText` | `#D4A843` (0.83, 0.66, 0.26) | 7.9:1 on canvas | Headings, active tab selection, artists, accents. |
| `AppTheme.mutedText` | `#997F7F` (0.60, 0.50, 0.50) | 4.6:1 on canvas | Timestamps, durations, unselected tabs, secondary captions. |
| `AppTheme.accent` | `#CD2027` (0.804, 0.125, 0.153) | 2.5:1 (Background fill only) | **Backgrounds only**: button fills, progress bar fills, StarShape. Never used as foreground text on dark surfaces. |
| `AppTheme.accentOnDark` | `#EC4D52` (0.93, 0.30, 0.32) | 4.88:1 on canvas, 3.86:1 on surface | **Foreground & Icon Accent**: active playing track text, heart likes, play/pause glyphs, active state dots. |
| `AppTheme.warning` | `#D4A843` (Gold) | 7.9:1 on canvas | Alerts, error banners, network retry buttons. |
| `AppTheme.destructive` | `#B31919` (0.70, 0.10, 0.10) | — | Destructive actions (sign out, clear data). |

### Contrast Rules & WCAG 2.1 Conformance
- Any foreground icon or text requiring crimson branding against dark surfaces MUST use `AppTheme.accentOnDark` (contrast $\ge 4.5:1$ against `#0A0A0A`).
- Background buttons and progress tracks use `AppTheme.accent` with high-contrast text (`primaryText` or `surface`).
- Verified by automated tests in `JucheboxTests/AppThemeContrastTests.swift`.

---

## 3. Spacing & Radius Tokens

### Spacing (`AppSpacing`) — 8pt Grid
- `AppSpacing.xs`: 4pt (icon gaps, tight metadata)
- `AppSpacing.sm`: 8pt (card internal padding, horizontal spacing)
- `AppSpacing.md`: 16pt (standard container padding, section margins)
- `AppSpacing.lg`: 24pt (transport controls, major section dividers)
- `AppSpacing.xl`: 32pt (sheet headers, onboarding padding)

### Corner Radii (`AppRadius`)
- `AppRadius.sm`: 4pt (track thumbnails, badges)
- `AppRadius.md`: 8pt (album cards, text fields, buttons)
- `AppRadius.lg`: 12pt (Now Playing artwork, modal sheets, hero banner)

---

## 4. Typography & Dynamic Type

All fonts are defined with semantic text styles and Dynamic Type scaling:

| Role | Font Style & Design | Weight | Scaling |
|---|---|---|---|
| Large Title | `.system(.largeTitle, design: .serif)` | `.black` | Standard Dynamic Type |
| Screen Title / Hero | `.system(.title2, design: .serif)` | `.black` | Standard Dynamic Type |
| Section Headline | `.system(.headline, design: .serif)` | `.bold` | Header trait (`.isHeader`) |
| Card / Row Title | `.system(.subheadline, design: .serif)` | `.semibold` | Standard Dynamic Type |
| Body Text | `.system(.body, design: .default)` | `.regular` | Standard Dynamic Type |
| Numeric / Duration | `.caption.monospacedDigit()` | `.regular` | Aligned monospaced numbers |
| Tab Bar Label | `.caption2.weight(.medium)` | `.medium` | Capped at `.accessibility1` |

Dynamic Type Cap: Custom navigation and tab bars use `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` to prevent UI truncation under extreme accessibility sizes while allowing graceful text reflow.

---

## 5. Navigation & Layout Architecture

```
RootView
 └─ VStack(spacing: 0)
     ├─ ZStack {
     │    Home Tab (0)     ──> NavigationStack(path: pathBinding(for: 0))
     │    Search Tab (1)   ──> NavigationStack(path: pathBinding(for: 1))
     │    Library Tab (2)  ──> NavigationStack(path: pathBinding(for: 2))
     │    NowPlaying (3)   ──> Standalone Full-Screen View
     │  }
     ├─ MiniPlayerBar (visible when track exists and selectedTab != 3)
     └─ ChollimaTabBar (56pt base height, @ScaledMetric, capped dynamic type)
```

### Tab Preservation & Isolation Rules
1. **Persistent Mounting**: Visited tabs are recorded in `@State private var visited: Set<Int>`. Once visited, tab view hierarchies remain mounted in memory to preserve scroll positions, search results, and navigation history.
2. **Hidden Tab Handling**: Non-active tabs are visually and structurally suppressed using:
   - `.opacity(selectedTab == index ? 1 : 0)`
   - `.allowsHitTesting(selectedTab == index)`
   - `.accessibilityHidden(selectedTab != index)`
3. **Reselect to Pop to Root**: Reselecting an already active tab invokes `appState.popToRoot(for: tab)`, clearing `paths[tab] = []`.
4. **Header Visibility**: Root views within navigation stacks declare `.toolbar(.hidden, for: .navigationBar)` so custom brand headers render cleanly; pushed views (`AlbumView`, `ArtistView`) retain standard system navigation bars with back arrows.

---

## 6. MiniPlayerBar Specifications

- **Height**: 56pt base height on `AppTheme.elevatedSurface`.
- **Visibility Conditions**:
  ```swift
  var isVisible: Bool {
      appState.isPlayerBarVisible &&
      appState.playerState.currentTrack != nil &&
      appState.selectedTab != 3
  }
  ```
- **Tap Behavior**: Switches `selectedTab = 3` to reveal the full Now Playing experience.
- **Controls**:
  - Artwork thumbnail (40×40, `AppRadius.sm`).
  - Track title in `AppTheme.primaryText`, artist in `AppTheme.mutedText`.
  - Play/Pause toggle with 44×44 touch target in `AppTheme.accentOnDark`.
  - Next Track button with 44×44 touch target and scaled 26×26 glyph in `AppTheme.secondaryText`.
- **Accessibility**: VoiceOver container declares `.accessibilityElement(children: .contain)` allowing users to interact directly with internal play/pause and skip controls.

---

## 7. ChollimaTabBar Specifications

- **Tab Items**:
  - `0`: Home (`house` / `house.fill`), title `t(.tabHome)`
  - `1`: Search (`magnifyingglass`), title `t(.tabSearch)`
  - `2`: Library (`music.note.list`), title `t(.tabLibrary)`
  - `3`: Now Playing (`music.note` / `play.circle.fill`), title `t(.tabNowPlaying)`
- **Active State Encoding**:
  - Selected tab: `AppTheme.secondaryText` (Gold).
  - Unselected tab: `AppTheme.mutedText`.
  - Now Playing active track dot: 6pt `AppTheme.accentOnDark` circle indicator positioned top-trailing on the Now Playing icon when audio is active (replacing infinite repeating pulse animations).
- **Hit Region**: Each tab button has a minimum 44pt touch height and full-width frame with `contentShape(Rectangle())`.
- **Accessibility Traits**: `.accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])`.

---

## 8. Screen Ergonomics & Touch Target Standards

1. **Touch Targets**: All interactive elements (buttons, menus, sliders, see-all links) enforce a minimum hit region of $44 \times 44\text{pt}$ with `contentShape(Rectangle())`.
2. **Lists & Rows**:
   - `SongRow`: Displays artwork, title, artist, locked indicator, duration, like button (44×44pt), and overflow `Menu` (44×44pt) exposing Play Next, Add to Queue, Go to Album, and Like.
   - Long-press context menus mirror the visible overflow menus.
3. **Search Experience**:
   - Auto-focuses search field upon first appearance or when navigating to an empty search tab.
   - Live search is debounced at 350ms.
   - Recent search queries are stored only upon Return submission, recent query tap, or result selection.
   - Zero-results view surfaces clear hints when queries yield no items.
4. **Library & Authentication**:
   - Independent parallel loading for liked songs and recently played tracks ensures partial network errors do not wipe local data.
   - Native pull-to-refresh (`.refreshable`).
   - Destructive sign-out requires confirmation dialog in both Library and Settings.

---

## 9. Internationalization & String Catalog

- **Languages Supported**: English (`en`) and North Korean Munhwaŏ (`kp`).
- **Storage**: All strings are centralized in `Translation.swift` under `Translation.Key`.
- **Completeness Enforcement**: Every case in `Translation.Key.nonAssociatedCases` is verified by `TranslationCompletenessTests.swift` to ensure non-empty English and Korean translations.
