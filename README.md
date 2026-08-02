# Juchebox

Juchebox is an independent, sideload-only iOS browser companion for people who already choose to use the public Juchify website.

It is not an official client, not endorsed by Juchify, Chollima Front, DPRK institutions, or any music rightsholder, and not a replacement service. The app is a native SwiftUI shell around `https://juchify.com` with a strict navigation policy, local-only privacy controls, and no analytics.

## What This Is Not

- No music downloading, recording, extraction, offline playback, scraping, mirroring, crawling, or indexing.
- No private API client and no reverse engineering of Juchify internals.
- No JavaScript injection, page modification, ad blocking, DRM bypass, paywall bypass, or credential interception.
- No bundled Juchify logo, favicon, screenshots, copyrighted artwork, or protected branding.
- No backend, proxy, telemetry, analytics SDK, advertising SDK, or crash-reporting SDK.

## Requirements

- iOS 17 or newer
- Xcode 16 or newer
- Swift 6
- A user-controlled Apple signing setup for installing on a device

## Build From Source

1. Open `Juchebox.xcodeproj` in Xcode.
2. Select the `Juchebox` scheme.
3. Set your Apple development team in Signing & Capabilities.
4. Build and run on an iOS 17+ simulator or your own signed device.

The project has no third-party dependencies.

## Sideloading

iOS requires signing. This project supports source distribution first:

- Build and install from Xcode with your own Apple account.
- Use AltStore-style self-signing only from source you inspect yourself.
- Use Ad Hoc exports only for explicitly registered test devices.

Do not provide your Apple ID or password to this app or repository.

## Privacy Summary

The app does not operate a server and does not collect analytics. Website browsing, login, and streaming activity happens inside WebKit when you choose to visit Juchify, and Juchify may process that activity under its own policies.

The app can clear locally stored WebKit website data and can use an ephemeral session so sign-in state is not intended to persist after the app closes.

Diagnostics are local-only and exportable only by explicit user action. They include sanitized host names and numeric error codes, never full URLs, cookies, tokens, page HTML, headers, media URLs, account identifiers, song names, or user-entered content.

## Security

Navigation is restricted by `DomainPolicy`. Allowed in-app hosts are configured in `Juchebox/Juchebox/Resources/domain-allowlist.json`; unknown third-party navigation is confirmed before system handoff, and insecure HTTP is blocked.

Report vulnerabilities through the repository security contact described in [SECURITY.md](SECURITY.md). Do not include passwords, cookies, account data, copyrighted media, or bypass instructions in reports.

## Public Site

This independent app opens the public Juchify website: [https://juchify.com](https://juchify.com)

