# Contributing

This project accepts small, focused changes that keep the app an independent, privacy-conscious WebKit companion.

## Ground Rules

- Do not add scraping, downloading, recording, mirroring, indexing, offline playback, JavaScript injection, ad blocking, private API access, or credential interception.
- Do not add Juchify branding, logos, screenshots, copyrighted art, or protected assets.
- Do not add analytics, advertising SDKs, opaque tracking, or a backend service.
- Keep dependencies at zero unless there is a clear, reviewed need.
- Keep code simple, tested, and fail-closed.

## Before Opening A Change

1. Run the unit and UI tests in Xcode.
2. Confirm diagnostics do not include full URLs, cookies, headers, tokens, user-entered content, or media details.
3. Confirm App Transport Security has no insecure exceptions.
4. Confirm external-domain navigation still requires confirmation.

