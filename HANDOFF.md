# Juchebox (주체박스) — Handoff Document & Project Overview

Welcome to the **Juchebox** iOS codebase! This document provides a complete technical handoff, architectural summary, and operational guide for the application.

---

## 📖 Project Context & Objectives

Juchebox (originally *Korean Music Web Companion*) is a specialized Swift/SwiftUI iOS application designed as a safe, isolated, and themed web wrapper around a configured `WKWebView` to access specific allowed music streaming websites of the Democratic People's Republic of Korea (DPRK).

### Core Goals achieved during the Rebrand:
1. **Zero Warnings/Errors**: Fully resolved Swift 6 strict concurrency errors, main-actor isolation issues, and Xcode recommended configuration settings.
2. **Authentic Socialist Realism Visual Design**: Re-themed the interface using a color palette of **Deep Crimson Red** (`#CD2027`), **Pure Black** (`#0A0A0A`), and **Bright Gold** (`#D4A843`), featuring custom vector star shapes, vinyl record animations, and a SwiftUI-rendered DPRK Flag.
3. **Dynamic Bilingual System**:
   - **English (Juche-themed)**: Uses translated revolutionary terminology ("The People's Revolutionary Music Explorer", "Forward!", "Party Directives").
   - **조선말 (North Korean Dialect / 문화어)**: Applies authentic DPRK spelling conventions (retaining initial 'ㄹ'/'ㄴ' consonants such as "련결", "리해") and translates the English language option pejoratively as **"미제승냥이말"** (US Imperialist Jackal tongue).
4. **AppIcon**: Integrated a premium, high-resolution vector app icon featuring the red star and golden vinyl disc motif.

---

## 🏗️ Architecture & Folder Structure

The application is structured cleanly using a modular, decoupled approach divided into four key layers:

```
KoreanMusicWebCompanion/
├── App/                         # Global Application Configurations
│   ├── JucheboxApp.swift        # App Entrypoint (@main)
│   ├── AppState.swift           # MainActor-isolated global navigation/view state
│   ├── AppStorageKey.swift      # Constants for UserDefaults/AppStorage keys
│   ├── AppTheme.swift           # Central design system token variables (Red, Gold, Black)
│   ├── AudioSessionController.swift  # Manages AVFoundation web audio streams & route changes
│   ├── Translation.swift        # The translation database and AppLanguage definitions
│   └── RootView.swift           # Evaluates onboarding status & routes UI layout
│
├── Core/                        # Foundation & Security Protocols
│   ├── DomainPolicy/
│   │   └── DomainPolicy.swift   # Evaluates links against the local whitelist configuration
│   └── Privacy/
│       ├── PrivacySettings.swift # Coordinates Persistent vs. Ephemeral browsing states
│       └── WebsiteDataCleaner.swift  # Controls purging of cookies, caches, and local storage
│
├── Features/                    # User Interface & View Controllers
│   ├── Diagnostics/
│   │   └── DiagnosticsLog.swift # Compiles device/error diagnostics (stored locally only)
│   ├── Onboarding/
│   │   └── OnboardingView.swift # Onboarding screen with the custom vector DPRK Flag & language picker
│   ├── Settings/
│   │   └── SettingsView.swift   # Settings Panel ("Party Directives")
│   └── Web/                     # Web wrapper implementation
│       ├── WebScreen.swift      # Main viewport with toolbar, progress bar, & error view overlays
│       ├── WebViewContainer.swift  # SwiftUI wrapper mapping UIKit's WKWebView
│       ├── WebNavigationCoordinator.swift  # Safe WKNavigationDelegate & WKUIDelegate coordinator
│       ├── ExternalLinkRequest.swift  # Struct matching external link confirmation alerts
│       ├── WebContentError.swift      # Localized web error helper mappings
│       └── ActivityView.swift   # UIActivityViewController bridging class
│
└── Resources/                   # Build Assets & Manifests
    ├── Assets.xcassets          # Asset Catalog (includes Juchebox AppIcon)
    ├── Info.plist               # App Info Manifest configuration
    └── domain-allowlist.json    # Allowed domain hosts
```

---

## 📡 Dynamic Localization Mapping

The translation mapping is centralized in [Translation.swift](KoreanMusicWebCompanion/App/Translation.swift). Here are key linguistic transitions between the two profiles:

| Original/Key | English Profile (Juche-Themed) | 조선말 Profile (North Korean Dialect) |
| :--- | :--- | :--- |
| **App Name** | Juchebox | 주체박스 (주체음악) |
| **Subtitle** | The People's Revolutionary Music Explorer | 인민의 혁명적 음악 탐색기 |
| **Accept Button** | Forward! | 리해하였으며 전진합네다! |
| **Settings Title** | Party Directives | 조절부 (당지침) |
| **Language Picker Title** | Language Selection | 조선말 / 외부어 선택 |
| **English Option** | English | 미제승냥이말 |
| **Korean Option** | 조선말 | 조선말 |
| **Clear Data Button** | Purge Web Data & Sign Out | 자료 정화 및 퇴장 |
| **Diagnostics Button** | Export Inspection Report | 검열보고서 수출 |

---

## 🔒 Security & Privacy Controls

1. **In-App Sandbox**: Web browsing is locked down using `DomainPolicy`. Only domains explicitly listed in `domain-allowlist.json` will load inside the app. External links trigger an explicit confirmation dialogue.
2. **Privacy Isolation**: The app includes an "Ephemeral Session" toggle. When active, it configures `WKWebsiteDataStore.nonPersistent()` so that no cookies, logs, or site artifacts are written to disk.
3. **Local Inspections**: Diagnostics are generated locally inside `DiagnosticsLog` to audit connections. No analytical SDKs, tracking libraries, or telemetry scripts are included.

---

## 🛠️ Swift 6 Concurrency & Strict Compiling

To comply with Swift 6 and maintain zero compiler warnings:
- Classes managing shared mutable states (`AppState`, `DiagnosticsLog`, `AudioSessionController`, `PrivacySettings`) are isolated to the `@MainActor`.
- Synchronous callback delegate hooks in `WebNavigationCoordinator` (e.g., `webView(_:decidePolicyFor:decisionHandler:)` and `WKUIDelegate` panels) use `@MainActor @Sendable` parameters.
- Asynchronous tasks in `AudioSessionController` leverage structured concurrency `Task { @MainActor in ... }` blocks rather than non-isolated thread dispatching.
- Mutable formatters (like `timestampFormatter`) are annotated with `nonisolated(unsafe)` to assert concurrency safety.

---

## 🚀 How to Run & Verify

To build and compile the application:

1. Open Xcode and load `KoreanMusicWebCompanion.xcodeproj`.
2. Select your target device (e.g., iPhone Simulator).
3. Press `Cmd + R` to run.

To verify via Command Line, execute the following command from the repository root:
```bash
xcodebuild -project KoreanMusicWebCompanion.xcodeproj -scheme KoreanMusicWebCompanion -destination "generic/platform=iOS Simulator" clean build
```
On success, you will see `** BUILD SUCCEEDED **` with no compiler errors or concurrency warnings.
