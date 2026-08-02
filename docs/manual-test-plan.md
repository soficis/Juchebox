# Manual Test Plan

## Browsing

- Fresh install shows the unofficial-app disclaimer before the WebView.
- Accepting the disclaimer opens `https://juchify.com`.
- Back, forward, reload, home, share, settings, and hide/show controls work.
- Unknown HTTPS links show external confirmation.
- HTTP links are blocked with a clear explanation.
- `mailto:` and `tel:` links require confirmation before system handoff.
- Search button opens a text field; entering a URL loads it; entering text loads it as an address (no invented search route).
- Save Page button stores the current URL locally and shows a confirmation toast.
- A page that never finishes loading shows the load-timeout error with Reload after 30 seconds.

## Loading & Recovery

- Slow or interrupted loads surface the timeout error after 30 seconds with a Reload button.
- Reload during a hung load restarts the timeout instead of stacking stale timers.
- Rapidly triggering reload/stop does not leave stale loading state.
- Web content process termination shows the error view; recovery is manual via Reload.

## Playback

- Sign into a test Juchify account if needed.
- Verify normal foreground playback through the website's own controls.
- Lock the screen and confirm behavior matches what WebKit and the site naturally support.
- Trigger phone-call/headphone/Control Center interruptions and verify playback recovers gracefully or foreground playback remains available.
- Confirm no native metadata, artwork, queue, or download behavior is fabricated.

## Privacy

- Toggle **Use Ephemeral Session** and confirm a confirmation dialog warns about sign-out and audio interruption before the new WebKit session is created.
- Use **Purge Web Data & Sign Out** and confirm the app reloads the home page.
- Export diagnostics and confirm there are no full URLs, cookies, headers, tokens, account identifiers, song names, media URLs, or user-entered content.
- Confirm the exported navigation timeline contains only sanitized host names and lifecycle events (load started, commit, finish, failure, process termination).

## Accessibility

- VoiceOver reads all native controls.
- Dynamic Type does not clip settings or disclaimer text.
- Touch targets remain at least 44 pt.
- Focus order is predictable.

