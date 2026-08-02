# Manual Test Plan

## Browsing

- Fresh install shows the unofficial-app disclaimer before the WebView.
- Accepting the disclaimer opens `https://juchify.com`.
- Back, forward, reload, home, share, settings, and hide/show controls work.
- Unknown HTTPS links show external confirmation.
- HTTP links are blocked with a clear explanation.
- `mailto:` and `tel:` links require confirmation before system handoff.

## Playback

- Sign into a test Juchify account if needed.
- Verify normal foreground playback through the website's own controls.
- Lock the screen and confirm behavior matches what WebKit and the site naturally support.
- Trigger phone-call/headphone/Control Center interruptions and verify playback recovers gracefully or foreground playback remains available.
- Confirm no native metadata, artwork, queue, or download behavior is fabricated.

## Privacy

- Toggle **Use Ephemeral Session** and confirm a new WebKit session is created.
- Use **Clear Website Data and Sign Out** and confirm the app reloads the home page.
- Export diagnostics and confirm there are no full URLs, cookies, headers, tokens, account identifiers, song names, media URLs, or user-entered content.

## Accessibility

- VoiceOver reads all native controls.
- Dynamic Type does not clip settings or disclaimer text.
- Touch targets remain at least 44 pt.
- Focus order is predictable.

