# Threat Model

## Assets To Protect

- User credentials and cookies held by WebKit
- User browsing context
- Website data stored by WebKit
- Media URLs and rightsholder-controlled content
- The project's non-affiliation posture

## Main Risks

| Risk | Mitigation |
| --- | --- |
| Arbitrary sites silently loading in-app | `DomainPolicy` allowlist and external confirmation |
| Insecure navigation | ATS plus explicit HTTP blocking |
| Sensitive data in diagnostics | Sanitized host-only diagnostics |
| Page/app boundary confusion | Native chrome is visually distinct and uses system controls |
| Media extraction pressure | No JavaScript injection, no bridge, no scraping, no downloader |
| Branding confusion | Neutral app name and repeated unofficial disclaimer |

## Explicit Non-Goals

- Bypassing Juchify controls
- Extracting or caching media
- Replacing the website's playback UI
- Collecting analytics
- Operating a backend or proxy

