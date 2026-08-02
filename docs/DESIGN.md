# Juchebox — Chollima Radio Design System (V1)

Product: **Juchebox** (주체박스) · Project: `Juchebox.xcodeproj`
Design direction: **Chollima Radio (천리마방송)** — Spotify's dark immersive grammar reconstructed in DPRK revolutionary-poster material. Crimson, gold, coal-black. Serif authority. One accent, honest chrome.

## 1. Design Principles

1. **Authority Through Restraint** — every surface earns its presence. The Juche material (red, gold, star) appears only on elements that do something: buttons, active states, section headers. Not wallpaper.
2. **Honest Content, Sovereign Chrome** — the app is native chrome around site content. Native surfaces show only user-created data (saved URLs) or legitimate WKWebView state (loading, host, errors). Never fabricated metadata, artwork, or playback state.
3. **Revolutionary Tempo** — motion maps to real state changes only. 150–250ms, GPU-composited (`opacity`/`transform`), `prefers-reduced-motion` respected.

## 2. Color Tokens (exact values — no drift from AppTheme)

| Token | Value | Rationale |
|---|---|---|
| `AppTheme.background` | `#0A0A0A` (0.04, 0.04, 0.04) | Immersive dark canvas. Spotify `#121212` translated to DPRK black. |
| `AppTheme.surface` | `#1A0D0D` (0.10, 0.05, 0.05) | Cards, list rows, tab bar. Warm-black crimson undertone. |
| `AppTheme.elevatedSurface` | `#281214` (0.16, 0.07, 0.08) | Mini-player, modals, banners. |
| `AppTheme.hairline` | gold @ 20% | Hairline dividers, borders. Presence, not noise. |
| `AppTheme.primaryText` | `#F5F2EA` (0.96, 0.95, 0.92) | Body text. Warm off-white. |
| `AppTheme.secondaryText` | `#D4A843` gold (0.83, 0.66, 0.26) | Headings, active tab labels, emphasis. Gold = authoritative. |
| `AppTheme.mutedText` | `#997F7F` (0.6, 0.5, 0.5) | Disabled states, timestamps, metadata. |
| `AppTheme.accent` | `#CD2027` crimson (0.804, 0.125, 0.153) | Primary CTA, active toggles, progress, StarShape fill. |
| `AppTheme.warning` | `#D4A843` gold | Error-card borders, action buttons in banners. |
| `AppTheme.destructive` | `#B31919` (0.7, 0.1, 0.1) | Purge data, destructive actions. |
| `AppTheme.mutedText` | — | (already listed) |

No new color families. `success` green is **explicitly rejected** (validator attack: red/gold/black app has no green family).

## 3. Spacing Tokens — `AppSpacing` (8pt grid)

| Token | Value | Use |
|---|---|---|
| `AppSpacing.xs` | 4 | Icon gaps, tight internal padding |
| `AppSpacing.sm` | 8 | Card internal padding, button padding |
| `AppSpacing.md` | 16 | Card spacing, section padding |
| `AppSpacing.lg` | 24 | Major section gaps |
| `AppSpacing.xl` | 32 | Onboarding section gaps |

## 4. Radius Tokens — `AppRadius`

| Token | Value | Use |
|---|---|---|
| `AppRadius.sm` | 4 | Badges, small chips |
| `AppRadius.md` | 8 | Buttons, banners, disclaimer cards (existing) |
| `AppRadius.lg` | 12 | Cards, modals, search field |

## 5. Motion Tokens — `AppMotion`

| Token | Value | Use |
|---|---|---|
| `AppMotion.fast` | 0.15 | Button press, toggle, tab switch |
| `AppMotion.default` | 0.25 | Fades, sheet presentation, splash exit |

All animations GPU-composited (`opacity`, `transform` only). Never animate layout properties. Respect `@Environment(\.accessibilityReduceMotion)` → replace motion with opacity crossfade.

## 6. Typography

| Role | Font | Weight |
|---|---|---|
| Display/Hero | `.system(design: .serif)` | `.black` |
| Heading | `.system(.title3, design: .serif)` | `.bold` |
| Subheading | `.system(.headline, design: .serif)` | `.bold` |
| Body | `.system(.body, design: .default)` | `.regular` |
| Caption | `.system(.caption, design: .default)` | `.medium` |
| Button | `.system(.body, design: .serif)` | `.black` |

## 7. Iconography

SF Symbols only. No emojis, no custom icon assets. Star motif via existing `StarShape` (SwiftUI Path) — used on splash, error states, CTA accents. Not decorative wallpaper.

## 8. V1 Component Inventory (with all states)

### Tab Bar (Browse + Settings)
| State | Visual |
|---|---|
| Default (inactive) | `mutedText` + outline SF Symbol on `AppTheme.surface` |
| Active | `secondaryText` (gold) + filled SF Symbol |
| Disabled | N/A — tabs never disabled |

### Loading Splash
| State | Visual |
|---|---|
| Visible | `AppTheme.background` full-screen, StarShape in `accent` (60pt centered), "주체박스"/"Juchebox" in `secondaryText` hero serif below |
| Exiting | Fade out `opacity` 1→0 over `AppMotion.default`, then reveal WebView |

Exit rule: fade out when `appState.isLoading == false && appState.estimatedProgress >= 1.0` OR when webContentError appears. No skeleton shimmer, no staggered sub-animations, no minimum-duration logic.

### Toolbar Buttons (existing WebToolbar, plus Search + Save)
| State | Visual |
|---|---|
| Default | `secondaryText` bold SF Symbol, 44×44 hit target |
| Disabled | `mutedText` (back/forward when no history) |
| Pressed | System button press feedback |

### Search Entry (toolbar button → alert with TextField)
| State | Visual |
|---|---|
| Default | Magnifying glass SF Symbol |
| Alert | TextField + "Go"/"Cancel" (translated), gold text on dark |

**Constraint:** NO hardcoded search URL. User-entered text is loaded as-is via `appState.load(url:)`. The site's search route is a black box (validator attack) — we never invent URLs.

### Save Page (toolbar button)
| State | Visual |
|---|---|
| Default | Bookmark SF Symbol |
| Saved | Toast: "Page saved"/"페지 보관됨" |
| No URL | Toast: "No page to save"/"보관할 페지 없음" |

Storage: `UserDefaults` array of URL strings (user-created data only — doctrine-compliant).

### Error Card (existing WebErrorView — design tokens applied)
| State | Visual |
|---|---|
| Active | `AppTheme.surface` card, gold border, StarShape in crimson, title gold serif, "다시읽기"/"Reload" crimson button |
| Retry in progress | Button shows spinner |

## 9. Accessibility Constraints

- Touch targets ≥ 44×44pt.
- Dynamic Type: no fixed-height clipping; all text reflows.
- VoiceOver: every control has a non-empty accessibility label via `Translation` catalog (all labels centralized — D2 regression guard).
- Reduced motion respected.
- Dark mode always (app is dark-only by design).

## 10. Accepted Debt (V1)

- No Card Grid / Discover surface (V2 rejected by owner — not needed).
- No My Library tab (Save Page button only; list UI if demand appears).
- No Mini-Player bar (no legitimate audio-state signal exists — validator attack; never fabricate).
- No skeleton shimmer (over-engineering — skeptic verdict).
- WebToolbar remains a bottom bar above the tab bar in Browse tab (not replaced by a 4-tab Navigator Shell).
