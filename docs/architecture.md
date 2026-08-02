# Architecture

Korean Music Web Companion is a native SwiftUI app around a single WebKit browsing surface.

## Layers

- `App/` contains application composition, shared state, audio-session setup, and accessibility identifiers.
- `Features/Web/` contains the `WKWebView` wrapper, navigation coordinator, native chrome, external-link confirmation, and web error UI.
- `Features/Settings/` contains local privacy and project settings.
- `Features/Onboarding/` contains the first-run unofficial-app disclaimer.
- `Features/Diagnostics/` contains local-only sanitized diagnostics.
- `Core/DomainPolicy/` contains the pure navigation decision engine.
- `Core/Privacy/` contains local session preferences and WebKit data clearing.

## Decision Log

### Browser Companion Only

The app is a dedicated browser container for the public Juchify website. It does not call private endpoints, inspect page internals, inject scripts, scrape content, or reimplement playback.

### Fail-Closed Navigation

Only hosts listed in `Resources/domain-allowlist.json` are allowed to load in the app. Unknown HTTPS hosts require explicit user handoff. HTTP and lookalike hosts are blocked.

### No Third-Party Dependencies

The MVP uses SwiftUI, WebKit, AVFoundation, and XCTest only. This keeps builds reproducible and keeps the privacy model easy to audit.

### Local Diagnostics Only

Diagnostics are never sent automatically. They include only sanitized host names, numeric error codes, app/iOS version, device class, timestamp, and session mode.

