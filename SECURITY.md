# Security Policy

## Reporting Vulnerabilities

Report security issues through the repository's private security advisory channel when available. If this source is shared outside a hosted repository, contact the maintainer through the release page or project contact listed with the source archive.

Do not include user passwords, cookies, account data, copyrighted media, private media URLs, tokens, or headers in a report.

## In Scope

- Navigation policy bypasses that allow arbitrary websites to load silently inside the app
- Insecure HTTP or TLS handling regressions
- Diagnostics exports that include sensitive data
- App code that stores or exposes cookies, tokens, credentials, or media URLs outside WebKit
- JavaScript bridge or script-injection regressions

## Out of Scope

This project does not accept reports aimed at bypassing Juchify controls, extracting media, scraping content, avoiding access restrictions, reverse engineering private endpoints, or weakening rightsholder protections.

## Security Defaults

- HTTPS is required by App Transport Security.
- Unknown HTTPS hosts require user confirmation before system handoff.
- HTTP is blocked by default.
- There is no JavaScript bridge, no injected user script, no custom backend, and no certificate-bypass mode.

